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



-- summarise runs for the last day
with    x as
        (
        select  job_id
        from    utils.job_monitor
        where   1=1
        and     job_name = 'ds3.update_search_agg_from_olive'
        and     start_time > current_date-1
        )
,       y as
        (
        select  min(jl.start_time) over (partition by jl.job_id order by jl.job_id) min_start_time
        ,       jl.*
        from    utils.job_logging jl
        ,       x
        where   1=1
        and     x.job_id = jl.job_id
        )
select  y.job_id
,       y.min_start_time
,       sum(y.end_time - y.start_time) as total_duration
,       sum(y.num_of_rows) as total_rows_processed
from    y
group by y.job_id
,        y.min_start_time
order by y.job_id desc;