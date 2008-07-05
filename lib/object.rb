class Valar
  class ValaObject
    attr_accessor :name, :functions, :outer_object, :abstract, :objects, :sup_class, :properties
    attr_accessor :constructor_params, :members, :enums
    
    def initialize
      @functions, @objects, @properties = [], [], []
      @constructor_params, @members, @enums = [], [], []
    end
    
    def convertible?
      descends_from? "GLib.Object" or abstract
#      true
    end
    
    def object(name)
      @objects.find{|o| o.name == name.to_s}
    end
    
    def method(name)
      @functions.find{|m| m.name == name.to_s}
    end
    
    def make_name(join, &transform)
      if outer_object
        outer_object.make_name(join, &transform) + join + 
          (block_given? ? transform[name] : name)
      else
        (block_given? ? transform[name] : name)
      end
    end
    
    def descends_from?(klass)
      sup_class and (sup_class == klass or Valar.defined_object?(sup_class).descends_from?(klass))
    end
    
    def vala_typename
      make_name(".")
    end

    def ruby_typename
      make_name("::")
    end
    
    def c_typename
      make_name("")
    end
    
    def underscore_typename
      make_name("_") {|name| name.underscore }
    end
    
    def self.new_from_xml(el)
      obj = ValaObject.new
      obj.name = el.attributes["name"]
      obj.functions = []
      el.elements.each("method") do |el2| 
        method = ValaMethod.new_from_xml(el2)
        method.obj = obj
        obj.functions << method
      end
      obj
    end
    
    def constructor_type_conversions
      str = ""
      @constructor_params.each do |param|
        next if RUBY_TYPES.include? param[0].name
        if ctype = VALA_TO_C[param[0].name]
          if param[0].nullable?
            str << f=<<END
    #{Valar.vala2c(param[0].name)} _c_#{param[1]};
    if (#{param[1]} == Qnil)
        _c_#{param[1]} = NULL;
    else
        _c_#{param[1]} = #{Valar.ruby2c(ctype).gsub("\\1", param[1])};
END
          else
            str << f=<<END
    #{Valar.vala2c(param[0].name)} _c_#{param[1]} = #{Valar.ruby2c(ctype).gsub("\\1", param[1])};
END
          end
        elsif obj_arg = Valar.defined_object?(param[0].name)
          if obj_arg.descends_from?("GLib.Object")
            str << f=<<END
    #{obj_arg.c_typename}* _c_#{param[1]} = RVAL2GOBJ(#{param[1]});
END
          else
            if param[0].nullable?
              str << f=<<END
    #{obj_arg.c_typename}* _c_#{param[1]};
    if (#{param[1]} == Qnil)
        _c_#{param[1]} = NULL;
    else {
        Data_Get_Struct(#{param[1]}, #{obj_arg.c_typename}, _c_#{param[1]});
    }
END
            else
              str << f=<<END
    #{obj_arg.c_typename}* _c_#{param[1]};
    Data_Get_Struct(#{param[1]}, #{obj_arg.c_typename}, _c_#{param[1]});
END
            end
          end
        end
      end
      str
    end
    
    def constructor_arg_list
      @constructor_params.map {|a| RUBY_TYPES.include?(a[0].name) ? a[1] : "_c_"+a[1]}.join(", ")
    end
    
    def rb_arg_list
      @constructor_params.map {|a| "VALUE "+a[1] }.join(", ")
    end
    
    def output_method_definitions(fout)
      fout.puts <<END

/****  #{vala_typename} methods *****/

END
      output_init_function(fout) unless abstract
      functions.each do |method|
        method.output(fout) if method.convertible?
      end
    end
    
    def output_member_definitions(fout)
      members.each do |member|
        member.output(fout) if member.convertible?
      end
    end
    
    def output_init_function(fout)
      fout.puts <<END

static VALUE #{underscore_typename}_initialize(VALUE self#{@constructor_params.empty? ? "" : ", "}#{rb_arg_list}) {
#{constructor_type_conversions}
    G_INITIALIZE(self, #{underscore_typename}_new (#{constructor_arg_list}));
    return Qnil;
}

END
    end
    
    def output_class_definition(fout)
      fout.puts <<END

/****  #{vala_typename} wrapper *****/

END
      fout.puts <<END
#define _#{underscore_typename.upcase}_SELF(s) #{underscore_typename.upcase}(RVAL2GOBJ(s))
static VALUE rbc_#{underscore_typename};
END
    end
    
    def output_definition(fout)
      if abstract
        if outer_object
          fout.puts <<END
    rbc_#{underscore_typename} = rb_define_class_under(rbc_#{outer_object.underscore_typename}, "#{name}", rb_cObject);
END
        else
          fout.puts <<END
    rbc_#{underscore_typename} = rb_define_class("#{name}", rb_cObject);
END
        end
      else
        if outer_object
          fout.puts <<END
    rbc_#{underscore_typename} = G_DEF_CLASS(#{underscore_typename}_get_type(), "#{name}", rbc_#{outer_object.underscore_typename});
END
        else
          fout.puts <<END
    rbc_#{underscore_typename} = G_DEF_CLASS(#{underscore_typename}_get_type(), "#{name}", rb_cObject);
END
        end
        fout.puts <<END
    rb_define_method(rbc_#{underscore_typename}, "initialize", #{underscore_typename}_initialize, #{@constructor_params.length});
END
      end
      functions.each do |method|
        if method.convertible?
          if method.static
            fout.puts <<END
    rb_define_singleton_method(rbc_#{underscore_typename}, "#{method.ruby_name}", rb_#{underscore_typename}_#{method.name.downcase}, #{method.params.length});
END
          else
            fout.puts <<END
    rb_define_method(rbc_#{underscore_typename}, "#{method.ruby_name}", rb_#{underscore_typename}_#{method.name.downcase}, #{method.params.length});
END
          end
        end
      end
      enums.each do |enum|
        fout.puts <<END
    VALUE rbc_#{enum.outer_object.underscore_typename}_#{enum.name.underscore} = rb_define_class_under(rbc_#{enum.outer_object.underscore_typename}, "#{enum.name}", rb_cObject);
END
        enum.values.each do |val|
          fout.puts <<END
    rb_define_const(rbc_#{enum.outer_object.underscore_typename}_#{enum.name.underscore}, "#{val}", INT2FIX(#{enum.outer_object.underscore_typename.upcase}_#{enum.name.underscore.upcase}_#{val}));
END
        end
      end
    end
  end
end

class String
  # ImiBob -> imi_bob
  # VLib   -> vlib
  def underscore
    self.gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end
  
  def errorcase
    self.gsub(/([a-z\d])([A-Z])/,'\1_\2').
      gsub(/([A-Z][A-Z])([A-Z])/,'\1_\2').
      tr("-", "_").
      upcase
  end
end
