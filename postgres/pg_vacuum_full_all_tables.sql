select  'select count(*) from '||pn.nspname||'.'||pc.relname||';' AS "query"
,       'vacuum full '||pn.nspname||'.'||pc.relname||';' AS "query"
,       'analyze '||pn.nspname||'.'||pc.relname||';' AS "query"
,       pn.nspname||'.'||pc.relname as "object"
,       reltuples::bigint
FROM    pg_class pc
,       pg_namespace pn
WHERE   1=1
AND     pn.nspname NOT IN ('pg_catalog')
AND     pc.relkind = 'r'
AND     pn.oid = pc.relnamespace
--AND     pc.relname not like 'import%'
--AND     pc.relname = 'ds3.archive_ad_groups'
--AND     pn.nspname||'.'||pc.relname in ('manual.conversions','adwords.archive_ads')
--AND     pc.reltuples between 1000000000 AND 10000000000
ORDER BY reltuples::bigint;