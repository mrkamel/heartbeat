
module Heartbeat
  class Controller
    attr_accessor :failover_ip, :ip_monitor

    def initialize
      self.failover_ip = FailoverIp.new(Heartbeat.config.failover_ip)
      self.ip_monitor = IpMonitor.new(Heartbeat.config.ping_ip)
    end

    def responsible?
      current = failover_ip.current_ping

      if Heartbeat.config.ping_ip == current || Heartbeat.config.ping_ip == Heartbeat.config.failover_ip
        true
      else
        Heartbeat.logger.info "Not responsible for #{current}"

        false
      end
    end

    def next_ip
      target = failover_ip.current_target

      if index = Heartbeat.config.ips.index { |ip| ip.target == target }
        (Heartbeat.config.ips.size - 1).times do |i|
          ip = Heartbeat.config.ips[(index + i + 1) % Heartbeat.config.ips.size]

          return ip if Ip.new(ip.ping).up?
        end 
      end

      Heartbeat.logger.error "No more ips available"

      nil
    end

    def switch
      if new_ip = next_ip
        failover_ip.switch_to new_ip.target
      end
    end

    def start
      ip_monitor.monitor do
        switch if responsible?

        return if Heartbeat.config.only_once?
      end
    end
  end
end

