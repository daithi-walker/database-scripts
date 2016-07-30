SELECT  reltuples::bigint
FROM    pg_class
WHERE   1=1
AND     oid = 'ds3.import_keyword_status'::regclass;