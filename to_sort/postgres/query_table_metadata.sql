SELECT  'select * from '||table_schema||'.'||table_name||';' vsql
FROM    information_schema.tables 
WHERE   1=1
AND     table_schema = 'services'
ORDER BY table_name;

-- OR... 

SELECT  'select * from '||schemaname||'.'||tablename||';' vsql
FROM    pg_tables
WHERE   1=1
AND     schemaname = 'services'
ORDER BY tablename;

select * from services.alert_messages;
select * from services.alert_subscription;
select * from services.archive_check_results;
select * from services.archive_checks;
select * from services.archiving;
select * from services.archiving_errors;
select * from services.bq_query_config;
select * from services.data_mart_sync;
select * from services.emr_job_status;
select * from services.exporting;
select * from services.file_monitor_subscription;
select * from services.ldr_columns;
select * from services.ldr_config_view;
select * from services.ldr_data_types;
select * from services.ldr_db_conn_types;
select * from services.ldr_dtype_param;
select * from services.ldr_feed_format;
select * from services.ldr_loaders;
select * from services.ldr_loader_types;
select * from services.ldr_schemas;
select * from services.ldr_schema_types;
select * from services.ldr_subschemas;
select * from services.process_monitor where trigger = '8f6d5738-9e9c-4c23-990a-a23cc96d5b25' order by process_ord;
select * from services.process_status where trigger = '8f6d5738-9e9c-4c23-990a-a23cc96d5b25';
select * from services.producer_log where out_routing_key = 'appsflyer.trigger' order by sent_time desc;
select * from services.s3_upload;
select * from services.scheduling where routing_key like '%apps%flyer%';
select * from services.scheduling_runs where job_id = 47; --appsflyer.trigger
