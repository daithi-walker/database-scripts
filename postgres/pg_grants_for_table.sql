-- Source: http://stackoverflow.com/questions/7336413/query-grants-for-a-table-in-postgres

--SQL
SELECT  rtg.grantee
,       rtg.privilege_type 
FROM    information_schema.role_table_grants rtg
WHERE   1=1
AND     rtg.table_name = 'mytable'

--psql
\z mytable

