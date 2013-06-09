
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
    failover_ip = FailoverIp.new(:ips => [
      { :ping => "127.0.0.1", :target => "1.1.1.1" },
      { :ping => "127.0.0.2", :target => "2.2.2.2" },
      { :ping => "255.0.0.1", :target => "3.3.3.3" },
      { :ping => "127.0.0.3", :target => "4.4.4.4" }
    ])

    assert_equal({ :ping => "127.0.0.2", :target => "2.2.2.2" }, failover_ip.next_ip("1.1.1.1"))
    assert_equal({ :ping => "127.0.0.3", :target => "4.4.4.4" }, failover_ip.next_ip("2.2.2.2"))
    assert_equal({ :ping => "127.0.0.1", :target => "1.1.1.1" }, failover_ip.next_ip("4.4.4.4"))

    failover_ip = FailoverIp.new(:ips => [
      { :ping => "255.0.0.1", :target => "1.1.1.1" },
      { :ping => "255.0.0.2", :target => "2.2.2.2" }
    ])

    assert_nil failover_ip.next_ip("1.1.1.1")
    assert_nil failover_ip.next_ip("2.2.2.2")
  end

  def test_initialize
    failover_ip = FailoverIp.new(:base_url => "base_url", :basic_auth => "basic_auth", :failover_ip => "failover_ip", :ping_ip => "ping_ip", :interval => 60,
      :ips => [{ :ping => "ping1", :target => "target1" }, { :ping => "ping2", :target => "target2" }], :timeout => 5, :tries => 1)

    assert_equal "base_url", failover_ip.base_url
    assert_equal "basic_auth", failover_ip.basic_auth
    assert_equal "failover_ip", failover_ip.failover_ip
    assert_equal "ping_ip", failover_ip.ping_ip
    assert_equal [{ :ping => "ping1", :target => "target1" }, { :ping => "ping2", :target => "target2" }], failover_ip.ips
    assert_equal 60, failover_ip.interval
    assert_equal 5, failover_ip.timeout
    assert_equal 1, failover_ip.tries
  end

  def test_current_target
    failover_ip = FailoverIp.new(:base_url => "https://robot-ws.your-server.de", :basic_auth => { :username => "username", :password => "password" }, :failover_ip => "0.0.0.0")

    set_current_target :failover_ip => failover_ip, :ip => "1.1.1.1"

    assert_equal "1.1.1.1", failover_ip.current_target
  end

  def test_current_ping
    failover_ip = FailoverIp.new(:base_url => "https://robot-ws.your-server.de", :basic_auth => { :username => "username", :password => "password" }, :failover_ip => "0.0.0.0",
      :ips => [{ :ping => "1.1.1.1", :target => "2.2.2.2" }, { :ping => "3.3.3.3", :target => "4.4.4.4" }])

    set_current_target :failover_ip => failover_ip, :ip => "2.2.2.2"

    assert_equal "1.1.1.1", failover_ip.current_ping

    set_current_target :failover_ip => failover_ip, :ip => "4.4.4.4"

    assert_equal "3.3.3.3", failover_ip.current_ping
  end

  def test_switch_ips
    failover_ip = FailoverIp.new(:base_url => "https://robot-ws.your-server.de", :basic_auth => { :username => "username", :password => "password" }, :failover_ip => "0.0.0.0",
      :ips => [{ :ping => "1.1.1.1", :target => "2.2.2.2" }, { :ping => "127.0.0.1", :target => "3.3.3.3" }])

    set_current_target :failover_ip => failover_ip, :ip => "2.2.2.2"

    assert_hooks_run do
      assert_switch(:failover_ip => failover_ip, :to => "3.3.3.3") { failover_ip.switch_ips }
    end
  end

  def test_check_with_failover
    failover_ip = FailoverIp.new(:base_url => "https://robot-ws.your-server.de", :basic_auth => { :username => "username", :password => "password" }, :failover_ip => "0.0.0.0",
      :ping_ip => "1.1.1.1", :ips => [{ :ping => "1.1.1.1", :target => "2.2.2.2" }, { :ping => "127.0.0.1", :target => "3.3.3.3" }])

    set_current_target :failover_ip => failover_ip, :ip => "2.2.2.2"

    assert_switch(:failover_ip => failover_ip, :to => "3.3.3.3") { refute failover_ip.check }
  end

  def test_check_without_failover
    failover_ip = FailoverIp.new(:base_url => "https://robot-ws.your-server.de", :basic_auth => { :username => "username", :password => "password" }, :failover_ip => "0.0.0.0",
      :ping_ip => "127.0.0.1", :ips => [{ :ping => "127.0.0.1", :target => "3.3.3.3" }])

    assert failover_ip.check
  end

  def test_base_url
    # Already tested
  end

  def test_failover_ip
    # Already tested
  end

  def test_ips
    # Already tested
  end
end

