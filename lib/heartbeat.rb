
require "heartbeat/controller"
require "heartbeat/failover_ip"
require "heartbeat/hooks"
require "heartbeat/ip_monitor"
require "heartbeat/ip"
require "heartbeat/version"
require "hashr"

module Heartbeat
  def self.config=(config)
    Thread.current[:config] = Hashr.new(:interval => 30, :down_interval => 300, :timeout => 10, :tries => 3).merge(config)
  end

  def self.config
    Thread.current[:config]
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger
  end
end

