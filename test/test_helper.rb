
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

echo "$1, $2, $3" > /tmp/hook1.txt
EOF
    end

    FileUtils.chmod 0755, File.join(hooks, "hook1")

    open(File.join(hooks, "hook2"), "w") do |stream|
      stream.write <<EOF
#!/bin/sh

echo "$1, $2, $3" > /tmp/hook2.txt
EOF
    end

    FileUtils.chmod 0755, File.join(hooks, "hook2")

    begin
      yield

      pattern = /\A[0-9]+\.[0-9]+\.[0-9]\.[0-9]+, [0-9]+\.[0-9]+\.[0-9]\.[0-9]+, [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\Z/

      assert File.exists?("/tmp/hook1.txt")
      assert File.read("/tmp/hook1.txt") =~ pattern

      assert File.exists?("/tmp/hook2.txt")
      assert File.read("/tmp/hook2.txt") =~ pattern
    ensure
      FileUtils.rm_f File.join(hooks, "hook1")
      FileUtils.rm_f File.join(hooks, "hook2")

      FileUtils.rm_f "/tmp/hook1.txt"
      FileUtils.rm_f "/tmp/hook2.txt"
    end
  end

  def set_current_target(options)
    response = { :failover => { :active_server_ip => options[:ip] } }

    url = "#{options[:failover_ip].base_url}/failover/#{options[:failover_ip].failover_ip}"

    RestClient.expects(:get).at_least_once.with(url).returns(JSON.dump(response))
  end

  def assert_switch(options)
    url = "#{options[:failover_ip].base_url}/failover/#{options[:failover_ip].failover_ip}"

    RestClient.expects(:post).with(url, :active_server_ip => options[:to]).returns(200)

    yield
  end

  def refute(boolean)
    assert !boolean
  end
end

