#!/bin/bash

command_file="$1"

command="$(cat "$command_file")"

trap 'command="$(cat "$command_file")"' HUP

while true; do
  clear
  echo "Custom watch"
  echo
  $command
  sleep 2
done