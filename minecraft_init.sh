#!/bin/bash
# /etc/init.d/minecraft
# version 2013-11-20 (YYYY-MM-DD)

### BEGIN INIT INFO
# Provides: minecraft
# Required-Start: $local_fs $remote_fs
# Required-Stop: $local_fs $remote_fs
# Should-Start: $network
# Should-Stop: $network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Minecraft server
# Description: Starts a Minecraft server
### END INIT INFO

# minecraft-init-script - An initscript to start Minecraft or CraftBukkit
# Copyright (C) 2011 - Super Jamie <jamie@superjamie.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

# Source function library
. /etc/rc.d/init.d/functions

## Settings
# Nice looking name of service for script to report back to users
SERVERNAME="Micronnet"
# Filename of server binary
SERVICE="minecraft_server.jar"
# Username of non-root user who will run the server
USERNAME="minecraft"
# Path of server binary and world
MCPATH="/Games/minecraft_server/"
# Number of CPU cores to thread across if using multithreaded garbage collection
CPU_COUNT=6
# Where backups go
BACKUPPATH="/backup/minecraft"
# Find the world name from the existing server file
WORLDNAME=`cat $MCPATH/server.properties | grep -E 'level-name' | sed -e s/.*level-name=//`
# Name of Screen session
SCRNAME="minecraft"

## The Java command to run the server

# Nothing special, just start the server with 1Gb RAM
# INVOCATION="java -Xms8192M -Xmx8192M -Djava.net.preferIPv4Stack=true -jar $SERVICE nogui"

# This is what I run my server with. Tune your RAM usage accordingly
# Tested fastest GC - Default parallel new gen collector, plus parallel old gen collector
INVOCATION="java -Xms8192M -Xmx8192M -Djava.net.preferIPv4Stack=true -XX:MaxPermSize=128M -XX:UseSSE=3 -XX:-DisableExplicitGC -XX:+UseParallelOldGC -XX:ParallelGCThreads=$CPU_COUNT -jar $SERVICE nogui"

# I removed these "performance" commands as I don't see any difference with them
# -XX:+UseFastAccessorMethods -XX:+AggressiveOpts -XX:+UseAdaptiveGCBoundary

# Add HugePage support if you have it configured on the OS
# -XX:+UseLargePages

## Runs all commands as the non-root user

as_user() {
  ME=$(whoami)
  if [ $ME == $USERNAME ]
  then
bash -c "$1"
  else
su - $USERNAME -c "$1"
  fi
}

## Check if the server is running or not, and get PID if it is

server_running() {
  if ps ax | grep -v grep | grep -iv SCREEN | grep $SERVICE > /dev/null
  then
PID=0
    PID="$(ps ax | grep -v grep | grep -iv SCREEN | grep $SERVICE | awk '{print $1}')"
    return 0
  else
return 1
  fi
}


## Start the server executable as a service

mc_start() {
  if server_running
  then
failure && echo " * $SERVERNAME was already running! (pid $PID)"
    exit 1
  else
echo " * $SERVERNAME was not already running. Starting..."
    echo " * Using map named \"$WORLDNAME\"..."
    cd $MCPATH
    as_user "cd $MCPATH && screen -c /dev/null -dmS $SCRNAME $INVOCATION"
    sleep 10
    echo " * Checking $SERVERNAME is running..."

    if server_running
    then
success && echo " * $SERVERNAME is now running. (pid $PID)"
    else
failure && echo " * Could not start $SERVERNAME."
      exit 1
    fi

fi
}

## Stop the executable

mc_stop() {
  if server_running
  then
echo " * $SERVERNAME is running (pid $PID). Commencing shutdown..."
    echo " * Notifying users of shutdown..."
    as_user "screen -p 0 -S $SCRNAME -X eval 'stuff \"say SERVER SHUTTING DOWN IN 10 SECONDS. Saving map...\"\015'"
    echo " * Saving map named \"$WORLDNAME\" to disk..."
    as_user "screen -p 0 -S $SCRNAME -X eval 'stuff \"save-all\"\015'"
    sleep 10
    echo " * Stopping $SERVERNAME..."
    as_user "screen -p 0 -S $SCRNAME -X eval 'stuff \"stop\"\015'"
    sleep 10
  else
failure && echo " * $SERVERNAME was not running!"
    exit 1
  fi

if server_running
  then
failure && echo " * $SERVERNAME could not be shutdown! Still running..."
    exit 1
  else
success && echo " * $SERVERNAME is shut down."
  fi
}

## Set the server read-only, save the map, and have Linux sync filesystem buffers to disk

mc_saveoff() {
  if server_running
  then
echo " * $SERVERNAME is running. Commencing save..."
    echo " * Notifying users of save..."
    as_user "screen -p 0 -S $SCRNAME -X eval 'stuff \"say SERVER BACKUP STARTING. Server going read-only...\"\015'"
    echo " * Setting server read-only..."
    as_user "screen -p 0 -S $SCRNAME -X eval 'stuff \"save-off\"\015'"
    echo " * Saving map named \"$WORLDNAME\" to disk..."
    as_user "screen -p 0 -S $SCRNAME -X eval 'stuff \"save-all\"\015'"
    sync
    sleep 10
    success && echo " * Map saved."
  else
failure && echo "$SERVERNAME was not running. Not suspending saves."
    exit 1
  fi
}

## Set the server read-write

mc_saveon() {
  if server_running
  then
echo " * $SERVERNAME is running. Re-enabling saves..."
    as_user "screen -p 0 -S $SCRNAME -X eval 'stuff \"say SERVER BACKUP ENDED. Server going read-write...\"\015'"
    as_user "screen -p 0 -S $SCRNAME -X eval 'stuff \"save-on\"\015'"
  else
failure && echo " * $SERVERNAME was not running. Not resuming saves."
    exit 1
  fi
}

## Checks for update, exits if update not required, updates if the server is not running
## http://cbukk.it/craftbukkit.jar is the recommended build URL

## Backs up map by rsyncing current world to backup location, creates tar.gz with datestamp

mc_backupmap() {
  echo " * Backing up $SERVERNAME map named \"$WORLDNAME\"..."
  echo " * Syncing "$MCPATH"/"$WORLDNAME" to "$BACKUPPATH"/"$WORLDNAME""
  as_user "cd $MCPATH && rsync -cghLoprtu "$WORLDNAME" "$BACKUPPATH""
  sleep 10
  echo " * Creating compressed backup..."
  NOW="`date "+%Y-%m-%d.%H-%M-%S"`"
  # Create a compressed backup file and background it so we can get back to restarting the server
  # You can tell when the compression is done as it makes an md5sum file of the backup
  as_user "cd $BACKUPPATH && tar cfz "$WORLDNAME"_backup_"$NOW".tar.gz "$WORLDNAME" && md5sum "$WORLDNAME"_backup_"$NOW".tar.gz > "$WORLDNAME"_backup_"$NOW".tar.gz.md5 &" # we can background this and get to restarting the server
  success && echo " * Backed up map."
}

## Backs up executable by copying it to backup location

mc_backupexe() {
  echo " * Backing up the $SERVERNAME server executable..."
  as_user "cd $MCPATH && cp "$SERVICE" "$BACKUPPATH"/"$SERVICE"_backup_"$NOW".jar"
  success && echo " * Backed up executable."
}

## Removes any backups older than 7 days, designed to be called by daily cron job

mc_removeoldbackups() {
  NUMBEROFBACKUPS="`find \"$BACKUPPATH\" -name \""$WORLDNAME"_backup*\" -type f -mtime +7 | wc -l`"
  if [ $NUMBEROFBACKUPS -ge 1 ]
  then
echo " * Removing map backups older than 7 days..."
    as_user "cd $BACKUPPATH && find . -name \""$WORLDNAME"_backup*\" -type f -mtime +7 | xargs rm -fv"
    echo " * Removed old map backups."
  else
echo " * No map backups older than 7 days to remove."
  fi

NUMBEROFEXES="`find \"$BACKUPPATH\" -name \""$SERVICE"_backup*\" -type f -mtime +7 | wc -l`"
  if [ $NUMBEROFEXES -ge 1 ]
  then
echo " * Removing executable backups older than 7 days..."
    as_user "cd $BACKUPPATH && find . -name \""$SERVICE"_backup*\" -type f -mtime +7 | xargs rm -fv"
    echo " * Removed old executable backups."
  else
echo " * No executable backups older than 7 days to remove."
  fi
}

## Rotates logfile to server.0 through server.7, designed to be called by daily cron job

mc_logrotate() {
  # Server logfiles in chronological order
  LOGLIST=$(ls -r $MCPATH/server.log* | grep -v lck)
  # How many logs to keep
  COUNT=6
  # Look at all the logfiles
  for i in $LOGLIST; do
LOGTMP=$(ls $i | cut -d "." -f 3)
    # If we're working with server.log then append .1
    if [ -z $LOGTMP ]
    then
LOGTMP=$MCPATH"/server.log"
      LOGNEW=$LOGTMP".1"
      as_user "/bin/cp $MCPATH"/server.log" "$LOGNEW""
    # Otherwise, check if the file number is under $COUNT
    elif [ $LOGTMP -gt $COUNT ]
    then
      # If so, delete it
      as_user "rm -f $i"
    else
      # Otherwise, add one to the number
      LOGBASE=$(ls $i | cut -d "." -f 1-2)
      LOGNEW=$LOGBASE.$(($LOGTMP+1))
      as_user "/bin/cp $i $LOGNEW"
    fi
done
  # Blank the existing logfile to renew it
  as_user "echo -n \"\" > $MCPATH/server.log"
}

## Check if server is running and display PID

mc_status() {
  if server_running
  then
echo " * $SERVERNAME (pid $PID) is running..."
  else
echo " * $SERVERNAME is not running. Check your logs."
    exit 1
  fi
}

## Display some extra environment informaton

mc_info() {
  if server_running
  then
RSS="$(ps -p $PID --format rss | tail -n 1)"
    HP_SIZE="$(cat /proc/meminfo | grep Hugepagesize | awk '{print $2}')"
    HP_TOTAL="$(cat /proc/meminfo | grep HugePages_Total | awk '{print $2}')"
    HP_FREE="$(cat /proc/meminfo | grep HugePages_Free | awk '{print $2}')"
    HP_RSVD="$(cat /proc/meminfo | grep HugePages_Rsvd | awk '{print $2}')"
    HP_EXTRA="$[$HP_FREE-$HP_RSVD]"
    HP_ALLOC="$[$HP_TOTAL-$HP_EXTRA]"
    TOTALMEM="$[$RSS+$[HP_ALLOC*$HP_SIZE]]"
    echo " - Java Path : $(readlink -f $(which java))"
    echo " - Start Command : $INVOCATION"
    echo " - Server Path : $MCPATH"
    echo " - World Name : $WORLDNAME"
    echo " - Process ID : $PID"
    echo " - Screen Session : $SCRNAME"
    echo " - Memory Usage : $[$RSS/1024] Mb ($RSS kb)"
  if [ -n $HP_TOTAL ]
  then
echo " - HugePage Usage : $[$HP_ALLOC*$[HP_SIZE/1024]] Mb ($HP_ALLOC HugePages)"
    echo " - Total Memory Usage : $[TOTALMEM/1024] Mb ($TOTALMEM kb)"
  fi
echo " - Active Connections : "
    netstat -tna | grep -E "Proto|25565"
  else
echo " * $SERVERNAME is not running."
    exit 1
  fi
}
 
## Connect to the active Screen session, disconnect with Ctrl+a then d

mc_console() {
  if server_running
  then
as_user "screen -S $SCRNAME -dr"
  else
failure && echo " * $SERVERNAME was not running!"
    exit 1
  fi
}

## These are the parameters passed to the script

case "$1" in
  start)
 mc_start
 ;;
  stop)
 mc_stop
 ;;
  restart)
 mc_stop
 sleep 1
 mc_start
 ;;
  backup)
 mc_saveoff
 mc_backupmap
 mc_backupexe
 mc_saveon
 ;;
  status)
 mc_status
 ;;
  info)
 mc_info
 ;;
  console)
 mc_console
 ;;
# These are intended for cron usage, not regular users.
  removeoldbackups)
 mc_removeoldbackups
 ;;
  logrotate)
 mc_logrotate
 ;;
# Debug usage only
  justbackup) # don't use this while the server is running!!!
 mc_backupmap
 mc_backupexe
 ;;
  *)
 echo " * Usage: minecraft {start|stop|restart|backup|status|info|console}"
 exit 1
 ;;
esac

exit 0
