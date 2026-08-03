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
	
	# Summary of method:
	# Get paths of all files in local and server folders
	# Compare them via pathname and md5sum for present and modified files
	# Write deleted files deleted.txt for future
	# Add all modified/created files into the directory, and if necessary, deleted.txt aswell

# Maintain logs (?)
	# Every execution should produce a log


sourceDir="/home/bari/Documents/Linux"
AbsExcludeDir="/home/bari/Documents/Linux/Resources/ISOs"
excludeDir="$(echo "$AbsExcludeDir" | sed "s|^$sourceDir||" | sed 's/^.//')"
	# rsync only accepts relative paths (to source)
user="$(echo "$(whoami)")"

backUpFolder="$(realpath $sourceDir | sed "s|^/home/$(whoami)/||")"
backUpName=$(echo $backUpFolder | sed 's|/|.|g')
DATE=$(date '+%Y-%m-%d')

destDir="backUps/$user/$backUpName/$DATE"

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