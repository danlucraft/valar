
require 'test/simple/build_simple'
require 'test/simple/simple_rb'
require 'test/unit'

class TestVala < Test::Unit::TestCase
  def test_objects
    assert Simple
    assert Simple.new
    assert_equal 7, Simple.new.seven
  end
end
