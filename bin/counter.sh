#!/bin/bash

set -eu -o pipefail

start=1
interval=1
step=1
end=1000

dir="$(cd "$(dirname "$0")" && pwd)"

function loadConfig() {
  source <(awk '/^(start|interval|step|end)=[0-9]+\s*$/' $dir/../config/counter.conf)
}

trap loadConfig HUP
trap "kill -s TERM $PPID 2> /dev/null || true; exit 0" TERM

loadConfig

for ((i=start; i <= end; i += step)); do
  echo $i
  sleep $interval
done
