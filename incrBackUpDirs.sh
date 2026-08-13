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
# echo "BACKUPDIR 	/path/to/$parentDestDir/
# echo

# Establishing SSH connection & Gathering files
> original.txt
> new.txt
eval "$(ssh-agent -s)"
ssh-add /path/to/key

# Current Local Directory
for hostFile in $(find $sourceDir -type f); do
	md5sum $hostFile
done >> /path/to/localFiles.txt

# Backup Folders
ssh user@ip '	
for servFile in $(find /path/to/"'$parentDestDir'"/ -type f); do
	md5sum $servFile;
done' >> /path/to/serverFiles.txt

# Reformatting directories from server > host, before comparison
echo "$(cat /path/to/serverFiles.txt | sed "s|/path/to/${parentDestDir}/||g" | sed -E 's/([0-9]{4})-([0-9]{2})-([0-9]{2})//g')" > /path/to/serverFiles.txt
sed -i '/deletedFiles.txt/d' /path/to/serverFiles.txt

# File Comparison
if [ $# -eq 1 ]; then
	echo "$(diff <(sort /path/to/serverFiles.txt) <(sort /path/to/localFiles.txt) | grep "> " | awk '{print $3}')" > /path/to/addedFiles.txt
	echo "$(diff <(sort /path/to/serverFiles.txt) <(sort /path/to/localFiles.txt) | grep "< " | awk '{print $3}')" > /path/to/deletedFiles.txt
elif [ $# -eq 2 ]; then
	echo "$(diff <(sort /path/to/serverFiles.txt) <(sort /path/to/localFiles.txt) | grep "> " | awk '{print $3}')" > /path/to/addedFiles.txt
	echo "$(diff <(sort /path/to/serverFiles.txt) <(sort /path/to/localFiles.txt) | grep "< " | awk '{print $3}')" > /path/to/deletedFiles.txt 
	sed -i "\|${AbsExcludeDir}|d" /path/to/addedFiles.txt
	sed -i "\|${AbsExcludeDir}|d" /path/to/deletedFiles.txt
fi

# Local dry-run for testing & user confirmation
rsync -av --files-from='/path/to/addedFiles.txt' --dry-run --rsync-path="mkdir -p /tmp/$destDir/ && rsync" / /tmp/$destDir/

echo "Above is dry-run locally, do you wish to implement changes on server? y/N"
read input

# Actual run
if [[ "$input" = "y" ]]; then
	mkdir -p /path/to/log/folder/$backUpName/
	echo "$(rsync -av --files-from='/path/to/addedFiles.txt' --rsync-path="mkdir -p /path/to/server/backup/folder/$destDir/ && rsync" / user@IP:/path/to/server/backup/folder/$destDir/)" > /path/to/log/folder/$backUpName/$DATE.txt
	sed -i '\|/$|d' /path/to/log/folder/$backUpName/$DATE.txt
	echo "List of changes can be found in log file"
else
	echo "Operation cancelled, exiting..."
	exit
fi
