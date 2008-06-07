require 'gtk2'
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
  
  def test_defined_type_arguments
    assert_equal "adama", Nested.foo_user(Nested::Foo.new)
    assert_equal 7, Nested.bar_user(Nested::Bar.new)
  end
  
  def test_defined_type_return
    assert_equal Nested::Baz::Qux, Nested.qux_returner.class
  end
  
  def test_constructor
    baz = Nested::Baz.new(101)
    assert_equal 101, baz.anint
  end
  
  def test_descended_from_gobj
    q = Nested::Baz::Quux.new(Nested::Baz::Qux.new)
    assert_equal 14, Nested.quux_user(q)
  end
  
  def test_data_members
    b = Nested::Bar.new
    b.member = 10
    assert_equal 10, b.member
    b.foom = Nested::Foo.new
    assert_equal "adama", Nested.foo_user(b.foom)
    
  end
end
