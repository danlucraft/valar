
class Valar
  class ValaTypeInstance
    attr_accessor :type, :nullable
    
    def nullable?
      @nullable
    end
    
    def initialize(type, nullable)
      @type = type
      @nullable = nullable
    end
    
    def method_missing(sym, *args, &block)
      return nil unless @type
      @type.send(sym, *args, &block)
    end
  end
  
  class ValaType
    attr_accessor :name, :type_builder, :superclass
    
    class TypeBuilder
      def initialize
        @c_to_ruby = {}
        @ruby_to_c = {}
      end
    
      def underscore_type(val)
        @underscore_type = val
      end
      
      def ruby_type(val)
        @ruby_type = val
      end
    
      def ruby_vala_type(val)
        @ruby_vala_type = val
      end
      
      def c_type(val)
        @c_type = val
      end
      
      def g_type(val)
        @g_type = val
      end
      
      def g_type_to_pointer(val)
        @g_type_to_pointer = val
      end
      
      def g_pointer_to_type(val)
        @g_pointer_to_type = val
      end
      
      def ref_func(val)
        @ref_func = val
      end
      
      def unref_func(val)
        @unref_func = val
      end
      
      def ruby_type_check(type_check_types, type_check_message)
        @type_check_types = type_check_types
        @type_check_message = type_check_message
      end
      
      def c_to_ruby(where=:after, &block)
        @c_to_ruby[where] = block
      end
      
      def ruby_to_c(where=:before, &block)
        @ruby_to_c[where] = block
      end
      
      def args(&block)
        @args = block
      end
      
      def return_args(&block)
        @return_args = block
      end
    end
    
    def underscore_type
      @type_builder.instance_variable_get(:@underscore_type)
    end
    
    def ruby_type
      @type_builder.instance_variable_get(:@ruby_type)
    end

    def ruby_vala_type
      @type_builder.instance_variable_get(:@ruby_vala_type)
    end

    def c_type
      @type_builder.instance_variable_get(:@c_type)
    end

    def g_type
      @type_builder.instance_variable_get(:@g_type)
    end
    
    def g_pointer_to_type
      @type_builder.instance_variable_get(:@g_pointer_to_type)
    end
    
    def g_type_to_pointer
      @type_builder.instance_variable_get(:@g_type_to_pointer)
    end
    
    def ruby_type_check
      return @type_builder.instance_variable_get(:@type_check_types),
             @type_builder.instance_variable_get(:@type_check_message)
    end
    
    def ref_func
      @type_builder.instance_variable_get(:@ref_func)
    end
    
    def unref_func
      @type_builder.instance_variable_get(:@unref_func)
    end
    
    def args(name)
      @c = name
      block = @type_builder.instance_variable_get(:@args)
      self.instance_eval(&block) if block
    end

    def return_args(name)
      @ruby = name
      block = @type_builder.instance_variable_get(:@return_args)
      self.instance_eval(&block) if block
    end
    
    attr_accessor :c, :ruby
    
    def c_to_ruby(where, from, to)
      @c, @ruby = from, to
      block = @type_builder.instance_variable_get(:@c_to_ruby)[where]
      return "" unless block
      self.instance_eval(&block)
    end
    
    def ruby_to_c(where, from, to)
      @ruby, @c = from, to
      block = @type_builder.instance_variable_get(:@ruby_to_c)[where]
      return "" unless block
      self.instance_eval(&block)
    end

    def forward_convertible?
      @type_builder.instance_variable_get(:@ruby_to_c).size > 0
    end
    
    def backward_convertible?
      @type_builder.instance_variable_get(:@c_to_ruby).size > 0
    end

    def self.parse(string)
      if string.include? "<"
        case string
        when /^Gee.ArrayList<(.*)>/
          type = ArrayListType.new(parse($1))
          type.name = string
          return ValaTypeInstance.new(type, false)
        when /^Gee.HashMap<(.*), ?(.*)>/
          type = HashMapType.new(parse($1), parse($2))
          type.name = string
          return ValaTypeInstance.new(type, false)
        end
      end
      if string[-1..-1] == "?"
        type = ValaType.find_type(string[0..-2])
        unless type
          type = ValaType.create(string) {}
        end
        ValaTypeInstance.new(type, true)
      else
        type = ValaType.find_type(string)
        unless type
          type = ValaType.create(string) {}
        end
        ValaTypeInstance.new(type, false)
      end
    end
    
    def self.create(name, &block)
      vb = TypeBuilder.new
      vb.instance_eval(&block)
      vt = ValaType.new
      vt.type_builder = vb
      vt.name = name
      @types ||= []
      @types << vt
      vt
    end
    
    def self.create_vala_ruby_type(name, &block)
      vb = TypeBuilder.new
      vb.instance_eval(&block)
      vt = ValaRubyType.new
      vt.type_builder = vb
      vt.name = name
      @types ||= []
      @types << vt
      vt
    end
    
    def self.types
      @types ||= []
    end
    
    def self.find_type(string)
      @types.find{|t| t.name == string}
    end
  end
  
  class ValaRubyType < ValaType
    def forward_convertible?
      true
    end
    
    def backward_convertible?
      true
    end

    def c_type
      "VALUE"
    end
    
    def c_to_ruby(where, from, to)
      case where
      when :before
        nil
      when :after
        "#{to} = #{from};"
      end
    end
    
    def ruby_to_c(where, from, to)
      case where
      when :before
        "#{to} = #{from};"
      when :after
        nil
      end
    end
  end
  
  class ArrayListType < ValaType
    def initialize(parameter_type)
      @parameter_type = parameter_type
    end
    
    def forward_convertible?
      @parameter_type.forward_convertible?
    end
    
    def backward_convertible?
      @parameter_type.backward_convertible?
    end
    
    def c_type
      "GeeArrayList*"
    end
    
    def ruby_type
      "Array"
    end

    def ruby_type_check 
      return ["T_ARRAY"], "expected an array"
    end
    
    def c_to_ruby(where, c, ruby)
      case where
      when :before
        nil
      when :after
      <<END
    // ArrayListType#c_to_ruby(#{where.inspect}, #{c.inspect}, #{ruby.inspect})
    if (#{c} == NULL) {
        #{ruby} = Qnil;
    }
    else {
        int it_#{u1 = Valar.uniqid};
        #{ruby} = rb_ary_new2((long) gee_collection_get_size (GEE_COLLECTION (#{c})));
        for (it_#{u1} = 0; it_#{u1} < gee_collection_get_size (GEE_COLLECTION (#{c})); it_#{u1} = it_#{u1} + 1) {
            #{@parameter_type.c_type} i_#{u2 = Valar.uniqid};
            i_#{u2} = #{@parameter_type.g_pointer_to_type} (gee_list_get (GEE_LIST (#{c}), it_#{u1}));
            VALUE rb_i#{u2};
            #{@parameter_type.c_to_ruby(:after, "i_"+u2, "rb_i"+u2)}
            rb_ary_store (#{ruby}, it_#{u1}, rb_i#{u2});
        }
    }
END
      end
    end
    
    def ruby_to_c(where, ruby, c)
      case where
      when :before
        if Valar.defined_object?(@parameter_type.name)
          ref_func = "((GBoxedCopyFunc) (g_object_ref))"
          unref_func = "g_object_unref"
        else
          ref_func = @parameter_type.ref_func
          unref_func = @parameter_type.unref_func
        end
        <<END
    // ArrayListType#ruby_to_c(#{where.inspect}, #{ruby.inspect}, #{c.inspect})
    int len_#{u1=Valar.uniqid} = RARRAY_LEN(#{ruby});
    _c_#{ruby} = gee_array_list_new (#{@parameter_type.g_type}, #{ref_func}, #{unref_func}, g_direct_equal);
    {
        gint i;
        i = 0;
        for (; i < len_#{u1}; i++) {
            VALUE _rb_el = rb_ary_entry(#{ruby}, (long) i);
            #{@parameter_type.c_type} #{@parameter_type.ruby_to_c(:before, "_rb_el", "_c_el")}
            gee_collection_add (GEE_COLLECTION (_c_#{ruby}), #{@parameter_type.g_type_to_pointer}(_c_el));
        }
    }
END
      when :after
        nil
      end
    end
  end
  
  class HashMapType < ValaType
    def initialize(key_type, value_type)
      @key_type, @value_type = key_type, value_type
    end
    
    def forward_convertible?
      [@key_type, @value_type].all? {|t| t.forward_convertible?}
    end
    
    def backward_convertible?
      [@key_type, @value_type].all? {|t| t.backward_convertible?}
    end
    
    def c_type
      "GeeHashMap*"
    end
    
    def ruby_type
      "Hash"
    end

    def ruby_type_check 
      return ["T_HASH"], "expected a hash"
    end
    
    def c_to_ruby(where, c, ruby)
      case where
      when :before
        nil
      when :after
      <<END
    // HashMap#c_to_ruby(#{where.inspect}, #{c.inspect}, #{ruby.inspect})
    if (#{c} == NULL) {
        #{ruby} = Qnil;
    }
    else {
        #{ruby} = rb_hash_new();
        GeeSet* s_collection;
        GeeIterator* s_it;
        s_collection = gee_map_get_keys (GEE_MAP (#{c}));
        s_it = gee_iterable_iterator (GEE_ITERABLE (s_collection));
        while (gee_iterator_next (s_it)) {
            #{@key_type.c_type} s;
            s = ((#{@key_type.c_type}) (gee_iterator_get (s_it)));
            {
                #{@value_type.c_type} v;
                v = GPOINTER_TO_INT (GPOINTER_TO_INT (gee_map_get (GEE_MAP (#{c}), s)));
                VALUE rb_s;
                #{@key_type.c_to_ruby(:after, "s", "rb_s")}
                VALUE rb_v;
                #{@value_type.c_to_ruby(:after, "v", "rb_v")}
                rb_hash_aset(#{ruby}, rb_s, rb_v);
//                s = (g_free (s), NULL);
            }
        }
        (s_it == NULL ? NULL : (s_it = (g_object_unref (s_it), NULL)));
        (s_collection == NULL ? NULL : (s_collection = (g_object_unref (s_collection), NULL)));
    }
END
      end
    end
    
    def ruby_to_c(where, ruby, c)
      case where
      when :before
        if Valar.defined_object?(@key_type.name)
          key_ref_func = "((GBoxedCopyFunc) (g_object_ref))"
          key_unref_func = "g_object_unref"
        else
          key_ref_func = @key_type.ref_func
          key_unref_func = @key_type.unref_func
        end
        if Valar.defined_object?(@value_type.name)
          value_ref_func = "((GBoxedCopyFunc) (g_object_ref))"
          value_unref_func = "g_object_unref"
        else
          value_ref_func = @value_type.ref_func
          value_unref_func = @value_type.unref_func
        end
        <<END
    // HashMap#ruby_to_c(#{where.inspect}, #{ruby.inspect}, #{c.inspect})
    _c_#{ruby} = gee_hash_map_new (#{@key_type.g_type}, #{key_ref_func}, #{key_unref_func}, #{@value_type.g_type}, #{value_ref_func}, #{value_unref_func}, g_str_hash, g_str_equal, g_direct_equal);
    VALUE rb_keys = rb_funcall(#{ruby}, rb_intern("keys"), 0);
    int len_#{u1=Valar.uniqid} = RARRAY_LEN(rb_keys);
    {
        gint i;
        i = 0;
        for (; i < len_#{u1}; i++) {
            VALUE _rb_key = rb_ary_entry(rb_keys, (long) i);
            VALUE _rb_value = rb_hash_aref(#{ruby}, _rb_key);
            #{@key_type.c_type} _c_key;
            #{@key_type.ruby_to_c(:before, "_rb_key", "_c_key")}
            #{@value_type.c_type} _c_value;
            #{@value_type.ruby_to_c(:before, "_rb_value", "_c_value")}
            gee_map_set (GEE_MAP (_c_#{ruby}), _c_key, #{@value_type.g_type_to_pointer} (_c_value));
        }
    }
END
      when :after
        nil
      end
    end
  end
  
  ValaType.create("void") do
    ruby_type       "NilClass"
    c_type          "void"
    
    c_to_ruby { "#{ruby} = Qnil;"       }
  end

  ValaType.create("int") do
    ruby_type       "Fixnum"
    ruby_vala_type  "Ruby.Int"
    c_type          "int"
    ruby_type_check ["T_FIXNUM"], "expected a small integer"
    g_type          "G_TYPE_INT"
    g_type_to_pointer "GINT_TO_POINTER"
    g_pointer_to_type "GPOINTER_TO_INT"
    ref_func        "NULL"
    unref_func      "NULL"
    
    c_to_ruby { "#{ruby} = INT2FIX(#{c});"       }
    ruby_to_c { "#{c} = FIX2INT(#{ruby});"  }
  end

  ValaType.create("long") do
    ruby_type       "Fixnum"
    ruby_vala_type  "Ruby.Int"
    c_type          "long"
    ruby_type_check ["T_FIXNUM"], "expected a small integer"
    ref_func        "NULL"
    unref_func      "NULL"
    
    c_to_ruby { "#{ruby} = LONG2FIX(#{c});"       }
    ruby_to_c { "#{c} = FIX2LONG(#{ruby});"  }
  end

  ValaType.create("double") do
    ruby_type       "Float"
    ruby_vala_type  "Ruby.Float"
    c_type          "double"
    ruby_type_check ["T_FLOAT"], "expected a float"
    
    c_to_ruby { "#{ruby} = rb_float_new(#{ruby});"  }
    ruby_to_c { "#{c} = NUM2DBL(#{ruby});"  }
  end
  
  ValaType.create("string") do
    ruby_type       "String"
    ruby_vala_type  "Ruby.String"
    c_type          "char *"
    ruby_type_check ["T_STRING"], "expected a string"
    g_type          "G_TYPE_STRING"
    ref_func        "((GBoxedCopyFunc) (g_strdup))"
    unref_func      "g_free"
    g_type_to_pointer ""
    g_pointer_to_type "(char *)"
    
    c_to_ruby do
      <<-END
      if (#{c} == NULL) {
        #{ruby} = Qnil;
      }
      else {
        #{ruby} = rb_str_new2(#{c});
      }
      END
    end
    ruby_to_c { "#{c} = g_strdup(STR2CSTR(#{ruby}));"    }
  end
  
  ValaType.create("bool") do
    ruby_vala_type "Ruby.Bool"
    c_type         "gboolean"
    ruby_type_check ["T_TRUE", "T_FALSE"], "expected true or false"
    
    c_to_ruby do 
      <<-END
      if (#{c} == TRUE)
          #{ruby} = Qtrue;
      else
          #{ruby} = Qfalse;
      END
    end
    
    ruby_to_c do
      <<-END
      if (#{ruby} == Qtrue)
          #{c} = TRUE;
      else
          #{c} = FALSE;
      END
    end
  end
  
  ValaType.create("unichar") do
    ruby_type       "String"
    ruby_vala_type  "Ruby.String"
    c_type          "gunichar"
    ruby_type_check ["T_STRING"], "expected a string"
    
    c_to_ruby { "#{ruby} = rb_str_new2(g_ucs4_to_utf8(&#{c}, 1, NULL, NULL, NULL));" }
    ruby_to_c { "#{c} = *g_utf8_to_ucs4(STR2CSTR(#{ruby}), RSTRING_LEN(#{ruby}), NULL, NULL, NULL);"        }
  end
  
  ValaType.create("string[]") do
    ruby_type      "Array"
    ruby_vala_type "Ruby.Array"
    c_type         "char**"
    ruby_type_check ["T_ARRAY"], "expected an array of strings"
    
    ruby_to_c(:before) do
      <<-END
          gint #{c}__length = RARRAY_LEN(#{ruby});
          #{c} = malloc(#{c}__length*sizeof(char*));
          long #{u1=Valar.uniqid};
          for(#{u1} = 0; #{u1} < #{c}__length; #{u1}++) {
             *(#{c}+#{u1}) = RSTRING_PTR(rb_ary_entry(#{ruby}, (long) #{u1}));
          }
      END
    end
    
    args       { "#{c}, #{c}__length" }
    
    c_to_ruby(:before) do 
      <<-END
          gint #{ruby}__length;
      END
    end

    return_args { "&#{ruby}__length" }
    
    c_to_ruby(:after) do
      <<-END
          if (#{c} == NULL) {
              #{ruby} = Qnil;
          }
          else {
              #{ruby} = rb_ary_new2(#{ruby}__length);
              long #{u1=Valar.uniqid};
              for(#{u1} = 0; #{u1} < #{ruby}__length; #{u1}++) {
                  rb_ary_store(#{ruby}, #{u1}, rb_str_new2(#{c}[#{u1}]));
//                g_free(#{c}[#{u1}]);
              }
          }
      END
    end
  end

  ValaType.create("int[]") do
    ruby_type      "Array"
    ruby_vala_type "Ruby.Array"
    c_type         "gint*"
    ruby_type_check ["T_ARRAY"], "expected an array of integers"
    
    ruby_to_c(:before) do
      <<-END
          gint #{c}__length = RARRAY_LEN(#{ruby});
          #{c} = malloc(#{c}__length*sizeof(gint));
          long #{u1=Valar.uniqid};
          for(#{u1} = 0; #{u1} < #{c}__length; #{u1}++) {
             #{c}[#{u1}] = NUM2INT(rb_ary_entry(#{ruby}, (long) #{u1}));
          }
      END
    end
    
    args       { "#{c}, #{c}__length" }
    
    c_to_ruby(:before) do 
      <<-END
          gint #{ruby}__length;
      END
    end

    return_args { "&#{ruby}__length" }
    
    c_to_ruby(:after) do
      <<-END
          #{ruby} = rb_ary_new2(#{ruby}__length);
          long #{u1=Valar.uniqid};
          for(#{u1} = 0; #{u1} < #{ruby}__length; #{u1}++) {
              rb_ary_store(#{ruby}, #{u1}, INT2NUM(#{c}[#{u1}]));
          }
      END
    end
  end
  
  ValaType.create_vala_ruby_type("Ruby.Value") {}
  ValaType.create_vala_ruby_type("Ruby.String")  do
    ruby_type_check ["T_STRING"], "expected a string"
  end
  ValaType.create_vala_ruby_type("Ruby.Number") do
    ruby_type_check ["T_FIXNUM", "T_BIGNUM", "T_FLOAT"], "expected a number"
  end
  ValaType.create_vala_ruby_type("Ruby.Int") do
    ruby_type_check ["T_FIXNUM"], "expected a small integer"
  end
  ValaType.create_vala_ruby_type("Ruby.Array") do
    ruby_type_check ["T_ARRAY"], "expected an array"
  end
  ValaType.create_vala_ruby_type("Ruby.Bool") {}
  ValaType.create_vala_ruby_type("Ruby.Hash") do
    ruby_type_check ["T_HASH"], "expected a Hash"
  end
  ValaType.create_vala_ruby_type "Ruby.Class" do
    ruby_type_check ["T_CLASS"], "expected a Class"
  end
  ValaType.create_vala_ruby_type "Ruby.Module" do
    ruby_type_check ["T_MODULE"], "expected a Module"
  end
  ValaType.create_vala_ruby_type "Ruby.Regexp" do
    ruby_type_check ["T_REGEXP"], "expected a Regexp"
  end
  ValaType.create_vala_ruby_type "Ruby.File" do
    ruby_type_check ["T_FILE"], "expected a File"
  end
  ValaType.create_vala_ruby_type "Ruby.Match" do
    ruby_type_check ["T_MATCH"], "expected a Matchdata"
  end
  ValaType.create_vala_ruby_type "Ruby.Symbol" do 
    ruby_type_check ["T_SYMBOL"], "expected a Symbol"
  end
  ValaType.create_vala_ruby_type "Ruby.Float" do
    ruby_type_check ["T_FLOAT"], "expected a Float"
  end
  
end
