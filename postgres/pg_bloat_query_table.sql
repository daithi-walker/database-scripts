-- Original Source: Unknown but lots of queries out there have similar syntax...
-- https://labs.omniti.com/pgtreats/trunk/tools/pg_bloat_report.sh
-- Query that shows table bloat on a database.
WITH x AS
(
SELECT  sml.schemaname||'.'||sml.tablename AS relation
,       sml.reltuples::BIGINT
,       sml.relpages::BIGINT
,       sml.otta
,       ROUND(CASE WHEN sml.otta=0 THEN 0.0 ELSE sml.relpages/sml.otta::NUMERIC END,1) AS tbloat
,       CASE WHEN sml.relpages < sml.otta THEN 0 ELSE sml.relpages::BIGINT - sml.otta END AS wastedpages
,       CASE WHEN sml.relpages < sml.otta THEN 0 ELSE sml.bs*(sml.relpages-sml.otta)::BIGINT END AS wastedbytes
,       pg_size_pretty((CASE WHEN sml.relpages < sml.otta THEN 0 ELSE sml.bs*(sml.relpages-sml.otta)::BIGINT END)::BIGINT) AS pwastedbytes
FROM    (
        SELECT  rs.schemaname
        ,       rs.tablename
        ,       cc.reltuples
        ,       cc.relpages
        ,       rs.bs
        ,       CEIL((cc.reltuples*((rs.datahdr+rs.ma-(CASE WHEN rs.datahdr%rs.ma=0 THEN rs.ma ELSE rs.datahdr%rs.ma END))+rs.nullhdr2+4))/(rs.bs-20::float)) AS otta
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
                                SELECT  (
                                        SELECT  current_setting('block_size')::NUMERIC) AS bs
                                        ,       CASE WHEN substring(v,12,3) IN ('8.0','8.1','8.2') THEN 27 ELSE 23 END AS hdr
                                        ,       CASE WHEN v ~ 'mingw32' THEN 8 ELSE 4 END AS ma
                                FROM    (SELECT  version() AS v) AS foo
                                ) AS constants
                        GROUP BY 1,2,3,4,5
                        ) AS foo
                ) AS rs
        JOIN pg_class cc ON cc.relname = rs.tablename
        JOIN pg_namespace nn ON cc.relnamespace = nn.oid
                             AND nn.nspname = rs.schemaname
                             AND nn.nspname <> 'information_schema'
        ) AS sml
WHERE   sml.relpages - sml.otta > 128 
AND     ROUND(CASE WHEN sml.otta=0 THEN 0.0 ELSE sml.relpages/sml.otta::NUMERIC END,1) > 1.2 
AND     CASE WHEN sml.relpages < otta THEN 0 ELSE sml.bs*(sml.relpages-sml.otta)::BIGINT END > 1024 * 100
ORDER BY wastedbytes DESC
)
--SELECT SUM(dummy.wastedbytes) AS wastedbytes FROM (SELECT x.wastedbytes FROM x UNION ALL SELECT 0 AS wastedbytes) dummy;
SELECT  *
FROM    x
UNION ALL
SELECT  'TOTAL:'
,       SUM(reltuples)
,       SUM(relpages)
,       SUM(otta)
,       SUM(tbloat)
,       SUM(wastedpages)
,       SUM(wastedbytes)
,       pg_size_pretty(SUM(wastedbytes)::BIGINT) FROM x;
