--query to identify primary key for a table
SELECT   acc.table_name
,        acc.column_name
,        acc.position
,        ac.status
,        ac.owner
FROM     all_constraints ac
,        all_cons_columns acc
WHERE    1=1
and      ac.constraint_type = 'P'
and      acc.table_name in ('PER_ALL_PEOPLE_F','AP_INVOICES_ALL')
AND      ac.constraint_name = acc.constraint_name
AND      ac.owner = acc.owner
ORDER BY acc.table_name
,        acc.position;