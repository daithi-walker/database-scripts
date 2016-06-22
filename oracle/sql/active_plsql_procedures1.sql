WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;
WHENEVER OSERROR EXIT 9;

SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT WRAPPED
SET LINESIZE 160;
SET PAGESIZE 1000;

PROMPT ***********************************************************
PROMPT ** active_plsql_procedures1.sql
PROMPT ***********************************************************
PROMPT ** 
PROMPT ***********************************************************

COL SID FOR A4
COL SERIAL FOR A4
COL USERNAME FOR A10
COL STATUS FOR A10
COL PLSQL_ENTRY_OBJECT1 FOR A10
COL PLSQL_ENTRY_SUBPROGRAM1 FOR A10
COL PLSQL_ENTRY_OBJECT2 FOR A10
COL PLSQL_ENTRY_SUBPROGRAM2 FOR A10
COL SQL_TEXT FOR A30

SELECT  se.sid      AS "SID"
,       se.serial#  AS "SERIAL"
,       se.username AS "USERNAME"
,       se.STATUS   AS "STATUS"
,       (
        SELECT  dp.object_name
        FROM    dba_procedures dp
        WHERE   1=1
        AND     dp.object_id = se.plsql_entry_object_id
        AND     dp.subprogram_id = 0
        ) AS "PLSQL_ENTRY_OBJECT1"
,       (
        SELECT  dp.procedure_name
        FROM    dba_procedures dp
        WHERE   1=1
        AND     dp.object_id = se.plsql_entry_object_id
        AND     dp.subprogram_id = se.plsql_entry_subprogram_id
        ) AS "PLSQL_ENTRY_SUBPROGRAM1"
,       (
        SELECT  dp.object_name
        FROM    dba_procedures dp
        WHERE   1=1
        AND     dp.object_id = se.plsql_object_id
        AND     dp.subprogram_id = 0
        ) AS "PLSQL_ENTRY_OBJECT2"
,       (
        SELECT  dp.procedure_name
        FROM    dba_procedures dp
        WHERE   1=1
        AND     dp.object_id = se.plsql_object_id
        AND     dp.subprogram_id = se.plsql_subprogram_id
        ) AS "PLSQL_ENTRY_SUBPROGRAM2"
,       (
        SELECT  MAX(sq.sql_text)
        FROM    v$sql sq
        WHERE   1=1
        AND     sq.sql_id = se.sql_id
        ) AS "SQL_TEXT"
--,       se.*
FROM    v$session se
WHERE   1=1
AND     se.status = 'ACTIVE'
AND     se.sid = :sid
AND     se.plsql_entry_object_id IS NOT NULL
AND     se.username = 'OLIVE'
ORDER BY se.sid;

EXIT;