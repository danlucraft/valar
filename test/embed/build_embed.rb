require 'fileutils'
FileUtils.cd "test/embed" do
  puts "cleaning..."
  %x{rm embed.c embed.h embed}
  puts "compiling embed..."
  puts %x{valac -C --library embed embed.vala --basedir ./ --vapidir=./../../vapi/ --pkg=Ruby}
  c_src = File.read("embed.c")
  c_src.gsub!("#include <embed.h>", "#include \"embed.h\"")
  File.open("embed.c", "w") do |f| 
    f.puts c_src
  end
  puts "compiling embed.c..."
  puts %x{gcc -o embed embed.c -I/usr/local/lib/ruby/1.8/i686-linux/ -lruby1.8  $(pkg-config --cflags --libs gobject-2.0)
}
  
end
