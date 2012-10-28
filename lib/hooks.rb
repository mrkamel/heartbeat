
class Hooks
  def self.run(from, to)
    Dir[File.expand_path("../../hooks/*", __FILE__)].sort.each do |file|
      system(file, from, to) if File.executable?(file)
    end
  end
end

