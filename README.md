# Linux signals

The examples in this project show you how you can use Linux signals. 

To list the available signals, run one of the following commands:

```bash
kill -l
```

or

```bash
trap -l
```

## Reload configuration file using HUP signal

Run 

```bash
./bin/watch.sh config/watch.conf
```

Change the configuration file, open a new terminal and search for the process ID

```bash
ps aux | watch.sh
```

Send HUP signal to reload the configuration file

```bash
pid=12345
kill -s HUP $pid
```

## Catch all signals

Run

```bash
./bin/signal.sh
```

Try to resize your teminal. You will see WINCH signal caught by the trap.
Find out the process ID:

```bash
ps aux | grep signal.sh
```

Use `kill` command to send any signal and you will see the caught signal's name on the screen.

```bash
# replace $pid with the actual process id of your signal.sh process.
kill -s TERM $pid
```

Press `CTRL+C` and you will see INT before the script terminates.
Play with ther signals to see what happens.

## Send signals between parent and child processes

Run 

```bash
./bin/run.sh
```

You will see `counter.sh` counting while the `healthcheck.sh` repeatedly says "I am alive" and `run.sh` says "Run, Forrest, Run!".

Press `CTRL+C` and `run.sh` will forward the INT signal to `counter.sh` and `healthcheck.sh`.
Run `run.sh` again and open a new terminal to terminate `counter.sh`:

```bash
kill -s TERM $(cat tmp/counter.bg.pid)
```

`counter.sh` will forward the TERM signal to the parent `run.sh` which will forward the signal to `healthcheck.sh`.

## Stop timeout

```bash
docker run -d --rm --name test python:3.8 python3 -m http.server 8080
time docker stop test
# Took 10 seconds to stop
```

```bash
docker stop --help
# Usage:  docker stop [OPTIONS] CONTAINER [CONTAINER...]
#
# Stop one or more running containers
#
# Options:
#   -t, --time int   Seconds to wait for stop before killing it (default 10)
```

```bash
docker run -d --rm --name test --stop-timeout 5 python:3.8 python3 -m http.server 8080
time docker stop test
# Took 5 seconds to stop
```

```bash
docker run -d --rm --name test --stop-timeout 5 python:3.8 python3 -m http.server 8080
time docker stop --time 3 test
# Took 3 seconds to stop
```

## Stop signal

```bash
docker run --help | grep stop
#   --stop-signal string             Signal to stop a container (default "SIGTERM")
#   --stop-timeout int               Timeout (in seconds) to stop a container
```

Docker uses signals to stop a container.
While stopping the HTTP server took 10 seconds by default, it stops quickly without a container.

First terminal

```bash
python3 -m http.server 8080
```

Second terminal

```bash
pid=$(ps ax -o pid,command | grep "[p]ython3 -m http\.server 8080" | cut -d " " -f1)
kill -s TERM $pid
# It terminates the HTTP server immediately
```

## PID 1

```bash
docker run -d --rm --name test python:3.8 python3 -m http.server 8080
docker exec -it -e COLUMNS="$(tput cols)" test ps x -o pid,command
#  PID COMMAND
#    1 python3 -m http.server 8080
#    8 ps x -o pid,command
time docker stop test
```

"python3" has PID 1, so it will ignore any default signal action.
This is why the HTTP server does not terminate since it does not handle 
signals itself.

## Without PID namespace

```bash
docker run -d --rm --name test --pid host python:3.8 python3 -m http.server 8080
docker exec -it -e COLUMNS="$(tput cols)" test ps x -o pid,command
# The output contains each process from the host point of view
time docker stop test
# The HTTP server handles SIGTERM with the default action.
```

## Using tini

```bash
cd docker/tini
docker build -t localhost/http-server .
docker run -d --rm --name test localhost/http-server
docker exec -it -e COLUMNS="$(tput cols)" test ps x -o pid,command
#  PID COMMAND
#    1 tini -- python3 -m http.server 8080
#    7 python3 -m http.server 8080
#    8 ps x -o pid,command
time docker stop test
```

## Using the --init flag

```bash
docker run -d --rm --name test --init python:3.8 python3 -m http.server 8080
docker exec -it -e COLUMNS="$(tput cols)" test ps x -o pid,command
#  PID COMMAND
#    1 /sbin/docker-init -- python3 -m http.server 8080
#    8 python3 -m http.server 8080
#  212 ps x -o pid,command
time docker stop test
# SIGTERM is handled with the default action
```

## HTTPD handles signals

```bash
docker run -d --rm --name test httpd:2.4
docker exec -it -e COLUMNS="$(tput cols)" test bash -c 'apt-get update && apt-get install -y --no-install-recommends procps && ps x -o pid,command'
#  PID COMMAND
#    1 httpd -DFOREGROUND
#   93 ps x -o pid,command
time docker stop test
```

## Wrapper script for httpd without exec

This way the httpd server will not receive signals from the bash szkript
so stopping the container means killing it after the timeout.

```bash
cd docker/httpd
./test.sh wrong WINCH
docker exec -it -e COLUMNS="$(tput cols)" test ps x -o pid,command
#  PID COMMAND
#    1 /bin/bash /start.sh
#    8 httpd -D FOREGROUND
#   93 ps x -o pid,command
time docker stop test
```

## Wrapper script for httpd with exec

This is the preferred way. Starting httpd would be like this:

```bash
# ...
exec httpd -D FOREGROUND
```

Building the image

```bash
cd docker/httpd
./test.sh exec WINCH
docker exec -it -e COLUMNS="$(tput cols)" test ps x -o pid,command
#  PID COMMAND
#    1 httpd -D FOREGROUND
#   91 ps x -o pid,command
time docker stop test
```

## Wrapper script for httpd with trap

```bash
./test.sh trap USR2
docker exec -it -e COLUMNS="$(tput cols)" test ps x -o pid,command
#  PID COMMAND
#    1 httpd -D FOREGROUND
#   91 ps x -o pid,command
time docker stop test
```

In this solution we had to replace WINCH signal with USR2 since sending WINCH to a bash process in the background would not be handled until the httpd process terminates.
