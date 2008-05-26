class Valar
  VERSION = '1.0.0'
  RUBY_TYPES = %w{Ruby.String Ruby.Array Ruby.Value Ruby.Int Ruby.Number Ruby.Float Ruby.Hash}
  TYPE_CHECK = {
    "Ruby.Array" => ["T_ARRAY", "expected an Array"],
    "Ruby.String" => ["T_STRING", "expected a String"],
    "Ruby.Class" => ["T_CLASS", "expected a Class"],
    "Ruby.Module" => ["T_MODULE", "expected a Module"],
    "Ruby.Regexp" => ["T_REGEXP", "expected a Regexp"],
    "Ruby.Hash" => ["T_HASH", "expected a Hash"],
    "Ruby.File" => ["T_FILE", "expected a File"],
    "Ruby.Match" => ["T_MATCH", "expected a Matchdata"],
    "Ruby.Symbol" => ["T_SYMBOL", "expected a Symbol"],
    "Ruby.Float" => ["T_FLOAT", "expected a Float"]
  }
  COMPOSITE_TYPE_CHECK = {
    "Ruby.Bool" => [["T_TRUE", "T_FALSE"], "expected true or false"],
    "Ruby.Int" => [["T_BIGNUM", "T_FIXNUM"], "expected an integer"],
    "Ruby.Number" => [["T_BIGNUM", "T_FIXNUM", "T_FLOAT"], "expected a number"],
  }
  
  TYPE_MAP = {
    'char'          => [ 'NUM2CHR',  'CHR2FIX' ],
    'char *'        => [ 'STR2CSTR', 'rb_str_new2' ],
    'char*'         => [ 'STR2CSTR', 'rb_str_new2' ],
    'const char *'  => [ 'STR2CSTR', 'rb_str_new2' ],
    'const char*'   => [ 'STR2CSTR', 'rb_str_new2' ],
    'double'        => [ 'NUM2DBL',  'rb_float_new' ],
    'int'           => [ 'F'+'IX2INT',  'INT2FIX' ],
    'long'          => [ 'NUM2INT',  'INT2NUM' ],
    'unsigned int'  => [ 'NUM2UINT', 'UINT2NUM' ],
    'unsigned long' => [ 'NUM2UINT', 'UINT2NUM' ],
    'unsigned'      => [ 'NUM2UINT', 'UINT2NUM' ],
    'VALUE'         => [ '', '' ],
    # Can't do these converters because they conflict with the above:
    # ID2SYM(x), SYM2ID(x), NUM2DBL(x), F\IX2UINT(x)
  }

  def self.ruby2c(type)
    raise ArgumentError, "Unknown type #{type.inspect}" unless TYPE_MAP.has_key? type
    TYPE_MAP[type].first
  end
  
  def self.c2ruby(type)
    raise ArgumentError, "Unknown type #{type.inspect}" unless TYPE_MAP.has_key? type
    TYPE_MAP[type].last
  end

  class ValaObject
    attr_accessor :name, :methods
    
    def self.new_from_xml(el)
      obj = ValaObject.new
      obj.name = el.attributes["name"]
      obj.methods = []
      el.elements.each("method") do |el2| 
        method = ValaMethod.new_from_xml(el2)
        method.obj = obj
        obj.methods << method
      end
      obj
    end
  end
  
  class ValaMethod
    attr_accessor :name, :symbol, :params, :returns, :obj
    
    def output(out)
      out.puts header
      out.puts type_checks
      out.puts argument_type_conversions
      out.puts body
      out.puts return_type_conversion
      out.puts <<END
    return _rb_return;
}

END
    end
    
    def convertible?
      (returns =~ /^Ruby\./ or returns == "void" or ctype?(returns)) and params[1..-1].all? {|param| param[0] =~ /^Ruby\./ or ctype?(param[0])}
    end
    
    def header
      f=<<END
static #{rb_return_type} rb_#{symbol}(#{rb_arg_list}) {
    #{obj.name} *#{obj.name.downcase};
    Data_Get_Struct(self, #{obj.name}, #{obj.name.downcase});
END
    end
    
    def type_checks
      str = ""
      params.each do |param|
        next unless RUBY_TYPES.include? param[0]
        ctype, msg = TYPE_CHECK[param[0]]
        if ctype
          str << f=<<END
    if (TYPE(#{param[1]}) != #{ctype}) {
        VALUE rb_arg_error = rb_eval_string("ArgumentError");
        rb_raise(rb_arg_error, "#{msg}");
    }
END
        end
        ctypes, msg = COMPOSITE_TYPE_CHECK[param[0]]
        if ctypes
          condition = ctypes.map {|ctype| "TYPE(#{param[1]}) != #{ctype}"}.join(" && ")
          str << f=<<END
    if (#{condition}) {
        VALUE rb_arg_error = rb_eval_string("ArgumentError");
        rb_raise(rb_arg_error, "#{msg}");
    }
END
        end
      end
      str
    end
    
    def argument_type_conversions
      str = ""
      params.each do |param|
        next if RUBY_TYPES.include? param[0]
        next if param[0] == obj.name+"*"
#        if convert_method = RUBY_TO_C_CONVERSIONS[param[0]]
          str << f=<<END
    #{param[0]} _c_#{param[1]} = #{Valar.ruby2c(param[0])}(#{param[1]});
END
#        end
      end
      str
    end
    
    def return_type_conversion
      if returns == "void"
        f=<<END
    VALUE _rb_return = Qnil;
END
      elsif ctype?(returns)
        f=<<END
    VALUE _rb_return = #{Valar.c2ruby(returns)}(_c_return);
END
      else
        ""
      end
    end
    
    def body
      if RUBY_TYPES.include? returns
        f=<<END
    VALUE _rb_return = #{symbol}(#{c_arg_list});
END
      elsif returns == "void"
        f=<<END
    #{symbol}(#{c_arg_list});
END
      else
        f=<<END
    #{Valar.vala_type(returns)} _c_return;
    _c_return = #{symbol}(#{c_arg_list});
END
        
      end
    end
    
    def rb_return_type
      "VALUE"
    end
    
    def rb_arg_list
      @params.map {|a| "VALUE "+a[1] }.join(", ")
    end
    
    def c_arg_list
      str = obj.name.downcase
      if params.length > 1
        str << ", "
      end
      str << params[1..-1].map do |param|
        if ctype?(param[0])
          "_c_"+param[1]
        else
          param[1]
        end
      end.join(", ")
      str
    end
    
    def ctype?(type)
      TYPE_MAP.include? type
    end
    
    def self.new_from_xml(el)
      obj = ValaMethod.new
      obj.params = []
      return_type = nil
      el.elements.each("return-type") {|rt| return_type = rt.attributes["type"]}
      el.elements.each("parameters/parameter") do |p1|
        obj.params << [p1.attributes["type"], p1.attributes["name"]]
      end
      obj.name = el.attributes["name"]
      obj.symbol = el.attributes["symbol"]
      obj.returns = return_type
      obj
    end
  end
  
  def self.vala_type(type)
    if RUBY_TYPES.include? type
      "VALUE"
    else
      type
    end
  end

  def self.parse_file(filename)
    if File.extname(filename) == ".gidl"
      parse_gidl_file(filename)
    else
      parse_vapi_file(filename)
    end
    output(filename)
  end
  
  def self.parse_gidl_file(filename)
    puts "loading #{filename}"
    doc = REXML::Document.new(File.read(filename))

    @objects = []

    doc.elements.each("api/object") do |el|
      @objects << ValaObject.new_from_xml(el)
    end
    
    doc.elements.each("api/struct") do |el|
      @objects << ValaObject.new_from_xml(el)
    end
  end
  
  def self.parse_vapi_file(filename)
    puts "loading #{ARGV[0]}"
    vapi_src = File.read(filename)
    
    @objects = []
    current_obj = nil
    vapi_src.each_line do |line|
      if line =~ /public class (.*) \{/
        current_obj = ValaObject.new
        @objects << current_obj
      end
    end
    exit
  end
  
  def self.output(filename)
    @objects.each do |obj|
      puts "object: #{obj.name}"
      obj.methods.each do |meth|
        print "  #{vala_type(meth.returns).ljust(12)} #{meth.symbol.ljust(22)}("
        print meth.params.map{|a| a.join " "}.join(", ")
        puts ")"
      end
    end

    obj = @objects.first
    objname = obj.name.downcase
    File.open(File.dirname(filename)+"/#{objname}_rb.c", "w") do |fout|
      fout.puts <<END
#include "ruby.h"
#include "#{objname}.h"

static VALUE c#{obj.name};

static void rb_#{objname}_destroy(void* #{objname}) {
    // this needs an unref I think.
}

static VALUE rb_#{objname}_alloc(VALUE klass) {
    #{obj.name} *#{objname} = #{objname}_new(#{objname}_get_type());
    VALUE obj;
    obj = Data_Wrap_Struct(klass, 0, rb_#{objname}_destroy, #{objname});
    return obj;
}

END
      obj.methods.each do |method|
        method.output(fout) if method.convertible?
      end
      
      fout.puts <<END
void Init_#{objname}_rb() {
    g_type_init();
    c#{obj.name} = rb_define_class("#{obj.name}", rb_cObject);
    rb_define_alloc_func(c#{obj.name}, rb_#{objname}_alloc);
END
      obj.methods.each do |method|
        if method.convertible?
          fout.puts <<END
    rb_define_method(c#{obj.name}, "#{method.name}", rb_#{method.symbol}, #{method.params.length-1});
END
        end
      end
      fout.puts "}\n"
    end

  end
end
