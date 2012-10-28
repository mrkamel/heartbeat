
require "test/unit"
require "fileutils"

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
end

