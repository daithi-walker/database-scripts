https://petesdbablog.wordpress.com/2013/04/06/disable-oracle-diagnostic-pack-tuning-pack/


-- for 11g +
SELECT  name
,       detected_usages detected
,       total_samples   samples
,       currently_used  used
,       last_sample_date
,       sample_interval interval
FROM    dba_feature_usage_statistics
WHERE   1=1
AND     (
        name = 'Automatic Workload Repository'
        OR
        name like 'SQL%'
        );

show parameter control_management_pack_access