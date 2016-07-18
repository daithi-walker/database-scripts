WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;
WHENEVER OSERROR EXIT 9;

SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT WRAPPED
SET LINESIZE 130;
SET PAGESIZE 10000;

PROMPT ***********************************************************
PROMPT ** query_dba_audit_session.sql
PROMPT ***********************************************************
PROMPT ** The following is a listing of all connections to the 
PROMPT ** database for the previous week. 
PROMPT ** Excludes users that belong to Oracle or that come from 
PROMPT ** sanctioned applications.
PROMPT ***********************************************************

COL os_username FOR A20
COL username    FOR A8
COL userhost    FOR A25
COL terminal    FOR A25
COL timestamp   FOR A19
COL action_name FOR A11

SELECT  das.os_username
,       das.username
,       das.userhost
,       das.terminal
,       TO_CHAR(das.timestamp,'DD-MM-YYYY HH24:MI:SS') AS "TIMESTAMP"
,       das.action_name
FROM    sys.dba_audit_session das
WHERE   1=1
AND     das.timestamp > SYSDATE-7
AND     das.returncode = 0
AND     das.username NOT IN ('DBSNMP','SYSMAN')
AND     das.userhost NOT IN ('ESSENCE\ESS-LON-OLAP-01')
ORDER BY das.timestamp DESC
;

EXIT;
