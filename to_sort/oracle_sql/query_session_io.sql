SELECT s.status,
       s.state,
       wait_class,
       seconds_in_wait,
       NVL(s.username, '(oracle)') AS username,
       s.osuser,
       s.sid,
       s.serial#,
       si.block_gets,
       si.consistent_gets,
       si.physical_reads,
       si.block_changes,
       si.consistent_changes
FROM   v$session s,
       v$sess_io si
WHERE  s.sid = si.sid
AND    s.sid = :sid
;