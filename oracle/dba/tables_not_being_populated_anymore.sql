SELECT  *
FROM    (
SELECT  dt.owner
,       dt.table_name
,       dt.tablespace_name
,       ds.segment_type object_type
,       CASE
          WHEN
             (
             dt.last_analyzed < trunc(SYSDATE,'YYYY')
             AND
             dtm.TIMESTAMP IS NULL
             )
             OR
             dtm.timestamp < trunc(SYSDATE,'YYYY')
          THEN
             'OLD'
          ELSE
             'RECENT'
       END update_status
,      dt.last_analyzed
,      dtm.TIMESTAMP last_modified
,      to_char(dt.num_rows,'999,999,999,999') estimated_rows
,      to_char(NVL(ds.total_bytes,0),'999,999,999,999') total_bytes
,      to_char(nvl(dsi.total_bytes,0),'999,999,999,999') total_ibytes
,      round((NVL(ds.total_bytes,0)+NVL(dsi.total_bytes,0))/1024/1024/1024,2) total_gbs
FROM   dba_tables dt
,      (
       SELECT  ds.owner
       ,       ds.segment_name
       ,       ds.segment_type
       ,       sum(ds.bytes) total_bytes
       FROM    dba_segments ds
       WHERE   1=1
       GROUP BY ds.owner
       ,        ds.segment_name
       ,        ds.segment_type
       ) ds
,      dba_tab_modifications dtm
,      (
       SELECT  di.owner
       ,       di.table_name
       ,       SUM(ds1.bytes) total_bytes
       FROM    dba_indexes di
       ,       dba_segments ds1
       WHERE   1=1
       AND     ds1.owner = di.owner
       AND     ds1.segment_name = di.index_name
       GROUP BY di.owner
       ,        di.table_name
       ) dsi
WHERE  1=1
AND    ds.owner = dt.owner
AND    ds.segment_name = dt.table_name
AND    dt.owner = dtm.table_owner (+)
AND    dt.table_name = dtm.table_name (+)
AND    dt.owner = dsi.owner (+)
AND    dt.table_name = dsi.table_name (+)
)
WHERE  1=1
AND    owner IN ('OLIVE','SANFRAN')
AND    (
       update_status = 'OLD'
       OR
       table_name = 'MIS_ARCHIVE_DT_ACTIVITY_OLD'
       )
ORDER BY total_bytes DESC
;