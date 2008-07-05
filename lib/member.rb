class Valar
  class ValaMemberSet < ValaMethod
    attr_accessor :type, :member 

    def throws
      []
    end
   
    def params
      [[type, member]]
    end
    
    def returns
      ValaType.parse("void")
    end
    
    def body
      f=<<END
    #{obj.underscore_typename}->#{member} = #{c_arg_list1};
END
    end
  end
  
  class ValaMemberGet < ValaMethod
    attr_accessor :type, :member

    def throws
      []
    end
    
    def params
      []
    end
    
    def returns
      @type
    end
    
    def body
      if RUBY_TYPES.include? returns.name
        f=<<END
    VALUE _rb_return =  #{obj.underscore_typename}->#{member};
END
      elsif obj_arg = Valar.defined_object?(returns.name)
        f=<<END
    #{obj_arg.c_typename}* _c_return;
    _c_return = #{obj.underscore_typename}->#{member};
END
      else
        f=<<END
    #{Valar.vala2c(returns.name)} _c_return = #{obj.underscore_typename}->#{member};
END
      end
    end
  end
end
