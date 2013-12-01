#!/usr/bin/env bash

if [ "x$1" == "x" ]; then
  top
else
  pids=`pgrep -d ' -p ' "$1"`
  if [ "x$pids" == "x" ]; then
    echo "no found process with \"$1\" in name"
  else
    top "-p "$pids;
  fi
fi
