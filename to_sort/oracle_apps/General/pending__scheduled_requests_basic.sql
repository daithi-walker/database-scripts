ALTER SESSION SET NLS_LANGUAGE='AMERICAN';

ALTER SESSION SET NLS_LANGUAGE='AMERICAN';

SELECT   fcrs.request_id
,        fcrs.program
,        DECODE(fcrs.status_code
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
,        DECODE(fcrs.phase_code
               ,'C', 'Completed'
               ,'I', 'Inactive'
               ,'P', 'Pending'
               ,'R', 'Running'
               ) phase
--,        fcrs.priority
,        TO_CHAR(fcrs.request_date,'DD-MON-YYYY HH24:MI:SS') request_date
,        fu.user_name
,        TO_CHAR(fcrs.requested_start_date,'DD-MON-YYYY HH24:MI:SS') requested_start_date
--,        fcrs.hold_flag
--,        fcrs.has_sub_request
--,        fcrs.update_protected
--,        fcrs.queue_method_code
--,        fcrs.*
FROM     apps.fnd_conc_req_summary_v fcrs
,        apps.fnd_user fu
WHERE    1=1
AND      fu.user_id = fcrs.requested_by
AND      fcrs.phase_code = 'P'
AND      fcrs.status_code IN ('I', 'Q')
AND      NVL(fcrs.request_type, 'X') <> 'S'
--AND      fcrs.requested_start_date >= SYSDATE
ORDER BY fcrs.requested_start_date;