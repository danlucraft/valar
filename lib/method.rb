class Valar
  class ValaMethod
    attr_accessor :name, :ruby_name, :params, :returns, :obj, :static, :throws
    
    def initialize
      @params = []
    end
    
    def ruby_name
      @ruby_name || @name
    end
    
    def output(out)
      out.puts header
      out.puts type_checks
      out.puts argument_type_conversions
      out.puts body
      out.puts return_type_conversion
      out.puts footer
    end
    
    def convertible?
      Valar.convertible_type?(returns) and 
        params.all? {|param| Valar.convertible_type?(param[0])}
    end
    
    def header
      if static
        f=<<END
static VALUE rb_#{obj.underscore_typename}_#{name.downcase}(VALUE self#{params.length > 0 ? ", " : nil}#{rb_arg_list}) {
END
      else
        f=<<END
static VALUE rb_#{obj.underscore_typename}_#{name.downcase}(VALUE self#{params.length > 0 ? ", " : nil}#{rb_arg_list}) {
    #{obj.c_typename}* #{obj.underscore_typename} = RVAL2GOBJ(self);
END
      end
    end
    
    def footer
      if returns.name == "void"
      <<END
    return Qnil;
}

END
      else
      <<END
    return _rb_return;
}

END
      end
    end
    
    def type_checks
      str = ""
      params.each do |param|
        if VALA_TO_RUBY.include? param[0].name
          type_name = VALA_TO_RUBY[param[0].name]
        else
          type_name = param[0].name
        end
        ctype, msg = TYPE_CHECK[type_name]
        if ctype
          if param[0].nullable?
            str << f=<<END
    if (TYPE(#{param[1]}) != #{ctype} && #{param[1]} != Qnil) {
        VALUE rb_arg_error = rb_eval_string("ArgumentError");
        rb_raise(rb_arg_error, "#{msg} or nil");
    }
END
          else
            str << f=<<END
    if (TYPE(#{param[1]}) != #{ctype}) {
        VALUE rb_arg_error = rb_eval_string("ArgumentError");
        rb_raise(rb_arg_error, "#{msg}");
    }
END
          end
        end
        ctypes, msg = COMPOSITE_TYPE_CHECK[type_name]
        if ctypes
          if param[0].nullable?
            condition = ctypes.map {|ctype| "TYPE(#{param[1]}) != #{ctype}"}.join(" && ")
            condition += " && #{param[1]} != Qnil"
            str << f=<<END
    if (#{condition}) {
        VALUE rb_arg_error = rb_eval_string("ArgumentError");
        rb_raise(rb_arg_error, "#{msg} or nil");
    }
END
          else
            condition = ctypes.map {|ctype| "TYPE(#{param[1]}) != #{ctype}"}.join(" && ")
            str << f=<<END
    if (#{condition}) {
        VALUE rb_arg_error = rb_eval_string("ArgumentError");
        rb_raise(rb_arg_error, "#{msg}");
    }
END
          end
        end
      end
      str
    end
    
    def argument_type_conversions
      str = ""
      params.each do |param|
        next if RUBY_TYPES.include? param[0].name
        if param[0].name == "bool"
          str << f=<<END
    gboolean _c_#{param[1]};
    if (#{param[1]} == Qtrue)
        _c_#{param[1]} = TRUE;
    else
        _c_#{param[1]} = FALSE;
END
        elsif ctype = VALA_TO_C[param[0].name]
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
    #{obj_arg.c_typename}* _c_#{param[1]} = _#{obj_arg.underscore_typename.upcase}_SELF(#{param[1]});
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
    
    def return_type_conversion
      if returns.name == "void"
        ""
      elsif returns.name == "bool"
          <<END
    VALUE _rb_return;
    if (_c_return == TRUE)
        _rb_return = Qtrue;
    else
        _rb_return = Qfalse;
END
      elsif ctype = VALA_TO_C[returns.name]
        if returns.nullable?
          f=<<END
     VALUE _rb_return;
    if (_c_return == NULL)
        _rb_return = Qnil;
    else
        _rb_return = #{Valar.c2ruby(ctype).gsub("\\1", "_c_return")};
END
        else
          f=<<END
    VALUE _rb_return = #{Valar.c2ruby(ctype).gsub("\\1", "_c_return")};
END
        end
      elsif obj_arg = Valar.defined_object?(returns.name)
        if returns.nullable?
          f=<<END
    VALUE _rb_return;
    if (_c_return == NULL) {
        _rb_return = Qnil;
    }
    else {
        _rb_return = GOBJ2RVAL(_c_return);
//        _rb_return = Data_Wrap_Struct(rbc_#{obj_arg.underscore_typename}, 0, rb_#{obj_arg.underscore_typename}_destroy, _c_return);
    }
END
        else
          f=<<END
    VALUE _rb_return = GOBJ2RVAL(_c_return);
//    VALUE _rb_return = Data_Wrap_Struct(rbc_#{obj_arg.underscore_typename}, 0, rb_#{obj_arg.underscore_typename}_destroy, _c_return);
END
        end
      else
        ""
      end
    end
    
    def body
      f=""
      if throws.any?
        f << <<END
    GError* inner_error;
    inner_error = NULL;
END
      end
      if RUBY_TYPES.include? returns.name
        f << <<END
    VALUE _rb_return = #{obj.underscore_typename}_#{name}(#{c_arg_list});
END
      elsif returns.name == "void"
        f << <<END
    #{obj.underscore_typename}_#{name}(#{c_arg_list});
END
      elsif obj_arg = Valar.defined_object?(returns.name)
        f << <<END
    #{obj_arg.c_typename}* _c_return;
    _c_return = #{obj.underscore_typename}_#{name}(#{c_arg_list});
END
      else
        f << <<END
    #{Valar.vala2c(returns.name)} _c_return;
    _c_return = #{obj.underscore_typename}_#{name}(#{c_arg_list});
END
      end
      if throws.any?
        f << <<END
    if (inner_error != NULL) {
END
        throws.each do |throw|
          f << <<END
        if (inner_error->domain == #{throw.errorcase}) {
            rb_raise(rb_vala_error, "[#{throw}]: %s", inner_error->message);
        }
END
        end
        f << <<END
    }
END
      end
      f
    end
    
    def rb_arg_list
      params.map {|a| "VALUE "+a[1] }.join(", ")
    end
    
    def c_arg_list
      if static
        str = ""
      else
        str = obj.underscore_typename
        if params.length > 0
          str += ", "
        end
      end
      str += c_arg_list1
      if throws.any?
        str += ", &inner_error"
      end
      str
    end
    
    def c_arg_list1
      params.map {|a| RUBY_TYPES.include?(a[0].name) ? a[1] : "_c_"+a[1]}.join(", ")
    end
    
    def ctype?(type)
      TYPE_MAP.include? type.name
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
end
