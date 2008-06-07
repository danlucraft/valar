require 'gtk2'
require 'test/vlib/build_vlib'
require 'test/vlib/vlib_rb'
require 'test/unit'

class TestVala < Test::Unit::TestCase
  def test_array_get_length
    assert_equal 3, Vala::VLib.new.get_length([1, 2, 3, ])
  end

  def test_string_get_length
    assert_equal 3, Vala::VLib.new.get_str_length("asd")
  end
  
  # if --no-type-checks, these segfault:
  def test_type_checks_work
    assert_raises(ArgumentError) {
      Vala::VLib.new.get_length(10)
    }
    assert_raises(ArgumentError) {
      Vala::VLib.new.get_str_length(10)
    }
    Vala::VLib.new.sum_3(10, 4, 2.0)
    assert_raises(ArgumentError) {
      Vala::VLib.new.sum_3(10, 4, 2)
    }
    assert_raises(ArgumentError) {
      Vala::VLib.new.sum_3(10.9, 4, 2.0)
    }
  end
  
  def test_ary_new
    a = Vala::VLib.new.get_ary
    assert_equal Array, a.class
    assert_equal 0, a.length
  end
  
  def test_id
    assert_equal false, Vala::VLib.new.responds_to_length(1)
    assert_equal true, Vala::VLib.new.responds_to_length([1, 2, 3])
  end
  
  def test_hash
    h = {}
    Vala::VLib.new.set_foo(h)
    assert_equal 123, h["foo"]
  end
  
  # these test conversions
  def test_times_2
    assert_equal 264, Vala::VLib.new.times_2(132)
    assert_equal 74, Vala::VLib.new.times_2(37)
  end
  
  def test_vala_length
    assert_equal 4, Vala::VLib.new.vala_length("asdf")
    assert_equal 7, Vala::VLib.new.vala_length("asdf123")
  end
  
  def test_static_methods
    assert_equal 7, Vala::VLib.add1(3, 4)
  end
  
  def test_nullable_return_values
    assert_equal "adama", Vala::VLib.maybe_string(100)
    assert_equal nil, Vala::VLib.maybe_string(1)
  end
  
  def test_nullable_arguments
    assert_equal 0, Vala::VLib.maybe_length(nil)
    assert_equal 5, Vala::VLib.maybe_length("adama")
    assert_raises(ArgumentError) {
      Vala::VLib.maybe_length(19)
    }
  end
  
  def test_simple_property
    vl = Vala::VLib.new
    vl.anint = 10
    assert_equal 10, vl.anint
  end
  
  def test_boolean_conversion
    assert_equal true, Vala::VLib.invert(false)
    assert_equal false, Vala::VLib.invert(true)
  end
end
