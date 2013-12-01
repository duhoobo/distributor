#!/usr/bin/env bash
# alecdu@gmail.com. check this shit out, man. and i smoke a lot.

wd=$(dirname $0)
diagnosis="off"

function trim_line()
{
  echo "$@"
}

function purify_line()
{
  line=$@ # line is trimmed at the same time

  # empty line
  if [ -z "$line" ]; then
    echo "0"
  fi

  n=$(expr match "$line" "#")
  if [ "$n" -eq "0" ]; then
    # not begine with #, check trailing #

    n=$(expr index "$line" "#")
    if [ ! "$n" -eq "0" ]; then
    # got trailing #
      let "n=$n-1"
      line=${line:0:$n}
      echo $(trim_line $line)
    else
      echo $line
    fi
  else
    echo "0"
  fi
}

function read_config() 
{
  declare -a array
  n=0
  conf=$1
  OLD_IFS=$IFS
  IFS=";"

  exec 3<&0 # save stdin
  exec 0<$conf # redirect file to stdin

  while read line; do
    line=$(purify_line $line)
    if [ "$line" = "0" ]; then
      continue
    fi

    array[$n]=$line
    let n=$n+1
  done 
  exec 0<&3 # restore stdin

  #eval "$2"=${array} # how to do parameter reference passing
  echo "${array[*]}"
  IFS=$OLD_IFS
}

function log_message()
{
  if [ "z$@" = "z" ]; then
    return 0;
  fi
  echo "$@"
}

function exp_exec()
{
  msg=$($wd/exp/remote_exec.exp $1 $2 $3 $4 "$5")
  ret=$?

  if [ z$diagnosis == "zon" ]; then
    log_message "$msg"
  fi

  return $ret
}

function exp_xfer()
{
  msg=$($wd/exp/remote_xfer.exp $1 $2 $3 $4 "$5")
  ret=$?

  if [ z$diagnosis == "zon" ]; then
    log_message "$msg"
  fi

  return $ret
}

## main

if [ $# -lt 1 ]; then
  echo "$0 conf-dir"
  exit 1
fi

if [ ! -d $1 ]; then
  echo "$1 is not a directory"
  exit 1
fi
bundle_dir=$1

single_step_mode='none'
if [ $# -ge 2 ]; then
  echo "single step mode"

  case x$2 in
    xpre|xxfer|xpost)
      single_step_mode=$2
      ;;
    *)
      echo "invalid mode '$2'"
      exit 1
      ;;
  esac
fi

pre_conf=$bundle_dir"/pre.conf"
xfer_conf=$bundle_dir"/xfer.conf"
post_conf=$bundle_dir"/post.conf"
accept_host_ls=$bundle_dir"/accept.list"
ignore_host_ls=$bundle_dir"/ignore.list"

if [[ ( ! -f $pre_conf ) && ( ! -f $xfer_conf ) && ( ! -f $post_conf ) ]]; then
  echo "$bundle_dir is not config bundle directory"
  exit 1
fi

if [[ ! -r $accept_host_ls ]]; then
  echo "$accept_host_ls is needed"
  exit 1
fi

# pre-exec commands
if [[ -r $pre_conf ]]; then
  pre_params=$(read_config $pre_conf)
fi

# file transfer rules
if [[ -r $xfer_conf ]]; then
  xfer_params=$(read_config $xfer_conf 0)
fi

# post-exec command
if [[ -r $post_conf ]]; then
  post_params=$(read_config $post_conf 0)
fi

declare -a ignore_host_array
if [[ -r $ignore_host_ls ]]; then
  OLD_IFS=$IFS
  IFS="|"
  ignore_host_array=( $(read_config $ignore_host_ls 1) )
  IFS=$OLD_IFS
fi

shadow_pass='xxxxxx'

while read host port user pass rest; do
  log_message "[host: $host, port: $port, user: $user, pass: $shadow_pass] stab"

  if [[ -z "$host" || -z "$port" || -z "$user" || -z "$pass" ]]; then
    log_message "line got fields missing"
    log_message "[host: $host, port: $port, user: $user, pass: $shadow_pass] skipped"
    continue 
  fi
  if [ ! -z "$rest" ]; then
    log_message "line got fields more than needed"
    log_message "[host: $host, port: $port, user: $user, pass: $shadow_pass] skipped"
    continue
  fi

  i=0
  skip=0
  n=${#ignore_host_array[@]}

  while [ $i -lt $n ]; do
    if [ "$host" = "${ignore_host_array[$i]}" ]; then
      skip=1
    fi

    let i=$i+1
  done

  if [ $skip -eq 1 ]; then
    log_message "$host ignored"
    log_message "[host: $host, port: $port, user: $user, pass: $shadow_pass] skipped"
    continue
  fi

  if [ $single_step_mode = "pre" -o $single_step_mode = "none" ]; then
    if [ ! -z "$pre_params" ]; then
      log_message "exp_exec $host $port $user $shadow_pass \"$pre_params\""
      exp_exec $host $port $user $pass "$pre_params"
    fi

    if [ "$?" != "0" ]; then
      log_message "pre-exec failed, skip xfer & post"
      log_message "[host: $host, port: $port, user: $user, pass: $shadow_pass] skipped"
      continue
    fi
  fi


  if [ $single_step_mode = "xfer" -o $single_step_mode = "none" ]; then
    if [ ! -z "$xfer_params"  ]; then
      log_message "exp_xfer $host $port $user $shadow_pass \"$xfer_params\""
      exp_xfer $host $port $user $pass "$xfer_params"
    fi

    if [ "$?" != "0" ]; then
      log_message "xfer failed, skip post"
      log_message "[host: $host, port: $port, user: $user, pass: $shadow_pass] skipped"
      continue
    fi
  fi

  if [ $single_step_mode = "post" -o $single_step_mode = "none" ]; then
    if [ ! -z "$post_params" ]; then
      log_message "exp_exec $host $port $user $shadow_pass \"$post_params\""
      exp_exec $host $port $user $pass "$post_params"
    fi

    if [ "$?" != "0" ]; then
      log_message "post actions failed"
      log_message "[host: $host, port: $port, user: $user, pass: $shadow_pass] skipped"
      continue
    fi
  fi

  log_message "[host: $host, port: $port, user: $user, pass: $shadow_pass] done"
done < $accept_host_ls

exit 0
