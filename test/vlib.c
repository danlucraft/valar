/* compiling with: */

#include "vlib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>




enum  {
	VLIB_DUMMY_PROPERTY
};
static gpointer vlib_parent_class = NULL;



void vlib_hello (VLib* self) {
	g_return_if_fail (self != NULL);
	fprintf (stdout, "Hello World, MyLib\n");
}


VALUE vlib_equals_nil (VLib* self, VALUE input) {
	0;
	if (input == Qnil) {
		return Qtrue;
	} else {
		return Qfalse;
	}
}


VALUE vlib_get_length (VLib* self, VALUE rb_array) {
	0;
	return INT2FIX (RARRAY_LEN (rb_array));
}


VALUE vlib_get_str_length (VLib* self, VALUE rb_string) {
	0;
	return INT2FIX (RSTRING_LEN (rb_string));
}


void vlib_print_string (VLib* self, VALUE rb_string) {
	g_return_if_fail (self != NULL);
	fprintf (stdout, "str: %s\n", RSTRING_PTR (rb_string));
}


/*   valac -C --library vlib vlib.vala --basedir ./*/
VLib* vlib_new (GType type) {
	VLib* self;
	self = ((VLib*) g_type_create_instance (type));
	return self;
}


static void vlib_class_init (VLibClass * klass) {
	vlib_parent_class = g_type_class_peek_parent (klass);
}


static void vlib_init (VLib * self) {
	self->ref_count = 1;
}


GType vlib_get_type (void) {
	static GType vlib_type_id = 0;
	if (G_UNLIKELY (vlib_type_id == 0)) {
		static const GTypeInfo g_define_type_info = { sizeof (VLibClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) vlib_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (VLib), 0, (GInstanceInitFunc) vlib_init };
		static const GTypeFundamentalInfo g_define_type_fundamental_info = { (G_TYPE_FLAG_CLASSED | G_TYPE_FLAG_INSTANTIATABLE | G_TYPE_FLAG_DERIVABLE | G_TYPE_FLAG_DEEP_DERIVABLE) };
		vlib_type_id = g_type_register_fundamental (g_type_fundamental_next (), "VLib", &g_define_type_info, &g_define_type_fundamental_info, 0);
	}
	return vlib_type_id;
}


gpointer vlib_ref (gpointer instance) {
	VLib* self;
	self = instance;
	g_atomic_int_inc (&self->ref_count);
	return instance;
}


void vlib_unref (gpointer instance) {
	VLib* self;
	self = instance;
	if (g_atomic_int_dec_and_test (&self->ref_count)) {
		g_type_free_instance (((GTypeInstance *) self));
	}
}




