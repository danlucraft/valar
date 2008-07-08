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
    
    def returns
      ValaType.parse(@returns)
    end
    
    def convertible?
      returns.backward_convertible? and 
        params.all? {|param| param.type.forward_convertible?}
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
        type = param.type
        varname = param.name
        ctypes, message = type.ruby_type_check
        next unless ctypes
        if type.nullable?
          condition = ctypes.map {|ctype| "TYPE(#{varname}) != #{ctype}"}.join(" && ")
          condition += " && #{param.name} != Qnil"
          str << f=<<END
    if (#{condition}) {
        VALUE rb_arg_error = rb_eval_string("ArgumentError");
        rb_raise(rb_arg_error, "#{message} or nil");
    }
END
        else
          condition = ctypes.map {|ctype| "TYPE(#{param.name}) != #{ctype}"}.join(" && ")
          str << f=<<END
    if (#{condition}) {
        VALUE rb_arg_error = rb_eval_string("ArgumentError");
        rb_raise(rb_arg_error, "#{message}");
    }
END
        end
      end
      str
    end
    
    def argument_type_conversions
      str = ""
      params.each do |param|
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
    
    def return_type_conversion
      if returns.name == "void"
        ""
      else
        if returns.nullable?
          f=<<END
    VALUE _rb_return;
    if (_c_return == NULL)
        _rb_return = Qnil;
    else {
        #{returns.c_to_ruby(:after, "_c_return", "_rb_return")}
    }
END
        else
          f=<<END
    VALUE _rb_return;
    #{returns.c_to_ruby(:after, "_c_return", "_rb_return")}
END
        end
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
      f << <<END
    #{returns.c_to_ruby(:before, "_c_return", "_rb_return")}
END
      if returns.name == "void"
        f << <<END
    #{obj.underscore_typename}_#{name}(#{c_arg_list});
END
      else
        f << <<END
    #{returns.c_type} _c_return;
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
      params.map {|param| "VALUE "+param.name }.join(", ")
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
        if str.length > 0
          str += ", "
        end
        str += "&inner_error"
      end
      str
    end
    
    def c_arg_list1
      s1 = params.map do |param| 
        param.type.args("_c_" + param.name) || "_c_#{param.name}"
      end.join(", ")
      s2 = (returns.return_args("_rb_return") || "")
      s1 + (((s1.length > 0 or !static) and s2.length > 0) ? ", " : "") + s2 
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
        obj.params << Param.new(p1.attributes["type"], p1.attributes["name"])
      end
      obj.name = el.attributes["name"]
      obj.symbol = el.attributes["symbol"]
      obj.returns = return_type
      obj
    end
  end
end

#         elsif obj_arg = Valar.defined_object?(param[0].name)
#           if obj_arg.descends_from?("GLib.Object")
#               str << f=<<END
#     #{obj_arg.c_typename}* _c_#{param[1]} = _#{obj_arg.underscore_typename.upcase}_SELF(#{param[1]});
# END
#           else
#             if param[0].nullable?
#               str << f=<<END
#     #{obj_arg.c_typename}* _c_#{param[1]};
#     if (#{param[1]} == Qnil)
#         _c_#{param[1]} = NULL;
#     else {
#         Data_Get_Struct(#{param[1]}, #{obj_arg.c_typename}, _c_#{param[1]});
#     }
# END
#             else
#               str << f=<<END
#     #{obj_arg.c_typename}* _c_#{param[1]};
#     Data_Get_Struct(#{param[1]}, #{obj_arg.c_typename}, _c_#{param[1]});
# END
#             end
#           end
#         end

# from return type converstion
#       elsif obj_arg = Valar.defined_object?(returns.name)
#         if returns.nullable?
#           f=<<END
#     VALUE _rb_return;
#     if (_c_return == NULL) {
#         _rb_return = Qnil;
#     }
#     else {
#         _rb_return = GOBJ2RVAL(_c_return);
# //        _rb_return = Data_Wrap_Struct(rbc_#{obj_arg.underscore_typename}, 0, rb_#{obj_arg.underscore_typename}_destroy, _c_return);
#     }
# END
#         else
#           f=<<END
#     VALUE _rb_return = GOBJ2RVAL(_c_return);
# //    VALUE _rb_return = Data_Wrap_Struct(rbc_#{obj_arg.underscore_typename}, 0, rb_#{obj_arg.underscore_typename}_destroy, _c_return);
# END
#         end

# from body
#       elsif obj_arg = Valar.defined_object?(returns.name)
#         f << <<END
#     #{obj_arg.c_typename}* _c_return;
#     _c_return = #{obj.underscore_typename}_#{name}(#{c_arg_list});
# END
