WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;
WHENEVER OSERROR EXIT 9;

SET SERVEROUTPUT ON

-- PLSQL_ENTRY_OBJECT_ID = Object ID of the top-most
-- PL/SQLsubprogram on the stack; NULL if there is no
-- PL/SQL subprogram on the stack.
-- PLSQL_OBJECT_ID = Object ID of the currently executing
-- PL/SQL subprogram; NULL if executing SQL.
SELECT  'CALLED PLSQL' AS "PLSQL_TYPE"
,       vs.username
,       do.object_name
FROM    dba_objects do
,       v$session vs
WHERE   1=1
AND     do.object_id = vs.plsql_entry_object_id
UNION ALL
SELECT  'CURRENT PLSQL' AS "PLSQL_TYPE"
,       vs.username
,       do.object_name
FROM    dba_objects do
,       v$session vs
WHERE   1=1
AND     do.object_id = vs.plsql_object_id;

EXIT;
