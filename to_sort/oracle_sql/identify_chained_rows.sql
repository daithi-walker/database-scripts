http://www.dba-oracle.com/t_identify_chained_rows.htm

select  owner
,       table_name
,       pct_free
,       pct_used
,       avg_row_len
,       num_rows
,       chain_cnt
,       chain_cnt/num_rows
from    dba_tables
where   1=1
and     owner = 'OLIVE' --not in ('SYS','SYSTEM')
and     table_name like 'MIS_ARCHIVE_DT_ACTIVITY'
and     table_name not in
        (
        select  table_name
        from    dba_tab_columns
        where   data_type in ('RAW','LONG RAW','CLOB','BLOB','NCLOB')
        )
and     chain_cnt > 0
order by chain_cnt desc
;

