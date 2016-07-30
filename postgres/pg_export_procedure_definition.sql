psql -qAt -d mis -c "SELECT pg_catalog.pg_get_functiondef('ds3.update_search_agg_from_olive'::regproc);" > ./ds3.update_search_agg_from_olive.sql
