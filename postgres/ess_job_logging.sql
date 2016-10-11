select  date_trunc('second',coalesce(jl.end_time,clock_timestamp()) - jl.start_time) as duration
,       jl.start_time::timestamp(0)
,       jl.end_time::timestamp(0)
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
        and     job_name = 'performance.upload_lineitem_activity:performance.dcm_activity:source_id-1'
        --and     job_name = 'performance.upload_lineitem_delivery:performance.dcm_delivery:source_id-1'
        --and     job_name = 'performance.upload_lineitem_activity:performance.ds3_activity:source_id-3'
        --and     job_name = 'performance.upload_lineitem_delivery:performance.ds3_delivery:source_id-3'
        and     start_time  > current_date-1
        )
order by
        job_id desc
,      step_id desc
limit 10;



-- summarise runs for the last day
with    jm as
        (
        select  job_id
        from    utils.job_monitor
        where   1=1
        --and     job_name = 'ds3.update_search_agg_from_olive'
        --and     job_name = 'performance.upload_lineitem_delivery:performance.dbm_delivery:source_id-8'
        and     start_time > current_date - 1
        )
,       jl as
        (
        select  min(jl.start_time) over (partition by jl.job_id order by jl.job_id) min_start_time
        ,       max(jl.end_time) over (partition by jl.job_id order by jl.job_id) max_end_time
        ,       jl.*
        from    utils.job_logging jl
        ,       jm
        where   1=1
        and     jm.job_id = jl.job_id
        )
select  jl.job_id
,       jl.min_start_time::timestamp(0)
,       (jl.max_end_time::timestamp(0) - jl.min_start_time::timestamp(0)) as total_duration
,       sum(date_trunc('second', jl.end_time - jl.start_time)) as total_exec_time
,       sum(jl.num_of_rows) as total_rows_processed
from    jl
where   1=1
and     (jl.max_end_time::timestamp(0) - jl.min_start_time::timestamp(0)) > interval '1 hours'
group by jl.job_id
,        jl.min_start_time
,        (jl.max_end_time::timestamp(0) - jl.min_start_time::timestamp(0))
order by jl.job_id desc
--order by total_duration
limit 1
;