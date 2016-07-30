select  coalesce(jl.end_time,clock_timestamp()) - jl.start_time as duration
,       jl.step_id
,       jl.job_id
,       jl.table_name
,       jl.operation
,       jl.num_of_rows
from    utils.job_logging jl
where   1=1
and     job_id in
        (
        select  job_id
        from    utils.job_monitor
        where   1=1
        and     job_name = 'ds3.update_search_agg_from_olive'
        and     start_time > current_date-1
        --and     start_time > '01-JUN-2016'::date
        )
order by
        job_id desc
,       step_id desc;