#!/bin/bash
#/etc/keepalived/scripts/check_postgresql_status.sh
su -l postgres -c "pg_isready -d postgres"|grep 'accepting connections' 2>&1> /dev/null
if (( $? ));
    then 
        exit 1; 
    else 
        exit 0;
fi
