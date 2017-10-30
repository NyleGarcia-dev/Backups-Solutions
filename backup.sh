#!/bin/bash
SERVER="0"
USER="minecraft"
fname=./backup.conf
t0=`date +%FT%H%M%S`;
DEBUGGING=0
RETAIN_NUM_LINES=3100

#rm -f backup.txt 


dircheck(){

	if [ -d "/opt/backups/$SERVER" ]; 
		then
		echo Dir found  >> /opt/backups/$SERVER/backup.log
		else 
			sudo -u $USER mkdir -p /opt/backups/$SERVER >> /opt/backups/$SERVER/backup.log
			borgint
	fi


	
}
borgint(){
	sudo -u $USER borg init --encryption=none /opt/backups/$SERVER/$SERVER >> /opt/backups/$SERVER/backup.log
	t0="Firstrun"
}
startbk(){
  	echo "_+=------------------------------------=+_" 	 >> /opt/backups/$SERVER/backup.log
	echo "Starting Backup: " $t0	 >> /opt/backups/$SERVER/backup.log
	echo "Sending tmux commands to $SERVER server!" >> /opt/backups/$SERVER/backup.log
	sudo -u $USER tmux send-keys -t $SERVER "say Starting Server Backup" ENTER >> /opt/backups/$SERVER/backup.log
}
endbk(){
	sudo -u $USER tmux send-keys -t $SERVER "say Server Backup Complete" ENTER >> /opt/backups/$SERVER/backup.log
	echo "Backup Complete: `date`"	 >> /opt/backups/$SERVER/backup.log
	echo "_+=------------------------------------=+_" >> /opt/backups/$SERVER/backup.log

}
saveall(){
	echo "Sending save-all command to tmux session" >> /opt/backups/$SERVER/backup.log
	sudo -u $USER tmux send-keys -t $SERVER "save-all" ENTER >> /opt/backups/$SERVER/backup.log

}
saveoff(){
	echo "Turning world save off for backup" >> /opt/backups/$SERVER/backup.log
	sudo -u $USER tmux send-keys -t $SERVER "save-off" ENTER >> /opt/backups/$SERVER/backup.log

}
runbackup(){
	echo "Running backup as user[ $USER ] on server [ $SERVER ] ..." >> /opt/backups/$SERVER/backup.log
	#Making incremental backup using attic
	sudo -u $USER borg create -v --stats /opt/backups/$SERVER/$SERVER::$t0 /opt/$SERVER  >> /opt/backups/$SERVER/backup.log

}
saveon(){
	echo "Turning world save back on " >> /opt/backups/$SERVER/backup.log
	sudo -u $USER tmux send-keys -t $SERVER "save-on" ENTER >> /opt/backups/$SERVER/backup.log 
}
prune(){
	echo "Running prune job to keep space available" >> /opt/backups/$SERVER/backup.log
	# Keep all backups in the last 10 days, 4 additional end of week archives,
	# and an end of month archive for every month:
	sudo -u $USER borg prune -v --list --keep-within=1d   --keep-daily=7 --keep-weekly=4  --keep-monthly=1 /opt/backups/$SERVER/$SERVER >> /opt/backups/$SERVER/backup.log
}
backup(){

	dircheck 
	startbk 
	saveall 
	saveoff 
	runbackup 
	saveon 
	prune 
	endbk 
}


while getopts s:u:f: option
do
 case "${option}"
  in
  s) SERVER=${OPTARG:-"0"};;
  u) USER=${OPTARG:-"minecraft"};;
  f) fname=${OPTARG:-"${DEFAULTBACKUPFILE}"};;
 esac
done




if [[ $SERVER = "0" ]]; 
then
echo "  $SERVER - - - $USER  ---- $fname "
	while read args; do
		echo "${args}"
		IFS=' ' read -a myarray <<< "${args}"
		index=0
		
		for i in ${myarray[@]};
		do 
			if [[ $i = "-u" ]]; 
			then
				USER=${myarray[ index + 1 ]}
		
			fi
			
			if [[ $i = "-s" ]]; 
			then
				SERVER=${myarray[ index + 1 ]}
			fi

			index=$((index+1))
		done
		
		echo "Backing up -u $USER -s $SERVER "
		backup
		
	done <${fname}

else
	backup
	
fi
echo "  "
echo "  "
echo "  "
