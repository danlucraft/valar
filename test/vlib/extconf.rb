# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf-gnome2'

# Give it a name
extension_name = 'vlib_rb'
PKGConfig.have_package('gtk+-2.0')
PKGConfig.have_package('gee-1.0')

# The destination
dir_config(extension_name)

# Do the work
create_makefile(extension_name)
