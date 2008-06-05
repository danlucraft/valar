=begin
extconf.rb for Ruby/GtkMozEmbed extention library
=end

PACKAGE_NAME = "simple_rb"

TOPDIR = ENV["RG2_DIR"] || File.expand_path(File.dirname(__FILE__) + '/..')

MKMF_GNOME2_DIR = TOPDIR + '/glib/src/lib'

SRCDIR = File.expand_path("./src")

$LOAD_PATH.unshift MKMF_GNOME2_DIR

require 'mkmf-gnome2'

PKGConfig.have_package('gtk+-2.0')

create_makefile_at_srcdir(PACKAGE_NAME, SRCDIR, 
                          "-DRUBY_WEBKITGTK_COMPILATION")
create_top_makefile
