

using Ruby;
using GLib;

namespace Nested {
	public class Foo {
		public string adama() {
			return "adama";
		}
	}

	public class Bar : Object {
		public static int seven() {
			return 7;
		}
	}

	public class Baz {
		public int times(int a, int b) {
			// implicit:
			Nested.Foo foo = new Nested.Foo();
			// Gobject:
			Nested.Bar bar = new Nested.Bar();
			return a*b;
		}
		public class Qux {
			public int nine() {
				return 9;
			}
		}
	}

	public static string foo_user(Foo f) {
		return f.adama();
	}

	public static int bar_user(Nested.Bar b) {
		return b.seven();
	}

	public static Baz.Qux qux_returner() {
		return new Baz.Qux();
	}
}