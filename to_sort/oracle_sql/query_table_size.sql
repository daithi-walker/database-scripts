SELECT  segment_name
,       segment_type
,       SUM(bytes/1024/1024) "MB"
FROM    dba_extents
WHERE   1=1
AND     segment_name = 'MIS_CMO_ESSENCE_GOO_PX'
GROUP BY segment_name
,        segment_type;