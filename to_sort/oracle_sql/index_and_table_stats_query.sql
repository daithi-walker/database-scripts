select  *
from    dba_tab_statistics
where   1=1
and     owner = 'OLIVE'
and     table_name in 
        ('MKTG_CODE_REFERENCE'
        ,'MKTG_PLACEMENTS'
        ,'MKTG_BOOKINGS '
        ,'MKTG_PROPERTIES'
        ,'MKTG_CHANNELS'
        ,'MKTG_CAMPAIGNS'
        ,'MKTG_CAM_PRODUCTS'
        ,'MKTG_COUNTRIES'
        ,'MIS_PERFORMANCE_LAG_EMEA_GOO'
        ,'MIS_PERFORMANCE_LAG_APAC_GOO'
        ,'MIS_PERFORMANCE_LAG_NA_GOO'
        ,'GLOBAL_SEARCH_GOO'
        ,'MIS_PERFORMANCE_GDN_APAC_GOO'
        ,'MIS_PERFORMANCE_GDN_NA_GOO'
        ,'MIS_PERFORMANCE_GDN_EMEA_GOO'
        ,'OLAP_FACEBOOK_MEASURES_GOO_CUR'
        )
and     last_analyzed < trunc(sysdate,'dd');

select  *
from    dba_tab_col_statistics
where   1=1
and     owner in ('OLIVE','OLIVE_INDEX')
and     table_name in 
        ('MKTG_CODE_REFERENCE'
        ,'MKTG_PLACEMENTS'
        ,'MKTG_BOOKINGS '
        ,'MKTG_PROPERTIES'
        ,'MKTG_CHANNELS'
        ,'MKTG_CAMPAIGNS'
        ,'MKTG_CAM_PRODUCTS'
        ,'MKTG_COUNTRIES'
        ,'MIS_PERFORMANCE_LAG_EMEA_GOO'
        ,'MIS_PERFORMANCE_LAG_APAC_GOO'
        ,'MIS_PERFORMANCE_LAG_NA_GOO'
        ,'GLOBAL_SEARCH_GOO'
        ,'MIS_PERFORMANCE_GDN_APAC_GOO'
        ,'MIS_PERFORMANCE_GDN_NA_GOO'
        ,'MIS_PERFORMANCE_GDN_EMEA_GOO'
        )
and     last_analyzed < trunc(sysdate,'dd');

select  *
from    dba_ind_statistics
where   1=1
and     owner in ('OLIVE','OLIVE_INDEX')
and     table_name in 
        ('MKTG_CODE_REFERENCE'
        ,'MKTG_PLACEMENTS'
        ,'MKTG_BOOKINGS '
        ,'MKTG_PROPERTIES'
        ,'MKTG_CHANNELS'
        ,'MKTG_CAMPAIGNS'
        ,'MKTG_CAM_PRODUCTS'
        ,'MKTG_COUNTRIES'
        ,'MIS_PERFORMANCE_LAG_EMEA_GOO'
        ,'MIS_PERFORMANCE_LAG_APAC_GOO'
        ,'MIS_PERFORMANCE_LAG_NA_GOO'
        ,'GLOBAL_SEARCH_GOO'
        ,'MIS_PERFORMANCE_GDN_APAC_GOO'
        ,'MIS_PERFORMANCE_GDN_NA_GOO'
        ,'MIS_PERFORMANCE_GDN_EMEA_GOO'
        )
and     index_name not like 'SYS_IL%'
--and     index_name like 'MIS_PERF_GDN_%_GOO_DU'
--and     (last_analyzed < trunc(sysdate,'dd') - 1 or last_analyzed is null)
;

BEGIN
--dbms_stats.gather_table_stats('OLIVE','MIS_PERFORMANCE_GDN_APAC_GOO');
--dbms_stats.gather_table_stats('OLIVE','MIS_PERFORMANCE_GDN_EMEA_GOO');
dbms_stats.gather_table_stats('OLIVE','MIS_PERFORMANCE_GDN_NA_GOO');
END;