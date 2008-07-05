
using GLib;

public class VLib : Object {
    public void hello() {
        stdout.printf ("Hello World, MyLib\n");
    }

	public Ruby.Bool equals_nil(Ruby.Value input) {
		if (input == Ruby.Nil)
			return Ruby.True;
		else
			return Ruby.False;
	}

	public Ruby.Value get_length(Ruby.Array rb_array) {
		return Ruby.int2fix(rb_array.length());
	}

	public Ruby.Value get_str_length(Ruby.String rb_string) {
		return Ruby.int2fix(rb_string.length());
	}

	public Ruby.Value str_length_from_vala(Ruby.String rb_string) {
		return Ruby.long2fix(rb_string.to_vala().size());
	}
	
	public void sum_3(Ruby.Int rb_a, Ruby.Number rb_b, Ruby.Float rb_c) {
		return;
	}

	public Ruby.Array get_ary() {
		return Ruby.Array.new();
	}

	public Ruby.Bool responds_to_length(Ruby.Value obj) {
		if (obj.respond_to(Ruby.id("length")) == 0)
			return Ruby.False;
		return Ruby.True;
	}

	public void set_foo(Ruby.Hash hash) {
		hash.set((Ruby.Value) Ruby.String.new("foo"), Ruby.int2fix(123));
		return;
	}

	public int times_2(int a) {
		return a*2;
	}

	public long vala_length(string str) {
		return str.size();
	}

	public static int add1(int a, int b) {
		return a + b;
	}

	public static string? maybe_string(int a) {
		if (a > 10)
			return "adama";
		else
			return null;
	}

	public static long maybe_length(string? a) {
		if (a == null)
			return 0;
		else
			return a.len();
	}

	public int anint { get; set; }

	public static bool invert(bool a) {
		if (a)
			return false;
		else
			return true;
	}

// 	public static int iterator_length(Ruby.Array rba) {
// 		int i = 0;
// 		foreach(Ruby.Value obj in rba)
// 			i += 1;
// 		return i;
// 	}

	public signal void sig_1(int a);

	public void trigger_sig_1(int a) {
		this.sig_1(a);
	}

	public unichar get_unichar(string s, int i) {
		return s[i];
	}

	public string set_unichar(unichar uc, int len) {
		StringBuilder s = new StringBuilder();
		for(int i = 0; i < len; i++) 
			s.append_unichar(uc);
		return s.str;
	}
	
	public void throws_error(int a) throws IOError {
		if (true) {
			throw new IOError.FILE_NOT_FOUND("Requested file could not be found.");
		}	
	}

	public void catch_error(int a) {
		try {
			throws_error(a);
		}
		catch (IOError e) {
			stdout.printf("caught error: %s\n", e.message);
		}
	}

	public string[] returns_string_array() {
		string[] arr = {"a", "b", "c"};
		return arr;
	}

	public int accepts_string_array(string[] foo) {
		int i = 0;
		foreach(string f in foo)
			if (f.size() > 1)
				i += 1;
		return i;
	}

	public int[] returns_int_array() {
		int[] arr = {1, 10, 100};
		return arr;
	}

	public int accepts_int_array(int[] foo) {
		int i = 0;
		foreach(int f in foo)
			if (f > 15)
				i += 1;
		return i;
	}
}

errordomain IOError {
	FILE_NOT_FOUND
}
