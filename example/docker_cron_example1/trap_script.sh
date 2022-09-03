#!/bin/bash

# make sure that you don't `set -e` because that causes the trap to exit the script
############################################
# await SIGHUP and then run the actual job #
############################################
trap 'bash /actual_job.sh' HUP
while :; do
    sleep 10 & wait ${!}
done

