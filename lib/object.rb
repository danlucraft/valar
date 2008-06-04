class Valar
  class ValaObject
    attr_accessor :name, :functions, :outer_object, :abstract, :objects, :sup_class, :properties
    
    def initialize
      @functions, @objects, @properties = [], [], []
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
      make_name("_") {|name| name.downcase}
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
    
    def alloc_function
      f=<<END
static VALUE rb_#{underscore_typename}_alloc(VALUE klass) {
END
      if sup_class == "GLib.Object"
        f+= <<END
    #{c_typename} *#{underscore_typename} = #{underscore_typename}_new();
END
      else
        f+= <<END
    #{c_typename} *#{underscore_typename} = #{underscore_typename}_new(#{underscore_typename}_get_type());
END
      end
      f+= <<END
    VALUE obj;
    obj = Data_Wrap_Struct(klass, 0, rb_#{underscore_typename}_destroy, #{underscore_typename});
END
      if sup_class == "GLib.Object"
        f+=<<END
    g_object_ref(#{underscore_typename});
END
      else
        f+=<<END
    #{underscore_typename}_ref(#{underscore_typename});
END
      end
      f+=<<END
    return obj;
}

END
      f
    end
    
    def destroy_function
      if sup_class == "GLib.Object"
        <<END
static void rb_#{underscore_typename}_destroy(void* #{underscore_typename}) {
    g_object_unref(#{underscore_typename});
}
END
      else
        <<END
static void rb_#{underscore_typename}_destroy(void* #{underscore_typename}) {
    #{underscore_typename}_unref(#{underscore_typename});
}
END
      end
    end
    
    def output_method_definition(fout)
      fout.puts <<END

/****  #{vala_typename} methods *****/

END
      functions.each do |method|
        method.output(fout) if method.convertible?
      end
    end
    
    def output_class_definition(fout)
      fout.puts <<END

/****  #{vala_typename} wrapper *****/

END
      fout.puts <<END
static VALUE rbc_#{underscore_typename};
END
      unless abstract
        fout.puts(destroy_function)
        fout.puts(alloc_function)
      end
    end
    
    def output_definition(fout)
      if outer_object
        fout.puts <<END
    rbc_#{underscore_typename} = rb_define_class_under(rbc_#{outer_object.underscore_typename}, "#{name}", rb_cObject);
END
      else
        fout.puts <<END
    rbc_#{underscore_typename} = rb_define_class("#{name}", rb_cObject);
END
      end
      unless abstract
        fout.puts <<END
    rb_define_alloc_func(rbc_#{underscore_typename}, rb_#{underscore_typename}_alloc);
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
    end
  end
end
