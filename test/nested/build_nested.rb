require 'fileutils'
FileUtils.cd "test/nested" do
  puts "cleaning..."
  %x{rm nested.c nested.h nested.so nested_rb.so nested_rb.c}
  puts "compiling nested..."
  puts %x{valac -C --library nested nested.vala --pkg gtksourceview-2.0 --basedir ./ --vapidir=./../../vapi/ --pkg=Ruby}
  c_src = File.read("nested.c")
  c_src.gsub!("#include <nested.h>", "#include \"nested.h\"")
  c_src.gsub!("#include <ruby.h>", "#include \"ruby.h\"");
  File.open("nested.c", "w") do |f| 
    f.puts c_src
  end
#   puts "linking nested..."
#   puts %x{gcc --shared -fPIC -o nested.so $(pkg-config --cflags --libs gobject-2.0 gtksourceview-2.0) nested.c -I/usr/local/lib/ruby/1.8/i686-linux}
  
end

puts "running VALAR..."
puts %x{ruby bin/valar test/nested/nested.vapi --deps="gtk+-2.0,gtksourceview-2.0"}
puts 
FileUtils.cd "test/nested" do
  puts "compiling nestedrb..."
  puts %x{ruby extconf.rb}
  puts %x{make}
end
puts
