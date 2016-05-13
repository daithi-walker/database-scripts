SELECT 	psut.schemaname AS SCHEMA
,       psut.relname AS TABLE
,       pg_size_pretty(pg_total_relation_size(psut.relid)) AS SIZE
,       pg_size_pretty(pg_total_relation_size(psut.relid) - pg_relation_size(psut.relid)) AS EXTERNAL_SIZE
FROM    pg_catalog.pg_statio_user_tables psut
WHERE   1=1
--AND     psut.schemaname = 'ds3'
AND     psut.relname LIKE 'import%'
ORDER BY pg_total_relation_size(psut.relid) DESC
LIMIT 20;


SELECT  pn.nspname || '.' || pc.relname AS RELATION
,       pg_size_pretty(pg_relation_size(pc.oid)) AS SIZE
FROM    pg_class pc
,       pg_namespace pn
WHERE   1=1
AND     pn.oid = pc.relnamespace
AND     pn.nspname NOT IN ('pg_catalog', 'information_schema')
--AND     pc.relname LIKE '%imp%'
ORDER BY pg_relation_size(pc.oid) DESC
LIMIT 20;


SELECT  sub.nspname AS SCHEMA
,       pg_size_pretty(sub.size) AS SIZE
FROM    (
        SELECT  nspname
        ,       SUM(pg_relation_size(pc.oid)) size
        FROM    pg_class pc
        ,       pg_namespace pn
        WHERE   1=1
        AND     pn.oid = pc.relnamespace
        AND     pn.nspname NOT IN ('pg_catalog', 'information_schema')
        --AND     pc.relname LIKE '%imp%'
        GROUP BY pn.nspname
        HAVING   SUM(pg_relation_size(pc.oid)) > 1073741824
        ORDER BY SUM(pg_relation_size(pc.oid)) DESC
        ) sub
ORDER BY sub.size DESC
LIMIT 20;

SELECT  nsp.nspname AS SCHEMA
,       cl.relname AS RELATION
,       CASE cl.relkind
            WHEN 'r' THEN 'ordinary table'
            WHEN 'i' THEN 'index'
            WHEN 'S' THEN 'sequence'
            WHEN 'v' THEN 'view'
            WHEN 'm' THEN 'materialized view'
            WHEN 'c' THEN 'composite type'
            WHEN 't' THEN 'TOAST table'
            WHEN 'f' THEN 'foreign table'
            ELSE 'Unknown'
        END AS RELATION_TYPE
,       pg_size_pretty(cl.relpages::bigint * 8 * 1024) AS SIZE
,       cl.reltuples::bigint AS ROWS
,       cl.relpages AS PAGES
,       cl.relfilenode FILE_NODE
FROM    pg_class cl
,       pg_namespace nsp
WHERE   1=1
AND     cl.relnamespace = nsp.oid
AND     nsp.nspname NOT IN ('pg_toast','pg_catalog','public','repack','information_schema')
--AND     nsp.nspname IN ('ds3')
--AND     cl.relname LIKE 'import%'
--AND     cl.relkind = 'r'
ORDER BY cl.relpages::bigint DESC
LIMIT 10
;