
require 'pp'
require 'rubygems'
require 'trollop'

class Valar  
  def self.uniqid
    @uniqid ||= 0
    @uniqid += 1
    "val#{@uniqid}"
  end
end

$: << File.dirname(__FILE__)
require 'library'
require 'object'
require 'method'
require 'type'
require 'member'
require 'enum'
require 'error'
require 'constant'
require 'param'

class Valar
  VERSION = '1.0.0'
  
  def self.defined_object?(name)
    defined_objects.find{ |o| o.vala_typename == name}
  end
  
  def self.defined_objects
    objs = []
    ObjectSpace.each_object(Valar::ValaLibrary) do |library|
      objs += library.objects
    end
    objs
  end
  
  def self.parse_file(filename, options)
    if options[:deps]
      deps = options[:deps].split(",").map{|l| l.strip}
      puts "dependencies: #{options[:deps]} #{deps.inspect}"
    else
      deps = []
    end
    deps.each do |dep|
      if File.exist? "/usr/local/share/vala/vapi/#{dep}.vapi"
        parse_vapi_file("/usr/local/share/vala/vapi/#{dep}.vapi")
      else
        options[:vapidirs].split(",").each do |vdir|
          if File.exist? vdir+"/#{dep}.vapi"
            parse_vapi_file(vdir+"/#{dep}.vapi")
          end
        end
      end
    end
    @library = parse_vapi_file(filename)
    @library.print
    @library.output_dir = options[:"output-dir"]||nil
    @library.output
  end

  def self.parse_vapi_file(filename)
    puts "loading #{ARGV[0]}"
    ValaLibrary.new_from_vapi(filename)
  end
end
