select  blocked_locks.pid           as blocked_pid
,       blocked_activity.usename    as blocked_user
,       blocking_locks.pid          as blocking_pid
,       blocking_activity.usename   as blocking_user
,       blocked_activity.query      as blocked_statement
,       blocking_activity.query     as current_statement_in_blocking_process
from    pg_catalog.pg_locks         blocked_locks
,       pg_catalog.pg_stat_activity blocked_activity
,       pg_catalog.pg_locks         blocking_locks 
,       pg_catalog.pg_stat_activity blocking_activity
where   1=1
and     blocked_activity.pid = blocked_locks.pid
and     blocking_locks.locktype = blocked_locks.locktype
and     blocking_locks.database is not distinct from blocked_locks.database
and     blocking_locks.relation is not distinct from blocked_locks.relation
and     blocking_locks.page is not distinct from blocked_locks.page
and     blocking_locks.tuple is not distinct from blocked_locks.tuple
and     blocking_locks.virtualxid is not distinct from blocked_locks.virtualxid
and     blocking_locks.transactionid is not distinct from blocked_locks.transactionid
and     blocking_locks.classid is not distinct from blocked_locks.classid
and     blocking_locks.objid is not distinct from blocked_locks.objid
and     blocking_locks.objsubid is not distinct from blocked_locks.objsubid
and     blocking_locks.pid != blocked_locks.pid
and     blocking_activity.pid = blocking_locks.pid
and     not blocked_locks.granted;


select  a.datname
,       c.relname
,       l.transactionid
,       l.mode
,       l.granted
,       a.usename
,       a.query
,       a.query_start
,       age(clock_timestamp(), a.query_start) as age
,       a.pid 
from    pg_stat_activity a
,       pg_locks l
,       pg_class c
where   1=1
and     l.pid = a.pid
and     c.oid = l.relation
order by a.query_start;

