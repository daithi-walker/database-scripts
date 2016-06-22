SELECT  tablespace_name
,       object_name
,       object_type
,       used_gb
,       used_perc_of_ts
--,       used_bytes
FROM    (
        SELECT  tablespace_name
        ,       object_name
        ,       object_type
        ,       used_gb
        ,       ROUND((used_gb/used_ts_gb)*100,2) used_perc_of_ts
        --,       used_bytes
        FROM    (
                SELECT  ds.tablespace_name
                ,       ds.segment_name         OBJECT_NAME
                ,       ds.segment_type         OBJECT_TYPE
                ,       ROUND(SUM(ds.bytes/(1024*1024*1024)) OVER (PARTITION BY ds.tablespace_name, ds.segment_name, ds.segment_type),2) USED_GB
                ,       ROUND(SUM(ds.bytes/(1024*1024*1024)) OVER (PARTITION BY ds.tablespace_name),2) USED_TS_GB
                --,       SUM(ds.bytes) OVER (PARTITION BY ds.tablespace_name, ds.segment_name, ds.segment_type) USED_BYTES
                FROM    dba_segments ds
                WHERE   1=1
                AND     ds.tablespace_name IN ('OLIVE')
                --AND     ds.segment_name = 'RIZ_GH_TEST'
                --AND     ds.segment_type <> 'TABLE'
                )
        ORDER BY used_gb DESC
        )
WHERE   1=1
--AND     ROWNUM <= 10
AND     used_gb > 1
;