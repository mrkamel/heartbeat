
$:.unshift File.expand_path("../..", __FILE__)

require "test/test_helper"
require "lib/hooks"

class HooksTest < Test::Unit::TestCase
  def test_run
    assert_hooks_run do
      Hooks.run "0.0.0.0", "1.1.1.1", "2.2.2.2"
    end
  end
end

