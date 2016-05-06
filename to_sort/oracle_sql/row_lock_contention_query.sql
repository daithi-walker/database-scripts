SELECT s.sid, q.sql_text
FROM   v$session s
,      v$sql q
WHERE  1=1
AND    q.sql_id (+) = s.sql_id
AND    s.state = 'WAITING'
AND    s.wait_class != 'Idle'
AND    s.event = 'enq: TX - row lock contention';