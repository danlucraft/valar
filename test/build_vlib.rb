require 'fileutils'
FileUtils.cd "test" do
  puts "cleaning..."
  %x{rm vlib.c vlib.h vlib.so vlibrb.so vlib.so}
  puts "compiling vlib..."
  puts %x{valac -C --library vlib vlib.vala --basedir ./ --vapidir=./../vapi/ --pkg=Ruby}
  c_src = File.read("vlib.c")
  c_src.gsub!("#include <vlib.h>", "#include \"vlib.h\"")
  c_src.gsub!("#include <ruby.h>", "#include \"ruby.h\"");
  File.open("vlib.c", "w") do |f| 
    f.puts c_src
  end
  puts "linking vlib..."
  puts %x{gcc --shared -fPIC -o vlib.so $(pkg-config --cflags --libs gobject-2.0) vlib.c -I/usr/local/lib/ruby/1.8/i686-linux}
  
  puts "compiling vlibrb..."
  puts %x{ruby extconf.rb}
  puts %x{make}
end
