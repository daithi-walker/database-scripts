SELECT  schemaname
,       relname
,       seq_scan-idx_scan AS too_much_seq
,       case when seq_scan-idx_scan>0 THEN 'Missing Index?' ELSE 'OK' END
,       pg_pretty_size(pg_relation_size(relid::regclass)) AS rel_size
,       seq_scan
,       idx_scan
 FROM   pg_stat_all_tables
 WHERE  1=1
 AND    schemaname NOT IN ('public','pg_toast','pg_catalog')
 AND    pg_relation_size(relname::regclass) > 80000
 ORDER BY too_much_seq DESC;
