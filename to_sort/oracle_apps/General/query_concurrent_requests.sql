alter session set nls_language='american';

SELECT   --fcr.*, 
         fcr.request_id 
,        fcr.oracle_process_id
,        fu.user_name   requested_by
,        frt.responsibility_name requested_using
,        fcr.requested_start_date
,        TO_CHAR(fcr.actual_start_date,'DD-MON-YYYY HH24:MI:SS') started
,        TO_CHAR(fcr.actual_completion_date,'DD-MON-YYYY HH24:MI:SS') completed
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
,        fcpt.user_concurrent_program_name
,        fcp.concurrent_program_name
,        fcr.argument_text
,        fcr.logfile_name
,        fcr.outfile_name
,        SUBSTR(fcq.concurrent_queue_name, 1, 20) queue
--,        fcr.priority_request_id
--,        fcr.priority
--,        fcp.request_priority
FROM     apps.fnd_concurrent_requests fcr
,        apps.fnd_concurrent_programs_tl fcpt
,        apps.fnd_concurrent_programs fcp
,        apps.fnd_responsibility_tl frt
,        apps.fnd_user fu
,        fnd_concurrent_processes fcp
,        apps.fnd_concurrent_queues fcq
WHERE    1=1
AND      fu.user_id = fcr.requested_by
AND      frt.responsibility_id = fcr.responsibility_id
AND      fcr.concurrent_program_id = fcpt.concurrent_program_id
AND      fcp.concurrent_program_id = fcpt.concurrent_program_id
--AND      fcr.request_id in ('8319432')
AND      fcpt.user_concurrent_program_name LIKE ''
--AND      fu.user_name = ''
--AND      fcr.argument_text LIKE '%%'
--AND      fcp.concurrent_program_name = ''
and      fcp.concurrent_process_id = fcr.controlling_manager
and      fcq.concurrent_queue_id = fcp.concurrent_queue_id
and      fcq.application_id = fcp.queue_application_id
ORDER BY fcr.actual_start_date DESC NULLS LAST
,        fcr.request_id DESC;

--select user_id from fnd_user where user_name = '';
--select responsibility_name, application_id, responsibility_id from fnd_responsibility_tl where responsibility_name like 'System Admin%'; --200, 52814

begin
   fnd_global.apps_initialize(45988  --USER_ID
                             ,20420 --RESP_ID
                             ,1   --RESP_APPL_ID
                             );
end;