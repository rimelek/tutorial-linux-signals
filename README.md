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