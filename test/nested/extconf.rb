# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf-gnome2'

# Give it a name
extension_name = 'nested_rb'
PKGConfig.have_package('gtk+-2.0')
PKGConfig.have_package('gtksourceview-2.0')

# The destination
dir_config(extension_name)

# Do the work
create_makefile(extension_name)
