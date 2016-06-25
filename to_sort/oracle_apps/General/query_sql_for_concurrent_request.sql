-- GET THE CURRENT SQL STATEMENT RUNNING FOR A CONCURRENT REQUEST
select   fcr.request_id
,        DECODE(fcr.status_code
               ,'A', 'Waiting'
               ,'B', 'Resuming'
               ,'C', 'Normal'
               ,'D', 'Cancelled'
               ,'E', 'Error'
               ,'F', 'Scheduled'
               ,'G', 'Warning'
               ,'H', 'On Hold'
               ,'I', 'Normal'
               ,'M', 'No Manager'
               ,'Q', 'Standby'
               ,'R', 'Normal'
               ,'S', 'Suspended'
               ,'T', 'Terminating'
               ,'U', 'Disabled'
               ,'W', 'Paused'
               ,'X', 'Terminated'
               ,'Z', 'Waiting','Error') status
,        DECODE(fcr.phase_code,'C', 'Completed'
               ,'I', 'Inactive'
               ,'P', 'Pending'
               ,'R', 'Running'
               ) phase
,        sess.sid
,        sess.serial#
,        sess.osuser
,        sess.process
,        proc.spid
,        sess.status session_status
,        sql.sql_text
from     apps.fnd_concurrent_requests fcr
,        apps.fnd_concurrent_processes fcp
,        v$process proc
,        v$session sess
,        v$sql sql
where    1=1
and      fcr.controlling_manager = fcp.concurrent_process_id
and      proc.pid = fcp.oracle_process_id
and      fcp.session_id = sess.audsid
and      sess.sql_address = sql.address (+)
--and      sess.status <> 'INACTIVE'
--and      fcr.phase_code <> 'C'
and      fcr.request_id = :REQUEST_ID
order by fcr.request_id
;