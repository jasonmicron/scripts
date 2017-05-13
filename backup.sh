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
#
#####################################
#
# First, let's check to make sure /backup is mounted
# If it isn't, e-mail jasonmicron@gmail.com and quit
# with exit code 2
#
function mountcheck (){
	/bin/mount |grep backup
	MOUNTED=$?
	if [ $MOUNTED != 0 ]
		then mail -s "BACKUP NOT MOUNTED, NOTHING BEING BACKED UP" jasonmicron@gmail.com < /dev/null > /dev/null
		echo "`date` - BACKUP NOT MOUNTED, NOTHING BEING BACKED UP" >> /var/log/backup.log
		exit 2
fi
}
#
function music_backup (){
echo -e "\n""=======================================" > /var/log/backup.log
echo -e "Initializing Backup for `date`" >> /var/log/backup.log
echo -e "\n""\n""Backing up Music..." >> /var/log/backup.log
rsync -av /shared/Media/Music/ /backup/Media/Music/ >> /var/log/backup.log
if [ `echo $?` != "0" ]
	then echo -e "\n""ERRORS BACKING UP MUSIC" >> /var/log/backup.log
	MUSICBAK=N
	else echo -e "\n""Backing up SUCCESSFUL of Music" >> /var/log/backup.log
fi
}
#
function pictures_backup (){
echo -e "\n""Backing up Pictures..." >> /var/log/backup.log
rsync -av /shared/Media/Pictures/ /backup/Media/Pictures/ >> /var/log/backup.log
if [ `echo $?` != "0" ]
	then echo -e "\n""ERRORS BACKING UP PICTURES" >> /var/log/backup.log
	PICBAK=N
	else echo -e "\n""Backing up SUCCESSFUL of Pictures" >> /var/log/backup.log
fi
}
#
function videos_backup (){
echo -e "\n""Backing up Videos..." >> /var/log/backup.log
rsync -av /shared/Media/Videos/ /backup/Media/Videos/ >> /var/log/backup.log
if [ `echo $?` != "0" ]
	then echo -e "\n""ERRORS BACKING UP VIDEOS" >> /var/log/backup.log
	VIDBAK=N
	else echo -e "\n""Backing up SUCCESSFUL of Videos" >> /var/log/backup.log
fi
}
#
function emulator_games_backup (){
echo -e "\n""Backing up Emulator Games..." >> /var/log/backup.log
rsync -av /shared/games/Emulator/ /backup/games/Emulator/ >> /var/log/backup.log
if [ `echo $?` != "0" ]
	then echo -e "\n""ERRORS BACKING UP EMULATED GAMES" >> /var/log/backup.log
	GAMEBAK=N
	else echo -e "\n""Backing up SUCCESSFUL of Emulated Games" >> /var/log/backup.log
fi
}
#
function minecraft_backup (){
echo -e "\n""Backing up Minecraft worlds..." >> /var/log/backup.log
rsync -avz /backup/minecraft/* jasonmicron@jasonmicron.com:/home/jasonmicron/minecraft/world_backup/
if [ `echo $?` != "0" ]
	then echo -e "\n""ERRORS RSYNCING MINECRAFT WORLDS" >> /var/log/backup.log
	MINEBAK=N
	else echo -e "\n""Rsync SUCCESSFUL of Minecraft Worlds" >> /var/log/backup.log
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
if [ "$MINEBAK" = "N" ]
	then BACKUPERR=1
fi
if [ "$GAMEBAK" = "N" ]
	then BACKUPERR=1
fi
if [ "$BACKUPERR" = "1" ]
	then mail -s "ERRORS DURING BACKUP ON `date`" jasonmicron@gmail.com < /var/log/backup.log > /dev/null 
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
music_backup
echo -e "\n""=======================================================================================" >> /var/log/backup.log
pictures_backup
echo -e "\n""=======================================================================================" >> /var/log/backup.log
videos_backup
echo -e "\n""=======================================================================================" >> /var/log/backup.log
emulator_games_backup
echo -e "\n""=======================================================================================" >> /var/log/backup.log
minecraft_backup
echo -e "\n""=======================================================================================" >> /var/log/backup.log
#
backup_check
#
#
exit 0
