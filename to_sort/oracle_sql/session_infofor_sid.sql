select vp.spid
,      vs.sid
,      vs.event
,      vs.state
,      vs.sql_id
,      vs.prev_sql_id
,      vs.seconds_in_wait
,      vs.p1
,      vs.p1raw
,      vs.p1text
,      vs.p2
,      vs.p2text
,      vs.p3
,      vs.p3text
,      vs.row_wait_obj#
,      vs.plsql_object_id
,      vs.plsql_subprogram_id
from   v$session vs
,      v$process vp
where  1=1
and    vs.paddr = vp.addr
--and    vp.spid = :PID
and    vs.sid = :SID
;