#!/bin/bash
#
######################
#
# This script will clean up minecraft world backups
# that are older than 1 day old.
#
# This is because they are already backed up into a tar
# nightly.  No need to eat up space needlessly.
#
# See /home/jasonmicron/scripts/backup.sh for nightly backup logic
#
MCBACKUPDIR=/backup/minecraft/minecraft_vanilla/ #Vanilla Minecraft
MCFTBBACKUPDIR=/backup/minecraft/minecraft_ftb/ #Feed The Beast
#
#
for i in `find $MCBACKUPDIR -mtime +1`; do rm -rf $i; done
for i in `find $MCFTBBACKUPDIR -mtime +1`; do rm -rf $i; done
#/etc/init.d/minecraft backup
#/etc/init.d/minecraft_ftb backup
exit 0
