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
      ValaType.parse(@type)
    end
    
    def type
      ValaType.parse(@type)
    end
    
    def body
      f=<<END
    #{returns.c_type} _c_return = #{obj.underscore_typename}->#{member};
END
    end
  end
end
