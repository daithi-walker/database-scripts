select  procedure_name
,       waiting_jobs
,       running_jobs
,       run_started::timestamp(0)
,       date_trunc('second',run_duration) as run_duration
,       earliest_waiting
from    services.archiving_runs_check
order by waiting_jobs desc;