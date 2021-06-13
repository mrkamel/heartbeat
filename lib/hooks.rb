
class Hooks
  def self.run(kind, failover_ip, old_ip, new_ip, dry = false)
    files = Dir[File.expand_path("../hooks/#{kind}/*", __dir__)]
    files.sort.select { |file| File.executable?(file) }.each do |file|
      if dry
        $logger.info "Dry run: would have executed hook: system(#{file}, #{failover_ip}, #{old_ip}, #{new_ip})"
      else
        system(file, failover_ip, old_ip, new_ip)
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

