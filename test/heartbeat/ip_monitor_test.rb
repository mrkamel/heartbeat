
$:.unshift File.expand_path("../..", __FILE__)

require "test_helper"

class Heartbeat::IpMonitorTest < Test::Unit::TestCase
  def setup
    Heartbeat.config = Hashr.new(:timeout => 1, :interval => 1, :down_interval => 1, :tries => 1)
  end

  def test_ip
    assert_equal "Ip", Heartbeat::IpMonitor.new("Ip").ip
  end

  def test_initialize
    # Already tested
  end

  def test_check
    assert Heartbeat::IpMonitor.new("8.8.8.8").check
    refute Heartbeat::IpMonitor.new("1.1.1.1").check

    Heartbeat.config.force_down = true

    refute Heartbeat::IpMonitor.new("8.8.8.8").check
  end

  def test_monitor_once_up
    Heartbeat.config.interval = 1

    Heartbeat::IpMonitor.new("8.8.8.8").monitor_once
  end

  def test_monitor_once_down
    Heartbeat.config.down_interval = 1

    invoked = false

    Heartbeat::IpMonitor.new("1.1.1.1").monitor_once { invoked = true }

    assert invoked
  end

  def test_monitor
    ip_monitor = Heartbeat::IpMonitor.new("8.8.8.8")

    ip_monitor.expects(:check).twice.returns(true).then.raises(LeaveLoopException)

    assert_raise(LeaveLoopException) { ip_monitor.monitor }
  end
end

