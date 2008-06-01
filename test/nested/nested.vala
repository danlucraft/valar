

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
			return a*b;
		}
		public class Qux {
			public int nine() {
				return 9;
			}
		}
	}
}