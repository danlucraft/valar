
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
}

