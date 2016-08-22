SELECT  hist.endpoint_number,
        (hist.endpoint_number - nvl(hist.prev_endpoint,0))  frequency,
        (hist.endpoint_number - nvl(hist.prev_endpoint,0)) / hist.max_endpoint_number  perc,
        ROUND(dt.num_rows*(hist.endpoint_number - NVL(hist.prev_endpoint,0)) / hist.max_endpoint_number)  hist_estimate,
        TO_DATE(hist.endpoint_value,'J') endpoint_value
FROM    (
        SELECT  dth.owner
        ,       dth.table_name
        ,       dth.endpoint_number
        ,       MAX(dth.endpoint_number) OVER (PARTITION BY 1) max_endpoint_number
        ,       LAG(dth.endpoint_number,1) OVER(ORDER BY dth.endpoint_number) prev_endpoint
        ,       dth.endpoint_value
        FROM    dba_tab_histograms dth
        WHERE   owner = 'OLIVE'
        AND     table_name = 'MIS_ARCHIVE_DT_ACTIVITY_2016'
        AND     column_name = 'MRD_DATE'
        ) hist
,       dba_tables dt
WHERE   1=1
AND     hist.owner = dt.owner
AND     hist.table_name = dt.table_name
--AND     TO_DATE(hist.endpoint_value,'J') BETWEEN '30-JUN-2016' AND '30-JUN-2016'
ORDER BY hist.endpoint_number DESC;