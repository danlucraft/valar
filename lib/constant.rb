class Valar
  class Constant
    attr_accessor :type, :name, :outer_object
    
    def initialize(type, name, outer_object)
      @type = type
      @name = name
      @outer_object = outer_object
    end
    
    def vala_typename
      @outer_object.vala_typename + "." + @name
    end
    
    def ruby_typename
      @outer_object.ruby_typename + "::" + @name
    end
    
    def c_typename
      @outer_object.c_typename.upcase + "_" + @name
    end
    
    def convertible?
      @type.backward_convertible?
    end
  end
end
