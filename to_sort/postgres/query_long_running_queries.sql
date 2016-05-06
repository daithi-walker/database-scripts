select  clock_timestamp() - psa.query_start as duration
,       psa.*
from    pg_stat_activity psa
where   1=1
and     psa.query <> ''::text
and     clock_timestamp() - psa.query_start > interval '360 minutes'
--and     query like 'autovacuum%'
--and     application_name like 'pgAdmin%'
and     state like 'idle%'
order by state_change;

