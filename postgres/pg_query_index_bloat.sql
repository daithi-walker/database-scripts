-- Original Source: Unknown but lots of queries out there have similar syntax...
-- https://labs.omniti.com/pgtreats/trunk/tools/pg_bloat_report.sh
-- Query that shows index bloat on a database.
WITH x AS (
SELECT  CASE WHEN ipages < iotta THEN 0 ELSE bs*(ipages-iotta) END AS wastedibytes
FROM    (
        SELECT  cc.relpages
        ,       bs
        ,       CEIL((cc.reltuples*((datahdr+ma-(CASE WHEN datahdr%ma=0 THEN ma ELSE datahdr%ma END))+nullhdr2+4))/(bs-20::float)) AS otta
        ,       COALESCE(c2.relname,'?') AS iname, COALESCE(c2.reltuples,0) AS ituples, COALESCE(c2.relpages,0) AS ipages
        ,       COALESCE(CEIL((c2.reltuples*(datahdr-12))/(bs-20::float)),0) AS iotta -- very rough approximation, assumes all cols
        FROM    (
                SELECT  ma
                ,       bs
                ,       schemaname
                ,       tablename
                ,       (datawidth+(hdr+ma-(case when hdr%ma=0 THEN ma ELSE hdr%ma END)))::numeric AS datahdr
                ,       (maxfracsum*(nullhdr+ma-(case when nullhdr%ma=0 THEN ma ELSE nullhdr%ma END))) AS nullhdr2
                FROM    (
                        SELECT  s.schemaname
                        ,       s.tablename
                        ,       constants.hdr
                        ,       constants.ma
                        ,       constants.bs
                        ,       SUM((1-s.null_frac)*s.avg_width) AS datawidth
                        ,       MAX(s.null_frac) AS maxfracsum
                        ,       constants.hdr +
                                (
                                SELECT  1+count(*)/8
                                FROM    pg_stats s2
                                WHERE   s2.null_frac <> 0
                                AND     s2.schemaname = s.schemaname
                                AND     s2.tablename = s.tablename
                                ) AS nullhdr
                        FROM    pg_stats s
                        ,       (
                                SELECT  (SELECT  current_setting('block_size')::numeric) AS bs
                                        ,       CASE WHEN substring(v,12,3) IN ('8.0','8.1','8.2') THEN 27 ELSE 23 END AS hdr
                                        ,       CASE WHEN v ~ 'mingw32' THEN 8 ELSE 4 END AS ma
                                        FROM    (SELECT version() AS v) foo
                                ) AS constants
                        GROUP BY 1,2,3,4,5
                        ) AS foo
                ) AS rs
        JOIN pg_class cc ON cc.relname = rs.tablename
        JOIN pg_namespace nn ON cc.relnamespace = nn.oid
                             AND nn.nspname = rs.schemaname
                             AND nn.nspname <> 'information_schema'
        LEFT JOIN pg_index i ON indrelid = cc.oid
        LEFT JOIN pg_class c2 ON c2.oid = i.indexrelid
        ) AS sml
WHERE   (sml.relpages - otta > 128 OR ipages - iotta > 128) 
AND     ROUND(CASE WHEN iotta=0 OR ipages=0 THEN 0.0 ELSE ipages/iotta::numeric END,1) > 1.2 
AND CASE WHEN ipages < iotta THEN 0 ELSE bs*(ipages-iotta) END > 1024 * 100
) 
SELECT  SUM(dummy.wastedibytes) AS wastedibytes
FROM    (SELECT x.wastedibytes AS wastedibytes FROM x UNION ALL SELECT 0 AS wastedibytes) dummy
;

