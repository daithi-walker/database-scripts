select   a.tablespace_name
,        a.bytes mb_total
,        b.bytes mb_free
,        b.largest
,        a.bytes-b.bytes mb_used
,        round(((a.bytes-b.bytes)/a.bytes)*100,2) percent_used
from     (
         select   tablespace_name
         ,        sum(bytes)/1048576 bytes 
         from     dba_data_files
         group by tablespace_name
         ) a
,        (
         select   tablespace_name
         ,        sum(bytes)/1048576 bytes
         ,        max(bytes)/1048576 largest
         from     dba_free_space
         group    by tablespace_name
         ) b
where    a.tablespace_name = b.tablespace_name
order by ((a.bytes-b.bytes)/a.bytes) desc;