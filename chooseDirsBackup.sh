#!/bin/bash

# The purpose of this script is to ask the user
	# Which dirs they want to backup
	# Which sub-dirs they want to want to exclude from backup
		# Includes error prevention
			# If the dir is not sub-dir, then it will exit with Error status
			# Syntax for this
			# https://unix.stackexchange.com/a/6454

function cronInput() {
	# Takes the directories and inputs them into the the crontable
	echo "# 0 13 * * *  /home/bari/Documents/Linux/bash/purposeful/incrBackupDirs $backUpDir $excludeDir" >> /var/spool/cron/bari
}

function checkCron(){
	# Removes all instances of the crontab -l | grep "incrBackupDirs"
	sed -i '/incrBackupDirs/d' /var/spool/cron/bari
}

echo
echo "Enter directory you wish to backup"
read backUpDir

if [ ! -d "$backUpDir" ]; then
	# Checks if backUpDir is not a valid path
	echo "Invalid path"
	exit 1
fi

echo
echo "Enter sub-directory of previous directory you wish to exclude, 0 for nothing"
read excludeDir
if [ "$excludeDir" = "0" ]; then
	# Option incase user doesn't want any exclusions
	excludeDir=
	checkCron
	cronInput
elif [ -d "$excludeDir" ]; then
	# Checks if excludeDir is a valid path
	case $excludeDir in
		# Checks if excludeDir is within backUpDir
	 	$backUpDir*) 
	 		checkCron
	 		cronInput;;
	 	*) 
	 		echo "Path is not within backup directory - exiting...";;
	esac
else
	echo "Invalid path"
fi

