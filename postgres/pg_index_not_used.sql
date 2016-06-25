-- list all unused inedxes in a database
SELECT  pg_size_pretty(pg_relation_size(psai.indexrelid)) relsize
,       * 
FROM    pg_stat_all_indexes  psai
WHERE   1=1
AND     psai.idx_scan = 0
AND     psai.schemaname NOT IN
        ('public'
        ,'pg_toast'
        ,'pg_catalog'
        )
ORDER BY psai.idx_scan ASC
,        pg_relation_size(psai.indexrelid) DESC;


-- total sie of all unused indexes in a database
SELECT  pg_size_pretty(SUM(pg_relation_size(psai.indexrelid))) relsize
FROM    pg_stat_all_indexes  psai
WHERE   1=1
AND     psai.idx_scan = 0
AND     psai.schemaname NOT IN
        ('public'
        ,'pg_toast'
        ,'pg_catalog'
        );