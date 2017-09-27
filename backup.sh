#!/bin/bash
DEFAULTBACKUPFILE=/opt/backups/scripts/backup.conf
DEBUGGING=0
RETAIN_NUM_LINES=100000
LOGFILE=backuplog.txt
#rm -f backuplog.txt 
#DEBUGGING=(0/1/2) 
# 0 being no logging
# 1 being some logging
# 2 being log everything

logsetup() {  
    TMP=$(tail -n $RETAIN_NUM_LINES $LOGFILE 2>/dev/null) && echo "${TMP}" > $LOGFILE
    exec > >(tee -a $LOGFILE)
    exec 2>&1
}
 log() {  
    echo "[$(date --rfc-3339=seconds)]: $*"
}

logsetup


startbk(){
  	echo "_+=------------------------------------=+_" 	
	echo "Starting Backup: " $t0	
	echo "Sending tmux commands to $SERVER server!"
	sudo -u $USER tmux send-keys -t $SERVER "say Starting Server Backup" ENTER
}
endbk(){
	sudo -u $USER tmux send-keys -t $SERVER "say Server Backup Complete" ENTER
	echo "Backup Complete: `date`"	
	echo "_+=------------------------------------=+_"

}
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
 
if [DEBUGGING > 0]; then log startbk else startbk fi
if [DEBUGGING > 1]; then log saveall else saveall fi
if [DEBUGGING > 1]; then log saveoff else saveoff fi
if [DEBUGGING > 1]; then log runbackup else runbackup fi
if [DEBUGGING > 1]; then log saveon else saveon fi
if [DEBUGGING > 1]; then log prune else prune fi
if [DEBUGGING > 0]; then log endbk else endbk fi


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
