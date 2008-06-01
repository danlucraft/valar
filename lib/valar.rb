$: << File.dirname(__FILE__)
require 'library'
require 'object'
require 'method'

class Valar
  VERSION = '1.0.0'
  RUBY_TYPES = %w{Ruby.String Ruby.Array Ruby.Value Ruby.Int Ruby.Number Ruby.Float Ruby.Hash}
  TYPE_CHECK = {
    "Ruby.Array" => ["T_ARRAY", "expected an Array"],
    "Ruby.String" => ["T_STRING", "expected a String"],
    "Ruby.Class" => ["T_CLASS", "expected a Class"],
    "Ruby.Module" => ["T_MODULE", "expected a Module"],
    "Ruby.Regexp" => ["T_REGEXP", "expected a Regexp"],
    "Ruby.Hash" => ["T_HASH", "expected a Hash"],
    "Ruby.File" => ["T_FILE", "expected a File"],
    "Ruby.Match" => ["T_MATCH", "expected a Matchdata"],
    "Ruby.Symbol" => ["T_SYMBOL", "expected a Symbol"],
    "Ruby.Float" => ["T_FLOAT", "expected a Float"]
  }
  COMPOSITE_TYPE_CHECK = {
    "Ruby.Bool" => [["T_TRUE", "T_FALSE"], "expected true or false"],
    "Ruby.Int" => [["T_BIGNUM", "T_FIXNUM"], "expected an integer"],
    "Ruby.Number" => [["T_BIGNUM", "T_FIXNUM", "T_FLOAT"], "expected a number"],
  }
  
  TYPE_MAP = {
    'char'          => [ 'NUM2CHR',  'CHR2FIX' ],
    'char *'        => [ 'STR2CSTR', 'rb_str_new2' ],
    'char*'         => [ 'STR2CSTR', 'rb_str_new2' ],
    'const char *'  => [ 'STR2CSTR', 'rb_str_new2' ],
    'const char*'   => [ 'STR2CSTR', 'rb_str_new2' ],
    'double'        => [ 'NUM2DBL',  'rb_float_new' ],
    'int'           => [ 'F'+'IX2INT',  'INT2FIX' ],
    'long'          => [ 'NUM2INT',  'INT2NUM' ],
    'unsigned int'  => [ 'NUM2UINT', 'UINT2NUM' ],
    'unsigned long' => [ 'NUM2UINT', 'UINT2NUM' ],
    'unsigned'      => [ 'NUM2UINT', 'UINT2NUM' ],
    'VALUE'         => [ '', '' ],
    # Can't do these converters because they conflict with the above:
    # ID2SYM(x), SYM2ID(x), NUM2DBL(x), F\IX2UINT(x)
  }

  VALA_TO_C = {
    "void" => "void",
    "int" => "int",
    "long" => "long",
    "double" => "double",
    "string" => "char*"
  }
  
  def self.ruby2c(type)
    raise ArgumentError, "Unknown type #{type.inspect}" unless TYPE_MAP.has_key? type
    TYPE_MAP[type].first
  end
  
  def self.c2ruby(type)
    raise ArgumentError, "Unknown type #{type.inspect}" unless TYPE_MAP.has_key? type
    TYPE_MAP[type].last
  end

  def self.vala_type(type)
    if RUBY_TYPES.include? type
      "VALUE"
    else
      type
    end
  end

  def self.convertible_type?(type)
    VALA_TO_C.include? type or RUBY_TYPES.include? type
  end
  
  def self.vala2c(type)
    VALA_TO_C[type] || (RUBY_TYPES.include?(type) ? "VALUE" : nil)
  end
  
  def self.parse_file(filename)
    if File.extname(filename) == ".gidl"
      parse_gidl_file(filename)
    else
      parse_vapi_file(filename)
    end
    @library.print
    @library.output
  end
  
  def self.parse_gidl_file(filename)
    @library = ValaLibrary.new_from_gidl(filename)
  end
  
  def self.parse_vapi_file(filename)
    puts "loading #{ARGV[0]}"
    @library = ValaLibrary.new_from_vapi(filename)
  end
  
end
