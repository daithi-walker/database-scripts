-- Source: https://wiki.postgresql.org/wiki/Index_Maintenance
-- Index size/usage statistics
-- Table & index sizes along which indexes are being scanned
-- and how many tuples are fetched. See Disk Usage for another
-- view that includes both table and index sizes.

SELECT  t.tablename
,       foo.indexname
,       c.reltuples AS num_rows
,       pg_size_pretty(pg_relation_size(t.schemaname||'.'||quote_ident(t.tablename)::text)) AS table_size
,       pg_size_pretty(pg_relation_size(foo.schemaname||'.'||quote_ident(foo.indexrelname)::text)) AS index_size
,       CASE
            WHEN foo.indisunique THEN 'Y'
            ELSE 'N'
        END AS UNIQUE
,       foo.idx_scan AS number_of_scans
,       foo.idx_tup_read AS tuples_read
,       foo.idx_tup_fetch AS tuples_fetched
FROM    pg_tables t
LEFT OUTER JOIN pg_class c
        ON t.tablename = c.relname
LEFT OUTER JOIN
        (
        SELECT  c.relname AS ctablename
        ,       ipg.relname AS indexname
        ,       x.indnatts AS number_of_columns
        ,       idx_scan
        ,       idx_tup_read
        ,       idx_tup_fetch
        ,       indexrelname
        ,       psai.schemaname
        ,       indisunique
        FROM    pg_index x
        JOIN pg_class c
                ON c.oid = x.indrelid
        JOIN pg_class ipg
                ON ipg.oid = x.indexrelid
        JOIN pg_stat_all_indexes psai
                ON x.indexrelid = psai.indexrelid
        ) AS foo
        ON t.tablename = foo.ctablename
WHERE   1=1
--AND     t.schemaname = 'public'
ORDER BY pg_relation_size(foo.schemaname||'.'||quote_ident(foo.indexrelname)::text) DESC NULLS LAST;