-- Source: https://docs.oracle.com/cd/E11882_01/server.112/e40402/statviews_2107.htm#REFRN20280
-- Run the FLUSH_DATABASE_MONITORING_INFO procedure in the DBMS_STATS PL/SQL package to populate these views with the latest information.
--EXEC DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO;

-- Source: https://community.oracle.com/message/10771879
SELECT  dt.owner
,       dt.table_name
,       ROUND(((dtm.deletes+dtm.updates+dtm.inserts)/dt.num_rows*100)) PERCENTAGE
,       dt.num_rows
,       dtm.inserts
,       dtm.updates
,       dtm.deletes
,       dtm.timestamp
,       dtm.truncated
FROM    dba_tables dt
,       dba_tab_modifications dtm
WHERE   1=1
AND     dt.owner = dtm.table_owner (+)
AND     dt.table_name = dtm.table_name (+)
AND     dt.num_rows > 0
AND     ((dtm.deletes+dtm.updates+dtm.inserts)/dt.num_rows*100) >= 10
--AND     dtm.truncated (+) = 'NO'
--AND     dtm.timestamp <= '01-JAN-2015'
AND     dt.owner IN ('OLIVE','SANFRAN')
AND     dt.table_name = 'MIS_ARCHIVE_DT_ACTIVITY_2016'
ORDER BY dt.num_rows DESC;
