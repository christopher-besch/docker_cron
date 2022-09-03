# docker_cron
Scheduling container tasks with docker-compose.

Docker_cron is a docker container used to control as many other containers as you like.
```yaml
version: "3.9"

services:
    example:
        image: chrisbesch/docker_cron_example
        environment:
            # this container's task runs every day at 03:00
            - "CRON_TIME=0 3 * * *"
            # it receives a HUP signal (since this is the default, this env variable can be omitted)
            # all signals here: https://github.com/fsouza/go-dockerclient/blob/01804dec8a84d0a77e63611f2b62d33e9bb2b64a/signal.go
            - CRON_SIGNAL=0x1
      
    docker_cron:
        image: chrisbesch/docker_cron
        volumes:
            - "/var/run/docker.sock:/var/run/docker.sock:rw"
        environment:
            - TZ=Europe/Berlin
```
This example can be found [here](https://github.com/christopher-besch/docker_cron/tree/main/example).

## The `docker_cron` container
All you have to do is add the `docker_cron` container to your `docker-compose.yaml`, give it read/write access to the docker socket and specify your timezone.
Now all containers that defined the `CRON_TIME` environment variable [receive a HUP signal](#the-hup-signal) whenever [their `CRON_TIME`](#cron_time) matches the current minute.
(This magic is performed by [docker-gen](https://github.com/nginx-proxy/docker-gen).)

## `CRON_TIME`
`CRON_TIME` consists out of five fields separated by <blank> characters:
1. Minute [0,59]
2. Hour [0,23]
3. Day of the month [1,31]
4. Month of the year [1,12]
5. Day of the week ([0,6] with 0=Sunday)
Each field can also be an `*`, meaning all valid values.
This is from an [extract from `man crontab`](#man-crontab-extract).

## The HUP Signal
When the current minute matches the `CRON_TIME` of a container, that container receives a HUP signal.
This is equivalent to `docker kill -s HUP <container name>` (which can also be used to force running your task for debugging).
The container is not restarted or otherwise nonconsensually touched.
It's your container's job to trap this HUP signal and do with it as it likes.
Here is a bash example doing this:
```bash
#!/bin/bash
trap 'bash /actual_job.sh' HUP
while :; do
    sleep 10 & wait ${!}
done
```
Make sure that you don't `set -e` because that causes the trap to exit the script.

## Sending Other Signals
If you want your container to receive a different signal, set the `CRON_SIGNAL` environment variable of the target container to the integer that identifies your desired signal.
Use this table to reference the correct one (from [here](https://github.com/fsouza/go-dockerclient/blob/01804dec8a84d0a77e63611f2b62d33e9bb2b64a/signal.go)):
| Signal    | int    |
|:--------- |:------ |
| SIGABRT   | `0x6`  |
| SIGALRM   | `0xe`  |
| SIGBUS    | `0x7`  |
| SIGCHLD   | `0x11` |
| SIGCLD    | `0x11` |
| SIGCONT   | `0x12` |
| SIGFPE    | `0x8`  |
| SIGHUP    | `0x1`  |
| SIGILL    | `0x4`  |
| SIGINT    | `0x2`  |
| SIGIO     | `0x1d` |
| SIGIOT    | `0x6`  |
| SIGKILL   | `0x9`  |
| SIGPIPE   | `0xd`  |
| SIGPOLL   | `0x1d` |
| SIGPROF   | `0x1b` |
| SIGPWR    | `0x1e` |
| SIGQUIT   | `0x3`  |
| SIGSEGV   | `0xb`  |
| SIGSTKFLT | `0x10` |
| SIGSTOP   | `0x13` |
| SIGSYS    | `0x1f` |
| SIGTERM   | `0xf`  |
| SIGTRAP   | `0x5`  |
| SIGTSTP   | `0x14` |
| SIGTTIN   | `0x15` |
| SIGTTOU   | `0x16` |
| SIGUNUSED | `0x1f` |
| SIGURG    | `0x17` |
| SIGUSR1   | `0xa`  |
| SIGUSR2   | `0xc`  |
| SIGVTALRM | `0x1a` |
| SIGWINCH  | `0x1c` |
| SIGXCPU   | `0x18` |
| SIGXFSZ   | `0x19` |

# `man crontab` extract
```
1. Minute [0,59]

2. Hour [0,23]

3. Day of the month [1,31]

4. Month of the year [1,12]

5. Day of the week ([0,6] with 0=Sunday)

Each of these patterns can be either an <asterisk> (meaning all valid values), an  ele‐
ment, or a list of elements separated by <comma> characters. An element shall be either
a number or two numbers separated by a <hyphen-minus> (meaning an inclusive range). The
specification of days can be made by two fields (day of the month and day of the week).
If month, day of month, and day of week are all <asterisk> characters, every day  shall
be matched. If either the month or day of month is specified as an element or list, but
the day of week is an <asterisk>, the month and day of month fields shall  specify  the
days that match. If both month and day of month are specified as an <asterisk>, but day
of week is an element or list, then only the specified days of the week match. Finally,
if  either the month or day of month is specified as an element or list, and the day of
week is also specified as an element or list, then any day matching  either  the  month
and day of month, or the day of week, shall be matched.
```
