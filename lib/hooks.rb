
class Hooks
  def self.run(failover_ip, old_ip, new_ip)
    Dir[File.expand_path("../../hooks/*", __FILE__)].sort.each do |file|
      system(file, failover_ip, old_ip, new_ip) if File.executable?(file)
    end
  end
end

