
module Heartbeat
  class Ip
    attr_accessor :ip

    def initialize(ip)
      self.ip = ip
    end

    def up?
      `ping -W #{Heartbeat.config.timeout || 10} -c #{Heartbeat.config.tries || 3} #{ip}`

      $?.success?
    end 

    def down?
      !up?
    end
  end
end

