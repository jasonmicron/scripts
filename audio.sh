#!/bin/bash
set -x
for v in `find . -print|grep mp4`
	do
	VOLUME=`ffmpeg -i ${v} -af "volumedetect" -f null /dev/null 2>&1 | \
	grep max_volume|awk -F ": " '{print $2}'|cut -d' ' -f1|awk -F "-" '{print $2}'`
	ffmpeg -i $v -af "volume=${VOLUME}dB" -c:v copy -c:a aac -strict experimental ${v}_new.mp4
done
exit

