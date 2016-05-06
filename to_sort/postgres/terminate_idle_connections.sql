select  --pg_terminate_backend(psa.pid),
        clock_timestamp() - psa.query_start as duration
,       psa.*
from    pg_stat_activity psa
where   1=1
and     psa.datname = 'mis'
and     psa.pid <> pg_backend_pid()
--and     psa.pid = 17438
--and     application_name = 'pgAdmin III - Query Tool'
and     psa.state like '%idle%'
--and     psa.usename in ('olive')
--and     psa.usename = 'iria.blanco'
--and     (psa.usename in ('olive','data','reporting'))
and     application_name  <> 'psql'
and     (
        psa.usename not in ('olive','data','reporting')
        or
            (
            psa.usename in ('olive','data','reporting')
            and
            application_name  is not null
            and
            application_name  <> ''
            )
        )
and     psa.state_change < current_timestamp - interval '1' hour
;

select  pg_terminate_backend(psa.pid)
,       clock_timestamp() - psa.query_start as duration
,       psa.*
from    pg_stat_activity psa
where   1=1
and     psa.datname = 'mis'
and     psa.pid <> pg_backend_pid()
and     psa.state like 'idle%'
--and     psa.usename = 'david.walker'
and     psa.usename not in ('olive','data','reporting')
and     psa.state_change < current_timestamp - interval '1' day
;

select  --pg_terminate_backend(psa.pid),
        clock_timestamp() - psa.query_start as duration
,       psa.*
from    pg_stat_activity psa
where   1=1
and     psa.datname = 'mis'
and     psa.pid <> pg_backend_pid()
and     psa.state like '%idle%'
and     psa.usename = 'sean'
and     psa.usename not in ('olive','data','reporting')
--and     psa.state_change < current_timestamp - interval '1' day
;

