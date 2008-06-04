class Valar
  class ValaLibrary
    attr_accessor :name, :objects, :directory
    
    def initialize
      @objects = []
    end
    
    def object(name)
      @objects.find{|o| o.name == name.to_s}
    end
    
    def object_names
      @objects.map{|o| o.name}.sort
    end
    
    def self.new_from_gidl(filename)
      lib = ValaLibrary.new
      @dirname = File.dirname(filename)
      @basename = File.basename(filename)
      @name = @basename.split(".").first
      p @name
      puts "loading library #{name}"
      doc = REXML::Document.new(File.read(filename))

      lib.objects = []

      doc.elements.each("api/object") do |el|
        lib.objects << ValaObject.new_from_xml(el)
      end
    
      doc.elements.each("api/struct") do |el|
        lib.objects << ValaObject.new_from_xml(el)
      end
      lib
    end
    
    def self.new_from_vapi(filename)
      lib = ValaLibrary.new
      vapi_src = File.read(filename)
      @dirname = File.dirname(filename)
      @basename = File.basename(filename)
      lib.name = @basename.split(".").first
      lib.directory = @dirname
      puts "loading library #{lib.name}"
      current_obj = nil
      vapi_src.each_line do |line|
        case line
        when /namespace (.*) \{/
          new_obj = ValaObject.new
          new_obj.name = $1
          new_obj.abstract = true
          new_obj.outer_object = current_obj
          current_obj.objects << new_obj if current_obj
          current_obj = new_obj
          lib.objects << new_obj
        when /public class (\w+)( : ([\w\.]+))? \{/
          new_obj = ValaObject.new
          new_obj.name = $1
          new_obj.outer_object = current_obj
          if $2
            new_obj.sup_class = $3
          end
          current_obj.objects << new_obj if current_obj
          current_obj = new_obj
          lib.objects << new_obj
        when /public (\w+ )*([\w\.\?]+) (\w+) \((.*)\);/
          params = $4
          keywords = $1
          new_meth = ValaMethod.new
          new_meth.name = $3
          new_meth.returns = ValaType.parse($2)
          new_meth.static = (keywords and keywords.include?("static"))
          if params
            params.split(", ").each do |param_str|
              type_def, arg_name = param_str.split(" ")
              new_meth.params << [ValaType.parse(type_def), arg_name]
            end
          end
          new_meth.obj = current_obj
          current_obj.functions << new_meth
        when /public (\w+ )*([\w\.\?]+) (\w+) \{(.*)\}/
          get_meth = ValaMethod.new
          get_meth.name = "get_#{$3}"
          get_meth.ruby_name = $3
          get_meth.returns = ValaType.parse($2)
          get_meth.obj = current_obj
          current_obj.functions << get_meth
          set_meth = ValaMethod.new
          set_meth.name = "set_#{$3}"
          set_meth.ruby_name = "#{$3}="
          set_meth.returns = ValaType.parse("void")
          set_meth.obj = current_obj
          set_meth.params << [ValaType.parse($2), "val"]
          current_obj.functions << set_meth
        when /^\s*\}$/
          current_obj = current_obj.outer_object
        when /\}/
          puts "error unknown scope opening: '#{line.chomp}'"
          raise
        end
      end
      lib
    end
    
    def print
      @objects.each do |obj|
        puts "#{obj.vala_typename}"
        obj.functions.sort_by{|m| m.name}.each do |meth|
          puts "  #{meth.convertible? ? "*" : "x"} #{meth.returns.name.ljust(12)} #{meth.name.ljust(30)}(#{meth.params.map{|a| "#{a[0].name} #{a[1]}"}.join ", "})"
        end
#         puts "  ---properties---"
#         obj.properties.sort_by{|m| m.name}.each do |prop|
#           puts "  * #{prop.type.name.ljust(12)} #{prop.name}"
#         end
      end
    end
    
    def output
      File.open(@directory+"/#{@name}_rb.c", "w") do |fout|
        fout.puts <<END
#include "ruby.h"
#include "#{@name}.h"
END
        @objects.each do |obj|
          obj.output_class_definition(fout)
        end
        @objects.each do |obj|
          puts "outputting: #{obj.name}"
          obj.output_method_definition(fout)
        end 
        
        fout.puts <<END
void Init_#{@name}_rb() {
    g_type_init();
END
        @objects.sort_by{|o| o.vala_typename.length}.each do |obj|
          obj.output_definition(fout)
        end
        fout.puts "}\n"
      end     
    end
  end
end
