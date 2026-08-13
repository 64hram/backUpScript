Incremental Backup Script
-

Functionality:

1. chooseDirsBackup.sh
   - Let's you choose the directories that you wish to backup, as well as one sub-directory if you wish to exclude it
   - Writes in the crontab in /var/spool/cron/, you can edit the times you wish to run the script in the cronInput() function
       - Will not function correctly if run more than once per day, each backup made is named after the day it was made
   - crontab executes the incrBackUpDirs.sh script with the path to the script and the folder you wish to backup

1. incrBackUpDirs.sh
   - Takes directories from chooseDirsBackUp.sh
   - Manipulates their names to create unique backup folders according to the user and day
   - Establishes SSH connection with the server
   - Compares local and server files to see what's been modified or added/removed, then creates a new directory with these files if true
       - First run will copy everything into a new directory
       - Subsequent runs will copy only modified or added

The following paths must be modified:
  - user@ip and /path/to/key 
    - SSH Connection
  - /path/to/localFiles.txt 
    - Stores all the current files in your local system
  - /path/to/serverFiles.txt
    - Stores all the backup files in server
  - /path/to/"'$parentDestDir'"/
    - Path to the backup folder, in format /home/user/backUps/user/path.to.desired.folder
  - /path/to/addedFiles.txt
    - Stores all the newly added/modified files after comparison of local & server files
  - /path/to/deletedFiles.txt
    - Stores all deleted files after comparison of local & server files
    - Text file is stored within backup directory on server, for future purposes, i.e. merging backups
  - /path/to/log/folder/$backUpName/
    - Logs from rsync of files transferred, stored in local system
  - /path/to/server/backup/folder/$destDir/
    - Where all the backup files will be stored


  
  
  
