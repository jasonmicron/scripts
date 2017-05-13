#!/bin/bash
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
for f in *
do
  ffmpeg -i $f -acodec copy -vcodec copy $f.mp4
done
IFS=$SAVEIFS
