#!/bin/bash
set -x
env &> /shared/tmp/processing.log
unset LD_LIBRARY_PATH
echo -e "\n""Setting Language...""\n" &>> /shared/tmp/processing.log
/usr/bin/mkvpropedit "$1" --edit track:a1 --set language=eng --edit track:v1 --set language=eng &>> /shared/tmp/processing.log
echo -e "\n""Sleeping for 5 seconds...""\n" &>> /shared/tmp/processing.log
sleep 5
echo -e "\n""Removing commercials..." &>> /shared/tmp/processing.log
/usr/bin/python /home/jasonmicron/PlexComskip/PlexComskip.py "$1" &>> /shared/tmp/processing.log
exit 0
