http://www.postgresql.org/docs/9.4/static/pgstatstatements.html

https://pganalyze.com/docs/install/01_enabling_pg_stat_statements
https://fmcgeough.wordpress.com/2014/08/31/postgresql-optimizing-sql-performance/

create extension "pg_stat_statements";

show shared_preload_libraries;

select * from pg_stat_statements;

SELECT query, calls, total_time, rows, 100.0 * shared_blks_hit /
               nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
          FROM pg_stat_statements ORDER BY total_time DESC LIMIT 5;