require 'test/unit'
require 'spreadskos'

class SpreadskosTest < Test::Unit::TestCase

  def test_skos_setup
    s = Spreadskos.new
    assert_not_nil s.skos_obj
  end

end
