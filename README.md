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
      
    docker_cron:
        image: chrisbesch/docker_cron
        volumes:
            - "/var/run/docker.sock:/var/run/docker.sock:rw"
        environment:
            - TZ=Europe/Berlin
```
This example can be found [here]().

## The `docker_cron` container
All you have to do is add the `docker_cron` container to your `docker-compose.yaml`, give it read/write access to the docker socket and specify your timezone.
Now all containers that defined the `CRON_TIME` environment variable [receive a HUP signal](#the-sighup) whenever [their `CRON_TIME`](cron-time) matches the current minute.
(This magic is performed by [docker-gen](https://github.com/nginx-proxy/docker-gen).)

## `CRON_TIME`
`CRON_TIME` consists out of five fields separated by <blank> characters:
1. Minute [0,59]
2. Hour [0,23]
3. Day of the month [1,31]
4. Month of the year [1,12]
5. Day of the week ([0,6] with 0=Sunday)
Each field can also be an `*`, meaning all valid values.
This is from an [extract from `man crontab`](#cron_time-definition-from-man-crontab).

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

# `CRON_TIME` definition from `man crontab`
```
In the POSIX locale, the user or application shall ensure that a crontab entry is a text file consisting of lines of six fields each.  The fields shall be separated by <blank>  characters.  The  first
five fields shall be integer patterns that specify the following:

1. Minute [0,59]

2. Hour [0,23]

3. Day of the month [1,31]

4. Month of the year [1,12]

5. Day of the week ([0,6] with 0=Sunday)

Each  of  these  patterns  can be either an <asterisk> (meaning all valid values), an element, or a list of elements separated by <comma> characters. An element shall be either a number or two numbers
separated by a <hyphen-minus> (meaning an inclusive range). The specification of days can be made by two fields (day of the month and day of the week). If month, day of month, and day of week are  all
<asterisk> characters, every day shall be matched. If either the month or day of month is specified as an element or list, but the day of week is an <asterisk>, the month and day of month fields shall
specify the days that match. If both month and day of month are specified as an <asterisk>, but day of week is an element or list, then only the specified days of the week match.  Finally,  if  either
the  month or day of month is specified as an element or list, and the day of week is also specified as an element or list, then any day matching either the month and day of month, or the day of week,
shall be matched.
```
