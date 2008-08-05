class Valar
  class ValaLibrary
    attr_accessor :name, :objects, :directory, :header_files, :output_dir
    
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
      lib.header_files = []
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
        when /cheader_filename = "(\w+).h"/
          lib.header_files << $1 unless lib.header_files.include? $1
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
        when /public class (\w+)( : ([\w\.]+)((, ([\w\.<>]+))*)?)? \{/
          new_obj = ValaObject.new
          new_obj.name = $1
          new_obj.outer_object = current_obj
          if $2
            new_obj.sup_class = $3
          end
          vt = ValaType.create(new_obj.vala_typename) do
            ruby_type       new_obj.ruby_typename
            c_type          new_obj.c_typename+"*"
            underscore_type new_obj.underscore_typename
            g_type          new_obj.g_typename
            
            ruby_to_c do
              "#{c} = _#{underscore_type.upcase}_SELF(#{ruby});"
            end
            c_to_ruby do
              "#{ruby} = GOBJ2RVAL(#{c});"
            end
          end
          current_obj.objects << new_obj if current_obj
          current_obj = new_obj
          lib.objects << new_obj
        when /public #{current_obj ? current_obj.name : "nothing"} \((.*)\);/
          if $1 != ""
            $1.split(", ").each do |param_str|
              type_def, arg_name = param_str.split(" ")
              current_obj.constructor_params << Param.new(type_def, arg_name)
            end
          end
        when /public (\w+ )*([\w\.\?\[\]<>,]+) (\w+) \((.*)\)( throws ((\w+)(, \w+)*))?;/
          unless $1 and $1.include? "signal"
            keywords, return_type, name = $1, $2, $3
            params, errors =  $4, ($6 ? $6.split(", ") : [])
            new_meth = ValaMethod.new
            new_meth.name = name
            new_meth.returns = return_type
            new_meth.static = (keywords and keywords.include?("static"))
            new_meth.throws = errors
            if params
              params.split(", ").each do |param_str|
                type_def, arg_name = param_str.split(" ")
                new_meth.params << Param.new(type_def, arg_name)
              end
            end
            new_meth.obj = current_obj
            current_obj.functions << new_meth
          end
        when /public const ([\w\.\?]+) (\w+);/
          new_const = Constant.new($1, $2, current_obj)
          current_obj.constants << new_const
        when /public (\w+ )*([\w\.\?]+) (\w+) \{(.*)\}/
          # property - automatically handled by ruby-glib
        when /public (\w+ )*([\w\.\?\[\]<>,]+) (\w+);/
          if ($1||"").include? "static"
            memberg = StaticMemberGet.new
            members = StaticMemberSet.new
          else
            memberg = ValaMemberGet.new
            members = ValaMemberSet.new
          end
          memberg.name = "get_#{$3}"
          memberg.ruby_name = $3
          memberg.type = $2
          memberg.member = $3
          memberg.obj = current_obj
          current_obj.functions << memberg
          members.name = "set_#{$3}"
          members.ruby_name = "#{$3}="
          members.type = $2
          members.member = $3
          members.obj = current_obj
          current_obj.functions << members
        when /^\s*\}$/
          current_obj = current_obj.outer_object
        when /\{.*\}/
        when /\{/
          puts "skipping scope opening: '#{line.chomp}'"
          count = 1
          while count > 0 and line
            i += 1
            line = lines[i]
            if line
              change = line.scan(/\{/).length - line.scan(/\}/).length
            end
            count += change
          end
        when /\}/
          puts "unexpected scope close '#{line.chomp}'"
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
        puts "#{obj.vala_typename}"
        unless obj.convertible?
          puts "  not convertible"
          next
        end
        unless obj.constructor_params.empty?
          c = obj.constructor_params.all? {|p| p.type.forward_convertible? }
          Kernel.print "  #{c ? "*" : "x"} #{" ".ljust(max_type_width)}  #{obj.name.ljust(max_name_width)}  ("
          ps = obj.constructor_params.map do |param|
            "#{param.type.name} #{param.name}"
          end.join(", ")
          Kernel.print(ps)
          puts ")"
        end
        obj.functions.sort_by{|m| m.name}.each do |meth|
          puts "  #{meth.convertible? ? "*" : "x"} #{meth.returns.name.ljust(max_type_width)}  #{meth.name.ljust(max_name_width)}  (#{meth.params.map{|p| "#{p.type.name} #{p.name}"}.join ", "})"
          if meth.throws.any?
            puts "                      throws #{meth.throws.join(", ")}"
          end
        end
#         obj.members.sort_by{|m| m.name}.each do |mem|
#           puts "  * #{mem.type.name.ljust(max_type_width)}  #{mem.name}"
#         end
        obj.constants.sort_by{|m| m.name}.each do |constant|
          puts "  #{constant.convertible? ? "*" : "x"} #{constant.type.name.ljust(max_type_width)}  #{constant.name}" 
        end
      end
    end
    
    def output
      File.open((@output_dir||@directory)+"/#{@name}_rb.c", "w") do |fout|
        fout.puts <<END
#include "ruby.h"
#include "rbgtk.h"
END
#include "#{@name}.h"
        @header_files.each do |hf|
          fout.puts <<END
#include "#{hf}.h"
END
        end
        fout.puts <<END
static VALUE rb_vala_error, rbc_gtk;
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
    rb_vala_error = rb_define_class("ValaError", rb_eval_string("Exception"));
    rbc_gtk = rb_eval_string("Gtk");
END
        @objects.sort_by{|o| o.vala_typename.length}.each do |obj|
          obj.output_definition(fout) if obj.convertible?
          obj.output_const_definitions(fout)
        end
        fout.puts "}\n"
      end     
    end
  end
end
