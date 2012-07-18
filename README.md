
# Heartbeat

Heartbeat is a rather simple daemon which pings a Hetzner Failover IP. If the
Failover IP is down, Heartbeat will try to set a new active server ip for the
Failover IP through the API provided by Hetzner. For further details of Hetzner
Failover IPs, please check

http://wiki.hetzner.de/index.php/Robot_Webservice#POST_.2Ffailover.2F.3Cfailover-ip.3E

## Current State

This is an early alpha. Simply don't use it yet!

## Heartbeat's Behaviour

A few words about Heartbeat's behaviour. Every 30 seconds, Heartbeat sends a
ping to the Hetzner Failover IP. If Heartbeat does not receive an answer, it
assumes that the server behind the Failover IP is down.

When the Failover IP is down, Heartbeat will ask the Hetzner API for the
current active server ip and looks up the ip in the list you've configured.
Heartbeat then pings the next ip from the list until it can reach an ip or has
to give up, because there are no remaining ips Heartbeat could try to reach.
The order of the ip addresses within the config file determines which ip is
tried our next. When the last ip of the list is reached, the first one is
tried.

After Heartbeat switched to another active server ip by using Hetzner's API,
Heartbeat will sleep for 300 seconds. This delay has been chosen to avoid
switching to different ips too often. Heartbeat will as well sleep for 300
seconds if the Hetzner API call fails, because Heartbeat assumes that the
server Heatbeat is running on is itself currently down or separated from the
network in some way.

## Setup

Heartbeat is written in ruby. Thus, you first have to install ruby, rubygems
and bundler.

<pre>
$ apt-get install ruby rubygems
$ gem install bundler
</pre>

Afterwards, you need to install Heartbeat's dependencies:

<pre>
$ cd /path/to/heartbeat
$ bundle
</pre>

If the bundle command can't be found, search your system for the bundle
executeable. This can e.g. happen for Debian Squeeze.

<pre>
$ cd /path/to/heartbeat
$ /var/lib/gems/1.8/bin/bundle
</pre>

To configure the Hetzner API access, the failover ip as well as your server's
ip addresses, edit config/config.yml

<pre>
base_url: https://username:password@robot-ws.your-server.de

failover_ip: 0.0.0.0

ips:
  - 1.1.1.1
  - 2.2.2.2
</pre>

In the future, Heartbeat will provide an init script for Debian you can use to
start Heartbeat at boot time. However, you have to symlink to it yourself.  It
is *important* to actually symlink to it. Otherwise, the init script can't find
the location of your Heartbeat installation.

<pre>
$ cd /etc/init.d
$ ln -s /path/to/heartbeat/bin/debian heartbeat
$ update-rc.d heartbeat defaults
</pre>

Finally, you can start the daemon:

<pre>
$ /etc/init.d/hearbeat start
</pre>

