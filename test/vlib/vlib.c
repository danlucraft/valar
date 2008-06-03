/* compiling with: */

#include "vlib.h"
#include <stdio.h>




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


VALUE vlib_str_length_from_vala (VLib* self, VALUE rb_string) {
	0;
	return LONG2FIX (strlen (RSTRING_PTR (rb_string)));
}


void vlib_sum_3 (VLib* self, VALUE rb_a, VALUE rb_b, VALUE rb_c) {
	g_return_if_fail (self != NULL);
	return;
}


VALUE vlib_get_ary (VLib* self) {
	0;
	return rb_ary_new ();
}


VALUE vlib_responds_to_length (VLib* self, VALUE obj) {
	0;
	if (rb_respond_to (obj, rb_intern ("length")) == 0) {
		return Qfalse;
	}
	return Qtrue;
}


void vlib_set_foo (VLib* self, VALUE hash) {
	g_return_if_fail (self != NULL);
	rb_hash_aset (hash, ((VALUE) rb_str_new2 ("foo")), INT2FIX (123));
	return;
}


gint vlib_times_2 (VLib* self, gint a) {
	g_return_val_if_fail (self != NULL, 0);
	return a * 2;
}


glong vlib_vala_length (VLib* self, const char* str) {
	g_return_val_if_fail (self != NULL, 0L);
	g_return_val_if_fail (str != NULL, 0L);
	return strlen (str);
}


gint vlib_add1 (gint a, gint b) {
	return a + b;
}


char* vlib_maybe_string (gint a) {
	if (a > 10) {
		return g_strdup ("adama");
	} else {
		return NULL;
	}
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




