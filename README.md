Documentation
=============

Introduction
------------
This script is pretty much the starting point for most of my local lab stuff on my mac.
The aim is to quickly, consistently get me a vm on my local machine, ready to accept ssh and ansible, no passwords needed.

Installation
------------
To work with it, put it somewhere in $PATH. (I'm using ~/Code/bin)

Configuration
-------------

I've set the script up to pick up a resource profile  through \`basename\`.
In order to use it:

```
ln -s mp-node.sh mp-node-<template>.sh
```
in the same bin directory.

```
$ ls -l ~/Code/bin/mp*
lrwxr-xr-x  1 antoon.huiskens  staff    10 Nov 25 13:32 /Users/antoon.huiskens/Code/bin/mp-node-big.sh -> mp-node.sh
lrwxr-xr-x  1 antoon.huiskens  staff    10 Jan  8 10:53 /Users/antoon.huiskens/Code/bin/mp-node-controller.sh -> mp-node.sh
lrwxr-xr-x  1 antoon.huiskens  staff    10 Nov 25 13:32 /Users/antoon.huiskens/Code/bin/mp-node-small.sh -> mp-node.sh
lrwxr-xr-x  1 antoon.huiskens  staff    10 Apr 16 13:27 /Users/antoon.huiskens/Code/bin/mp-node-small16.sh -> mp-node.sh
-rwxr--r--  1 antoon.huiskens  staff  3489 Apr 22 22:38 /Users/antoon.huiskens/Code/bin/mp-node.sh
```

What it does
------------
In general the script...
* launches an ubuntu vm with 18.04LTS through multipass with a cloud-init template.
* ssh-keys get created per vm and stored in ~/.ssh/multipass/
* ssh-keyscan the new vm to prevent the initial ssh interaction
* ssh config snippet is put into .ssh/multipass/ setting up the user ssh-key and password.
* ~/Code/hosts gets the name/ip details and gets read by dnsmasq.
* ~/Code/ansible_hosts gets a similar update adding the user

End result
----------
a multipass vm with
* a user called nginx
* setup for passwordless ssh with passwordless sudo
* published to dns and available through local dns resolution
i.e. ready for ansible

my main usage is something like this:
```
$ mp-node-small.sh launch revproxy && ansible-playbook deploy.yaml
```


Good to know
------------
You can't pick a port on /etc/resolv.conf in ubuntu 18.04LTS. the base64 line in the cloud-init template essentially drops in an iptables rule picking up any traffic on 53 and 5353 and passes it to 192.168.64.1:5353 where I have dnsmasq listening. (Thanks Mark for building that).
Likewise, don't put dnsmasq on 53 or on 0.0.0.0. It's a world of pain.

On the MacOS side, I've setup /etc/resolver/<mydomain>:
```
$cat /etc/resolver/<mydomain>.<fake_tld>
nameserver 192.168.64.1
port 5353
```

and my dnsmasq conf:
```
cat /usr/local/etc/dnsmasq.conf
listen-address=192.168.64.1
port=5353
expand-hosts
addn-hosts=/Users/antoon.huiskens/Code/hosts
domain=antoonh.nginx
local=/antoonh.nginx/
```

I haven't looked into dns config too deeply, so need to check if this actually works. This setup is only a recent addition, so I still have to kick the habit of adding entries to /etc/hosts.

The script has a couple of main usage patterns:
```
$ mp-node-small.sh launch myvm
$ mp-node-small.sh destroy myvm
$ mp-node-small.sh rebuild myvm
```
Hoping that is self explanatory, with a caveat that the template is only looked at during "launch".

So this will "just" work and destroy `myvm2`
```
$ mp-node-small.sh launch myvm2
$ mp-node-large.sh destroy myvm2
```
Likewise, the following will result in a `myvm3` based on the large profile.
```
$ mp-node-small.sh launch myvm3
$ mp-node-large.sh rebuild myvm3
```

To clean up after yourself efficiently:
```
$ mp-node-small.sh nuclear
```

Caveats:
I am vaguely aware that multipass supports virtual box as a backend. I haven't tested it. Can't be bothered to investigate.

I am mildly annoyed that it limits me to ubuntu only. At some point I may get angry enough to figure out how to build multipass images with packer and get CentOS, possibly others in.
