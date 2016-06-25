alter session set nls_language='american';

--to check run times for a concurrent request:

select   request_id
,        program
,        actual_start_date start_date
,        actual_completion_date end_date
,        trunc((actual_completion_date-actual_start_date)*24*60*60) duration_seconds
,        argument_text
from     fnd_conc_req_summary_v
where    1=1
and      user_concurrent_program_name = 'Preliminary Payment Register'
--and      status_code = 'C'
--and      phase_code = 'C'
order by request_id
;