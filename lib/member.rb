
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
    // ValaMemberSet#body
    #{obj.underscore_typename}->#{member} = _c_#{params.first.name};
END
      if params.first.type.name.include? "[]"
        f+=<<END
    #{obj.underscore_typename}->#{member}_length1 = _c_#{params.first.name}__length;
END
      end
      f
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
      f = <<END
    // ValaMemberGet#body
    #{returns.c_type} _c_return = #{obj.underscore_typename}->#{member}; 
END
      if returns.name.include? "[]"
        f += <<END
    gint _rb_return__length = #{obj.underscore_typename}->#{member}_length1;
END
      end
      f
    end
  end

  class StaticMemberSet < ValaMemberSet
    def body
      f=<<END
    // StaticMemberSet#body
    #{obj.underscore_typename}_#{member} = _c_#{params.first.name}; 
END
      if params.first.type.name.include? "[]"
        f+=<<END
    #{obj.underscore_typename}_#{member}_length1 = _c_#{params.first.name}__length;
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
      f = <<END
    // StaticMemberGet#body
    #{returns.c_type} _c_return = #{obj.underscore_typename}_#{member};
END
      if returns.name.include? "[]"
        f += <<END
    gint _rb_return__length = #{obj.underscore_typename}_#{member}_length1;
END
      end
      f
    end

    def static
      true
    end
  end
end
