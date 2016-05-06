select  *
from    dba_tab_col_statistics
where   1=1
and     owner in ('SANFRAN','OLIVE')
and     table_name = 'MIS_DTS_EVENT_MAPPINGS'
and     column_name like 'SYS!_%' escape '!'
;

select  *
from    dba_stat_extensions
where   1=1
and     owner in ('SANFRAN','OLIVE')
and     extension_name like 'SYS!_%' escape '!'
and     table_name = 'MIS_DTS_EVENT_MAPPINGS'
;

