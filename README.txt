= valar

* http://github.com/danlucraft/valar/tree/master

== DESCRIPTION:

 * Write Ruby extensions in Vala. 
 * Automatically generate Ruby bindings for them.
 * Embed a Ruby interpreter into Vala.

Includes a VAPI file for calling the Ruby C API from Vala, and a 
code generator valar to introspect on a Vala library and automatically
generate bindings for Ruby.

Other features:

 * automated conversions between Vala and Ruby types
 * An object oriented Ruby API. Instead of RSTRING_PTR(str), 
   you write str.to_vala()
 * Ruby types. So instead of VALUE, VALUE, VALUE, you 
   write Ruby.Value, Ruby.Array, Ruby.String and enjoy automatically
   generated type checking to rule out segfaults.
 * Automated memory management, linked to the Ruby garbage collector.

== IMPORTANT NOTES

This is new software and there are various notes:

 * I have not yet been able to figure out how to wrap GLib types that
   do not descend from GObject, so Valar will not convert them yet.
 * Memory management for class data members is non existent, so don't
   use them except for the most basic types.
 * Valar currently ignores custom property getters and setters. They are 
   all translated the same way, possibly incorrectly.
 * It only generates .c files not .h files so circular function references 
   will probably cause failures. I'm getting around to it....

== REQUIREMENTS:

Technically none, but to compile your Vala code you will need Vala 
(latest SVN) and to compile the generated C you and your users will
need Ruby-Gnome2 and glib.

However, the only actually necessary part of Ruby-Gnome2 is the glib 
binding, and it should be possible to include that in future versions of 
Valar, removing the Ruby-Gnome2 dependency.

== INSTALL:

  * not yet

== USAGE

  To generate Ruby extension in C:
    ruby /path/to/valar/bin/valar path/to/code.vapi

== LICENSE:

(The MIT License)

Copyright (c) 2008 FIX

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
