
class Valar
  class ValaMemberSet < ValaMethod
    attr_accessor :type, :member 

    def throws
      []
    end
   
    def params
      [Param.new(@type, member)]
    end
    
    def returns
      ValaType.parse("void")
    end
    
    def type
      ValaType.parse("void")
    end
    
    def body
      f=<<END
    #{obj.underscore_typename}->#{member} = #{c_arg_list1};  // ValaMemberSet#body
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
      ValaType.parse(@type)
    end
    
    def type
      ValaType.parse(@type)
    end
    
    def body
      <<END
    #{returns.c_type} _c_return = #{obj.underscore_typename}->#{member}; // ValaMemberGet#body
END
    end
  end

  class StaticMemberSet < ValaMemberSet
    def body
      f=<<END
    #{obj.underscore_typename}_#{member} = #{c_arg_list_direct}; // StaticMemberSet#body
END
      if returns.name.include? "[]"
        f+=<<END
    _rb_return__length = #{obj.underscore_typename}_#{member}_length1;
END
      end
      f
    end

    def static
      true
    end
  end
  
  class StaticMemberGet < ValaMemberGet
    def body
      <<END
    #{returns.c_type} _c_return = #{obj.underscore_typename}_#{member}; // StaticMemberGet#body
END
    end

    def static
      true
    end
  end
end
