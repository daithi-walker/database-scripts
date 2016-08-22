SELECT  DISTINCT
        de.file_id
,       de.segment_name
FROM    dba_extents de
,       dba_data_files ddf
WHERE   1=1
AND     de.file_id = ddf.file_id
AND     ddf.file_id IN (45)
ORDER BY de.segment_name;