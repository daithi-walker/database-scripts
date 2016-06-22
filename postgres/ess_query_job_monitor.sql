select  job_name
,       max(case when rnk = 1 then start_time else null end) last_run_time
,       max(case when rnk = 1 then duration else 0 end) last_run_duration
,       round(avg(case when rnk <> 1 then duration else 0 end)) as "avg_prev_duration"
,       count(*) cnt_job
,       min(case when rnk <> 1 then duration else 0 end) as "min_prev_duration"
,       max(case when rnk <> 1 then duration else 0 end) as "max_prev_duration"
from    (
        select  job_name
        ,       start_time
        --,       end_time
        ,       rank() over (partition by job_name order by job_id desc) rnk
        ,       round(
                    extract(seconds from (end_time-start_time)) + 
                    extract(mins    from (end_time-start_time))*60 + 
                    extract(hours   from (end_time-start_time))*60*60 +
                    extract(days    from (end_time-start_time))*60*60*24
                    ) duration
        from    utils.job_monitor where 1=1
        and     start_time > '2016-06-16 00:00:00'::date
        and     status = 0
        ) sub
group by job_name
order by last_run_time desc
--limit 10
;