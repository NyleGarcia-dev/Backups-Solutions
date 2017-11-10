#!/bin/bash
SERVER="0"
USER="minecraft"
fname=/opt/backup.conf
t0=`date +%FT%H%M%S`;
RETAIN_NUM_LINES=3100
BOTNAME=PotatoHook
DISCORDHOOK=link
TOSEND="you have been backed up by a potato"
NICK="Potato"



function logsetup {  
    TMP=$(tail -n $RETAIN_NUM_LINES $LOGFILE 2>/dev/null) && echo "${TMP}" > $LOGFILE
    exec > >(tee -a $LOGFILE)
    exec 2>&1
}
function log {  
    echo "[$(date --rfc-3339=seconds)]: $*"
}
webhook(){
LOGPASTE=$(fpaste -n $NICK  $LOGFILE | grep https://paste.fedoraproject.org/ | awk '{print $3}')

curl -X POST \
  $DISCORDHOOK \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'postman-token: fd3e4d9a-c59f-d5d4-2e8b-769e3b4ce230' \
  -d '{
  "username":"'"$BOTNAME"'",
  "avatar_url": "https://i.imgur.com/4M34hi2.png",
  "content":"'"$TOSEND"'",
 "embeds": [
    {
      "author": {
        "name": "Backup:"
      },
	  "title":"'"$SERVER"'",
      "description": "A backup has been ran on '"$SERVER"' here is a full [log]('"$LOGPASTE"')",
      "color": 1101584,
      "fields": [
        {
          "name": "Start Time",
		  "value":"'"$D1"'",
          "inline": false
        },
        {
          "name": "End Time",
          "value":"'"$D2"'",
          "inline": false
        }
      ]
    }
  ]
}'

echo " "
}
dircheck(){

	if [ -d "/opt/backups/$SERVER" ]; 
		then
			echo dir found
		else 
			sudo -u $USER mkdir -p /opt/backups/$SERVER/$SERVER
			borgint
	fi


	
}
borgint(){
	sudo -u $USER borg init --encryption=none /opt/backups/$SERVER/$SERVER
	t0="Firstrun"
}
startbk(){
	D1=`date`;
  	echo "_+=------------------------------------=+_" 	
	echo "Starting Backup: " $t0	
	echo "Sending tmux commands to $SERVER server!"
	sudo -u $USER tmux send-keys -t $SERVER "say Starting Server Backup" ENTER
}
endbk(){
	sudo -u $USER tmux send-keys -t $SERVER "say Server Backup Complete" ENTER
	echo "Backup Complete: `date`"	
	echo "_+=------------------------------------=+_"
	D2=`date`;
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
	sudo -u $USER borg prune -v --list --keep-within=1d   --keep-daily=7 --keep-weekly=4  --keep-monthly=1 /opt/backups/$SERVER/$SERVER
}
backup(){
LOGFILE=/opt/backups/$SERVER/backuplog.txt
rm -rf $LOGFILE
logsetup

	dircheck
	startbk 
	saveall 
	saveoff
	runbackup 
	saveon
	prune
	endbk 
	df -h
	webhook
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

