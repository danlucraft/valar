class Valar
  class ValaObject
    attr_accessor :name, :functions, :outer_object, :abstract, :objects, :sup_class, :properties
    attr_accessor :constructor_params, :members, :enums, :constants
    
    def initialize
      @functions, @objects, @properties = [], [], []
      @constructor_params, @members, @enums = [], [], []
      @constants = []
    end
    
    def convertible?
      descends_from? "GLib.Object" or descends_from? "Gtk.Object" or abstract
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
      return false unless sup_class
      return true if sup_class == klass
      sup_object = Valar.defined_object?(sup_class)
      if sup_object
        sup_object.descends_from?(klass)
      else
        false
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
      make_name("_") {|name| name.underscore }
    end
    
    def g_typename
      if outer_object
        outer_object.underscore_typename.upcase + "_TYPE_" + name.underscore.upcase
      else
        "TYPE_"+name.upcase
      end
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
        type, varname = param.type, param.name
        if type.nullable?
          str << f=<<END
    #{type.c_type} _c_#{varname};
    if (#{varname} == Qnil)
        _c_#{varname} = NULL;
    else {
        #{type.ruby_to_c(:before, varname, "_c_"+varname)}
    }
END
        else
          str << f=<<END
    #{type.c_type} _c_#{varname};
    #{type.ruby_to_c(:before, varname, "_c_"+varname)}
END
        end
      end
      str
    end
    
    def constructor_arg_list
      @constructor_params.map {|param| "_c_"+param.name}.join(", ")
    end
    
    def rb_arg_list
      @constructor_params.map {|param| "VALUE "+param.name }.join(", ")
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
END
      if descends_from?("Gtk.Object")
        fout.puts <<END
    RBGTK_INITIALIZE(self, #{underscore_typename}_new (#{constructor_arg_list}));
END
      elsif descends_from?("GLib.Object")
        fout.puts <<END
    G_INITIALIZE(self, #{underscore_typename}_new (#{constructor_arg_list}));
END
      end
      fout.puts <<END
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
      @functions.each do |func|
        if func.class == StaticMemberGet
          fout.puts <<END
#{func.returns.c_type} #{func.obj.underscore_typename}_#{func.member};
END
          if func.returns.name.include? "[]"
            fout.puts <<END
gint #{func.obj.underscore_typename}_#{func.member}_length1;
END
          end
        end
      end
    end
    
    def output_const_definitions(fout)
      @constants.each do |const|
        next unless const.convertible?
        fout.puts <<END
    VALUE _rb_#{const.c_typename.downcase};
    #{const.type.c_to_ruby(:after, const.c_typename, "_rb_"+const.c_typename.downcase)}
    rb_define_const(rbc_#{underscore_typename}, "#{const.name}", _rb_#{const.c_typename.downcase});
END
      end
    end
    
    def output_definition(fout)
      return if self.vala_typename == "Gtk"
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

  # FileError -> FILE_ERROR
  # IOError -> IO_ERROR
  def errorcase
    self.gsub(/([a-z\d])([A-Z])/,'\1_\2').
      gsub(/([A-Z][A-Z])([A-Z])/,'\1_\2').
      tr("-", "_").tr(".", "_").
      upcase.gsub("GLIB_", "G_")
  end
end
