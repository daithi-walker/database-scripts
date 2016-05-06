select  round(sum(bytes/(1024*1024*1024)) over (partition by segment_name, tablespace_name),2) USED_GB
,       segment_name
,       tablespace_name
from    dba_segments
where   1=1
and     tablespace_name in ('OLIVE','OLIVE_INDEX')
and     segment_name like 'MIS_ARC%2016%'
order by 1 desc
;