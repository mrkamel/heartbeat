
$:.unshift File.expand_path("../..", __FILE__)

require "test/test_helper"
require "stringio"
require "lib/failover_ip"

class FailoverIpTest < Test::Unit::TestCase
  def test_ping
    assert FailoverIp.new(:ping_ip => "127.0.0.1").ping
  end

  def test_up?
    assert FailoverIp.new(:ping_ip => "127.0.0.1").up?
  end

  def test_down?
    assert FailoverIp.new(:ping_ip => "111.111.111.111").down?
  end

  def test_next_ip
    failover_ip = FailoverIp.new(:ips => ["127.0.0.1", "127.0.0.2", "111.111.111.111", "127.0.0.3"])

    assert_equal "127.0.0.2", failover_ip.next_ip("127.0.0.1")
    assert_equal "127.0.0.3", failover_ip.next_ip("127.0.0.2")
    assert_equal "127.0.0.1", failover_ip.next_ip("127.0.0.3")

    failover_ip = FailoverIp.new(:ips => ["111.111.111.111", "222.222.222"])

    assert_nil failover_ip.next_ip("111.111.111.111")
    assert_nil failover_ip.next_ip("222.222.222.222")
  end

  def test_initialize
    failover_ip = FailoverIp.new(:base_url => "base_url", :failover_ip => "failover_ip",
      :ping_ip => "ping_ip", :ips => ["ip1", "ip2"], :interval => 60, :timeout => 5, :tries => 1)

    assert_equal "base_url", failover_ip.base_url
    assert_equal "failover_ip", failover_ip.failover_ip
    assert_equal "ping_ip", failover_ip.ping_ip
    assert_equal ["ip1", "ip2"], failover_ip.ips
    assert_equal 60, failover_ip.interval
    assert_equal 5, failover_ip.timeout
    assert_equal 1, failover_ip.tries
  end

  def test_current_ip
    failover_ip = FailoverIp.new(:base_url => "https://username:password@robot-ws.your-server.de",
      :failover_ip => "0.0.0.0")

    set_current_ip :failover_ip => failover_ip, :ip => "1.1.1.1"

    assert_equal "1.1.1.1", failover_ip.current_ip
  end

  def test_switch_ips
    failover_ip = FailoverIp.new(:base_url => "https://username:password@robot-ws.your-server.de",
      :failover_ip => "0.0.0.0", :ips => ["1.1.1.1", "127.0.0.1"])

    set_current_ip :failover_ip => failover_ip, :ip => "1.1.1.1"

    assert_hooks_run do
      assert_switch(:failover_ip => failover_ip, :to => "127.0.0.1") { failover_ip.switch_ips }
    end
  end

  def test_base_url
    # Already tested.
  end

  def test_failover_ip
    # Already tested.
  end

  def test_ips
    # Already tested.
  end
end

