SELECT  CAST(pl.relation::regclass as text) as "fullname"
,       pl.locktype
,       pl.mode
,       pl.transactionid AS tid
,       pl.virtualtransaction AS vtid
,       pl.pid
,       pl.granted
FROM    pg_catalog.pg_locks pl
LEFT JOIN pg_catalog.pg_database db ON db.oid = pl.database
WHERE   1=1
AND     (db.datname = 'mis' OR db.datname IS NULL)
AND     pl.pid = 23712
AND NOT pl.pid = pg_backend_pid()
ORDER BY fullname;