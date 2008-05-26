// compiling with: 
//   valac -C --library vlib vlib.vala --basedir ./

using GLib;

public class VLib {
    public void hello() {
        stdout.printf ("Hello World, MyLib\n");
    }

	public Ruby.Value equals_nil(Ruby.Value input) {
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

	public void print_string(Ruby.String rb_string) {
		stdout.printf("str: %s\n", rb_string.to_c());
	}
}

