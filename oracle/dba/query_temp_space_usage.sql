SELECT  b.total_mb
,       b.total_mb - ROUND(a.used_blocks*8/1024) current_free_mb
,       ROUND(a.used_blocks*8/1024)                current_used_mb
,       ROUND(a.max_used_blocks*8/1024)            max_used_mb
FROM    v$sort_segment a
,       (
        SELECT  ROUND(SUM(bytes)/1024/1024) total_mb
        FROM    dba_temp_files
        ) b
;


col hash_value for a40
col tablespace for a10
col username for a15
set linesize 132 pagesize 1000
 
SELECT  s.sid
,       s.username
,       u.tablespace
,       s.sql_hash_value||'/'||u.sqlhash hash_value
,       u.segtype
,       u.contents
,       u.blocks
FROM    v$session s
,       v$tempseg_usage u
WHERE   1=1
AND     s.saddr = u.session_addr
order by u.blocks;