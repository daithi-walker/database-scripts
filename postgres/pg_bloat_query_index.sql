-- Original Source: Unknown but lots of queries out there have similar syntax...
-- https://labs.omniti.com/pgtreats/trunk/tools/pg_bloat_report.sh
-- Query that shows index bloat on a database.
WITH x AS (
SELECT  schemaname||'.'||iname as relation
--,       tablename
--,       ROUND(CASE WHEN otta=0 THEN 0.0 ELSE sml.relpages/otta::NUMERIC END,1) AS tbloat
--,       reltuples::BIGINT
--,       relpages::BIGINT
--,       otta
,       ituples::BIGINT
,       ipages::BIGINT
,       iotta
,       ROUND(CASE WHEN iotta=0 OR ipages=0 THEN 0.0 ELSE ipages/iotta::NUMERIC END,1) AS ibloat
,       CASE WHEN ipages < iotta THEN 0 ELSE ipages::BIGINT - iotta END AS wastedipages
,       CASE WHEN ipages < iotta THEN 0 ELSE bs*(ipages-iotta) END AS wastedibytes
,       pg_size_pretty((CASE WHEN ipages < iotta THEN 0 ELSE bs*(ipages-iotta) END)::BIGINT) AS pwastedisize
FROM    (
        SELECT  rs.schemaname
        ,       rs.tablename
        ,       cc.reltuples
        ,       cc.relpages
        ,       rs.bs
        ,       CEIL((cc.reltuples*((rs.datahdr+rs.ma-(CASE WHEN rs.datahdr%rs.ma=0 THEN rs.ma ELSE rs.datahdr%rs.ma END))+nullhdr2+4))/(rs.bs-20::FLOAT)) AS otta
        ,       COALESCE(c2.relname,'?') AS iname
        ,       COALESCE(c2.reltuples,0) AS ituples
        ,       COALESCE(c2.relpages,0) AS ipages
        ,       COALESCE(CEIL((c2.reltuples*(datahdr-12))/(rs.bs-20::FLOAT)),0) AS iotta -- very rough approximation, assumes all cols
        FROM    (
                SELECT  foo.ma
                ,       foo.bs
                ,       foo.schemaname
                ,       foo.tablename
                ,       (foo.datawidth+(foo.hdr+foo.ma-(case when foo.hdr%foo.ma=0 THEN foo.ma ELSE foo.hdr%foo.ma END)))::NUMERIC AS datahdr
                ,       (foo.maxfracsum*(foo.nullhdr+foo.ma-(case when foo.nullhdr%foo.ma=0 THEN foo.ma ELSE foo.nullhdr%foo.ma END))) AS nullhdr2
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
                                SELECT  (SELECT  current_setting('block_size')::NUMERIC) AS bs
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
WHERE   (sml.relpages - sml.otta > 128 OR sml.ipages - sml.iotta > 128) 
AND     ROUND(CASE WHEN sml.iotta=0 OR sml.ipages=0 THEN 0.0 ELSE sml.ipages/sml.iotta::NUMERIC END,1) > 1.2 
AND     CASE WHEN sml.ipages < sml.iotta THEN 0 ELSE sml.bs*(sml.ipages-sml.iotta) END > 1024 * 100
AND     sml.iname like '%import%'
ORDER BY wastedibytes DESC
) 
--SELECT SUM(dummy.wastedibytes) AS wastedibytes FROM (SELECT x.wastedibytes AS wastedibytes FROM x UNION ALL SELECT 0 AS wastedibytes) dummy;
SELECT  *
FROM    x
UNION ALL
SELECT  'TOTAL:'
,       SUM(ituples)
,       SUM(ipages)
,       SUM(iotta)
,       SUM(ibloat)
,       SUM(wastedipages)
,       SUM(wastedibytes)
,       pg_size_pretty(SUM(wastedibytes)::BIGINT)
FROM    x;
;

