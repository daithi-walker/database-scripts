WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;
WHENEVER OSERROR EXIT 9;

-- Source: http://blog.tanelpoder.com/2009/03/21/oracle-11g-reading-alert-log-via-sql/

SET LINESIZE 160
SET PAGESIZE 100

PROMPT ***********************************************************
PROMPT ** query_alert_log.sql
PROMPT ***********************************************************
PROMPT ** The following is a listing of all alert log messages  
PROMPT ** generated since the beginning of the last day.
PROMPT ***********************************************************

COL ts              FOR A20
COL message_text    FOR A100

SELECT  to_char(originating_timestamp,'dd.mm.yyyy hh24:mi:ss') AS "TS"
,       message_text
FROM    x$dbgalertext
WHERE   1=1
AND     originating_timestamp > TRUNC(SYSDATE)-1
;

EXIT;
