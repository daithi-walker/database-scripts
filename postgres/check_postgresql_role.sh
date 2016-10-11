#!/bin/bash
#/etc/keepalived/scripts/check_postgresql_role.sh
su -l postgres -c "pg_isready -d postgres"|grep 'accepting connections' 2>&1> /dev/null
if (( $? ));
        then 
                exit 1; 
        elif [ `su -l postgres -c "psql -c 'select pg_is_in_recovery();'|sed -n 3p|tr -d ' '"` == "f" ];
                then exit 0;
                else exit 1;
fi
