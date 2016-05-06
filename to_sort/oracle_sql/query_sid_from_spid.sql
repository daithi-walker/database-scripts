select vp.spid
,      vs.sid
from   v$session vs
,      v$process vp
where  1=1
and    vs.paddr = vp.addr
and    vp.spid = :PID --13006
and    vs.sid = :SID --324
;