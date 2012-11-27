
require "json"
require "rest-client"
require "lib/hooks"

class FailoverIp
  attr_accessor :base_url, :failover_ip, :ping_ip, :ips, :interval, :timeout, :tries

  def ping(ip = ping_ip)
    `ping -W #{timeout} -c #{tries} #{ip}`

    $?.success?
  end

  def up?
    ping
  end

  def down?
    !ping
  end

  def current_ip
    JSON.parse(RestClient.get("#{base_url}/failover/#{failover_ip}"))["failover"]["active_server_ip"]
  rescue Exception => e
    $logger.error "Unable to retrieve the active server ip."

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
    if new_ip = next_ip
      $logger.info "Switching to #{new_ip}."

      old_ip = current_ip

      RestClient.post "#{base_url}/failover/#{failover_ip}", :active_server_ip => new_ip

      Hooks.run failover_ip, old_ip, new_ip

      return true
    end

    false
  rescue Exception => e
    $logger.error "Unable to set a new active server ip."

    false
  end

  def initialize(base_url, failover_ip, ping_ip, ips, interval = 30, timeout = 10, tries = 3)
    self.base_url = base_url
    self.failover_ip = failover_ip
    self.ping_ip = ping_ip
    self.ips = ips
    self.interval = interval
    self.timeout = timeout
    self.tries = tries
  end

  def monitor
    loop do
      if down?
        $logger.info "#{ping_ip} is down."

        switch_ips

        sleep 300
      else
        $logger.info "#{ping_ip} is up."

        sleep interval
      end
    end
  end
end

