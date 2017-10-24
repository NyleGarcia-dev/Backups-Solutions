#!/bin/bash
Backupdir=""
Source=""

bktime=1m



dircheck(){

	if [ -d "$Backupdir" ]; 
		then 
		 
		 
		else
			 mkdir -p $Backupdir
			 borgint
	fi


	
}
borgint(){
	 borg init --encryption=none $Backupdir
	t0="Firstrun"
}
startbk(){
  	echo "_+=------------------------------------=+_" 	
	echo "Starting Backup: " $t0	
	
}
endbk(){
	echo "Backup Complete: `date`"	
	echo "_+=------------------------------------=+_"

}

runbackup(){
	echo "Backing up source[ $Source ] to [ $Backupdir ] ..."
	#Making incremental backup using borg
	 borg create -v --stats $Backupdir::$t0 $Source 

}

prune(){
	echo "Running prune job to keep space available"
	# Keep all backups in the last 10 days, 4 additional end of week archives,
	# and an end of month archive for every month:
	 borg prune -v --list --keep-within=1d   --keep-daily=7 --keep-weekly=4  --keep-monthly=1 $Backupdir
}
backup(){
	dircheck
	startbk 
	runbackup 
	prune
	endbk 
}


while getopts s:d: option
do
 case "${option}"
  in
  s) Source=${OPTARG:-"0"};;
  d) Backupdir=${OPTARG:-""};;
 esac 

 
done


while :
do
t0=`date +%FT%H%M%S`;

backup
echo "  "
echo "  "
echo "  "
sleep $bktime
done


