#!/usr/bin/env bash

function get_inet_addr()
{
    ifconfig | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'
}

addrs=`get_inet_addr`

if [ ! -d "./data" ]; then
  mkdir data
fi

for addr in $addrs; do
  ./netflow.sh eth0 1 10 2>&1 >./data/$addr.netflow
  break
done
