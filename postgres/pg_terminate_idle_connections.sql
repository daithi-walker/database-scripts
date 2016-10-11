--Source: http://stackoverflow.com/questions/12391174/how-to-close-idle-connections-in-postgresql-automatically/30769511#30769511

WITH inactive_connections_list AS (
    SELECT  pid
    ,       rank() over (partition by client_addr order by backend_start ASC) as rank
    FROM    pg_stat_activity
    WHERE   1=1
    -- Exclude the thread owned connection (ie no auto-kill)
    AND     pid <> pg_backend_pid( )
    -- Exclude known applications connections
    --AND     application_name !~ '(?:psql)|(?:pgAdmin.+)'
    -- Include connections to the same database the thread is connected to
    AND     datname = current_database() 
    -- Include connections using the same thread username connection
    --AND     usename = current_user 
    -- Include inactive connections only
    AND     state in ('idle', 'idle in transaction', 'idle in transaction (aborted)', 'disabled') 
    -- Include old connections (found with the state_change field)
    AND     current_timestamp - state_change > interval '5 minutes' 
)
SELECT  --pg_terminate_backend(pid)
        pid
FROM    inactive_connections_list 
WHERE   1=1
AND     rank > 1 -- Leave one connection for each application connected to the database
;