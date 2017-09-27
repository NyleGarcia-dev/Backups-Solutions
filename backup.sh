#!/bin/bash
DEFAULTBACKUPFILE=/opt/backups/scripts/backup.conf
DEBUGGING=0
#DEBUGGING=(0/1/2) 
# 0 being no logging
# 1 being some logging
# 2 being log everything
saveall(){
	echo "Sending save-all command to tmux session"
	sudo -u $USER tmux send-keys -t $SERVER "save-all" ENTER

}
saveoff(){
	echo "Turning world save off for backup"
	sudo -u $USER tmux send-keys -t $SERVER "save-off" ENTER

}
runbackup(){
	echo "Running backup as user[ $USER ] on server [ $SERVER ] ..."
	#Making incremental backup using attic
	sudo -u $USER borg create -v --stats /opt/backups/$SERVER/$SERVER::$t0 /opt/$SERVER 

}
saveon(){
	echo "Turning world save back on "
	sudo -u $USER tmux send-keys -t $SERVER "save-on" ENTER
}
prune(){
	echo "Running prune job to keep space available"
	# Keep all backups in the last 10 days, 4 additional end of week archives,
	# and an end of month archive for every month:
	sudo -u $USER borg prune   -d 1 -w 1 -m 1 -y 1 --keep-within=1d /opt/backups/$SERVER
}
backup(){
case "${DEBUGGING}"
  in
  0) 
  	echo "_+=------------------------------------=+_" 	
	echo "Starting Backup: " $t0	
	echo "Sending tmux commands to $SERVER server!"
	sudo -u $USER tmux send-keys -t $SERVER "say Starting Server Backup" ENTER
	saveall()
	saveoff()
	runbackup()
	saveon()
	prune()
	sudo -u $USER tmux send-keys -t $SERVER "say Server Backup Complete" ENTER

	echo "Backup Complete: `date`"	
	echo "_+=------------------------------------=+_"
  ;;
  

  1) USER=${OPTARG:-"0"}
  	echo "_+=------------------------------------=+_" >> backuplog.txt	
	echo "Starting Backup: " $t0 >> backuplog.txt	
	echo "Sending tmux commands to $SERVER server!"
	sudo -u $USER tmux send-keys -t $SERVER "say Starting Server Backup" ENTER
	saveall()
	saveoff()
	runbackup()
	saveon()
	prune()
	sudo -u $USER tmux send-keys -t $SERVER "say Server Backup Complete" ENTER

	echo "Backup Complete: `date`" >> backuplog.txt	
	echo "_+=------------------------------------=+_" >> backuplog.txt	
	

  ;;
  2) echo "Not implemented yet";;
 esac


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
		IFS=$' '       # make space the only separator
		for j in $(args)    
		do
			SERVER=$j
			USER=$j
		done
		backup()
			
	done
else
	backup()
fi
