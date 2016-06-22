-- query lists the owned for an index.
-- Source: Unknown

SELECT  pn.nspname as "schema"
,       pc.relname as "name"
,       CASE pc.relkind
            WHEN 'r' THEN 'table'
            WHEN 'v' THEN 'view'
            WHEN 'i' THEN 'index'
            WHEN 'S' THEN 'sequence'
            WHEN 's' THEN 'special'
        END as "type"
,       pu.usename as "owner"
,       pc2.relname as "table"
FROM    pg_catalog.pg_class pc
JOIN    pg_catalog.pg_index pi ON pi.indexrelid = pc.oid
JOIN    pg_catalog.pg_class pc2 ON pi.indrelid = pc2.oid
LEFT JOIN pg_catalog.pg_user pu ON pu.usesysid = pc.relowner
LEFT JOIN pg_catalog.pg_namespace pn ON pn.oid = pc.relnamespace
WHERE   1=1
AND     pn.nspname NOT IN ('pg_catalog', 'pg_toast')
and     pc.relkind IN ('i','')
and     pc.relname = 'date_ext_plat_idx'
--AND     pg_catalog.pg_table_is_visible(pc.oid)  --doesnt work for some reason?
ORDER BY schema
,        name;