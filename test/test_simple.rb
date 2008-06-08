require 'gtk2'
require 'test/simple/build_simple'
require 'test/simple/src/simple_rb'
require 'test/unit'


class TestVala < Test::Unit::TestCase
  def test_gobjects
    assert Vala::Simple
    assert Vala::Simple.new(3)
    assert_equal 7, Vala::Simple.new(8).seven
  end
  
  def test_objects
    assert Vala::Simple2
    assert Vala::Simple2.new(3)
    assert_equal 8, Vala::Simple2.new(3).eight
  end
end
