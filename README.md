
# Recent changes!

The config has recently changes, as we migrated to httparty.
You now no longer set the API authentication within the base url.
Checkout the example above or config/heartbeat.yml

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

We've used heartbeat for quite some time in production now.

## Limitations

Heartbeat uses plain-old ping's. Thus, it can only detect full crashes of
your servers, where the server does no longer reply to a ping. However,
other monitoring options will probably be added in the future.

## Heartbeat's Behaviour

A few words about Heartbeat's behaviour. By default, every 30 seconds,
Heartbeat sends a ping to the Hetzner Failover IP. If Heartbeat does not
receive an answer, it assumes that the server behind the Failover IP is down.

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

```
$ apt-get install ruby rubygems
$ gem install bundler
```

Afterwards, you need to install Heartbeat's dependencies:

```
$ cd /path/to/heartbeat
$ bundle
```

If the bundle command can't be found, search your system for the bundle
executeable. This can e.g. happen for Debian Squeeze.

```
$ cd /path/to/heartbeat
$ /var/lib/gems/1.8/bin/bundle
```

To configure the Hetzner API access, the Failover IP as well as your server's
ip addresses, edit config/heartbeat.yml

```yaml
base_url: https://robot-ws.your-server.de

basic_auth:
  username: username
  password: password

failover_ip: 0.0.0.0

ping_ip: 0.0.0.0

ips:
  - ping: 10.0.0.1
    target: 10.0.0.2
  - ping: 10.0.1.1
    target: 10.0.1.2

interval: 30

timeout: 10

tries: 3
```

The `ping_ip` option is explained below in detail. The `interval` option
specifies how long to sleep between the ping attempts. The `timeout` specifies
the timeout to use for a ping and `tries` specifies how many pings to send to
the ip which is about to be tested.

Heartbeat provides an init script for Debian you can use to start Heartbeat at
boot time. However, you have to symlink to it yourself. It is *important* to
actually symlink to it. Otherwise, the init script can't find the location of
your Heartbeat installation.

```
$ cd /etc/init.d
$ ln -s /path/to/heartbeat/bin/debian heartbeat
$ update-rc.d heartbeat defaults
```

Finally, you can start the daemon:

```
$ /etc/init.d/hearbeat start
```

## What's `ping_ip`, `ping` and `target`?

Unless you run heartbeat on a hetzner machine that actually listens to your
Failover IP, you can simply use your Failover IP for the `ping_ip` option.

Otherwise, assume, you have e.g., two load balancers and you want heartbeat to
run on each load balancer to monitor the state of the other one. In case one
load balancer crashes, you want heartbeat running on the other load balancer to
detect this and to switch the Failover IP to itself. However, as your load
balancers actually both listen to the Failover IP themeselves, heartbeat will
do nothing but monitor the indivual server it's running on (not the other one).
Thus, the `ping_ip` option enables you to specfiy the exact ip you want to
monitor on a specific host, i.e. the individual IP of the other load balancer.

Example:

You have two load balancers `1.1.1.1` and `2.2.2.2` and a Failover IP
`0.0.0.0` both load balancers are addtionally listening to.

On `1.1.1.1`, the respective parts of your heartbeat config would look like:

```yaml
failover_ip: 0.0.0.0

ping_ip: 2.2.2.2

ips:
  - ping: 1.1.1.1
    target: 1.1.1.1
  - ping: 2.2.2.2
    target: 2.2.2.2
```

And on `2.2.2.2` your heartbeat config would partially look like:

```yaml
failover_ip: 0.0.0.0

ping_ip: 1.1.1.1

ips:
  - ping: 1.1.1.1
    target: 1.1.1.1
  - ping: 2.2.2.2
    target: 2.2.2.2
```

But what about `ping` and `target` within the `ips` block?

Assume you run virtual machines on your server, where each virtual machine
listens to an individual IP address. Your Failover IP, however, can only be
bound to your server's main IP address. Thus, the `ping` option tells heartbeat
about the virtual machine's IP addresses and heartbeat will use these addresses
to check the availability of your virtual machines. Instead, `target` tells
heartbeat which IP address to use in case heartbeat switches the Failover IP to
the associated server. If you don't use virtual machines or multiple IP
addresses on your servers, you can simply use your server's main IP addresses
for both, the `ping` as well as `target` option.

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

