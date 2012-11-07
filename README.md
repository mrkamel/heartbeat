
# Heartbeat

Heartbeat is a rather simple daemon which pings a Hetzner Failover IP. If the
Failover IP is down, Heartbeat will automatically try to set a new active server
ip for the Failover IP through the API provided by Hetzner. For further details
of Hetzner Failover IPs, please check

http://wiki.hetzner.de/index.php/Robot_Webservice#POST_.2Ffailover.2F.3Cfailover-ip.3E

## Motivation

There are plenty of HA tools out there. However, i thought (and think!) they
are too heavy-weight for this rather simple task. Thus, i wrote Heartbeat to
automatically switch between load balancers and mySQL servers i run behind
Hetzner Failover IPs in case one becomes down/unavailable.

## Current State

This is an early alpha. Simply don't use it yet!

## Heartbeat's Behaviour

A few words about Heartbeat's behaviour. Every 30 seconds, Heartbeat sends a
ping to the Hetzner Failover IP. If Heartbeat does not receive an answer, it
assumes that the server behind the Failover IP is down.

Since, Heartbeat uses plain-old ping's, be sure you can ping your servers
before using Heartbeat!

When the Failover IP is down, Heartbeat will ask the Hetzner API for the
current active server ip and looks up the ip in the list you've configured.
Heartbeat then pings the next ip from the list until it can reach an ip or has
to give up, because there are no remaining ips Heartbeat could try to reach.
The order of the ip addresses within the config file determines which ip is
tried out next. When the last ip of the list is reached, the first one is
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

To configure the Hetzner API access, the Failover IP as well as your server's
ip addresses, edit config/heartbeat.yml

<pre>
base_url: https://username:password@robot-ws.your-server.de

failover_ip: 0.0.0.0

ping_ip: 0.0.0.0

ips:
  - 1.1.1.1
  - 2.2.2.2
</pre>

What is meant by `ping_ip` is explained below in detail.

Heartbeat provides an init script for Debian you can use to start Heartbeat at
boot time. However, you have to symlink to it yourself. It is *important* to
actually symlink to it. Otherwise, the init script can't find the location of
your Heartbeat installation.

<pre>
$ cd /etc/init.d
$ ln -s /path/to/heartbeat/bin/debian heartbeat
$ update-rc.d heartbeat defaults
</pre>

Finally, you can start the daemon:

<pre>
$ /etc/init.d/hearbeat start
</pre>

## What does this `ping_ip` thing do?

Unless you run heartbeat on a hetzner machine that actually listens to your
Failover IP, you can just use your Failover IP as `ping_ip`.

Otherwise, assume, you have e.g., two load balancers running and you want
heartbeat to sit on each load balancer to monitor the state of the other.
In case one load balancer is down, heartbeat running on the other load
balancer will detect this. However, as your load balancers both listen to
the Failover IP they actually want to monitor, they do nothing but monitor
themselves only. Thus, the `ping_ip` enables you to ping the individual
IP of the other load balancer - just what you want.

Example: You have two load balancers `1.1.1.1` and `2.2.2.2` and a Failover IP
`0.0.0.0` both load balancers are addtionally listening to.

On `1.1.1.1` your heartbeat config would look like:

<pre>
base_url: ...

failover_ip: 0.0.0.0

ping_ip: 2.2.2.2

ips:
  - 1.1.1.1
  - 2.2.2.2
</pre>

And an `2.2.2.2` your heartbeat config would look like:

<pre>
base_url: ...

failover_ip: 0.0.0.0

ping_ip: 1.1.1.1

ips:
  - 1.1.1.1
  - 2.2.2.2
</pre>

## Hooks

You can add your own hooks which will be run after the Failover IP is switched
from one active server ip to another in case the first one is down. To add hooks,
add your shell, ruby or other scripts to the 'hooks' folder within heartbeat's
root folder. Please note that your scripts must of course be executable by the
heartbeat daemon. Heartbeat will execute your scripts in alphabetical order and
will pass the failover ip as first argument, the old active server ip as second
argument and the new active server ip as the third argument to your scripts.
Please take a look at examples/hooks/email to learn more about how to write your
own hooks.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

