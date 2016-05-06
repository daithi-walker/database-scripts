SELECT  psut.schemaname
,       psut.relname as "Table"
,       pg_size_pretty(pg_total_relation_size(psut.relid)) As "Size"
,       pg_size_pretty(pg_total_relation_size(psut.relid) - pg_relation_size(psut.relid)) as "External Size"
FROM    pg_catalog.pg_statio_user_tables psut
WHERE   1=1
AND     psut.relname like 'import%'
ORDER BY pg_total_relation_size(psut.relid) DESC
LIMIT 20;


SELECT  pn.nspname || '.' || pc.relname AS "relation"
,       pg_size_pretty(pg_relation_size(pc.oid)) AS "size"
FROM    pg_class pc
,       pg_namespace pn
WHERE   1=1
AND     pn.oid = pc.relnamespace
AND     pn.nspname NOT IN ('pg_catalog', 'information_schema')
--AND     pc.relname LIKE '%imp%'
ORDER BY pg_relation_size(pc.oid) DESC
LIMIT 20;


SELECT  sub.nspname
,       pg_size_pretty(sub.size)
FROM    (
        SELECT  nspname
        ,       SUM(pg_relation_size(pc.oid)) size
        FROM    pg_class pc
        ,       pg_namespace pn
        WHERE   1=1
        AND     pn.oid = pc.relnamespace
        AND     pn.nspname NOT IN ('pg_catalog', 'information_schema')
        --AND     pc.relname like '%imp%'
        GROUP BY pn.nspname
        HAVING   SUM(pg_relation_size(pc.oid)) > 1073741824
        ORDER BY SUM(pg_relation_size(pc.oid)) DESC
        ) sub
LIMIT 20;