http://www.postgresql.org/docs/9.4/static/functions-admin.html

http://www.practiceovertheory.com/blog/2013/07/06/distributed-locking-in-postgres/

SELECT  pl.granted
,       psa.query
,       psa.query_start
FROM    pg_locks pl 
,       pg_stat_activity psa
WHERE   pl.pid = psa.pid
AND     pl.locktype = 'advisory';

SELECT pg_advisory_lock(1);

SELECT pg_advisory_unlock(1);