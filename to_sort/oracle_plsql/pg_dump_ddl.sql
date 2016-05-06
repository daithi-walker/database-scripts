export PGPASSWORD="pgadild0"

SELECT   'pg_dump -U data -h ess-lon-mis-db-001 mis -s -t '||table_schema||'.'||table_name||' -f '||table_schema||'.'||table_name||'.sql' vsql
FROM     information_schema.tables
WHERE    1=1
AND      table_type = 'VIEW'
AND      table_schema NOT IN ('pg_catalog', 'information_schema')
AND      table_name !~ '^pg_'
ORDER BY table_schema
,        table_name
;