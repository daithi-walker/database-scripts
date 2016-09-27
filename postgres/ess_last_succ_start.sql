\x auto
prepare vsql (bigint) as
with main as
    (
    select  jm.job_id
    ,       jm.job_name
    ,       jm.effective_start_time::timestamp(0)
    ,       jm.start_time::timestamp(0)
    ,       jm.end_time::timestamp(0)
    ,       jm.last_succ_start::timestamp(0)
    ,       lag(jm.job_id) over (partition by case when end_time is null then 'error' else jm.job_name end order by jm.job_id) prev_job_id
    from    utils.job_monitor jm
    where   1=1
    and     jm.job_name = 'performance.upload_lineitem_delivery:performance.dbm_delivery:source_id-8'
    )
select  main.*
,       jm.last_succ_start::timestamp(0) prev_last_succ_start
from    main
,       utils.job_monitor jm
where   1=1
and     jm.job_id = main.prev_job_id
and     jm.job_id = $1
order by jm.job_id desc;
execute vsql(1196510);
deallocate vsql;


with main as
    (
    select  jm.job_id
    ,       jm.job_name
    ,       jm.effective_start_time::timestamp(0)
    ,       jm.start_time::timestamp(0)
    ,       jm.end_time::timestamp(0)
    ,       jm.last_succ_start::timestamp(0)
    ,       lag(jm.job_id) over (partition by case when end_time is null then 'error' else jm.job_name end order by jm.job_id) prev_job_id
    from    utils.job_monitor jm
    where   1=1
    and     jm.job_name = 'performance.update_lineitem_performance'
    )
select  main.*
,       jm.last_succ_start::timestamp(0) prev_last_succ_start
from    main
,       utils.job_monitor jm
where   1=1
and     main.start_time > '2016-09-13 15:05:00'
and     main.end_time < '2016-09-13 23:59'
and     jm.job_id = main.prev_job_id
order by jm.job_id desc;