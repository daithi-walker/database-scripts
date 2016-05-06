-- run script via command line...
psql -h localhost -U data -d mis_local -f ./ddl/services/exporting/configurations/config.sql

-- export table dml
pg_dump -h localhost -U data -d mis_local -t 'service.archiving' --schema-only