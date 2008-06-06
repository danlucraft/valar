

using Ruby;
using GLib;

namespace Nested {
	public class Foo : Object{
		public string adama() {
			return "adama";
		}
	}

	public class Bar : Object {
		public int member;
		public weak Foo foom;
		public static int seven() {
			return 7;
		}
	}

	public class Baz : Object {
		public int anint {get; set;}
		
		construct {
			this.anint += 10;
		}

		public Baz(int a) {
			this.anint = a;
		}

		public static void use_baz() {
			Baz b = new Baz(10);
			return;
		}

		public int times(int a, int b) {
			// implicit:
			Nested.Foo foo = new Nested.Foo();
			// Gobject:
			Nested.Bar bar = new Nested.Bar();
			return a*b;
		}
		public class Qux : Object {
			public int nine() {
				return 9;
			}
		}
		public class Quux : Baz {
			public int fourteen() {
				return 14;
			}
			public Quux(Qux q) {
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

	public static int quux_user(Nested.Baz.Quux q) {
		return q.fourteen();
	}
}