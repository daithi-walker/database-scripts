with    source
as      (
        select  3  as v_source_id
        )
,       activity_source
as      (
        select  v_source_id
        ,       activity_source as v_activity
        ,       delivery_source as v_delivery
        from    performance.sources
        ,       source
        where   source_id = v_source_id
        )
,       func
as      (
        select  'performance.upload_lineitem_activity'||':'||v_activity||':source_id-'||v_source_id as v_func
        from    activity_source
        union
        select  'performance.upload_lineitem_delivery'||':'||v_delivery||':source_id-'||v_source_id as v_func
        from    activity_source
        )
select  v_func
,       utils.get_last_succ_run(v_func) as v_last_run
from    func;
