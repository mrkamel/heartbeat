
class Hooks
  def self.run(kind, failover_ip, old_ip, new_ip, dry = false)
    Dir[File.expand_path("../../hooks/#{kind}/*", __FILE__)].sort.each do |file|
      if File.executable?(file)
        if !dry
          system(file, failover_ip, old_ip, new_ip)
        else
          $logger.info "Dry run: would have executed hook: system(#{file}, #{failover_ip}, #{old_ip}, #{new_ip})"
        end
      end
    end
  end

  def self.run_before(failover_ip, old_ip, new_ip, dry = false)
    run "before", failover_ip, old_ip, new_ip, dry
  end

  def self.run_after(failover_ip, old_ip, new_ip, dry = false)
    run "after", failover_ip, old_ip, new_ip, dry
  end
end

