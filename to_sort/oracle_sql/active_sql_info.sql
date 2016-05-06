select a.sid
,      a.serial#
,      a.username
,      a.status
,      a.osuser
,      b.sql_fulltext
from   v$session a
,      v$sql b
where  1=1
and    a.sql_id = b.sql_id (+)
and    a.osuser = SYS_CONTEXT('USERENV','OS_USER');

select * from v$session where osuser = SYS_CONTEXT('USERENV','OS_USER');

select * from v$sql where sql_id = :sql_id;