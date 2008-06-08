
using GLib;

public class Simple : Object {
	public int anint {get; set;}
	public int seven() {
		return 7;
	}
	public Simple(int a) {
		anint = a;
	}
}

public class Simple2 {
	public int anint {get; set;}
	public int eight() {
		return 8;
	}
	public Simple2(int a) {
		anint = a;
	}
}