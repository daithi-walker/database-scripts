--drop indexes
SELECT   pn.nspname index_schema
,        pc2.relname index_table
,        pc.relname index_name
,        'DROP INDEX "'||pn.nspname||'"."'||pc.relname||'" RESTRICT;' dml
FROM     pg_index pi
,        pg_class pc
,        pg_namespace pn
,        pg_class pc2
WHERE    1=1
AND      pi.indexrelid = pc.oid
AND      pn.oid = pc.relnamespace
AND      pi.indisprimary = FALSE
AND      pi.indisvalid = TRUE
AND      pn.nspname NOT LIKE 'pg_%'
AND      pi.indrelid = pc2.oid
AND      pn.nspname = 'apps_flyer'
AND      pc2.relname = 'events'
ORDER BY pn.nspname
,        pc.relname;

--create indexes
SELECT   pn.nspname index_schema
,        pc2.relname index_table
,        pc.relname index_name
,        pg_get_indexdef(pi.indexrelid)||';' dml
FROM     pg_index pi
,        pg_class pc
,        pg_namespace pn
,        pg_class pc2
WHERE    1=1
AND      pi.indexrelid = pc.oid
AND      pn.oid = pc.relnamespace
AND      pi.indisprimary = FALSE
AND      pi.indisvalid = TRUE
AND      pn.nspname NOT LIKE 'pg_%'
AND      pi.indrelid = pc2.oid
AND      pn.nspname = 'apps_flyer'
AND      pc2.relname = 'events'
ORDER BY pn.nspname
,        pc.relname;
