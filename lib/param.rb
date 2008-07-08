class Valar
  class Param
    attr_accessor :typename, :name
    
    def initialize(typename, name)
      @typename, @name = typename, name
    end
    
    def type
      ValaType.parse(typename)
    end
  end
end
