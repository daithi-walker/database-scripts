select   s.username
,        s.sid
,        s.serial#
,        s.last_call_et/60 mins_running
,        q.sql_text
from     v$session s
,        v$sqltext_with_newlines q
where    1=1
and      s.sql_address = q.address
and      s.status = 'ACTIVE'
and      s.type <>'BACKGROUND'
and      s.last_call_et > 60
and      s.sid = 66
order by s.sid
,        s.serial#
,        q.piece
;