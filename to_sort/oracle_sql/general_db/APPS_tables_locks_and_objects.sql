select   a.request_id
,        d.sid
,        d.serial#
,        d.osuser
,        d.process
,        c.spid
,        e.sql_text
from     apps.fnd_concurrent_requests a
,        apps.fnd_concurrent_processes b
,        v$process c
,        v$session d
,        v$sql e
where    1=1
and      a.controlling_manager = b.concurrent_process_id
and      c.pid = b.oracle_process_id
and      b.session_id = d.audsid
and      d.sql_address = e.address
and      a.request_id = :request_id;
   
SELECT   username U_NAME
,        owner OBJ_OWNER
,        object_name
,        object_type
,        s.osuser
,        DECODE(l.block
               ,0, 'Not Blocking'
               ,1, 'Blocking'
               ,2, 'Global'
               ) STATUS
,        DECODE(v.locked_mode
               ,0, 'None'
               ,1, 'Null'
               ,2, 'Row-S (SS)'
               ,3, 'Row-X (SX)'
               ,4, 'Share'
               ,5, 'S/Row-X (SSX)'
               ,6, 'Exclusive'
               ,TO_CHAR(lmode)
               ) MODE_HELD
,        s.*
FROM     gv$locked_object v
,        dba_objects d
,        gv$lock l
,        gv$session s
WHERE    1=1
AND      v.object_id = d.object_id
AND      d.object_name  = :object_name --AP_INV_SELECTION_CRITERIA_ALL
AND      v.object_id = l.id1
AND      v.session_id = s.sid
ORDER BY username
,        session_id;