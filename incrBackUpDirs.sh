#!/bin/bash

# Incremental backup script
	# Method: (No need for iterations, first run will see there's no backups, so it will copy everything)
	# find $(readlink -f /path/to/original/) -fprint "original.txt" | sed -i '/original.txt/d' /path/to/original/original.txt
	# ssh find -type f $(readlink -f /home/bari/backUps/$user/$backUpName/) -fprint "new.txt" | sed -i '/new.txt/d' /home/bari/backUps/$user/$backUpName/new.txt
	# ^ via SSH ^
	# Note, you can probs just take STDOUT locally and write it to file
	# diff original.txt new.txt
		# Top section shows what's been removed ("<")
		# Bottom what's been added (">")
	# Encountered problem - diff only sees newly created files, comparing all files for differences may take long too...
		# We could either compare all files by size (Not always sees modded files or renamed)
		# Or by checksum $ md5sum
		# But what if we delete a file?, how will we merge the backups?
		# Create a deleted.txt file
		# First cron run will not have any removed files when running diff command
		# From then on if any file has been removed/renamed it will be written in deleted.txt
			# md5sum will not detect renamed files, gives same md5sum value
			# Run diff command with only paths, to detect newly created files, and deleted files and sort them accordingly 
			# Then run md5sum command with diff to detect modified files, and copy them
	#Path to backup
	
	# Create a function that:
	# [D] Get paths of all files in local and server folders
	#  If $# = 2, include exclusions by sed -i '/excludedDirs/d' /path/to/new.txt && sed -i '/excludedDirs/d' /path/to/original.txt
	# Compare them via pathname and md5sum for present and modified files
	# Write different files into difference.txt
	# dry run with with --files-from=difference.txt
	# Write deleted files deleted.txt for future
	# Add all modified/created files into the directory, and if necessary, deleted.txt aswell

# Maintain logs (?)
	# Every execution should produce a log

# Directory manipulation
sourceDir="/home/bari/Documents/Linux/bash/purposeful/testDirectoryBU"
AbsExcludeDir="/home/bari/Documents/Linux/bash/purposeful/testDirectoryBU/excludedDir/"
excludeDir="$(echo "$AbsExcludeDir" | sed "s|^$sourceDir||" | sed 's/^.//')" # rsync only accepts relative paths (to source)
user="$(echo "$(whoami)")"
backUpFolder="$(realpath $sourceDir | sed "s|^/home/$(whoami)/||")"
backUpName=$(echo $backUpFolder | sed 's|/|.|g')
DATE=$(date '+%Y-%m-%d')
parentDestDir="backUps/$user/$backUpName"
export parentDestDir="backUps/$user/$backUpName"
destDir="backUps/$user/$backUpName/$DATE"

echo
echo "sourceDir:	$sourceDir"
echo "AbsExcludeDir:	$AbsExcludeDir"
echo "excludeDir:	$excludeDir"
echo "user:		$user"
echo "backUpFolder:	$backUpFolder"
echo "backUpName:	$backUpName"
echo "DATE:		$DATE"
echo "parentDestDir:	$parentDestDir"
echo "destDir:	$destDir"
echo "BACKUPDIR 	/home/bari/$parentDestDir/"
echo
# Establishing SSH connection & Gathering files
> original.txt
> new.txt
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/ansible_key
# find $(readlink -f $sourceDir) -fprint "/home/bari/Documents/BackUpScript/original.txt" # Working
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
echo "$(cat /home/bari/Documents/BackUpScript/new.txt | sed "s|/home/bari/${destDir}||g")" > /home/bari/Documents/BackUpScript/new.txt

# Locally run to reduce #SSH conns
if [ $# -eq 1 ]; then
	rsync -av --dry-run --rsync-path="mkdir -p /tmp/$destDir/ && rsync" $sourceDir /tmp/$destDir/
elif [ $# -eq 2 ]; then
	echo "$excludeDir" > excludeList.txt
	rsync -av --exclude-from='excludeList.txt' --dry-run --rsync-path="mkdir -p /tmp/$destDir/ && rsync"  $sourceDir /tmp/$destDir/	
fi

echo "Above is dry-run locally, do you wish to implement changes on server? y/N"
read input

if [[ $# -eq 1 && "$input" = "y" ]]; then
	rsync -av --rsync-path="mkdir -p /home/bari/$destDir/ && rsync" $sourceDir bari@192.168.1.23:/home/bari/$destDir/

elif [[ $# -eq 2 && "$input" = "y" ]]; then
	rsync -av --rsync-path="mkdir -p /home/bari/$destDir/ && rsync" --exclude '$excludeDir' $sourceDir bari@192.168.1.23:/home/bari/$destDir/
else
	echo "Operation cancelled, exiting..."
	exit
fi


###################################
##### Checklist ####
## Locally ##
# Corrent destination name
# Correct exclusion and