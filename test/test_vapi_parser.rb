require 'test/unit'
require 'lib/valar'

class TestVapiParser < Test::Unit::TestCase
  def test_a
    Valar.parse_vapi_file("test/vlib/vlib.vapi")
  end
  
  def test_b
    lib = Valar.parse_vapi_file("test/nested/nested.vapi")
    assert_equal %w(Bar Baz Foo Nested Qux), lib.object_names
    assert(nested=lib.object("Nested"))
    assert(foo=nested.object("Foo"))
    assert(adama=foo.method(:adama))
    assert_equal Valar::ValaType.parse("string"), adama.returns
    assert_equal [], adama.params
  end
end
