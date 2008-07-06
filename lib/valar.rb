
require 'rubygems'
require 'trollop'

class Valar  
  def self.uniqid
    @uniqid ||= 0
    @uniqid += 1
    "valar__#{@uniqid}"
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
      parse_vapi_file("/usr/local/share/vala/vapi/#{dep}.vapi")
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
