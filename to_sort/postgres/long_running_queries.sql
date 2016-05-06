select  clock_timestamp() - psa.query_start as duration
,       psa.*
from    pg_stat_activity psa
where   1=1
and     psa.query <> ''::text
and     state_change < clock_timestamp() - interval '30' minute
and     state like 'idle'
order by clock_timestamp() - psa.query_start desc;