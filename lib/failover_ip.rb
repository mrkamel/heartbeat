
class FailoverIp
  attr_accessor :logger, :base_url, :failover_ip, :ips

  def ping(ip = failover_ip)
    `ping -W #{10} -c 1 #{ip}`

    $?.success?
  end

  def up?
    ping
  end

  def down?
    !ping
  end

  def current_ip
    # JSON.parse(RestClient.get("https://#{base_url}/failover/#{failover_ip}"))["failover"]["active_server_ip"]
  rescue Exception => e
    logger.error "Unable to retrieve the active server ip."

    nil
  end

  def next_ip(current = current_ip)
    if index = ips.index(current)
      (ips.size - 1).times do |i|
        ip = ips[(index + i + 1) % ips.size]

        return ip if ping(ip)
      end
    end

    nil
  end

  def switch_ips
    if switch_to = next_ip
      # RestClient.post("https://#{base_url}/failover/#{failover_ip}", :active_server_ip => switch_to)

      return true
    end

    false
  rescue Exception => e
    logger.error "Unable to set a new active server ip."

    false
  end

  def initialize(logger, base_url, failover_ip, ips)
    self.logger = logger
    self.base_url = base_url
    self.failover_ip = failover_ip
    self.ips = ips
  end

  def monitor
    loop do
      if down?
        logger.info "#{failover_ip} is down."

        switch_ips

        sleep 300
      else
        logger.info "#{failover_ip} is up."

        sleep 30
      end
    end
  end
end

