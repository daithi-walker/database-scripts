SELECT   pn.nspname  constraint_schema
,        pcl.relname constraint_table
,        pco.conname constraint_name
,        CASE pco.contype WHEN 'c' THEN 'check constraint' WHEN 'f' THEN 'foreign key constraint' WHEN 'p' THEN 'primary key constraint' WHEN 'u' THEN 'unique constraint' END constraint_Type
,        'ALTER TABLE '''||pn.nspname||'''.'''||pcl.relname||''' ADD CONSTRAINT '''||pco.conname||''' '||pg_get_constraintdef(pco.oid)||';' constraint_dml
FROM     pg_constraint pco
,        pg_class pcl
,        pg_namespace pn
WHERE    1=1
AND      pco.conrelid = pcl.oid
AND      pn.oid = pcl.relnamespace
AND      pco.conname = 'archiving_runs_status_check'
AND      pcl.relname = 'archiving_runs'
ORDER BY pn.nspname
,    pcl.relname
,    CASE pco.contype WHEN 'c' THEN 4 WHEN 'f' THEN 2 WHEN 'p' THEN 1 WHEN 'u' THEN 3 END
,    pco.conname
;
