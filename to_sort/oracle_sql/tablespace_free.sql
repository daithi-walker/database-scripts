select  nvl(b.tablespace_name
,       nvl(a.tablespace_name,'UNKNOWN')) "Tablespace"
,       kbytes_alloc "Allocated MB"
,       kbytes_alloc-nvl(kbytes_free,0) "Used MB"
,       nvl(kbytes_free,0) "Free MB"
,       ((kbytes_alloc-nvl(kbytes_free,0))/kbytes_alloc) "Used"
,       data_files "Data Files"
from    (
        select  sum(bytes)/1024/1024 Kbytes_free
        ,       max(bytes)/1024/1024 largest
        ,       tablespace_name
        from    sys.dba_free_space
        group by tablespace_name
        ) a
,       (
        select  sum(bytes)/1024/1024 Kbytes_alloc
        ,       tablespace_name
        ,       count(*) data_files
        from    sys.dba_data_files
        group by tablespace_name
        ) b
where   1=1
and     a.tablespace_name (+) = b.tablespace_name
--and (:TABLESPACE_NAME is null or   instr(lower(b.tablespace_name),lower(:TABLESPACE_NAME)) > 0)
and     b.tablespace_name not in ('SYSAUX','SYSTEM','UNDOTBS1','PERFSTAT')
order by 2 desc