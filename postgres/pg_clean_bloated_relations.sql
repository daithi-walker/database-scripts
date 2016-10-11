WITH x AS (
-- gather tables
SELECT  't' AS relkind
,       sml.schemaname||'.'||sml.tablename AS relation
,       pg_total_relation_size(sml.schemaname||'.'||sml.tablename) AS disksize
,       CASE WHEN sml.relpages < sml.otta THEN 0 ELSE sml.bs*(sml.relpages-sml.otta)::BIGINT END AS wastedbytes
FROM    (
        SELECT  rs.schemaname
        ,       rs.tablename
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
AND     sml.schemaname NOT IN ('pg_catalog')
AND     ROUND(CASE WHEN sml.otta=0 THEN 0.0 ELSE sml.relpages/sml.otta::NUMERIC END,1) > 1.2 
AND     CASE WHEN sml.relpages < otta THEN 0 ELSE sml.bs*(sml.relpages-sml.otta)::BIGINT END > 1024 * 100
UNION ALL
-- gather indexes
SELECT  'i' AS relkind
,       schemaname||'.'||tablename as relation
,       pg_total_relation_size(schemaname||'.'||iname) AS disksize
,       CASE WHEN ipages < iotta THEN 0 ELSE bs*(ipages-iotta) END AS wastedbytes
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
AND     sml.schemaname NOT IN ('pg_catalog')
AND     ROUND(CASE WHEN sml.iotta=0 OR sml.ipages=0 THEN 0.0 ELSE sml.ipages/sml.iotta::NUMERIC END,1) > 1.2 
AND     CASE WHEN sml.ipages < sml.iotta THEN 0 ELSE sml.bs*(sml.ipages-sml.iotta) END > 1024 * 100
)
SELECT    'ppm -c ''vacuum full analyze verbose '||x.relation||''';' psql
--        'psql -h ess-lon-mis-db-001 -d mis -U "david.walker" -c ''vacuum full analyze verbose '||x.relation||''';' psql
--,       x.relation
--,       pg_size_pretty(SUM(x.disksize)) disk
--,       pg_size_pretty(SUM(x.wastedbytes)::BIGINT) wasted
--,       pg_size_pretty(SUM(CASE WHEN x.relkind = 't' then x.disksize else 0 end)) AS tdisk
--,       pg_size_pretty(SUM(CASE WHEN x.relkind = 't' then x.wastedbytes else 0 end)::BIGINT) AS twaste
--,       pg_size_pretty(SUM(CASE WHEN x.relkind = 'i' then x.disksize else 0 end)) AS idisk
--,       pg_size_pretty(SUM(CASE WHEN x.relkind = 'i' then x.wastedbytes else 0 end)::BIGINT) AS iwaste
FROM    x
WHERE   1=1
-- exclude items which are currently locked.
AND     NOT EXISTS
        (
        SELECT  NULL
        FROM    pg_locks pl
        WHERE   1=1
        AND     CAST(pl.relation::regclass AS VARCHAR) = x.relation
        AND     pl.relation IS NOT NULL
        )
--AND     x.relation like '%imp%'
GROUP BY x.relation
HAVING   SUM(x.disksize) < 10000000000  -- display relation that has a disk usage under 10gb
--HAVING   SUM(x.wastedbytes) >= 100000000
ORDER BY SUM(x.wastedbytes)
--LIMIT 1
;
