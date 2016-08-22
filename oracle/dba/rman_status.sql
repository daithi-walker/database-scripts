SELECT  sid
,       recid
,       session_stamp
,       operation
,       status
,       MBYTES_PROCESSED
,       TO_CHAR(start_time, 'dd-mon-yyyy hh24:mi:ss' ) START_TIME
,       TO_CHAR(end_time, 'dd-mon-yyyy hh24:mi:ss' ) END_TIME
,       INPUT_BYTES/1024/1024/1024 INPUT
,       OUTPUT_BYTES/1024/1024/1024 OUTPUT 
FROM    v$rman_status
WHERE   1=1
--AND     session_stamp = 919631097
ORDER BY start_time;