SELECT  nmsp_parent.nspname AS parent_schema
,       parent.relname      AS parent
,       nmsp_child.nspname  AS child_schema
,       child.relname       AS child
FROM    pg_inherits
,       pg_class parent
,       pg_class child
,       pg_namespace nmsp_parent
,       pg_namespace nmsp_child
WHERE   parent.relname = 'parent_table_name'
AND     pg_inherits.inhparent = parent.oid
AND     pg_inherits.inhrelid   = child.oid
AND     nmsp_parent.oid  = parent.relnamespace
AND     nmsp_child.oid   = child.relnamespace
;