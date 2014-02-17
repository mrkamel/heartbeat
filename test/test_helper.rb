
$:.unshift File.expand_path("../../lib", __FILE__)
$:.unshift File.expand_path("../../test", __FILE__)

require "rubygems"
require "bundler/setup"
require "test/unit"
require "fileutils"
require "logger"
require "hashr"
require "mocha/setup"
require "heartbeat"
require "test/unit"

Heartbeat.logger = Logger.new(File.expand_path("../../log/test.log", __FILE__))

class LeaveLoopException < Exception; end

class Test::Unit::TestCase
  def assert_hooks_run(dir, kind)
    hooks = File.expand_path("../../#{dir}", __FILE__)

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

    begin
      yield

      pattern = /\A[0-9]+\.[0-9]+\.[0-9]\.[0-9]+, [0-9]+\.[0-9]+\.[0-9]\.[0-9]+, [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\Z/

      assert File.exists?("/tmp/hook1.txt")
      assert File.read("/tmp/hook1.txt") =~ pattern

      assert File.exists?("/tmp/hook2.txt")
      assert File.read("/tmp/hook2.txt") =~ pattern
    ensure
      FileUtils.rm_f File.join(hooks, kind, "hook1")
      FileUtils.rm_f File.join(hooks, kind, "hook2")

      FileUtils.rm_f "/tmp/hook1.txt"
      FileUtils.rm_f "/tmp/hook2.txt"
    end
  end

  def refute(boolean)
    assert !boolean
  end
end

