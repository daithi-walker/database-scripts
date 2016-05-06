-- Query to identify grants from missing schemas and add them to ddl
select  vsql
from    (
        select  table_schema
        ,       vsql
        from    (
                select  distinct t.table_schema, 'GRANT SELECT ON ALL TABLES IN SCHEMA '||t.table_schema||' TO ds_readonly;' vsql
                from    information_schema.tables t
                where   1=1
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
                union all
                select  distinct t.table_schema, 'GRANT ALL ON ALL TABLES IN SCHEMA '||t.table_schema||' TO datasystems;' vsql
                from    information_schema.tables t
                where   1=1
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
                ) a
        order by table_schema
        ,        vsql
        ) b;