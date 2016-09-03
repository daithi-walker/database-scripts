-- Source: 
-- http://michael.otacoo.com/postgresql-2/postgres-feature-highlight-pg_buffercache/

SELECT  pc.relname
,       count(*) AS buffers
FROM    pg_buffercache pb
,       pg_class pc
WHERE   1=1
AND     pb.relfilenode = pg_relation_filenode(pc.oid)
AND     pb.reldatabase IN
        (0
        ,(
            SELECT  oid
            FROM    pg_database
            WHERE   datname = current_database()
         )
        )
GROUP BY pc.relname
ORDER BY 2 DESC
LIMIT 20;