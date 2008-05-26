



[CCode (cprefix = "Ruby")]
namespace Ruby {
	public static delegate weak Value Callback(Ruby.Value self, void* varargs);

	[SimpleType]
 	[CCode (cname = "VALUE", cheader_filename = "ruby.h")]
	public struct Value {
		[CCode (cname = "rb_define_method")]
		public void define_method (string name, Ruby.Callback func, int argc);
	}

	[SimpleType]
 	[CCode (cname = "VALUE", cheader_filename = "ruby.h")]
	public struct Array : Value {
		[CCode (cname = "RARRAY_LEN", cheader_filename = "ruby.h")]
		public weak int length();
	}

	[SimpleType]
 	[CCode (cname = "VALUE", cheader_filename = "ruby.h")]
	public struct String : Value {
		[CCode (cname = "RSTRING_LEN", cheader_filename = "ruby.h")]
		public weak int length();
		[CCode (cname = "RSTRING_PTR", cheader_filename = "ruby.h")]
		public weak string to_c();
	}

	[CCode (cname = "rb_cObject")]
	public const Value Object;
	[CCode (cname = "Qnil")]
	public const Value Nil;
	[CCode (cname = "Qtrue")]
	public const Value True;
	[CCode (cname = "Qfalse")]
	public const Value False;

	[CCode (cname = "rb_define_class", cheader_filename = "ruby.h")]
	public static weak Ruby.Value define_class (string name, Ruby.Value superclass);
	[CCode (cname = "rb_define_alloc_func", cheader_filename = "ruby.h")]
	public static weak Ruby.Value define_alloc_func (Ruby.Value classmod, Ruby.Callback func);
	[CCode (cname = "rb_define_class_under", cheader_filename = "ruby.h")]
	public static weak Ruby.Value define_class_under (Ruby.Value under, string name, Ruby.Value superclass);
	[CCode (cname = "rb_define_module", cheader_filename = "ruby.h")]
	public static weak Ruby.Value define_module (string name);
	[CCode (cname = "Data_Wrap_Struct", cheader_filename = "ruby.h")]
	public static weak Ruby.Value data_wrap_struct (Ruby.Value klass, Ruby.Callback mark, Ruby.Callback free, void* ptr);

	// Type conversions
	[CCode (cname = "INT2FIX", cheader_filename = "ruby.h")]
	public static weak Ruby.Value int2fix(int v);

}
