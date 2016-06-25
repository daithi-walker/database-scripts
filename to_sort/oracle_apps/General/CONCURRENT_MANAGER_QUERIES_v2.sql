--Count of pending concurrent requests:
select COUNT (distinct cwr.request_id) Peding_Requests   FROM apps.fnd_concurrent_worker_requests cwr, apps.fnd_concurrent_queues_tl cq, apps.fnd_user fu WHERE (cwr.phase_code = 'P' OR cwr.phase_code = 'R')   AND cwr.hold_flag != 'Y'   AND cwr.requested_start_date <= SYSDATE    AND cwr.concurrent_queue_id = cq.concurrent_queue_id   AND cwr.queue_application_id = cq.application_id  and cq.LANGUAGE='US'
AND cwr.requested_by = fu.user_id and cq.user_concurrent_queue_name
in ( select unique user_concurrent_queue_name from apps.fnd_concurrent_queues_tl);

--Pending with CRM
select count(cwr.request_id) "Pending with CRM" FROM apps.fnd_concurrent_worker_requests cwr, apps.fnd_concurrent_queues_tl cq, apps.fnd_user fu
WHERE (cwr.phase_code = 'P' OR cwr.phase_code = 'R')   AND cwr.hold_flag != 'Y'   AND cwr.requested_start_date <= SYSDATE
AND cwr.concurrent_queue_id = cq.concurrent_queue_id   AND cwr.queue_application_id = cq.application_id  and cq.LANGUAGE='US'
AND cwr.requested_by = fu.user_id and cq.user_concurrent_queue_name in ( 'Conflict Resolution Manager');

--Pending with Standard Manager
select count(cwr.request_id) "pending with Standard Manager" FROM apps.fnd_concurrent_worker_requests cwr, apps.fnd_concurrent_queues_tl cq, apps.fnd_user fu
WHERE (cwr.phase_code = 'P' OR cwr.phase_code = 'R')   AND cwr.hold_flag != 'Y'   AND cwr.requested_start_date <= SYSDATE
AND cwr.concurrent_queue_id = cq.concurrent_queue_id   AND cwr.queue_application_id = cq.application_id  and cq.LANGUAGE='US'
AND cwr.requested_by = fu.user_id and cq.user_concurrent_queue_name in ( 'Standard Manager');

--Pending with Internal Manager
select COUNT (distinct cwr.request_id) "Pending with Internal Manager"   FROM apps.fnd_concurrent_worker_requests cwr, apps.fnd_concurrent_queues_tl cq, apps.fnd_user fu WHERE (cwr.phase_code = 'P' OR cwr.phase_code = 'R')   AND cwr.hold_flag != 'Y'   AND cwr.requested_start_date <= SYSDATE    AND cwr.concurrent_queue_id = cq.concurrent_queue_id   AND cwr.queue_application_id = cq.application_id  and cq.LANGUAGE='US'     AND cwr.requested_by = fu.user_id and cq.user_concurrent_queue_name in ('Internal Manager');

--Pending with Any other Manager this sql Prompts for the Manager Name
select COUNT (distinct cwr.request_id) Peding_Requests FROM apps.fnd_concurrent_worker_requests cwr, apps.fnd_concurrent_queues_tl cq, apps.fnd_user fu WHERE (cwr.phase_code = 'P' OR cwr.phase_code = 'R')   AND cwr.hold_flag != 'Y'   AND cwr.requested_start_date <= SYSDATE    AND cwr.concurrent_queue_id = cq.concurrent_queue_id   AND cwr.queue_application_id = cq.application_id  and cq.LANGUAGE='US'     AND cwr.requested_by = fu.user_id and cq.user_concurrent_queue_name in ('&Concurrent_Manager_Name');

--User Concurrent Queue Status
select MAX_PROCESSES,RUNNING_PROCESSES from apps.fnd_CONCURRENT_QUEUES where CONCURRENT_QUEUE_NAME
in(select CONCURRENT_QUEUE_NAME from apps.fnd_CONCURRENT_QUEUES_TL where USER_CONCURRENT_QUEUE_NAME='&User_Concurrent_Queue_name');

--Concurrent Request Status this prompts for request id
select REQUEST_ID,PHASE_CODE,STATUS_CODE,HOLD_FLAG,HAS_SUB_REQUEST,IS_SUB_REQUEST,to_char(ACTUAL_START_DATE,'dd-mon-yy hh24:mi:ss') "Start Date",CONCURRENT_PROGRAM_NAME,CONCURRENT_QUEUE_NAME,USER_CONCURRENT_PROGRAM_NAME  from apps.fnd_concurrent_worker_requests where REQUEST_ID=&reqid;

--Concurrent queue name and its user concurrent queue name
col CONCURRENT_QUEUE_NAME for a30
col USER_CONCURRENT_QUEUE_NAME for a60
set line 200
select UNIQUE FCQ.CONCURRENT_QUEUE_NAME,FCQT.USER_CONCURRENT_QUEUE_NAME,fcq.max_processes,fcq.running_processes
from apps.fnd_concurrent_queues fcq,apps.fnd_concurrent_queues_tl fcqt where fcq.concurrent_queue_id=fcqt.concurrent_queue_id and fcq.application_id=fcqt.application_id order by fcq.running_processes desc;

--Councurrent–>Manager–>Administer Screen from back-end
select cq.user_concurrent_queue_name,fcq.max_processes,fcq.running_processes,count(cwr.request_id)
FROM apps.fnd_concurrent_worker_requests cwr, apps.fnd_concurrent_queues_tl cq, apps.fnd_user fu,apps.fnd_concurrent_queues fcq
WHERE (cwr.phase_code = 'P' OR cwr.phase_code = 'R')   AND cwr.hold_flag != 'Y'   AND cwr.requested_start_date <= SYSDATE
AND cwr.concurrent_queue_id = cq.concurrent_queue_id   AND cwr.queue_application_id = cq.application_id  and cq.LANGUAGE='US'
and fcq.concurrent_queue_id=cq.concurrent_queue_id and fcq.application_id=cq.application_id
AND cwr.requested_by = fu.user_id and cq.user_concurrent_queue_name
in (select unique user_concurrent_queue_name from apps.fnd_concurrent_queues_tl)
group by cq.user_concurrent_queue_name,fcq.max_processes,fcq.running_processes;