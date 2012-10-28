
require "rubygems"
require "bundler/setup"
require "test/unit"
require "mocha"
require "fileutils"
require "logger"

$logger = Logger.new(File.expand_path("../../log/test.log", __FILE__))

class Test::Unit::TestCase
  def assert_hooks_run
    hooks = File.expand_path("../../hooks", __FILE__)

    open(File.join(hooks, "hook1"), "w") do |stream|
      stream.write <<EOF
#!/bin/sh

echo "$1, $2" > /tmp/hook1.txt
EOF
    end

    FileUtils.chmod 0755, File.join(hooks, "hook1")

    open(File.join(hooks, "hook2"), "w") do |stream|
      stream.write <<EOF
#!/bin/sh

echo "$1, $2" > /tmp/hook2.txt
EOF
    end

    FileUtils.chmod 0755, File.join(hooks, "hook2")

    begin
      yield

      assert File.exists?("/tmp/hook1.txt")
      assert File.read("/tmp/hook1.txt") =~ /[0-9]+\.[0-9]+\.[0-9]\.[0-9]+, [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/

      assert File.exists?("/tmp/hook2.txt")
      assert File.read("/tmp/hook2.txt") =~ /[0-9]+\.[0-9]+\.[0-9]\.[0-9]+, [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/
    ensure
      FileUtils.rm_f File.join(hooks, "hook1")
      FileUtils.rm_f File.join(hooks, "hook2")

      FileUtils.rm_f "/tmp/hook1.txt"
      FileUtils.rm_f "/tmp/hook2.txt"
    end
  end

  def setup_current_ip(current_ip)
    response = { :failover => { :active_server_ip => current_ip } }

    RestClient.expects(:get).at_least_once.with("https://username:password@robot-ws.your-server.de/failover/0.0.0.0").returns(JSON.dump(response))
  end
end

