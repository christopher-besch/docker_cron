#!/bin/sh

# cron -f & allows cron stdout to be directed at host docker
# <- redirect output to cron stdout and stderr
# this is also done for the notify command
cron -f & \
    docker-gen \
    -notify 'crontab /etc/cron.d/crontab 1>/proc/$(cat /var/run/crond.pid)/fd/1 2>/proc/$(cat /var/run/crond.pid)/fd/2 && cp /etc/cron.d/crontab /proc/$(cat /var/run/crond.pid)/fd/1' \
    -watch /var/lib/docker_cron/crontab.tmpl \
    /etc/cron.d/crontab

