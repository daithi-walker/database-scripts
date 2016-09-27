#!/bin/bash

DATE="`date -d '5 minutes ago' +'%Y-%m-%d %H:%M'`"

FILELIST="`find /var/log/postgresql/ -name 'postgresql*.log' -mmin -5`"

LINE_NO="`cat ${FILELIST} | grep -n "^\[${DATE}" | head -1 | cut -d':' -f1`"

COUNT="`cat ${FILELIST} | tail -n+${LINE_NO} | egrep ' ERROR: ' | wc -l`"

if [ -z "$COUNT" ]
then
   echo 'check_postgres_logs: errors during script execution'
   exit 3
fi

if [ $COUNT -gt 0 ]
then
   echo 'PostgreSQL errors: '
   echo
   cat ${FILELIST} | tail -n+${LINE_NO} | egrep ' ERROR: '
   exit 1
fi

exit 0
