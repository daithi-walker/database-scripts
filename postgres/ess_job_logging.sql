select  coalesce(jl.end_time,now()) - jl.start_time duration
,       jl.*
from    utils.job_logging jl
where   1=1
and     job_id in
        (
        select distinct job_id
        from utils.job_logging
        where 1=1
        and table_name = 'ds3_tmp_search_agg_from_olive_changed'
        and start_time > '01-JUN-2016'::date
        )
--and     table_name = 'ds3_tmp_search_agg_from_olive_changed'
--and     start_time > '01-JUN-2016'::date
and     job_id = 579788
order by
        job_id desc
,       step_id desc
--limit 1
;