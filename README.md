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

## Supervisor

Go to `docker/supervisor` from the project root and build the image:

```bash
docker build -t localhost/supervisor .
```

Start the Docker container

```bash
docker run -d --name supervisor -p 1080:80 -p 8080:8080 localhost/supervisor
```

Now the HTTPD server is available on port 1080 and the Python HTTP server on port 8080.

If everything is right, supervisor should shutdown in about 3 seconds, but definitely less then 10. This means the stopsignals work properly.

## Systemd

Systemd is not what you want to use for production in a Docker container, but if you need, you can do it mainly for testing. 

**Note:** All of the examples run the containers in the foreground. Add `-d` to `docker run` if you don wan't to open a second terminal to be able to stop the containers before the next test.

These examples were tested on an Ubuntu 18.04 host.

From the project root go to `docker/systemd` and continue reading.

### First container

`Dockerfile.v1` contains the most important commands to define a Systemd image based on Ubuntu 20.04.

First of all build the image:

```bash
docker build -t localhost/ubuntu-2004-systemd:v1 -f Dockerfile.v1 .
```

Then Run the first container:

```bash
docker run -it --rm --name systemd localhost/ubuntu-2004-systemd:v1
```

This will probably result the following error message:

```
Failed to mount tmpfs at /run: Operation not permitted
Failed to mount tmpfs at /run/lock: Operation not permitted
[!!!!!!] Failed to mount API filesystems.
Freezing execution.
```

Run `docker kill systemd` in a second terminal to stop and remove the container. 
You need to mount `/run` and `/run/lock` as tmpfs with the following command:

```bash
docker run -it --rm --name systemd \
  --tmpfs /run \
  --tmpfs /run/lock \
  localhost/ubuntu-2004-systemd:v1
```

The next error message is:

```
Failed to create /docker/074a179e247370c547fc291bdeac25161fb01f4ee90bbbda9a6ce5110d6b698f/init.scope control group: Read-only file system
Failed to allocate manager object: Read-only file system
[!!!!!!] Failed to allocate manager object.
Freezing execution.
```

This can be solved by bind mounting `/sys/fs/cgroup` from the host after you deleted the previous container:

```bash
docker run -it --rm --name systemd \
  --tmpfs /run \
  --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup \
  localhost/ubuntu-2004-systemd:v1
```

The previous error messages were red in a color terminal but the next is "just" yellow:

```
Failed to set up the root directory for shared mount propagation: Operation not permitted
```

You could think you could use the `--privileged` parameter to have more permission but
it is not so easy despite the fact that many tutorial say it is. It could restart your GUI
in case you are working on a desktop machine. So run it only if it is not a problem for you:

```bash
docker run -it --rm --name systemd \
  --tmpfs /run \
  --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup \
  --privileged \
  localhost/ubuntu-2004-systemd:v1
```

Actually, you don't need privileged mode for this container, only the variable "container" with the value "docker".

```bash
docker run -it --rm --name systemd \
  --tmpfs /run \
  --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup \
  -e container=docker \
  localhost/ubuntu-2004-systemd:v1
```

Now you should have an output with an end like this:

```
Ubuntu 20.04.3 LTS e9e0a9854e42 console

e9e0a9854e42 login:
```

Unfortunately there is one error message left which does not seem to be a problem for testing, so you can ignore it for now:

```
Couldn't move remaining userspace processes, ignoring: Input/output error
```

In case you are wondering if the variable "container" is enough to solve our previous error messages, it is not.
However, since systemd knows it is a Docker container, it stops after displaying the error message so 
you can have your host shell prompt back. Try it with the next command:

```bash
docker run -it --rm --name systemd -e container=docker localhost/ubuntu-2004-systemd:v1
```

### Disable Systemd's login prompt

Use `Dockerfile.v2` and run

```bash
docker build -t localhost/ubuntu-2004-systemd:v2 -f Dockerfile.v2 .
docker run -it --rm --name systemd  \
  --tmpfs /run \
  --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup \
  -e container=docker \
  localhost/ubuntu-2004-systemd:v2
```

### Install Apache HTTPD server

Run 

```bash
docker build -t localhost/ubuntu-2004-systemd:v3 -f Dockerfile.v3 .
docker run -it --rm --name systemd \
  --tmpfs /run \
  --tmpfs /run/lock\
  -v /sys/fs/cgroup:/sys/fs/cgroup \
  -e container=docker \
  -p 8080:80 \
  localhost/ubuntu-2004-systemd:v3
```

Now you can test the running webserver with curl from the host on which the Docker daemon is running:

```bash
curl localhost:8080
```

### Test stop timeout

Run the following command to see if the systemd container can be stopped before the 10 seconds timeout:

```
time docker stop systemd
```