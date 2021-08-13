#!/bin/bash

set -m

echo "HELLO" > "/usr/local/apache2/htdocs/index.html"

httpd -D FOREGROUND & pid=$!

for signal in TERM USR1 HUP INT; do
  trap "echo SIGNAL: $signal; kill -s $signal $pid" $signal
done

# USR2 converted to WINCH
trap "kill -s WINCH $pid" USR2

status=999
while true; do
  if (( $status <= 128 )); then
    # Status codes larger than 128 indicates a trapped signal terminated the wait command (128 + SIGNAL).
    # In any other case we can stop the loop. 
    break
  fi
  wait -f
  status=$?
  echo exit status: $status
done
