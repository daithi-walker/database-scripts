select  relname
,       tgname
,       tgtype
,       proname
,       prosrc
--,       tgisconstraint
--,       tgconstrname
,       tgconstrrelid
,       tgdeferrable
,       tginitdeferred
,       tgnargs
,       tgattr
,       tgargs
from    pg_trigger
join pg_class on (tgrelid=pg_class.oid)
join pg_proc on (tgfoid=pg_proc.oid)
where   1=1
and     tgrelid = 'olive.line_lineitem'::regclass
;


SELECT tgname
FROM   pg_trigger
WHERE  tgrelid = 'olive.line_lineitem'::regclass;

-- trigger definition
select pg_get_functiondef(oid)
from pg_proc
where proname = 'RI_FKey_check_upd';