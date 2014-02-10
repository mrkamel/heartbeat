
require "json"
require "httparty"

module Heartbeat
  class FailoverIp
    attr_accessor :ip

    def initialize(ip)
      self.ip = ip
    end

    def current_target
      response = HTTParty.get("#{Heartbeat.config.base_url}/failover/#{ip}", :basic_auth => Heartbeat.config.basic_auth)

      raise unless response.success?

      response.parsed_response.deep_symbolize_keys[:failover][:active_server_ip]
    rescue
      Heartbeat.logger.error "Unable to retrieve the active server ip"

      nil
    end

    def current_ping
      target = current_target

      res = Heartbeat.config.ips.detect { |ip| ip.target == target }

      return res.ping if res 

      nil 
    end 

    def switch_to(target)
      Heartbeat.logger.info "Switching to #{target}."

      old_target = current_target

      Hooks.run_before ip, old_target, target

      raise unless HTTParty.post("#{Heartbeat.config.base_url}/failover/#{ip}", :body => { :active_server_ip => target }, :basic_auth => Heartbeat.config.basic_auth).success?

      Hooks.run_after ip, old_target, target
    rescue
      Heartbeat.logger.error "Unable to set a new active server ip"
    end
  end
end

