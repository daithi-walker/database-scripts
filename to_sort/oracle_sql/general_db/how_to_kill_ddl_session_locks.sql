select   osuser
,        'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||''' IMMEDIATE;'
from     v$session
where    1=1
and      status = 'INACTIVE'
and      upper(osuser) like 'VERSION1%'
--where osuser = 'DWALKER'
;

SELECT * FROM  V$DB_OBJECT_CACHE WHERE NAME LIKE '%ROS%PROCESS%' and locks > 0;

SELECT s.sid,
s.serial#,
s.osuser,
s.status,
s.program,
s.blocking_instance,
s.blocking_session 
FROM v$session s
--wwhere osuser = 'DWALKER'
order by 4
;

SELECT   session_id sid
,        owner||'.'||name object_name
,        type
,        mode_held held
,        mode_requested request
FROM     dba_ddl_locks
WHERE    1=1
AND      name LIKE UPPER('%ROS%PROCESS%');