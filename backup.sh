#!/bin/bash
DEFAULTBACKUPFILE=/opt/backups/scripts/backup.conf
t0=`date +%FT%H%M%S`;
DEBUGGING=0
RETAIN_NUM_LINES=3100
LOGFILE=backuplog.txt
#rm -f backuplog.txt 
#DEBUGGING=(0/1/2) 
# 0  no logging
# 1  some logging
# 2  log everything

logsetup() {  
    TMP=$(tail -n $RETAIN_NUM_LINES $LOGFILE 2>/dev/null) && echo "${TMP}" > $LOGFILE
    exec > >(tee -a $LOGFILE)
    exec 2>&1
}
 log() {  
    echo "[$(date --rfc-3339=seconds)]: $*"
}

logsetup

dircheck(){
if [ -d "/opt/backups/$SERVER/$SERVER" ]; 
    then 
		echo ""
    else 
		borgint	
fi

}





borgint(){


sudo -u $USER borg init --encryption=none /opt/backups/$SERVER/$SERVER
t0="Firstrun"


}



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
	sudo -u $USER borg prune   -d 1 -w 1 -m 1 -y 1 --keep-within=1d /opt/backups/$SERVER/$SERVER
}
backup(){

dircheck
 
if [ $DEBUGGING -gt 0 ]; 
then 
	log startbk 
else 
	startbk 
fi

if [ $DEBUGGING -gt 1 ]; 
then 
	log saveall 
	log saveoff
	log runbackup 
	log saveon
	log prune
else 
	saveall 
	saveoff
	runbackup 
	saveon
	prune 
fi

if [ $DEBUGGING -gt 0 ]; 
then 
	log endbk 
else 
	endbk 
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

if [ $SERVER = "0" ] && [ $USER = "0" ]; 
then
	for args in $fname
	do		
		if [ $DEBUGGING -eq "2" ]; 
		then
			./backup.sh "${args}" >> backuplog.txt			
		else	
			./backup.sh "${args}"			
		fi			
	done
else
	backup
	
fi
echo " "
