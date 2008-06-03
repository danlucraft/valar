= valar

* http://github.com/danlucraft/valar/tree/master

== DESCRIPTION:

Write Ruby extensions in Vala.

Includes a VAPI file for calling the Ruby C API from Vala, and a 
code generator valar to introspect on a Vala library and automatically
generate bindings for Ruby.

Other features:

 * automated conversions between Vala and Ruby types
 * An object oriented Ruby API. Instead of RSTRING_PTR(str), 
   you write str.to_c()
 * Ruby types. So instead of VALUE, VALUE, VALUE, you 
   write Ruby.Value, Ruby.Array, Ruby.String and enjoy automatically
   generated type checking to rule out segfaults.
 * Automated memory management, linked to the Ruby garbage collector.

== REQUIREMENTS:

Technically none, but if you want to compile your vala code you will 
need valac and glib, and if you want to distribute the generated C, your
users will need glib.

== INSTALL:

* not yet.

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
