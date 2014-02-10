
$:.unshift File.expand_path("../..", __FILE__)

require "test_helper"

class Heartbeat::ControllerTest < Test::Unit::TestCase
  def test_failover_ip
    Heartbeat.config = Hashr.new(:failover_ip => "Failover ip")

    assert_equal "Failover ip", Heartbeat::Controller.new.failover_ip.ip
  end

  def test_ip_monitor
    Heartbeat.config = Hashr.new(:ping_ip => "Ping ip")

    assert_equal "Ping ip", Heartbeat::Controller.new.ip_monitor.ip
  end

  def test_initialize
    # Already tested
  end

  def test_responsible_ping_ip_equals_failover_ip
    Heartbeat.config = Hashr.new(:failover_ip => "Failover ip", :ping_ip => "Failover ip")

    controller = Heartbeat::Controller.new

    controller.failover_ip.expects(:current_ping).returns("Another ip")

    assert controller.responsible?
  end

  def test_responsible_current_ping_equals_ping_ip
    Heartbeat.config = Hashr.new(:failover_ip => "Failover ip", :ping_ip => "Ping ip")

    controller = Heartbeat::Controller.new

    controller.failover_ip.expects(:current_ping).returns("Ping ip")

    assert controller.responsible?
  end

  def test_not_responsible
    Heartbeat.config = Hashr.new(:failover_ip => "Failover ip", :ping_ip => "Ping ip")

    controller = Heartbeat::Controller.new

    controller.failover_ip.expects(:current_ping).returns("Another ip")

    refute controller.responsible?
  end

  def test_next_ip  
    Heartbeat.config = Hashr.new(:ips => [
      { :ping => "Another ping", :target => "Another target" },
      { :ping => "Desired ping", :target => "Desired target" },
      { :ping => "Current ping", :target => "Current target" }
    ])

    Heartbeat.config.ips = Heartbeat.config.ips.collect { |ip| Hashr.new ip }

    controller = Heartbeat::Controller.new

    controller.failover_ip.expects(:current_target).returns("Current target")

    Heartbeat::Ip.expects(:new).with("Another ping").returns stub(:up? => false)
    Heartbeat::Ip.expects(:new).with("Desired ping").returns stub(:up? => true)

    assert_equal controller.next_ip, :ping => "Desired ping", :target => "Desired target"
  end

  def test_switch
    controller = Heartbeat::Controller.new

    controller.expects :next_ip => stub(:target => "Next ip")
    controller.failover_ip.expects(:switch_to).with("Next ip")

    controller.switch
  end

  def test_start
    Heartbeat.config = Hashr.new(:ping_ip => "Ping ip", :down_interval => 1)

    Heartbeat::Ip.expects(:new).twice.with("Ping ip").returns stub(:down? => true)

    controller = Heartbeat::Controller.new

    controller.expects(:responsible?).twice.returns(true)
    controller.expects(:switch).twice.returns(true).then.raises(LeaveLoopException)

    assert_raise(LeaveLoopException) { controller.start }
  end

  def test_start_only_once
    Heartbeat.config = Hashr.new(:ping_ip => "Ping ip", :only_once => true)

    Heartbeat::Ip.expects(:new).with("Ping ip").returns stub(:down? => true)

    controller = Heartbeat::Controller.new

    controller.expects(:responsible?).returns(true)
    controller.expects(:switch).returns(true)

    controller.start
  end
end

