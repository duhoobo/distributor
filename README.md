distributor
===========

What is it
----------

It's a bunch of scripts, written with bash and expect/Tcl. 

When you find yourself in a situation, like, you need, 

* to change multiple server's password;
* to transfer files to multiple servers;
* to perform some actions (mkdir, rm, etc) before or after the transfer;

then, you may need this package.


How to Use
----------

* You need a directory, say, `conf` for example, containing several config 
  files.

        mkdir conf

    * `pre.conf` lists commands to execute before *xfer*. This file is optional
    with the presence of `xfer.conf` or `post.conf`. See EXAMPLES below.

    * `xfer.conf` lists file transfer rules. This file is optional with the
    presence of `pre.conf` or `post.conf`. See EXAMPLES below.

    * `post.conf` lists commands to execute after *xfer*. This file is optional 
    with the presence of `pre.conf` or `xfer.conf` See EXAMPLES below.

    * `accept.list` lists remote hosts to perform operations on. This file is 
    mandatory.  See EXAMPLES below.

    * `ignore.list` lists remote hosts to ignore for now. This file is 
    optional.


EXAMPLES
--------

        $ cat pre.conf
        mkdir -p /tmp/store

        $ cat xfer.conf
        # local         remote      direction
        /tmp            /tmp/store  push
        /opt/           /opt/       pull

        $ cat post.conf
        # execute some commands on /tmp/store
        rm -rf /tmp/store


        $ cat accept.list
        # host          port    user    pass
        192.168.101.9   22      root    123456

        $ cat ignore.list
        # host
        192.168.101.8


How to Install
--------------

Just put it somewhere you can get your hands on.


**except rocks**


