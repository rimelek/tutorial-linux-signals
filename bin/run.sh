#!/bin/bash

set -eu -o pipefail

dir="$(cd "$(dirname "$0")" && pwd)"
app_root="$dir/.."
counter_pid=""
healthcheck_pid=""

function trap_handler() {
  local signal_name="$1"
  local pid_files="$(find $app_root/tmp -name '*.bg.pid' )"
  for pid_file in $pid_files; do
    kill -s "$signal_name" "$(cat $pid_file)" 2> /dev/null || true
  done
}

trap "trap_handler TERM; exit 0" TERM INT
trap "trap_handler HUP" HUP

$dir/counter.sh     & counter_pid=$!
$dir/healthcheck.sh & healthcheck_pid=$!

echo "$$"               > $app_root/tmp/run.pid
echo "$counter_pid"     > $app_root/tmp/counter.bg.pid
echo "$healthcheck_pid" > $app_root/tmp/healthcheck.bg.pid

while true; do
  echo "Run, Forrest, run!"
  sleep 2
done