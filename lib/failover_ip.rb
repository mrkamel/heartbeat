
require "json"
require "httparty"
require "lib/hooks"
require "hashr"

class FailoverIp
  attr_accessor :base_url, :basic_auth, :failover_ip, :ping_ip, :ips, :interval, :timeout, :tries

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

  def current_target
    response = HTTParty.get("#{base_url}/failover/#{failover_ip}", :basic_auth => basic_auth).parsed_response

    response.deep_symbolize_keys[:failover][:active_server_ip]
  rescue
    $logger.error "Unable to retrieve the active server ip."

    nil
  end

  def current_ping
    target = current_target

    res = ips.detect { |ip| ip[:target] == target }

    return res[:ping] if res

    nil
  end

  def next_ip(target = current_target)
    if index = ips.index { |ip| ip[:target] == target }
      (ips.size - 1).times do |i|
        ip = ips[(index + i + 1) % ips.size]

        return ip if ping(ip[:ping])
      end
    end

    $logger.error "No more ip's available."

    nil
  end

  def switch_ips
    if new_ip = next_ip
      $logger.info "Switching to #{new_ip[:target]}."

      old_target = current_target

      HTTParty.post("#{base_url}/failover/#{failover_ip}", :body => { :active_server_ip => new_ip[:target] }, :basic_auth => basic_auth)

      Hooks.run failover_ip, old_target, new_ip[:target]

      return true
    end

    false
  rescue
    $logger.error "Unable to set a new active server ip."

    false
  end

  def initialize(options)
    self.base_url = options[:base_url]
    self.basic_auth = options[:basic_auth]
    self.failover_ip = options[:failover_ip]
    self.ping_ip = options[:ping_ip]
    self.ips = options[:ips]
    self.interval = options[:interval] || 30
    self.timeout = options[:timeout] || 10
    self.tries = options[:tries] || 3
  end

  def check
    if down?
      $logger.info "#{ping_ip} is down."

      current = current_ping

      if ping_ip == current
        switch_ips
      else
        $logger.info "Not responsible for #{current}."
      end

      false
    else
      $logger.info "#{ping_ip} is up."

      true
    end
  end

  def monitor
    loop do
      check ? sleep(interval) : sleep(300)
    end
  end
end

