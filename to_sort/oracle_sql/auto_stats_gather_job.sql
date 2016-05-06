SELECT CLIENT_NAME               ,
       STATUS                    ,
       MEAN_INCOMING_TASKS_7_DAYS,
       MEAN_INCOMING_TASKS_30_DAYS
FROM   DBA_AUTOTASK_CLIENT
WHERE  CLIENT_NAME = 'auto optimizer stats collection';

--next run date for stats collection
select owner,job_name,job_class,enabled,next_run_date,repeat_interval
from dba_scheduler_jobs
where job_name = 'BSLN_MAINTAIN_STATS_JOB' ;

--past schedule of stats 
select * from dba_scheduler_job_run_details 
where 1=1
--and job_name = 'BSLN_MAINTAIN_STATS_JOB' 
order by 1 desc
;

--schedule is under BSLN_MAINTAIN_STATS_SCHED
select owner, schedule_name,schedule_type,start_date,repeat_interval 
from dba_scheduler_schedules 
where schedule_name = 'BSLN_MAINTAIN_STATS_SCHED';