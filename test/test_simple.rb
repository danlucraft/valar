require 'gtk2'
require 'test/simple/build_simple'
require 'test/simple/src/simple_rb'
require 'test/unit'


class TestVala < Test::Unit::TestCase
  def test_objects
    assert Vala::Simple
    assert Vala::Simple.new(3)
    assert_equal 7, Vala::Simple.new(8).seven
  end
end
