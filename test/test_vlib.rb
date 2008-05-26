
require 'test/build_vlib'
require 'test/vlib_rb'
require 'test/unit'

class TestVala < Test::Unit::TestCase
  def test_array_get_length
    assert_equal 3, VLib.new.get_length([1, 2, 3, ])
  end

end
