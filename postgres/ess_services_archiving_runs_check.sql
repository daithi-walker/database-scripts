select  procedure_name
,       waiting_jobs as waiting
,       running_jobs as running
,       run_started::timestamp(0)
,       date_trunc('second',run_duration) as run_duration
,       earliest_waiting::timestamp(0)
from    services.archiving_runs_check
--order by run_duration desc
order by waiting_jobs desc
;
