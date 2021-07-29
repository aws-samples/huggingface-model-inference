#!/bin/bash
set -e

wait_for_nrtd() {
  nrtd_sock="/run/neuron.sock"
  SOCKET_TIMEOUT=300
  is_wait=true
  wait_time=0
  i=1
  sp="/-\|"
  echo -n "Waiting for neuron-rtd  "
  pid=$1
  while $is_wait; do
    if [ -S "$nrtd_sock" ]; then
      echo "$nrtd_sock Exist..."
      is_wait=false
    else
      sleep 1
      wait_time=$((wait_time + 1))
      if [ "$wait_time" -gt "$SOCKET_TIMEOUT" ]; then
        echo "neuron-rtd failed to start, exiting"
	      cat /tmp/nrtd.log
        exit 1
      fi
      printf "\b${sp:i++%${#sp}:1}"
    fi
  done
  cat /tmp/nrtd.log
}

# Start neuron-rtd
/opt/aws/neuron/bin/neuron-rtd -g unix:/run/neuron.sock --log-console  >>  /tmp/nrtd.log 2>&1 &
nrtd_pid=$!
echo "NRTD PID: "$nrtd_pid""
#wait for nrtd to be up (5 minutes timeout)
wait_for_nrtd $nrtd_pid
export NEURON_RTD_ADDRESS=unix:/run/neuron.sock
nrtd_present=1

if [[ "$1" = "serve" ]]; then
    shift 1
    
    torchserve --start --ncs --model-store model_store --ts-config /opt/config.properties --models my_tc_inf=bert-max_length128-batch_size6.mar 2>&1 | tee torchserve.log &
    
    for i in 3 2 1 0
    do
        echo -ne "\rWaiting server start in $i ...\033[0K" && sleep 1
    done

    echo ""
    echo "Checking Server status:"
    curl http://127.0.0.1:8443/ping
      
else
    eval "$@"
fi

# prevent docker exit
tail -f /dev/null
