SELECT  tablespace_name
,       object_name
,       object_type
,       used_gb
FROM    (
        SELECT  tablespace_name
        ,       object_name
        ,       object_type
        ,       used_gb
        FROM    (
                SELECT  ds.tablespace_name
                ,       ds.segment_name         OBJECT_NAME
                ,       ds.segment_type         OBJECT_TYPE
                ,       ROUND(SUM(ds.bytes/(1024*1024*1024)) OVER (PARTITION BY ds.tablespace_name, ds.segment_name, ds.segment_type),2) USED_GB
                FROM    dba_segments ds
                WHERE   1=1
                AND     ds.tablespace_name IN ('OLIVE')
                AND     ds.segment_name LIKE 'MIS_ARCHIVE%'
                --AND     ds.segment_type <> 'TABLE'
                )
        ORDER BY used_gb DESC
        )
WHERE   1=1
AND     ROWNUM <= 10
;