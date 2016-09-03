--explain
select  *
from    (
select  pr.rolname
,       pn.nspname||'.'||pc.relname AS relation
,       has_table_privilege(pr.rolname, pn.nspname||'.'||pc.relname,'SELECT') AS sel
,       has_table_privilege(pr.rolname, pn.nspname||'.'||pc.relname,'INSERT') AS ins
,       has_table_privilege(pr.rolname, pn.nspname||'.'||pc.relname,'UPDATE') AS upd
,       has_table_privilege(pr.rolname, pn.nspname||'.'||pc.relname,'DELETE') AS del
,       has_table_privilege(pr.rolname, pn.nspname||'.'||pc.relname,'TRUNCATE') AS trunc
,       has_table_privilege(pr.rolname, pn.nspname||'.'||pc.relname,'REFERENCES') AS ref
,       has_table_privilege(pr.rolname, pn.nspname||'.'||pc.relname,'TRIGGER') AS trig
from    pg_class pc
,       pg_namespace pn
,       pg_roles pr
where   1=1
and     pn.oid = pc.relnamespace
--and     pc.relname like 'import%'
--and     pr.rolname in ('o3_readonly')
--and     pn.nspname = 'olive'
order by pr.rolname
,        pn.nspname||'.'||pc.relname
--limit 10
) a
where   1=1
AND     (a.sel OR a.ins OR a.upd OR a.del OR a.trunc OR a.ref OR a.trig)
;