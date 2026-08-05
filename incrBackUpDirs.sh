#!/bin/bash

# Incremental backup script

# Directory manipulation
sourceDir="$1"
AbsExcludeDir="$2"
excludeDir="$(echo "$AbsExcludeDir" | sed "s|^$sourceDir||" | sed 's/^.//')" # rsync only accepts relative paths (to source)
user="$(echo "$(whoami)")"
backUpFolder="$(realpath $sourceDir | sed "s|^/home/$(whoami)/||")"
backUpName=$(echo $backUpFolder | sed 's|/|.|g')
DATE=$(date '+%Y-%m-%d')
parentDestDir="backUps/$user/$backUpName"
export parentDestDir="backUps/$user/$backUpName"
destDir="backUps/$user/$backUpName/$DATE"

# Directories for testing
# echo
# echo "sourceDir:	$sourceDir"
# echo "AbsExcludeDir:	$AbsExcludeDir"
# echo "excludeDir:	$excludeDir"
# echo "user:		$user"
# echo "backUpFolder:	$backUpFolder"
# echo "backUpName:	$backUpName"
# echo "DATE:		$DATE"
# echo "parentDestDir:	$parentDestDir"
# echo "destDir:	$destDir"
# echo "BACKUPDIR 	/home/bari/$parentDestDir/"
# echo

# Establishing SSH connection & Gathering files
> original.txt
> new.txt
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/ansible_key

# Current Local Directory
for hostFile in $(find $sourceDir -type f); do
	md5sum $hostFile
done >> /home/bari/Documents/BackUpScript/original.txt

# Backup Folders
ssh bari@192.168.1.23 '	
for servFile in $(find /home/bari/"'$parentDestDir'"/ -type f); do
	md5sum $servFile;
done' >> /home/bari/Documents/BackUpScript/new.txt

# Reformatting directories from server > host before comparison
echo "$(cat /home/bari/Documents/BackUpScript/new.txt | sed "s|/home/bari/${parentDestDir}/||g" | sed -E 's/([0-9]{4})-([0-9]{2})-([0-9]{2})//g')" > /home/bari/Documents/BackUpScript/new.txt
sed -i '/deleted.txt/d' /home/bari/Documents/BackUpScript/new.txt

# File Comparison
if [ $# -eq 1 ]; then
	echo "$(diff <(sort /home/bari/Documents/BackUpScript/new.txt) <(sort /home/bari/Documents/BackUpScript/original.txt) | grep "> " | awk '{print $3}')" > /home/bari/Documents/BackUpScript/added.txt
	echo "$(diff <(sort /home/bari/Documents/BackUpScript/new.txt) <(sort /home/bari/Documents/BackUpScript/original.txt) | grep "< " | awk '{print $3}')" > /home/bari/Documents/BackUpScript/deleted.txt
elif [ $# -eq 2 ]; then
	echo "$(diff <(sort /home/bari/Documents/BackUpScript/new.txt) <(sort /home/bari/Documents/BackUpScript/original.txt) | grep "> " | awk '{print $3}')" > /home/bari/Documents/BackUpScript/added.txt
	echo "$(diff <(sort /home/bari/Documents/BackUpScript/new.txt) <(sort /home/bari/Documents/BackUpScript/original.txt) | grep "< " | awk '{print $3}')" > /home/bari/Documents/BackUpScript/deleted.txt 
	sed -i "\|${AbsExcludeDir}|d" /home/bari/Documents/BackUpScript/added.txt
	sed -i "\|${AbsExcludeDir}|d" /home/bari/Documents/BackUpScript/deleted.txt
fi

# Local dry-run for testing & user confirmation
rsync -av --files-from='/home/bari/Documents/BackUpScript/added.txt' --dry-run --rsync-path="mkdir -p /tmp/$destDir/ && rsync" / /tmp/$destDir/

echo "Above is dry-run locally, do you wish to implement changes on server? y/N"
read input

# Actual run
if [[ "$input" = "y" ]]; then
	mkdir -p /home/bari/Documents/BackUpScript/logs/$backUpName/
	echo "$(rsync -av --files-from='/home/bari/Documents/BackUpScript/added.txt' --rsync-path="mkdir -p /home/bari/$destDir/ && rsync" / bari@192.168.1.23:/home/bari/$destDir/)" > /home/bari/Documents/BackUpScript/logs/$backUpName/$DATE.txt
	sed -i '\|/$|d' /home/bari/Documents/BackUpScript/logs/$backUpName/$DATE.txt
	echo "List of changes can be found in log file"
else
	echo "Operation cancelled, exiting..."
	exit
fi

###################################
##### ToDo ####
# Clean script for ease of use
# Add a README

# Further improvements
# chooseDirsBackup.sh to accept a list of excluded directories
# Replace all file paths for original, new, added, and deleted.txt and log text files for ease of use
# Transfer deleted.txt alongside /home/bari/$destDir/ - for future use when merging backups
# Allow for multiple cron jobs under a user (Could cause overloads)
# Reduce workload by using a mix of both size and md5sum for file comparison