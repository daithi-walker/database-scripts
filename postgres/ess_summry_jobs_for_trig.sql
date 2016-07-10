select  procedure_name
,       substr(triggers_str,1,strpos(triggers_str, '.')-1) as "TRIG_BASE"
,       sum(case when status = 'NEW' then 1 else 0 end) as "NEW"
,       sum(case when status = 'SENT_FOR_RETRY' then 1 else 0 end) as "SENT_FOR_RETRY"
,       sum(case when status = 'RUNNING' then 1 else 0 end) as "RUNNING"
,       sum(case when status = 'COMPLETED' then 1 else 0 end) as "COMPLETED"
,       sum(case when status = 'ERROR' then 1 else 0 end) as "ERROR"
,       sum(case when status = 'DUPLICATE' then 1 else 0 end) as "DUPLICATE"
from    services.archiving_runs
where   1=1 
and     triggers_str like '%24666c5e-b72c-4c9f-a1df-b724eed31bc2%'
group by procedure_name
,        substr(triggers_str,1,strpos(triggers_str, '.')-1)
order by procedure_name desc
;
