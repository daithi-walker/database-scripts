select  --pg_terminate_backend(pid),
        (current_timestamp - backend_start) as duration_st
,       (current_timestamp - state_change) as duration_lc
,       octet_length(query) as query_bytes
--,       datid
,       datname
,       pid
--,       usesysid
,       usename
--,       application_name
--,       client_addr
--,       client_hostname
--,       client_port
,       backend_start::timestamp(0)
,       xact_start::timestamp(0)
,       query_start::timestamp(0)
,       state_change::timestamp(0)
,       waiting
,       state
--,       backend_xid
--,       backend_xmin
,       query
from   pg_stat_activity
where  1=1
and    pid <> pg_backend_pid()
and    backend_start < current_timestamp - interval '10' minute -- for long running jobs
--and    (xact_start is null and query = 'COMMIT') -- for connections that are not being closed.
and    (
       state in ('idle', 'idle in transaction', 'idle in transaction (aborted)', 'disabled')
       and
       not waiting
       and
       state_change < current_timestamp - interval '5' minute
       )  -- for idle connections
and    query <> 'COMMIT'
--and    application_name  <> ''
--and    usename = 'david.walker'
order by backend_start
