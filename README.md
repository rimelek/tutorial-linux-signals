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

