#!/bin/sh

# cron -f & allows cron stdout to be directed at host docker
# <- redirect output to cron stdout and stderr
# this is also done for the notify command
crond -f & \
    docker-gen \
    -notify 'crontab /etc/crontabs/root 1>/proc/$(cat /var/run/crond.pid)/fd/1 2>/proc/$(cat /var/run/crond.pid)/fd/2 && cat /etc/crontabs/root >/proc/$(cat /var/run/crond.pid)/fd/1' \
    -watch /var/lib/docker_cron/crontab.tmpl \
    /etc/crontabs/root

