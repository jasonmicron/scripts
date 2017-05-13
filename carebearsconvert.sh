#!/bin/bash
set -x
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
for i in `ls|grep S02`
do
  cd $i
  unrar x `ls|grep part01`
  mv *.avi ..
  cd ..
  ffmpeg -i $i -acodec copy -vcodec copy $i.mp4
done
IFS=$SAVEIFS
