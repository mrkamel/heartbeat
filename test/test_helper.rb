
require "bundler/setup"
require "minitest/autorun"
require "mocha/minitest"
require "ostruct"
require "fileutils"
require "logger"

$logger = Logger.new(File.expand_path("../log/test.log", __dir__))

class BaseTest < Minitest::Test
  def create_hooks(kind, hooks)

    open(File.join(hooks, kind, "hook1"), "w") do |stream|
      stream.write <<EOF
#!/bin/sh

echo "$1, $2, $3" > /tmp/hook1.txt
EOF
    end

    FileUtils.chmod 0755, File.join(hooks, kind, "hook1")

    open(File.join(hooks, kind, "hook2"), "w") do |stream|
      stream.write <<EOF
#!/bin/sh

echo "$1, $2, $3" > /tmp/hook2.txt
EOF
    end

    FileUtils.chmod 0755, File.join(hooks, kind, "hook2")
  end

  def remove_hooks(kind, hooks)
      FileUtils.rm_f File.join(hooks, kind, "hook1")
      FileUtils.rm_f File.join(hooks, kind, "hook2")
  end

  def assert_hooks_run(kind)
    hooks = File.expand_path("../hooks", __dir__)
    create_hooks(kind, hooks)

    begin
      yield

      pattern = /\A[0-9]+\.[0-9]+\.[0-9]\.[0-9]+, [0-9]+\.[0-9]+\.[0-9]\.[0-9]+, [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\Z/

      assert File.exist?("/tmp/hook1.txt")
      assert File.read("/tmp/hook1.txt") =~ pattern

      assert File.exist?("/tmp/hook2.txt")
      assert File.read("/tmp/hook2.txt") =~ pattern
    ensure
      remove_hooks(kind, hooks)

      FileUtils.rm_f "/tmp/hook1.txt"
      FileUtils.rm_f "/tmp/hook2.txt"
    end
  end

  def assert_hooks_do_not_run(kind)
    hooks = File.expand_path("../hooks", __dir__)
    create_hooks(kind, hooks)

    begin
      yield

      assert !File.exist?("/tmp/hook1.txt")
      assert !File.exist?("/tmp/hook2.txt")
    ensure
      remove_hooks(kind, hooks)
    end
  end

  def set_current_target(options)
    url = "#{options[:failover_ip].base_url}/failover/#{options[:failover_ip].failover_ip}"

    basic_auth = { :username => "username", :password => "password" }

    parsed_response = { "failover" => { "active_server_ip" => options[:ip] } }

    response = OpenStruct.new(:parsed_response => parsed_response, :success? => true)

    HTTParty.expects(:get).at_least_once.with(url, :basic_auth => basic_auth).returns(response)
  end

  def assert_switch(options)
    url = "#{options[:failover_ip].base_url}/failover/#{options[:failover_ip].failover_ip}"

    basic_auth = { :username => "username", :password => "password" }

    body = { :active_server_ip => options[:to] }

    response = OpenStruct.new(:success? => true)

    HTTParty.expects(:post).with(url, :body => body, :basic_auth => basic_auth).returns(response)

    yield
  end

  def refute(boolean)
    assert !boolean
  end
end

