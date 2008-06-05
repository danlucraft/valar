require 'fileutils'
FileUtils.cd "test/simple/src" do
  puts "cleaning..."
  %x{rm simple.c simple.h simple.so simple_rb.so simple_rb.c}
  puts "compiling simple..."
  puts %x{valac -C --library simple simple.vala --basedir ./ --vapidir=./../../../vapi/ --pkg=Ruby}
  c_src = File.read("simple.c")
  c_src.gsub!("#include <simple.h>", "#include \"simple.h\"")
  c_src.gsub!("#include <ruby.h>", "#include \"ruby.h\"");
  File.open("simple.c", "w") do |f| 
    f.puts c_src
  end
  puts "linking simple..."
  puts %x{gcc --shared -fPIC -o simple.so $(pkg-config --cflags --libs gobject-2.0) simple.c -I/usr/local/lib/ruby/1.8/i686-linux}
end

puts "running VALAR..."
puts %x{ruby bin/valar test/simple/src/simple.vapi}
puts 
FileUtils.cd "test/simple" do
  puts "compiling simplerb..."
  puts %x{ruby extconf.rb}
  puts %x{make}
end
puts
