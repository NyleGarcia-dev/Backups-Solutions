#!/bin/bash
#set time stamp for current run.
t0=`date +%FT%H%M%S`;
#pull args from options
while getopts s:u: option
do
 case "${option}"
  in
  s) SERVER=${OPTARG};;
  u) USER=${OPTARG};;
 esac
done
#let the log and users know what's going on.
echo "_+=------------------------------------=+_"
echo "Starting Backup: " $t0
echo "Sending tmux commands to $SERVER server!"
sudo -u $USER tmux send-keys -t $SERVER "say Starting Server Backup" ENTER
echo "Sending save-all command to tmux session"
sudo -u $USER tmux send-keys -t $SERVER "save-all" ENTER
echo "Turning world save off for backup"
sudo -u $USER tmux send-keys -t $SERVER "save-off" ENTER
echo "Running backup as user[ $USER ] on server [ $SERVER ] ..."
#Making incremental backup using attic
sudo -u $USER borg create -v --stats /opt/backups/$SERVER/$SERVER::$t0 /opt/$SERVER 
echo "Turning world save back on "
sudo -u $USER tmux send-keys -t $SERVER "save-on" ENTER
sudo -u $USER tmux send-keys -t $SERVER "say Server Backup Complete" ENTER
echo "Running prune job to keep space available"
# Keep all backups in the last 10 days, 4 additional end of week archives,
# and an end of month archive for every month:
sudo -u $USER borg prune   -d 1 -w 1 -m 1 -y 1 --keep-within=1d /opt/backups/$SERVER
echo "Backup Complete: `date`"
echo "_+=------------------------------------=+_"
