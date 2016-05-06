-- Query to identify grants from missing views and add them to ddl
select  *
from    (
        select  t.table_schema||'.'||t.table_name det
        ,       'GRANT ALL ON '||t.table_schema||'.'||t.table_name||' TO datasystems;' sql1
        from    information_schema.tables t
        where   1=1
        and     t.table_catalog = 'mis'
        --and     t.table_type = 'VIEW'
        and     t.table_schema not in ('repack','pg_catalog','information_schema','finance_reports','nw_stage','public','reporting')
        and     not exists
                (
                select  null
                from    information_schema.role_table_grants  g
                where   1=1
                and     g.table_schema = t.table_schema
                and     g.table_name = t.table_name
                and     g.grantee = 'datasystems'
                )
        union all
        select  t.table_schema||'.'||t.table_name
        ,       'GRANT SELECT ON '||t.table_schema||'.'||t.table_name||' TO ds_readonly;' sql1
        from    information_schema.tables t
        where   1=1
        and     t.table_catalog = 'mis'
        --and     t.table_type = 'VIEW'
        and     t.table_schema not in ('repack','pg_catalog','information_schema','finance_reports','nw_stage','public','reporting')
        and     not exists
                (
                select  null
                from    information_schema.role_table_grants  g
                where   1=1
                and     g.table_schema = t.table_schema
                and     g.table_name = t.table_name
                and     g.grantee = 'ds_readonly'
                )
        ) sub
order by 1;