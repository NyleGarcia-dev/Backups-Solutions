#!/bin/bash
SERVER="0"
USER="minecraft"
fname=./backup.conf
t0=`date +%FT%H%M%S`;
DEBUGGING=0
RETAIN_NUM_LINES=3100
LOGFILE=backuplog.txt
#rm -f backup.txt 
#DEBUGGING=(0/1/2) 
# 0  no ging
# 1  some ging
# 2   everything




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
		 startbk 
	else 
		startbk 
	fi

	if [ $DEBUGGING -gt 1 ]; 
	then 
		 saveall 
		 saveoff
		 runbackup 
		 saveon
		 prune
	else 
		saveall 
		saveoff
		runbackup 
		saveon
		prune 
	fi

	if [ $DEBUGGING -gt 0 ]; 
	then 
		 endbk 
	else 
		endbk 
	fi


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
