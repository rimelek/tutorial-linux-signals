#!/bin/bash

for signal in $(trap -l | awk 'gsub(/\t/, "\n")' | awk 'gsub(/SIG/, "") {print $2}'); do
  command="echo $signal"
  # Let CTRL+C terminate the script sending SIGINT
  [[ "$signal" == "INT" ]] && command="echo; $command; exit 0"
  # Do not catch SIGCHLD. It will be sent every time the sleep command terminates in the loop. 
  [[ "$signal" == "CHLD" ]] && continue
  trap "$command" $signal
done

while true; do sleep 1; done
