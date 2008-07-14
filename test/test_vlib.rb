require 'gtk2'
require 'test/vlib/build_vlib'
require 'test/vlib/vlib_rb'
require 'test/unit'

class TestVala < Test::Unit::TestCase
  def test_array_get_length
    assert_equal 3, VLib.new.get_length([1, 2, 3, ])
  end

  def test_string_get_length
    assert_equal 3, VLib.new.get_str_length("asd")
  end
  
  # if --no-type-checks, these segfault:
  def test_type_checks_work
    assert_raises(ArgumentError) {
      VLib.new.get_length(10)
    }
    assert_raises(ArgumentError) {
      VLib.new.get_str_length(10)
    }
    VLib.new.sum_3(10, 4, 2.0)
    assert_raises(ArgumentError) {
      VLib.new.sum_3(10, 4, 2)
    }
    assert_raises(ArgumentError) {
      VLib.new.sum_3(10.9, 4, 2.0)
    }
  end
  
  def test_ary_new
    a = VLib.new.get_ary
    assert_equal Array, a.class
    assert_equal 0, a.length
  end
  
  def test_id
    assert_equal false, VLib.new.responds_to_length(1)
    assert_equal true, VLib.new.responds_to_length([1, 2, 3])
  end
  
  def test_hash
    h = {}
    VLib.new.set_foo(h)
    assert_equal 123, h["foo"]
  end
  
  # these test conversions
  def test_times_2
    assert_equal 264, VLib.new.times_2(132)
    assert_equal 74, VLib.new.times_2(37)
  end
  
  def test_vala_length
    assert_equal 4, VLib.new.vala_length("asdf")
    assert_equal 7, VLib.new.vala_length("asdf123")
  end
  
  def test_static_methods
    assert_equal 7, VLib.add1(3, 4)
  end
  
  def test_nullable_return_values
    assert_equal "adama", VLib.maybe_string(100)
    assert_equal nil, VLib.maybe_string(1)
  end
  
  def test_nullable_arguments
    assert_equal 0, VLib.maybe_length(nil)
    assert_equal 5, VLib.maybe_length("adama")
    assert_raises(ArgumentError) {
      VLib.maybe_length(19)
    }
  end
  
  def test_simple_property
    vl = VLib.new
    vl.anint = 10
    assert_equal 10, vl.anint
  end
  
  def test_boolean_conversion
    assert_equal true, VLib.invert(false)
    assert_equal false, VLib.invert(true)
  end
  
  def signals
    v = VLib.new
    foo = nil
    v.signal_connect("sig_1") do |val|
      foo = val
    end
    assert_nil foo
    v.trigger_sig_1(101)
    assert_equal 101, foo
  end
  
  def test_unichar
    v = VLib.new
    assert_equal "ö", v.get_unichar("höllo", 1)
    assert_equal "ööööö", v.set_unichar("ö", 5)
  end
  
  def test_errors
    v = VLib.new
    assert_raises(ValaError) {
      v.throws_error(10)
    }
  end
  
  def test_string_array_translation
    v = VLib.new
    assert_equal %w(a b c), v.returns_string_array
    assert_equal 3, v.accepts_string_array(%w(aa bb c ddd e))
  end
  
  def test_int_array_translation
    v = VLib.new
    assert_equal [1, 10, 100], v.returns_int_array
    assert_equal 1, v.accepts_int_array([1, 10, 100])
  end
  
  def test_consts
    assert_equal 1, VLib::FOO
    assert_equal 2, VLib::BAR
  end
  
  def test_returns_array_list_int
    assert_equal [], VLib.new.returns_int_al(0)
    assert_equal [3, 3, 3], VLib.new.returns_int_al(3)
  end
  
  def test_accepts_array_list_int
    assert_equal 10, VLib.new.accepts_int_al([1, 2, 3, 4])
  end
  
  def test_type_check_for_array_list
    assert_raises(ArgumentError) {
      VLib.new.accepts_int_al(6)
    }
  end
  
  def test_accepts_vlib_array_list
    v1 = VLib.new
    v1.anint = 1
    v2 = VLib.new
    v2.anint = 10
    v3 = VLib.new
    v3.anint = 20
    assert_equal 31, VLib.accepts_array_of_objects([v1, v2, v3])
  end
  
  def test_accepts_string_array_list
    assert_equal 10, VLib.new.accepts_string_al(%w(hi ho hum tum))
  end
  
  def test_returns_string_array_list
    assert_equal %w(tic tac toe), VLib.new.returns_string_al("tic-tac-toe", "-")
  end
  
  def test_member_int
    v = VLib.new
    v.memberint = 121
    assert_equal 121, v.memberint
  end
  
  def test_member_string
    v = VLib.new
    v.memberstring = "as"
    assert_equal "as", v.memberstring
  end
  
  def test_string_member_that_is_null
    v = VLib.new
    assert_equal nil, v.memberstring
  end

  def test_member_array_list
    v = VLib.new
    v.member_sal = %w(tic tac toe)
    assert_equal %w(tic tac toe), v.member_sal
  end
  
  def test_static_member_string
    VLib.static_memberstring = "asdf"
    assert_equal "asdf", VLib.static_memberstring
  end

#   def test_member_string_array
#     VLib.member_string_array = %w(tic tac toe)
#     assert_equal %w(tic tac toe), VLib.member_string_array
#   end

end
