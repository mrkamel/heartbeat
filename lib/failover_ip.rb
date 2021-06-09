
require "json"
require "httparty"
require "lib/hooks"

class FailoverIp
  attr_accessor :base_url, :basic_auth, :failover_ip, :ping_ip, :ips, :interval, :timeout, :tries, :force_down, :only_once, :dry

  def ping(ip = ping_ip)
    tries.times.any? do |i|
      start = Time.now.to_f

      `ping -W #{timeout} -c 1 #{ip}`

      success = $?.success?

      $logger.info("ping #{i + 1}/#{tries} of #{ping_ip} failed") unless success

      rest = [timeout - (Time.now.to_f - start), timeout].min

      sleep(rest) if rest > 0 && !success

      success
    end
  end

  def down?
    force_down || !ping
  end

  def current_target
    response = HTTParty.get("#{base_url}/failover/#{failover_ip}", :basic_auth => basic_auth)

    raise unless response.success?

    active_server_ip = response.parsed_response["failover"]["active_server_ip"]
    $logger.info "Ip of active server: #{active_server_ip}"
    active_server_ip
  rescue
    $logger.error "Unable to retrieve the active server ip for #{failover_ip} from #{base_url}/failover/#{failover_ip}"
    $logger.error "Response from Hetzner Robot API was: #{response}"

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

        if ping(ip[:ping])
          return ip
        else
          $logger.info "Not selecting #{ip[:target]} to switch to since it doesn't ping on #{ip[:ping]}"
        end

      end
    end

    $logger.error "No more ip's available for #{failover_ip}"

    nil
  end

  def switch_ips
    if new_ip = next_ip
      $logger.info "Switching #{failover_ip} to #{new_ip[:target]}"

      old_target = current_target

      Hooks.run_before failover_ip, old_target, new_ip[:target], dry

      if !dry
        response = HTTParty.post("#{base_url}/failover/#{failover_ip}", :body => { :active_server_ip => new_ip[:target] }, :basic_auth => basic_auth)
        raise unless response.success?
        $logger.info "Switch #{failover_ip} to #{new_ip[:target]} completed"
      else
        $logger.info "Dry run: would have switched #{failover_ip} to #{new_ip[:target]}"
      end

      Hooks.run_after failover_ip, old_target, new_ip[:target], dry

      return true
    end

    false
  rescue
    $logger.error "Unable to set a new active server ip for #{failover_ip} via POST to #{base_url}/failover/#{failover_ip}, :body => { :active_server_ip => #{new_ip[:target]} }, :basic_auth => #{basic_auth}"
    $logger.error "Response from Hetzner Robot API was: #{response}"

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
    self.force_down = options[:force_down] || false
    self.only_once = options[:only_once] || false
    self.dry = options[:dry] || false
  end

  def responsible_for?(ip)
    ping_ip == ip || ping_ip == failover_ip
  end

  def check
    if down?
      $logger.info "#{ping_ip} is down"

      current = current_ping

      if responsible_for?(current)
        switch_ips
      else
        $logger.info "Not responsible for IP #{current}"
      end

      false
    else
      $logger.info "#{ping_ip} is up"

      true
    end
  end

  def monitor
    loop do
      res = check

      return if only_once

      res ? sleep(interval) : sleep(300)
    end
  end
end

