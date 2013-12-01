#!/usr/bin/env bash
# /proc/net/dev
# Format:
# Interface |   Receive                                                  |   Transmit
#           | bytes    packets errs drop fifo frame compressed multicast | bytes     packets errs drop fifo colls carrier compressed
#         lo: 4099762   36312    0    0    0     0          0         0     4099762   36312    0    0    0     0       0          0 


# functions
function signal_handler() 
{
  echo "-------------------------------------------------------------"
  exit 0
}

# main process
if [ $# -lt 2 ]; then
  echo $0" interf pulse [round]"
  exit 1
fi
interf=$1
pulse=$2
round=$3

# signal handling
trap signal_handler INT TERM 


line=`grep "$interf" /proc/net/dev | awk -F: '{print $2}' | awk '{print $1, $2, $9, $10}'` 
if [ "$line""x" = "x" ]; then
  echo $interf": No such device"
  exit 1
fi

read last_recv_bytes last_recv_pkgs last_send_bytes last_send_pkgs << HERE
	$(echo $line)
HERE

# you know why it doesn't work?
# a clue: sub process
#echo $line | read last_recv_bytes

# header
if [ ".$round" == "." ]; then
  echo "Timestamp   recv_bw     recv_pkgs     send_bw       send_pkgs"
  echo "-------------------------------------------------------------"
fi


# output result intervally
while [ 1 ]; do

  line=`grep "$interf" /proc/net/dev | awk -F: '{print $2}' | awk '{print $1, $2, $9, $10}'` 
  read now_recv_bytes now_recv_pkgs now_send_bytes now_send_pkgs < <(echo $line)

  let recv_bw=($now_recv_bytes-$last_recv_bytes)*8/$pulse
  let send_bw=($now_send_bytes-$last_send_bytes)*8/$pulse
  let recv_pkgs=($now_recv_pkgs-$last_recv_pkgs)/$pulse
  let send_pkgs=($now_send_pkgs-$last_send_pkgs)/$pulse

  echo `date +"%s: "` "$recv_bw bits/s, $recv_pkgs pkgs/s, $send_bw bits/s, $send_pkgs pkgs/s"

  read last_recv_bytes last_recv_pkgs last_send_bytes last_send_pkgs << HERE
	$(echo $now_recv_bytes $now_recv_pkgs $now_send_bytes $now_send_pkgs)
HERE

  if [ ".$round" != "." ]; then
    if [ $round -gt 0 ]; then
      let round--
      if [ "$round" = "0" ]; then
        break
      fi
    fi
  fi

  sleep $pulse
done

exit 0
