
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