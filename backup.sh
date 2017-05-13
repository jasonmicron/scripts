#!/bin/bash
#####################################
#
# This script will backup mediasrv to /backup and e-mail
# jasonmicron@gmail.com upon any failures
#
#####################################
#
# Exit Codes:
# 0 - Successful execution of script, does not mean successful backup
# 1 - Unknown error
# 2 - Error when checking mount point of /backup
#
#####################################
#
# Declarations
#
BACKUPERR=0
BACKUPDEST1=/backup/drive1
BACKUPDEST2=/backup/drive2
BACKUPLOG=/var/log/backup.log
RSYNCERRORMESSAGE="ERROR backing up $MODULE"
RSYNCSUCCESSMESSAGE="SUCCESSFULLY backed up $MODULE"
declare RSYNCCOMMAND="rsync -av --delete /shared/Media" &>/dev/null
#
#####################################
#
# First, let's check to make sure /backup is mounted
# If it isn't, e-mail jasonmicron@gmail.com and quit
# with exit code 2
#
function mountcheck (){
if grep -qs $BACKUPDEST1 /proc/mounts && grep -qs $BACKUPDEST2 /proc/mounts; then
	BACKCHECK="pass"
	else BACKCHECK="fail"
fi
if [ $BACKCHECK = "fail" ]; then
	mail -s "BACKUP NOT MOUNTED, NOTHING BEING BACKED UP" jasonmicron@gmail.com < $BACKUPLOG > /dev/null
	echo "`date` - BACKUP NOT MOUNTED, NOTHING BEING BACKED UP" >> $BACKUPLOG
	exit 2
fi
}
#
function music_backup (){
export MODULE=Music
echo -e "\n""\n""Backing up Music..." >> $BACKUPLOG
eval $RSYNCCOMMAND/${MODULE}/ $BACKUPDEST2/Media/${MODULE}/ >> $BACKUPLOG
if [ `echo $?` != "0" ]
	then printf "\n${RSYNCERRORMESSAGE}" >> $BACKUPLOG
	MUSICBAK=N
	else printf "\n${RSYNCSUCCESSMESSAGE}" >> $BACKUPLOG
fi
}
#
function pictures_backup (){
MODULE=Pictures
echo -e "\n""Backing up Pictures..." >> $BACKUPLOG
eval $RSYNCCOMMAND/${MODULE}/ $BACKUPDEST2/Media/${MODULE}/ >> $BACKUPLOG
if [ `echo $?` != "0" ]
	then printf "\n${RSYNCERRORMESSAGE} ${MODULE}" >> $BACKUPLOG
	PICBAK=N
	else printf "\n${RSYNCSUCCESSMESSAGE} ${MODULE}" >> $BACKUPLOG
fi
}
#
function videos_backup (){
MODULE=Videos
echo -e "\n""Backing up Videos..." >> $BACKUPLOG
eval $RSYNCCOMMAND/${MODULE}/ --exclude "TV\ Shows" $BACKUPDEST2/Media/${MODULE}/ >> $BACKUPLOG
if [ `echo $?` != "0" ]
	then printf "\n${RSYNCERRORMESSAGE} ${MODULE}" >> $BACKUPLOG
	VIDBAK=N
	else printf "\n${RSYNCSUCCESSMESSAGE} ${MODULE}" >> $BACKUPLOG
fi
}
#
function tv_backup (){
MODULE="Videos/TV\ Shows"
echo -e "\n""Backing up Videos..." >> $BACKUPLOG
eval $RSYNCCOMMAND/"${MODULE}"/ $BACKUPDEST1/Media/"${MODULE}"/ >> $BACKUPLOG
if [ `echo $?` != "0" ]
	then printf "\n${RSYNCERRORMESSAGE} ${MODULE}" >> $BACKUPLOG
	TVBAK=N
	else printf "\n${RSYNCSUCCESSMESSAGE} ${MODULE}" >> $BACKUPLOG
fi
}
#
function minecraft_backup (){
MODULE=minecraft
echo -e "\n""Backing up Minecraft worlds..." >> $BACKUPLOG
rsync -avz /backup/minecraft/* jasonmicron@jasonmicron.com:/home/jasonmicron/minecraft/world_backup/
if [ `echo $?` != "0" ]
	then printf "\n${RSYNCERRORMESSAGE}" >> $BACKUPLOG
	MINEBAK=N
	else printf "\n${RSYNCSUCCESSMESSAGE}" >> $BACKUPLOG
fi
}
#
function backup_check (){
if [ "$MUSICBAK" = "N" ]
	then BACKUPERR=1
fi
if [ "$PICBAK" = "N" ]
	then BACKUPERR=1
fi
if [ "$VIDBAK" = "N" ]
	then BACKUPERR=1
fi
if [ "$TVBAK" = "N" ]
	then BACKUPERR=1
fi
if [ "$MINEBAK" = "N" ]
	then BACKUPERR=1
fi
if [ "$BACKUPERR" = "1" ]
	then mail -s "ERRORS DURING BACKUP ON `date`" jasonmicron@gmail.com < $BACKUPLOG > /dev/null 
fi
if [ "$BACKUPERR" = "0" ]
	then echo "All is well." | mail -s "Backups completed successfully on `date`" jasonmicron@gmail.com > /dev/null
fi
}
#####################################
#
# Beginning backups...
#
#####################################
#
#
mountcheck
music_backup
pictures_backup
videos_backup
tv_backup
#minecraft_backup
backup_check
printf "\n\n\n"
#
#
exit 0
