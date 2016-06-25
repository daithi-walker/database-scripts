-- Source: https://wiki.postgresql.org/wiki/Index_Maintenance
-- Duplicate indexes
-- Finds multiple indexes that have the same set of columns,
-- same opclass, expression and predicate -- which make them
-- equivalent. Usually it's safe to drop one of them, but no
-- guarantees.

SELECT  pg_size_pretty(SUM(pg_relation_size(idx))::BIGINT) AS SIZE
,       (array_agg(idx))[1] AS idx1
,       (array_agg(idx))[2] AS idx2
,       (array_agg(idx))[3] AS idx3
,       (array_agg(idx))[4] AS idx4
FROM    (
        SELECT  indexrelid::regclass AS idx
        ,       (
                indrelid::TEXT              ||E'\n'||
                indclass::TEXT              ||E'\n'||
                indkey::TEXT                ||E'\n'||
                COALESCE(indexprs::TEXT,'') ||E'\n'||
                COALESCE(indpred::TEXT,'')
                ) AS KEY
        FROM    pg_index
        ) sub
GROUP BY KEY HAVING COUNT(*)>1
ORDER BY SUM(pg_relation_size(idx)) DESC;