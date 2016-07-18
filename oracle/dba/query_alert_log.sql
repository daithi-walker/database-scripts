WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;
WHENEVER OSERROR EXIT 9;

SET LINESIZE 160
SET PAGESIZE 100

PROMPT ***********************************************************
PROMPT ** query_alert_log.sql
PROMPT ***********************************************************
PROMPT ** The following is a listing of all alert log messages  
PROMPT ** generated since the beginning of the last day.
PROMPT ***********************************************************

col ts              for a20
col message_text    for a100

SELECT  to_char(originating_timestamp,'dd.mm.yyyy hh24:mi:ss') AS "TS"
,       message_text
FROM    x$dbgalertext
WHERE   1=1
AND     originating_timestamp > TRUNC(SYSDATE)-1
;

EXIT;
