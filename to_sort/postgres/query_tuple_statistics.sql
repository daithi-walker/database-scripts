http://www.postgresql.org/docs/9.1/static/pgstattuple.html

The pgstattuple module provides various functions to obtain tuple-level statistics.

select * from pgstattuple('ds3.import_keyword_delivery');
select * from pgstatindex('ds3.import_keyword_delivery_idx_trig');