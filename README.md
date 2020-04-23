This script is pretty much the starting point for most of my local lab stuff on my mac.

To work with it, put it somewhere in $PATH. (I'm using ~/Code/bin)

I've set it up to pick up a resource profile  through \`basename\`.
In order to use it, I ln -s mp-node.sh mp-node-<template>.sh in the same bin directory.

e.g.

`ls -l ~/Code/bin/mp*
lrwxr-xr-x  1 antoon.huiskens  staff    10 Nov 25 13:32 /Users/antoon.huiskens/Code/bin/mp-node-big.sh -> mp-node.sh
lrwxr-xr-x  1 antoon.huiskens  staff    10 Jan  8 10:53 /Users/antoon.huiskens/Code/bin/mp-node-controller.sh -> mp-node.sh
lrwxr-xr-x  1 antoon.huiskens  staff    10 Nov 25 13:32 /Users/antoon.huiskens/Code/bin/mp-node-small.sh -> mp-node.sh
lrwxr-xr-x  1 antoon.huiskens  staff    10 Apr 16 13:27 /Users/antoon.huiskens/Code/bin/mp-node-small16.sh -> mp-node.sh
-rwxr--r--  1 antoon.huiskens  staff  3489 Apr 22 22:38 /Users/antoon.huiskens/Code/bin/mp-node.sh`
