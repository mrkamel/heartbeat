
$:.unshift File.expand_path("../..", __FILE__)

require "test_helper"

class Heartbeat::HooksTest < Test::Unit::TestCase
  def test_run_before
    assert_hooks_run "before" do
      Heartbeat::Hooks.run_before "0.0.0.0", "1.1.1.1", "2.2.2.2"
    end
  end

  def test_run_after
    assert_hooks_run "after" do
      Heartbeat::Hooks.run_after "0.0.0.0", "1.1.1.1", "2.2.2.2"
    end
  end
end

