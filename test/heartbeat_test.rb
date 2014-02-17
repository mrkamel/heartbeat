
$:.unshift File.expand_path("../../test", __FILE__)

require "test_helper"
require "hashr"

class HeartbeatTest < Test::Unit::TestCase
  def test_config
    config = Heartbeat.config

    begin
      Heartbeat.config = Hashr.new(:key => :value)
      assert_equal Hashr.new(:hooks_dir => "hooks", :interval => 30, :down_interval => 300, :timeout => 10, :tries => 3, :key => :value), Heartbeat.config
    ensure
      Heartbeat.config = config
    end
  end

  def test_logger
    logger = Heartbeat.logger

    begin
      Heartbeat.logger = "Logger"
      assert_equal "Logger", Heartbeat.logger
    ensure
      Heartbeat.logger = logger
    end
  end
end

