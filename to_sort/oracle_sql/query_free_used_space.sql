select   fs.tablespace_name                          "Tablespace"
,        (df.totalspace - fs.freespace)/1024              "Used GB"
,        fs.freespace/1024                                "Free GB"
,        df.totalspace/1024                               "Total GB"
,        round(100 * (fs.freespace / df.totalspace)) "Pct. Free"
from     (
         select   tablespace_name
         ,        round(sum(bytes) / 1048576) TotalSpace
         from     dba_data_files
         group by tablespace_name
         ) df
,        (
         select   tablespace_name
         ,        round(sum(bytes) / 1048576) FreeSpace
         from     dba_free_space
         group by tablespace_name
         ) fs
where    1=1
AND      fs.tablespace_name IN ( 'OLIVE','OLIVE_INDEX')
and      df.tablespace_name = fs.tablespace_name
order by fs.tablespace_name
;
