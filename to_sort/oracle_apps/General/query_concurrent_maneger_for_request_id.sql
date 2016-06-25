alter session set nls_language='american';

select   b.user_concurrent_queue_name
,        b.sleep_seconds
from     fnd_concurrent_processes a
,        fnd_concurrent_queues_vl b
,        fnd_concurrent_requests c
where    1=1
and      a.concurrent_queue_id = b.concurrent_queue_id
and      a.concurrent_process_id = c.controlling_manager
and      c.request_id = :request_id --10516705
;