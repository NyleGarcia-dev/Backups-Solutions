#!/bin/bash
DEFAULTBACKUPFILE=/opt/backups/scripts/backup.conf
debugging=0
#Debugging=(0/1/2) 
# 0 being no logging
# 1 being some logging
# 2 being log everything


backup(){

if [$debugging == 0]; then
	echo "_+=------------------------------------=+_"
	echo "Starting Backup: `date`"
	echo "Sending tmux commands to $SERVER server!"
	sudo -u $USER tmux send-keys -t $SERVER "say Starting Server Backup" ENTER
	echo "Sending save-all command to tmux session"
	sudo -u $USER tmux send-keys -t $SERVER "save-all" ENTER
	echo "Turning world save off for rsync backup"
	sudo -u $USER tmux send-keys -t $SERVER "save-off" ENTER
	echo "Running rsync as user[ $USER ] on server [ $SERVER ] ..."
	sudo -u $USER rsync -azP -H --delete --numeric-ids /opt/$SERVER /opt/backups/$SERVER
	echo "Turning world save back on "
	sudo -u $USER tmux send-keys -t $SERVER "save-on" ENTER
	sudo -u $USER tmux send-keys -t $SERVER "say Server Backup Complete" ENTER
	echo "Backup Complete: `date`"
	echo "_+=------------------------------------=+_"	
fi

if [$debugging == 1]; then
	echo "_+=------------------------------------=+_" >> backuplog.txt
	echo "Starting Backup: `date`" >> backuplog.txt
	echo "Sending tmux commands to $SERVER server!"
	sudo -u $USER tmux send-keys -t $SERVER "say Starting Server Backup" ENTER
	echo "Sending save-all command to tmux session"
	sudo -u $USER tmux send-keys -t $SERVER "save-all" ENTER
	echo "Turning world save off for rsync backup"
	sudo -u $USER tmux send-keys -t $SERVER "save-off" ENTER
	echo "Running rsync as user[ $USER ] on server [ $SERVER ] ..."
	sudo -u $USER rsync -azP -H --delete --numeric-ids /opt/$SERVER /opt/backups/$SERVER
	echo "Turning world save back on "
	sudo -u $USER tmux send-keys -t $SERVER "save-on" ENTER
	sudo -u $USER tmux send-keys -t $SERVER "say Server Backup Complete" ENTER
	echo "Backup Complete: `date`" >> backuplog.txt
	echo "_+=------------------------------------=+_" >> backuplog.txt
		
fi
}

while getopts s:u:f: option
do
 case "${option}"
  in
  s) SERVER=${OPTARG:-"0"};;
  u) USER=${OPTARG:-"0"};;
  f) fname=${OPTARG:-"$DEFAULTBACKUPFILE"};;
 esac
done

if [$SERVER == "0" && $USER == "0"]; then
	for args in ($fname)
	do		
		if [$debugging == 2]; then
			./backup.sh "${args}" >> backuplog.txt			
		else	
			./backup.sh "${args}"			
		fi			
	done
else
	backup()
fi
