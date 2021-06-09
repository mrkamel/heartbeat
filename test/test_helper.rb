
require "rubygems"
require "bundler/setup"
require "test/unit"
require "mocha/setup"
require "fileutils"
require "logger"

$logger = Logger.new(File.expand_path("../../log/test.log", __FILE__))

class Test::Unit::TestCase
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
    hooks = File.expand_path("../../hooks", __FILE__)
    create_hooks

    begin
      yield

      pattern = /\A[0-9]+\.[0-9]+\.[0-9]\.[0-9]+, [0-9]+\.[0-9]+\.[0-9]\.[0-9]+, [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\Z/

      assert File.exists?("/tmp/hook1.txt")
      assert File.read("/tmp/hook1.txt") =~ pattern

      assert File.exists?("/tmp/hook2.txt")
      assert File.read("/tmp/hook2.txt") =~ pattern
    ensure
      remove_hooks(kind, hooks)

      FileUtils.rm_f "/tmp/hook1.txt"
      FileUtils.rm_f "/tmp/hook2.txt"
    end
  end

  def assert_hooks_do_not_run(kind)
    hooks = File.expand_path("../../hooks", __FILE__)
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

    parsed_response = { :failover => { :active_server_ip => options[:ip] } }

    response = Hashr.new(:parsed_response => parsed_response, :success => true)

    HTTParty.expects(:get).at_least_once.with(url, :basic_auth => basic_auth).returns(response)
  end

  def assert_switch(options)
    url = "#{options[:failover_ip].base_url}/failover/#{options[:failover_ip].failover_ip}"

    basic_auth = { :username => "username", :password => "password" }

    body = { :active_server_ip => options[:to] }

    response = Hashr.new(:success => true)

    HTTParty.expects(:post).with(url, :body => body, :basic_auth => basic_auth).returns(response)

    yield
  end

  def refute(boolean)
    assert !boolean
  end
end

