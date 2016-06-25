select   log.*
from     fnd_log_messages log
,        fnd_log_transaction_context con
where    1=1
and      con.transaction_id = 7866958
and      con.transaction_type = 'REQUEST'
and      con.transaction_context_id = log.transaction_context_id
order by log.log_sequence desc