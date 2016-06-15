select  a.dbname
,       a.instname
,       b.name         group_name
,       a.disk_number
,       a.reads
,       a.read_errs
,       a.read_time
,       ( a.bytes_read / (1024*1024)) mb_read
,       a.writes
,       a.write_errs
,       a.write_time
,       ( a.bytes_written / (1024*1024)) mb_wrtn
-- **************************
-- new data columns in 11gr2 
-- **************************
,       (a.hot_bytes_read / (1024*1024))      hot_mb_read
,       (a.cold_bytes_read / (1024*1024))    cold_mb_read
,       (a.hot_bytes_written / (1024*1024))  hot_mb_wrtn
,       (a.cold_bytes_written / (1024*1024)) cold_mb_wrtn
FROM    v$asm_disk_iostat a
,       v$asm_diskgroup   b
 WHERE  1=1
 AND    a.group_number = b.group_number
 ORDER BY a.dbname
,         a.instname;