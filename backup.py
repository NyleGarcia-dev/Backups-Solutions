#!/usr/bin/env python3
import requests
import json
import time
import sys
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import email
import smtplib
import logging
import os
import glob
import re
import random
import subprocess
import multiprocessing as mp
from datetime import datetime

url = ""

LOG_FILENAME = 'log.txt'
LEVELS = {'debug': logging.DEBUG,
          'info': logging.INFO,
          'warning': logging.WARNING,
          'error': logging.ERROR,
          'critical': logging.CRITICAL}

if len(sys.argv) > 1:
    level_name = sys.argv[1]
else:
    level_name = 'debug'

level = LEVELS.get(level_name, logging.NOTSET)
logging.basicConfig(filename=LOG_FILENAME,level=level)

Config = []
with open('/opt/Config.json') as config_file:
     Config = json.load(config_file)


def webhook(name='Potato',EMBEDS=[]):

    

    headers = {
        'Content-Type': "application/json",
        'User-Agent': "PostmanRuntime/7.15.0",
        'Cache-Control': "no-cache",
        'Postman-Token': "67b0f650-82f1-40a4-a136-4b233bb659c9,4da3521f-221a-4a27-9593-017d70b5d0a2",
        'Host': "discordapp.com",
        'content-length': "36",
        'Connection': "keep-alive",
        'cache-control': "no-cache"
        }

    payload = {
        'username': name,
        'content': "You have been backed up by a potato",
        'embeds':EMBEDS
        }

    response = requests.request("POST", url, json=payload, headers=headers)

    print(response.text)

def get_ts():

    return '{:%Y-%m-%dT%H%M%S}'.format(datetime.now())


def borgint(USER='minecraft',Encryption='none',BKPATH=''):
    tmp = subprocess.Popen(['sudo', 'mkdir','-p',BKPATH])
    tmp = subprocess.Popen(['sudo', 'chmod','-R','777',BKPATH])
    tmp = subprocess.Popen(['sudo','-u',USER,'borg','init','--encryption='+Encryption,BKPATH], stdout = subprocess.PIPE).communicate()[0]



def startbk():
    
    print( "_+=------------------------------------=+_")
    print( "Starting Backup: " +datetime.now())


def endbk():
    print( "Backup Complete: " + datetime.now())  
    print( "_+=------------------------------------=+_")
    

def saveAll(USER='minecraft',Tmux_session=""):
    print( "Sending save-all command to tmux session")
    tmp = subprocess.Popen(['sudo','-u',USER,'tmux','send-keys','-t',Tmux_session,'"save-all"','ENTER'], stdout = subprocess.PIPE).communicate()[0]
    return tmp

def saveOff(USER='minecraft',Tmux_session=""):
    print( "Turning world save off for backup")
    tmp = subprocess.Popen(['sudo','-u',USER,'tmux','send-keys','-t',Tmux_session,'"save-all"','ENTER'], stdout = subprocess.PIPE).communicate()[0]
    return tmp

def saveON(USER='minecraft',Tmux_session=""):
    print( "Turning world save back on")
    tmp = subprocess.Popen(['sudo','-u',USER,'tmux','send-keys','-t',Tmux_session,'"save-all"','ENTER'], stdout = subprocess.PIPE).communicate()[0]
    return tmp

def runBackup(USER='minecraft',BKPATH='',Source='',Tmux_session=''):
    
    print( 'Running backup as user['+USER+'] on server ['+Tmux_session+'] ...')
    tmp = subprocess.Popen(['sudo','-u',USER,'borg','create','-v','--stats','-C','zlib,3',BKPATH+"::"+get_ts(),Source], stdout = subprocess.PIPE,stderr=subprocess.PIPE).communicate()
    return tmp

def prune(USER='minecraft',BKPATH='',Days='5d',Daily='5',Weekly='3',Monthly='5'):
    print( "Running prune job to keep space available")
    # Keep all backups in the last 10 days, 4 additional end of week archives,
    # and an end of month archive for every month:
    tmp = subprocess.Popen(['sudo','-u',USER,'borg','prune','-v','--list','--keep-within='+Days,'--keep-daily='+Daily,'--keep-weekly='+Weekly,'--keep-monthly='+Monthly,BKPATH], stdout = subprocess.PIPE).communicate()[0]
    return tmp

def getDriveSpace():
    return subprocess.Popen(['df','-h','./'], stdout = subprocess.PIPE,stderr=subprocess.PIPE).communicate()


def Backup(Serverindex):


    print('Starting - '+str(Serverindex))
    Server=Config['Servers'][Serverindex]
    BKPath=Server['BackupPATH']
    USER=Server['User']
    Tmux_session = Server['Tmux-session']

    if os.path.exists(BKPath) == False:
        borgint(USER,Server['Encryption'],BKPath)
    if Server['Saving']['Force save'] == True:
        saveAll(USER,Tmux_session)
    if Server['Saving']['Save Off'] == True:
        saveOff(USER,Tmux_session)
    ST=str(datetime.now())
    Backupcheck = runBackup(USER,BKPath,Server['Source-Path'],Server['Name'])
    ET=str(datetime.now())
    prune(USER,BKPath,Server['prune']['Days'],Server['prune']['Daily'],Server['prune']['Weekly'],Server['prune']['Monthly'])
    if Server['Saving']['Save Off'] == True:
        saveON(USER,Tmux_session)

    # if Backupcheck[2] == 'none':
    #      color = 1101584
    # else:
    #     color = 16711680

    drivespace = str(getDriveSpace()[0].decode('ascii'))
    Backupstats={
      'author': {
        'name': "Backup:"+ Server['Name']
      },
	  'title': Server['Name'],
      'description': str(Backupcheck[1].decode('ascii')),
      'color': 1101584,
      'fields': [
        {
          'name': "Start Time",
		  'value': ST,
          'inline': False
        },
        {
          'name': "End Time",
          'value': ET,
          'inline': True
        },
        {
          'name': "Disk space",
          'value': drivespace,
          'inline': False
        }
      ]
    }

    return Backupstats


def Parrelles():
    pool_size = Config['Max-Threads']
    pool = mp.Pool(processes=pool_size)
    ServerCount=len(Config['Servers'])
    results = pool.map(Backup,range(0,ServerCount))    

    webhook('Potato keeper 2.0',results)



def main():

    Parrelles()



try:
    if __name__== "__main__":
        main()

except Exception as e:
    logging.exception(e)
    os.system(r'mv ./log.txt ./logs/'+datetime.now()+'log.txt')

    

