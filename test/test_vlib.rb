
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
  
  # if --no-type-checks, these segfaults:
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
  
  def test_nullable_types
    assert_equal "adama", VLib.maybe_string(100)
    assert_equal nil, VLib.maybe_string(1)
  end
end
