
class Valar
  class ValaType
    attr_accessor :name
    attr_writer :nullable
    
    def nullable?
      @nullable
    end
    
    def ==(o)
      @name == o.name and
        @nullable == o.nullable?
    end
    
    def self.parse(string)
      type = ValaType.new
      if string[-1..-1] == "?"
        type.name = string[0..-2]
        type.nullable = true
      else
        type.name = string
      end
      type
    end
  end
end
