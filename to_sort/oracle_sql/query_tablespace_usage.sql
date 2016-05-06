select  df.tablespace_name "Tablespace"
,       round(totalusedspace/1024,2) "Used GB"
,       round((df.totalspace - tu.totalusedspace)/1024,2) "Free GB"
,       round(df.totalspace/1024,2) "Total GB"
,       round(100 * ( (df.totalspace - tu.totalusedspace)/ df.totalspace)) "Pct. Free"
from    (
        select  tablespace_name
        ,       round(sum(bytes) / 1048576) TotalSpace
        from    dba_data_files 
        group by tablespace_name
        ) df
,       (
        select  round(sum(bytes)/(1024*1024)) totalusedspace
        ,       tablespace_name
        from    dba_segments 
        group by tablespace_name
        ) tu
where   1=1
and     df.tablespace_name = tu.tablespace_name
and     df.tablespace_name in ('OLIVE','OLIVE_INDEX');