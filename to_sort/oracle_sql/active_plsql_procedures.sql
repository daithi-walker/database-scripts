select 'CALLED PLSQL', vs.username, d_o.object_name
  from dba_objects d_o
       inner join
       v$session vs
          on d_o.object_id = vs.plsql_entry_object_id
union all
select 'CURRENT PLSQL', vs.username, d_o.object_name
  from dba_objects d_o
       inner join
       v$session vs
          on d_o.object_id = vs.plsql_object_id;

plsql_entry_object_id=Object ID of the top-most PL/SQL subprogram on the stack; NULL if there is no PL/SQL subprogram on the stack
plsql_object_id=Object ID of the currently executing PL/SQL subprogram; NULL if executing SQL

SELECT se.sid
,      se.serial#
,      se.username
,      se.status
,      ( SELECT dp.object_name    FROM dba_procedures dp WHERE dp.object_id = se.plsql_entry_object_id AND dp.subprogram_id = 0) AS plsql_entry_object
,      ( SELECT dp.procedure_name FROM dba_procedures dp WHERE dp.object_id = se.plsql_entry_object_id AND dp.subprogram_id = se.plsql_entry_subprogram_id) AS plsql_entry_subprogram
,      ( SELECT dp.object_name    FROM dba_procedures dp WHERE dp.object_id = se.plsql_object_id       AND dp.subprogram_id = 0) AS plsql_entry_object
,      ( SELECT dp.procedure_name FROM dba_procedures dp WHERE dp.object_id = se.plsql_object_id       AND dp.subprogram_id = se.plsql_subprogram_id) AS plsql_entry_subprogram
,      ( SELECT max(sq.sql_text) FROM v$sql sq WHERE sq.sql_id = se.sql_id ) AS sql_text
--,      se.*
FROM   v$session se
WHERE  1=1
AND   se.status = 'ACTIVE'
AND    sid = :sid
AND    plsql_entry_object_id IS NOT NULL
AND    username = 'OLIVE'
ORDER BY se.sid