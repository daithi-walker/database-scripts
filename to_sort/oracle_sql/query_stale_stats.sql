SELECT  dt.owner
,       dt.table_name
,       dt.last_analyzed
,       DBMS_STATS.get_prefs(ownname=>dt.owner,tabname=>dt.table_name,pname=>'STALE_PERCENT') STALE_PERC
,       DECODE(dt.num_rows,0,0,ROUND( (dtm.deletes + dtm.updates + dtm.inserts) / dt.num_rows * 100, 2)) CURR_PER
,       dts.stattype_locked
,       dts.stale_stats
,       dtm.deletes
,       dtm.updates
,       dtm.inserts
,       dt.num_rows
,       '  DBMS_STATS.GATHER_TABLE_STATS('''||dt.owner||''','''||dt.table_name||''');' vsql
FROM    sys.dba_tables dt
,       sys.dba_tab_modifications dtm
,       sys.dba_tab_statistics dts
WHERE   1=1
AND     dts.owner = dt.owner
AND     dts.table_name = dt.table_name
AND     dt.owner = dtm.table_owner
AND     dt.table_name = dtm.table_name
--AND     dt.num_rows >= 1000000
AND     (
        DECODE(dt.num_rows,0,0,ROUND( (dtm.deletes + dtm.updates + dtm.inserts) / dt.num_rows * 100, 2)) >= DBMS_STATS.get_prefs(ownname=>dt.owner,tabname=>dt.table_name,pname=>'STALE_PERCENT')
        OR
        dts.stale_stats = 'YES'
        )
AND     dts.stattype_locked IS NULL
AND     dt.owner IN ('OLIVE','SANFRAN')
--AND     (dt.table_name like 'MIS_ARCHIVE_DT%' or dt.table_name = 'IMP_HOLIDAY_AUTO_FIRST_INT')
--AND     (dts.table_name NOT LIKE '%IMP%' AND dts.table_name NOT LIKE 'TMP%')
AND     dts.table_name NOT LIKE '%BIN%'
--AND     dt.last_analyzed < SYSDATE - 1
ORDER BY DECODE(dt.num_rows,0,0,ROUND( (dtm.deletes + dtm.updates + dtm.inserts) / dt.num_rows * 100, 2))desc;