
$:.unshift File.expand_path("../..", __FILE__)

require "test_helper"

class Heartbeat::HooksTest < Test::Unit::TestCase
  def setup
    Heartbeat.config = Hashr.new(:hooks_dir => "hooks")
  end

  def test_run_before
    assert_hooks_run "hooks", "before" do
      Heartbeat::Hooks.run_before "0.0.0.0", "1.1.1.1", "2.2.2.2"
    end
  end

  def test_run_after
    assert_hooks_run "hooks", "after" do
      Heartbeat::Hooks.run_after "0.0.0.0", "1.1.1.1", "2.2.2.2"
    end
  end
end

