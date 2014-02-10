
$:.unshift File.expand_path("../..", __FILE__)

require "test_helper"

class Heartbeat::FailoverIpTest < Test::Unit::TestCase
  def test_ip
    assert_equal "Ip", Heartbeat::FailoverIp.new("Ip").ip
  end

  def test_initialize
    # Already tested
  end

  def test_current_target
    Heartbeat.config = Hashr.new(:base_url => "https://base_url", :basic_auth => "Basic auth")

    response = stub(:success? => true, :parsed_response => { "failover" => { "active_server_ip" => "Active server ip" }})

    HTTParty.expects(:get).with("https://base_url/failover/Ip", :basic_auth => "Basic auth").returns(response)

    assert_equal "Active server ip", Heartbeat::FailoverIp.new("Ip").current_target
  end

  def test_current_ping
    Heartbeat.config = Hashr.new(:ips => [{ :ping => "Another ping", :target => "Another target" }, { :ping => "Current ping", :target => "Current target" }])
    Heartbeat.config.ips = Heartbeat.config.ips.collect { |ip| Hashr.new ip }

    failover_ip = Heartbeat::FailoverIp.new("Ip")
    failover_ip.expects(:current_target).returns("Current target")

    assert_equal "Current ping", failover_ip.current_ping
  end

  def test_switch_to
    Heartbeat.config = Hashr.new(:base_url => "https://base_url", :basic_auth => "Basic auth")

    failover_ip = Heartbeat::FailoverIp.new("Ip")
    failover_ip.expects(:current_target).returns("Current target")

    Heartbeat::Hooks.expects(:run_before).with("Ip", "Current target", "Desired target")
    Heartbeat::Hooks.expects(:run_after).with("Ip", "Current target", "Desired target")

    HTTParty.expects(:post).with("https://base_url/failover/Ip", :body => { :active_server_ip => "Desired target" }, :basic_auth => "Basic auth").returns stub(:success? => true)

    failover_ip.switch_to "Desired target"
  end
end

