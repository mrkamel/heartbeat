
require "heartbeat/controller"
require "heartbeat/failover_ip"
require "heartbeat/hooks"
require "heartbeat/ip_monitor"
require "heartbeat/ip"
require "heartbeat/version"

module Heartbeat
  def self.config=(config)
    Thread.current[:config] = config
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

