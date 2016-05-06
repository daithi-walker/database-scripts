select  nsp.nspname as schema_name
,       cl.relname
,       case cl.relkind
            when 'r' then 'ordinary table'
            when 'i' then 'index'
            when 'S' then 'sequence'
            when 'v' then 'view'
            when 'm' then 'materialized view'
            when 'c' then 'composite type'
            when 't' then 'TOAST table'
            when 'f' then 'foreign table'
            else 'Unknown'
        end relkind
,       pg_size_pretty(cl.relpages::bigint * 8 * 1024) as size        
,       cl.reltuples::bigint as rows
,       cl.relpages
,       cl.relfilenode
from    pg_class cl
,       pg_namespace nsp
where   1=1
and     cl.relnamespace = nsp.oid
and     nsp.nspname not in ('pg_toast','pg_catalog','public','repack','information_schema')
--and     nsp.nspname in ('adwords')
--and     cl.relname like 'import%'
--and     cl.relkind = 'r'
order by cl.relpages::bigint desc
limit 10
;