select  a.sid
,       a.username
,       b.sql_id
,       b.sql_fulltext
from    v$session a
,       v$sql b
where   1=1
and     a.sql_id = b.sql_id
and     a.status = 'ACTIVE'
and     a.username != 'SYS';