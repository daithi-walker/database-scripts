--begin
--  dbms_stats.CREATE_STAT_TABLE( ownname=>user
--                             , stattab=>'DW_STATS_20160212'
--                              );
--end;
--begin
--  dbms_stats.DROP_STAT_TABLE( ownname=>user
--                             , stattab=>'DW_STATS_20160212'
--                              );
--end;
--
--begin
--  dbms_stats.export_schema_stats( ownname=>user
--                                , stattab=>'DW_STATS_20160212'
--                                , statid=>'CURRENT_STATS'
--                                );
--end;

--begin 
--DBMS_STATS.EXPORT_TABLE_STATS
--( ownname => user
--, tabname => 'MIS_ARCHIVE_DT_ACTIVITY'
--, stattab => 'DW_STATS_20160212'
--, statid  => 'CURRENT_STATS'
--);
--end;

select * --statid, type, count(*)
from DW_STATS_20160212
where type = 'T'
--group by statid, type
;

select dbms_stats.get_prefs('ESTIMATE_PERCENT','OLIVE','MIS_ARCHIVE_DT_ACTIVITY') from dual;

begin
  dbms_stats.set_table_prefs('OLIVE','MIS_ARCHIVE_DT_ACTIVITY','ESTIMATE_PERCENT','1');
end;

begin
  dbms_stats.gather_table_stats('OLIVE','MIS_ARCHIVE_DT_ACTIVITY');
end;

select    count(*);
select  --* --MRD_DATE
--,       decode(level,1,count(*),0) day0
--,       count(*) day1
MRD_DATE
,MRD_CRE_ID
,MRD_PAGE_ID
,MRD_AD_ID
,MRD_ACTIVITY_TYPE
,MRD_ACTIVITY_SUB_TYPE
,MRD_EVENT_ID
,MRD_SOURCE_DATE
from    mis_archive_dt_activity
where   1=1
and     MRD_DATE in ('10-FEB-2016')
and mrd_activity_type = 'gxbo'
and mrd_activity_sub_type = 'gyb-g0'
--connect by level <= 2
--group by MRD_DATE
;

    "MRD_ACTIVITY_TYPE" VARCHAR2(10 BYTE), 
    "MRD_ACTIVITY_SUB_TYPE" VARCHAR2(32 BYTE), 
    
    select trunc(sysdate)-1 from dual;