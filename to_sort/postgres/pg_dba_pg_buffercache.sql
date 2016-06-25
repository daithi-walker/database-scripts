--does not require a restart
create extension if not exists pg_buffercache;

select * from pg_buffercache bc 

select pg_get_viewdef('pg_buffercache');

SELECT  p.bufferid
,       p.relfilenode
,       p.reltablespace
,       p.reldatabase
,       p.relforknumber
,       p.relblocknumber
,       p.isdirty
,       p.usagecount
FROM    pg_buffercache_pages() p(bufferid integer, relfilenode oid, reltablespace oid, reldatabase oid, relforknumber smallint, relblocknumber bigint, isdirty boolean, usagecount smallint);

SELECT  c.relname
,       count(*) AS buffers
FROM    pg_buffercache b
,       pg_class c
WHERE   1=1
AND     pg_relation_filenode(c.oid) = b.relfilenode
AND     b.reldatabase IN
        (0
        ,   (
            SELECT  oid
            FROM    pg_database
            WHERE   1=1
            AND     datname = current_database()
            )
        )
GROUP BY c.relname
ORDER BY 2 DESC
LIMIT 10;


SELECT  *
FROM    (
        SELECT  db.datname db_name
        ,       tsp.spcname table_space
        ,       pg_get_userbyid(c.relowner) object_owner
        ,       c.relname object_name
        ,       CASE c.relkind
                  WHEN 'r' THEN 'ordinary table'
                  WHEN 'i' THEN 'index'
                  WHEN 'S' THEN 'sequence'
                  WHEN 'v' THEN 'view'
                  WHEN 'm' THEN 'materialized view'
                  WHEN 'c' THEN 'composite type'
                  WHEN 't' THEN 'TOAST table'
                  WHEN 'f' THEN 'foreign table'
                  ELSE 'unkown type'
                END object_type
        ,       count(*) over (partition by c.relname) AS total_buffers
        ,       bc.bufferid
        ,       bc.relfilenode
        ,       bc.relblocknumber
        ,       bc.isdirty
        ,       bc.usagecount
        FROM    pg_buffercache bc
        ,       pg_class c
        ,       pg_tablespace tsp
        ,       pg_database db
        WHERE   1=1
        AND     c.relname = 'dwtest'
        AND     pg_relation_filenode(c.oid) = bc.relfilenode
        AND     tsp.oid = bc.reltablespace
        AND     db.oid = bc.reldatabase
        AND     bc.reldatabase IN
                (0
                ,   (
                    SELECT  oid
                    FROM    pg_database
                    WHERE   1=1
                    AND     datname = current_database()
                    )
                )
        ) sub
WHERE   1=1
ORDER BY total_buffers DESC
,        relblocknumber
--LIMIT 10
;