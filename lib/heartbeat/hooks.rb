
module Heartbeat
  class Hooks
    def self.run(kind, failover_ip, old_ip, new_ip)
      Dir[File.expand_path("../../../#{Heartbeat.config.hooks_dir}/#{kind}/*", __FILE__)].sort.each do |file|
        system(file, failover_ip, old_ip, new_ip) if File.executable?(file)
      end
    end

    def self.run_before(failover_ip, old_ip, new_ip)
      run "before", failover_ip, old_ip, new_ip
    end

    def self.run_after(failover_ip, old_ip, new_ip)
      run "after", failover_ip, old_ip, new_ip
    end
  end
end

