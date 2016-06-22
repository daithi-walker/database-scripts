-- Source https://wiki.postgresql.org/wiki/Index_Maintenance
-- Index summary
-- Here's a sample query to pull the number of rows, indexes,
-- and some info about those indexes for each table.
SELECT  pc.relname
,       pc.reltuples AS num_rows
,       COUNT(indexname) AS number_of_indexes
,       CASE
          WHEN x.is_unique = 1 THEN 'Y'
          ELSE 'N'
        END AS UNIQUE
,       SUM(
          CASE
            WHEN foo.number_of_columns = 1 THEN 1
            ELSE 0
          END
        ) AS single_column
,       SUM(
          CASE
            WHEN foo.number_of_columns IS NULL THEN 0
            WHEN foo.number_of_columns = 1 THEN 0
            ELSE 1
          END
        ) AS multi_column
FROM    pg_namespace pn
LEFT OUTER JOIN pg_class pc
        ON pn.oid = pc.relnamespace
LEFT OUTER JOIN
        (
        SELECT  pi.indrelid
        ,       MAX(CAST(pi.indisunique AS INTEGER)) AS is_unique
        FROM    pg_index pi
        GROUP BY pi.indrelid
        ) x
        ON pc.oid = x.indrelid
LEFT OUTER JOIN
        (
        SELECT  c.relname AS ctablename
        ,       ipg.relname AS indexname
        ,       x.indnatts AS number_of_columns
        FROM    pg_index x
        JOIN    pg_class c ON c.oid = x.indrelid
        JOIN    pg_class ipg ON ipg.oid = x.indexrelid
        ) AS foo
        ON pc.relname = foo.ctablename
WHERE   1=1
AND     pn.nspname='public' -- probably want your schema here.
AND     pc.relkind = 'r'
GROUP BY pc.relname
,        pc.reltuples
,        x.is_unique
ORDER BY num_rows DESC;