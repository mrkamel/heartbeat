
require "yaml"

module Config
  def self.load(path)
    deep_symbolize(YAML.load_file(path))
  end

  def self.deep_symbolize(value)
    if value.is_a?(Array)
      value.map { |val| deep_symbolize(val) }
    elsif value.is_a?(Hash)
      value.transform_keys(&:to_sym).transform_values { |val| deep_symbolize(val) }
    else
      value
    end
  end
end
