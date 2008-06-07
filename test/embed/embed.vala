
using GLib;

public class RubyTest : Object {
	public static void test1() {
		Ruby.init();
		Ruby.init_loadpath();
		Ruby.script("embedded");
		Ruby.eval("p :ruby_from_vala");
	}

	public static void test2() {
		Ruby.init();
		Ruby.init_loadpath();
		Ruby.script("embedded2");
		Ruby.require("test/embed/sum.rb");
		Ruby.Value summer;
		Ruby.Int result;
		summer = Ruby.class_new_instance(0, 0, Ruby.const_get(Ruby.cObject, Ruby.id("Summer")));
		result = (Ruby.Int) summer.send(Ruby.id("sum"), 1, Ruby.int2fix(10));
		stdout.printf("result: %d\n", result.to_vala());
		Ruby.finalize();
	}

	public static void main(string[] args) {
		if (args[1] == null || args[1] == "test1")
			RubyTest.test1();
		else if (args[1] == "test2")
			RubyTest.test2();
	}

	public Ruby.Value get_length(Ruby.Array rb_array) {
		return Ruby.int2fix(rb_array.length());
	}

}