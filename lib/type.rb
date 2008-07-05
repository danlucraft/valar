
class Valar
  class ValaTypeInstance
    attr_accessor :type, :nullable
    
    def nullable?
      @nullable
    end
    
    def initialize(type, nullable)
      @type = type
      @nullable = nullable
    end
    
    def method_missing(sym, *args, &block)
      return nil unless @type
      @type.send(sym, *args, &block)
    end
  end
  
  class ValaType
    attr_accessor :name, :type_builder, :superclass
    
    class TypeBuilder
      def initialize
        @c_to_ruby = {}
        @ruby_to_c = {}
      end
    
      def underscore_type(val)
        @underscore_type = val
      end
      
      def ruby_type(val)
        @ruby_type = val
      end
    
      def ruby_vala_type(val)
        @ruby_vala_type = val
      end
      
      def c_type(val)
        @c_type = val
      end
      
      def ruby_type_check(type_check_types, type_check_message)
        @type_check_types = type_check_types
        @type_check_message = type_check_message
      end
      
      def c_to_ruby(where=:after, &block)
        @c_to_ruby[where] = block
      end
      
      def ruby_to_c(where=:before, &block)
        @ruby_to_c[where] = block
      end
      
      def args(&block)
        @args = block
      end
      
      def return_args(&block)
        @return_args = block
      end
    end
    
    def underscore_type
      @type_builder.instance_variable_get(:@underscore_type)
    end
    
    def ruby_type
      @type_builder.instance_variable_get(:@ruby_type)
    end

    def ruby_vala_type
      @type_builder.instance_variable_get(:@ruby_vala_type)
    end

    def c_type
      @type_builder.instance_variable_get(:@c_type)
    end
    
    def ruby_type_check
      return @type_builder.instance_variable_get(:@type_check_types),
             @type_builder.instance_variable_get(:@type_check_message)
    end
    
    def args(name)
      @c = name
      block = @type_builder.instance_variable_get(:@args)
      self.instance_eval(&block) if block
    end

    def return_args(name)
      @ruby = name
      block = @type_builder.instance_variable_get(:@return_args)
      self.instance_eval(&block) if block
    end
    
    attr_accessor :c, :ruby
    
    def c_to_ruby(where, from, to)
      @c, @ruby = from, to
      block = @type_builder.instance_variable_get(:@c_to_ruby)[where]
      return "" unless block
      self.instance_eval(&block)
    end
    
    def ruby_to_c(where, from, to)
      @ruby, @c = from, to
      block = @type_builder.instance_variable_get(:@ruby_to_c)[where]
      return "" unless block
      self.instance_eval(&block)
    end

    def forward_convertible?
      @type_builder.instance_variable_get(:@ruby_to_c).size > 0
    end
    
    def backward_convertible?
      @type_builder.instance_variable_get(:@c_to_ruby).size > 0
    end

    def self.parse(string)
      if string[-1..-1] == "?"
        type = ValaType.find_type(string[0..-2])
        unless type
          type = ValaType.create(string) {}
        end
        ValaTypeInstance.new(type, true)
      else
        type = ValaType.find_type(string)
        unless type
          type = ValaType.create(string) {}
        end
        ValaTypeInstance.new(type, false)
      end
    end
    
    def self.create(name, &block)
      vb = TypeBuilder.new
      vb.instance_eval(&block)
      vt = ValaType.new
      vt.type_builder = vb
      vt.name = name
      @types ||= []
      @types << vt
      vt
    end
    
    def self.create_vala_ruby_type(name, &block)
      vb = TypeBuilder.new
      vb.instance_eval(&block)
      vt = ValaRubyType.new
      vt.type_builder = vb
      vt.name = name
      @types ||= []
      @types << vt
      vt
    end
    
    def self.types
      @types ||= []
    end
    
    def self.find_type(string)
      @types.find{|t| t.name == string}
    end
  end
  
  class ValaRubyType < ValaType
    def forward_convertible?
      true
    end
    
    def backward_convertible?
      true
    end

    def c_type
      "VALUE"
    end
    
    def c_to_ruby(where, from, to)
      case where
      when :before
        nil
      when :after
        "#{to} = #{from};"
      end
    end
    
    def ruby_to_c(where, from, to)
      case where
      when :before
        "#{to} = #{from};"
      when :after
        nil
      end
    end
  end
  
  ValaType.create("void") do
    ruby_type       "NilClass"
    c_type          "void"
    
    c_to_ruby { "#{ruby} = Qnil;"       }
  end

  ValaType.create("int") do
    ruby_type       "Fixnum"
    ruby_vala_type  "Ruby.Int"
    c_type          "int"
    ruby_type_check ["T_FIXNUM"], "expected a small integer"
    
    c_to_ruby { "#{ruby} = INT2FIX(#{c});"       }
    ruby_to_c { "#{c} = FIX2INT(#{ruby});"  }
  end

  ValaType.create("long") do
    ruby_type       "Fixnum"
    ruby_vala_type  "Ruby.Int"
    c_type          "long"
    ruby_type_check ["T_FIXNUM"], "expected a small integer"
    
    c_to_ruby { "#{ruby} = LONG2FIX(#{c});"       }
    ruby_to_c { "#{c} = FIX2LONG(#{ruby});"  }
  end

  ValaType.create("double") do
    ruby_type       "Float"
    ruby_vala_type  "Ruby.Float"
    c_type          "double"
    ruby_type_check ["T_FLOAT"], "expected a float"
    
    c_to_ruby { "#{ruby} = rb_float_new(#{ruby});"  }
    ruby_to_c { "#{c} = NUM2DBL(#{ruby});"  }
  end
  
  ValaType.create("string") do
    ruby_type       "String"
    ruby_vala_type  "Ruby.String"
    c_type          "char *"
    ruby_type_check ["T_STRING"], "expected a string"
    
    c_to_ruby { "#{ruby} = rb_str_new2(#{c});" }
    ruby_to_c { "#{c} = STR2CSTR(#{ruby});"    }
  end
  
  ValaType.create("bool") do
    ruby_vala_type "Ruby.Bool"
    c_type         "gboolean"
    ruby_type_check ["T_TRUE", "T_FALSE"], "expected true or false"
    
    c_to_ruby do 
      <<-END
      if (#{c} == TRUE)
          #{ruby} = Qtrue;
      else
          #{ruby} = Qfalse;
      END
    end
    
    ruby_to_c do
      <<-END
      if (#{ruby} == Qtrue)
          #{c} = TRUE;
      else
          #{c} = FALSE;
      END
    end
  end
  
  ValaType.create("unichar") do
    ruby_type       "String"
    ruby_vala_type  "Ruby.String"
    c_type          "gunichar"
    ruby_type_check ["T_STRING"], "expected a string"
    
    c_to_ruby { "#{ruby} = rb_str_new2(g_ucs4_to_utf8(&#{c}, 1, NULL, NULL, NULL));" }
    ruby_to_c { "#{c} = *g_utf8_to_ucs4(STR2CSTR(#{ruby}), RSTRING_LEN(#{ruby}), NULL, NULL, NULL);"        }
  end
  
  ValaType.create("string[]") do
    ruby_type      "Array"
    ruby_vala_type "Ruby.Array"
    c_type         "char**"
    ruby_type_check ["T_ARRAY"], "expected an array of strings"
    
    ruby_to_c(:before) do
      <<-END
          int #{c}__length = RARRAY_LEN(#{ruby});
          #{c} = malloc(#{c}__length*sizeof(char*));
          long #{u1=Valar.uniqid};
          for(#{u1} = 0; #{u1} < #{c}__length; #{u1}++) {
             *(#{c}+#{u1}) = RSTRING_PTR(rb_ary_entry(#{ruby}, (long) #{u1}));
          }
      END
    end
    
    args       { "#{c}, #{c}__length" }
    
    c_to_ruby(:before) do 
      <<-END
          int #{ruby}__length;
      END
    end

    return_args { "&#{ruby}__length" }
    
    c_to_ruby(:after) do
      <<-END
          #{ruby} = rb_ary_new2(#{ruby}__length);
          long #{u1=Valar.uniqid};
          for(#{u1} = 0; #{u1} < #{ruby}__length; #{u1}++) {
              rb_ary_store(#{ruby}, #{u1}, rb_str_new2(#{c}[#{u1}]));
          }
      END
    end
  end

  ValaType.create("int[]") do
    ruby_type      "Array"
    ruby_vala_type "Ruby.Array"
    c_type         "gint*"
    ruby_type_check ["T_ARRAY"], "expected an array of integers"
    
    ruby_to_c(:before) do
      <<-END
          int #{c}__length = RARRAY_LEN(#{ruby});
          #{c} = malloc(#{c}__length*sizeof(gint));
          long #{u1=Valar.uniqid};
          for(#{u1} = 0; #{u1} < #{c}__length; #{u1}++) {
             #{c}[#{u1}] = NUM2INT(rb_ary_entry(#{ruby}, (long) #{u1}));
          }
      END
    end
    
    args       { "#{c}, #{c}__length" }
    
    c_to_ruby(:before) do 
      <<-END
          int #{ruby}__length;
      END
    end

    return_args { "&#{ruby}__length" }
    
    c_to_ruby(:after) do
      <<-END
          #{ruby} = rb_ary_new2(#{ruby}__length);
          long #{u1=Valar.uniqid};
          for(#{u1} = 0; #{u1} < #{ruby}__length; #{u1}++) {
              rb_ary_store(#{ruby}, #{u1}, INT2NUM(#{c}[#{u1}]));
          }
      END
    end
  end
  
  ValaType.create_vala_ruby_type("Ruby.Value") {}
  ValaType.create_vala_ruby_type("Ruby.String")  do
    ruby_type_check ["T_STRING"], "expected a string"
  end
  ValaType.create_vala_ruby_type("Ruby.Number") do
    ruby_type_check ["T_FIXNUM", "T_BIGNUM", "T_FLOAT"], "expected a number"
  end
  ValaType.create_vala_ruby_type("Ruby.Int") do
    ruby_type_check ["T_FIXNUM"], "expected a small integer"
  end
  ValaType.create_vala_ruby_type("Ruby.Array") do
    ruby_type_check ["T_ARRAY"], "expected an array"
  end
  ValaType.create_vala_ruby_type("Ruby.Bool") {}
  ValaType.create_vala_ruby_type("Ruby.Hash") do
    ruby_type_check ["T_HASH"], "expected a Hash"
  end
  ValaType.create_vala_ruby_type "Ruby.Class" do
    ruby_type_check ["T_CLASS"], "expected a Class"
  end
  ValaType.create_vala_ruby_type "Ruby.Module" do
    ruby_type_check ["T_MODULE"], "expected a Module"
  end
  ValaType.create_vala_ruby_type "Ruby.Regexp" do
    ruby_type_check ["T_REGEXP"], "expected a Regexp"
  end
  ValaType.create_vala_ruby_type "Ruby.File" do
    ruby_type_check ["T_FILE"], "expected a File"
  end
  ValaType.create_vala_ruby_type "Ruby.Match" do
    ruby_type_check ["T_MATCH"], "expected a Matchdata"
  end
  ValaType.create_vala_ruby_type "Ruby.Symbol" do 
    ruby_type_check ["T_SYMBOL"], "expected a Symbol"
  end
  ValaType.create_vala_ruby_type "Ruby.Float" do
    ruby_type_check ["T_FLOAT"], "expected a Float"
  end
end
