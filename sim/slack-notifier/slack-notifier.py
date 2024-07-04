#!/usr/bin/env python3
import os,sys,subprocess
from datetime import datetime, timezone, timedelta

if not os.path.isfile(sys.path[0]+'/slack-webhook-url.txt'):
    print('==============================================================')
    print('                             HOWDY!                           ')
    print('slack-notifier.py can help let you know when your sim is done.')
    print('To make it work, please supply your Slack bot webhook URL in:')
    print(sys.path[0]+'/slack-webhook-url.txt')
    print('Tutorial for slack webhook urls: https://bit.ly/BenSlackNotifier')
    print('==============================================================')
else:
    urlFile = open(sys.path[0]+'/slack-webhook-url.txt','r')
    url = urlFile.readline().strip('\n')

    # Traverse 3 parents up the process tree
    result = subprocess.check_output('ps -o ppid -p $PPID',shell=True)
    PPID2 = str(result).split('\\n')[1]
    result = subprocess.check_output('ps -o ppid -p '+PPID2,shell=True)
    PPID3 = str(result).split('\\n')[1]
    # Get command name
    result = subprocess.check_output('ps -o cmd -p '+PPID3,shell=True)
    cmdName = str(result).split('\\n')[1]
    # Get current time
    timezone_offset = -8.0  # Pacific Standard Time (UTC−08:00)
    tzinfo = timezone(timedelta(hours=timezone_offset))
    time = datetime.now(tzinfo).strftime('%I:%M %p')
    # Send message
    message = 'Command `'+cmdName+'` completed at '+time+' PST'
    result = subprocess.run('curl -X POST -H \'Content-type: application/json\' --data \'{"text":"'+message+'"}\' '+url,shell=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    print('Simulation stopped. Sending Slack message.')
