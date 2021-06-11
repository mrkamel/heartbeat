
$:.unshift File.expand_path("../..", __FILE__)

require "test/test_helper"
require "lib/config_helper"

class ConfigHelperTest < BaseTest
  def test_deep_symbolize
    assert_equal ConfigHelper.deep_symbolize("bool" => true, "array" => [{ "string" => "value" }, { "float" => 1.0 }], "integer" => 1),
      bool: true, array: [{ string: "value" }, { float: 1.0 }], integer: 1
  end
end

