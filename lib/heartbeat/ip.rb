
module Heartbeat
  class Ip
    attr_accessor :ip

    def initialize(ip)
      self.ip = ip
    end

    def up?
      Heartbeat.config.tries.times.any? do |i|
        `ping -W #{Heartbeat.config.timeout} -c 1 #{ip}`

        Heartbeat.logger.info("ping #{i + 1}/#{Heartbeat.config.tries} of #{ip} failed") unless $?.success?

        $?.success?
      end
    end 

    def down?
      !up?
    end
  end
end

