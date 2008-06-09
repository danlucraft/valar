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
      lines = vapi_src.split("\n")
      i = 0
      while i < lines.length
        line = lines[i]
        case line
        when /namespace (.*) \{/
          new_obj = ValaObject.new
          new_obj.name = $1
          new_obj.abstract = true
          new_obj.outer_object = current_obj
          current_obj.objects << new_obj if current_obj
          current_obj = new_obj
          lib.objects << new_obj
        when /public enum (\w+) \{/
          new_enum = ValaEnum.new
          new_enum.name = $1
          new_enum.outer_object = current_obj
          i += 1
          line = lines[i]
          until line =~ /\s\}/
            line =~ /\s(\w+),?/
            new_enum.values << $1
            i += 1
            line = lines[i]
          end
          current_obj.enums << new_enum
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
        when /public #{current_obj ? current_obj.name : "nothing"} \((.*)\);/
          if $1 != ""
            $1.split(", ").each do |param_str|
              type_def, arg_name = param_str.split(" ")
              current_obj.constructor_params << [ValaType.parse(type_def), arg_name]
            end
          end
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
          # property - automatically handled by ruby-glib
        when /public (\w+ )*([\w\.\?]+) (\w+);/
          member = ValaMemberGet.new
          member.name = "get_#{$3}"
          member.ruby_name = $3
          member.type = ValaType.parse($2)
          member.member = $3
          member.obj = current_obj
          current_obj.functions << member
          member = ValaMemberSet.new
          member.name = "set_#{$3}"
          member.ruby_name = "#{$3}="
          member.type = ValaType.parse($2)
          member.member = $3
          member.obj = current_obj
          current_obj.functions << member
        when /^\s*\}$/
          current_obj = current_obj.outer_object
        when /\}/
          puts "error unknown scope opening: '#{line.chomp}'"
          raise
        end
        i += 1
      end
      lib
    end
    
    def print
      max_type_width = @objects.map{ |o|o.functions.map{ |m| m.returns.name.length}}.flatten.max
      max_name_width = @objects.map{ |o|o.functions.map{ |m| m.name.length}}.flatten.max
      @objects.each do |obj|
        next unless obj.convertible?
        puts "#{obj.vala_typename}"
        obj.functions.sort_by{|m| m.name}.each do |meth|
          puts "  #{meth.convertible? ? "*" : "x"} #{meth.returns.name.ljust(max_type_width)}  #{meth.name.ljust(max_name_width)}  (#{meth.params.map{|a| "#{a[0].name} #{a[1]}"}.join ", "})"
        end
        obj.members.sort_by{|m| m.name}.each do |mem|
          puts "  * #{mem.type.name.ljust(max_type_width)}  #{mem.name}"
        end
      end
    end
    
    def output
      File.open(@directory+"/#{@name}_rb.c", "w") do |fout|
        fout.puts <<END
#include "ruby.h"
#include "rbgtk.h"
#include "#{@name}.h"
END
        @objects.each do |obj|
          obj.output_class_definition(fout) if obj.convertible?
        end
        @objects.each do |obj|
          if obj.convertible?
            obj.output_method_definitions(fout)
            obj.output_member_definitions(fout)
          end
        end 
        
        fout.puts <<END
void Init_#{@name}_rb() {
    VALUE m_vala = rb_define_class("Vala", rb_cObject);
END
        @objects.sort_by{|o| o.vala_typename.length}.each do |obj|
          obj.output_definition(fout) if obj.convertible?
        end
        fout.puts "}\n"
      end     
    end
  end
end
