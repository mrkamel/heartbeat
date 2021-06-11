
$:.unshift File.expand_path("..", __dir__)

require "test/test_helper"
require "lib/config"

class ConfigTest < BaseTest
  def test_load
    assert_equal Config.load(File.expand_path("../examples/config/heartbeat.yml", __dir__)),
      base_url: "https://robot-ws.your-server.de",
      basic_auth: { username: "username", password: "password" },
      failover_ip: "0.0.0.0",
      ping_ip: "0.0.0.0",
      ips: [
        { ping: "1.1.1.1", target: "1.1.1.1" },
        { ping: "2.2.2.2", target: "2.2.2.2" }
      ],
      interval: 30,
      timeout: 10,
      tries: 3
  end
end

