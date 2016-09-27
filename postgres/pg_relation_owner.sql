--Source: http://cully.biz/2013/12/11/postgresql-getting-the-owner-of-tables/

select  t.table_name
,       t.table_type
--,       c.relowner  --id for owner
,       u.usename AS table_owner
from    information_schema.tables t
join    pg_catalog.pg_class c on (t.table_name = c.relname)
join    pg_catalog.pg_user u on (c.relowner = u.usesysid)
where   1=1
and     t.table_schema = 'mis3_api'
--and     c.relname = 'dwtest'
;