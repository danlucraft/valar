
require 'test/nested/build_nested'
require 'test/nested/nested_rb'
require 'test/unit'

class TestVala < Test::Unit::TestCase
  def test_objects
    assert Nested
    assert Nested::Foo
    assert Nested::Bar
    assert Nested::Baz
    assert Nested::Baz::Qux
  end
  
  def test_methods
    assert_equal "adama", Nested::Foo.new.adama
  end
end
