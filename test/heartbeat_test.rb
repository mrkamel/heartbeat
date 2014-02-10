
$:.unshift File.expand_path("../../test", __FILE__)

require "test_helper"

class HeartbeatTest < Test::Unit::TestCase
  def test_config
    config = Heartbeat.config

    begin
      Heartbeat.config = "Config"
      assert_equal "Config", Heartbeat.config
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

