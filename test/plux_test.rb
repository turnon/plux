require "test_helper"

class PluxTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Plux::VERSION
  end
end
