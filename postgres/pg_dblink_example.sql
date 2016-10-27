SELECT  *
FROM    dblink('host=<host> port=<port> dbname=<dbname> user=<user> password=<password>'
              ,'select  procedure_name
                ,       waiting_jobs
                ,       running_jobs
                ,       run_started
                ,       run_duration
                ,       earliest_waiting
                from    services.archiving_runs_check;'
              )
AS DATA (procedure        text
        ,waiting_jobs     bigint
        ,running_jobs     bigint
        ,run_started      timestamp with time zone
        ,run_duration     interval
        ,earliest_waiting timestamp with time zone
        );