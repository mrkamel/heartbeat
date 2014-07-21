
module Heartbeat
  class IpMonitor
    attr_accessor :ip

    def initialize(ip)
      self.ip = ip
    end

    def check
      if Heartbeat.config.force_down? || Ip.new(ip).down?
        Heartbeat.logger.info "#{ip} is down"

        false
      else
        Heartbeat.logger.info "#{ip} is up"

        true
      end
    end

    def monitor_once
      if check
        sleep Heartbeat.config.interval
      else
        yield

        sleep Heartbeat.config.down_interval
      end
    end

    def monitor(&block)
      loop { monitor_once(&block) }
    end
  end
end

