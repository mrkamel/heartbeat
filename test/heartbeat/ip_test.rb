
$:.unshift File.expand_path("../..", __FILE__)

require "test_helper"

class Heartbeat::IpTest < Test::Unit::TestCase
  def setup
    Heartbeat.config = Hashr.new(:timeout => 1, :tries => 1)
  end

  def test_ip
    assert_equal "Ip", Heartbeat::Ip.new("Ip").ip
  end

  def test_initialize
    # Already tested
  end

  def test_up?
    assert Heartbeat::Ip.new("8.8.8.8").up?
    refute Heartbeat::Ip.new("1.1.1.1").up?
  end

  def test_down?
    assert Heartbeat::Ip.new("1.1.1.1").down?
    refute Heartbeat::Ip.new("8.8.8.8").down?
  end
end


