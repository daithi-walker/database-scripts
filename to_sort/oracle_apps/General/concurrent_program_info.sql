--SELECT USERENV('LANG') FROM DUAL;
--ALTER SESSION SET NLS_LANGUAGE='AMERICAN';

SELECT   fat.application_name
,        fa.application_short_name
,        fa.basepath
,        cpt.user_concurrent_program_name
,        cp.enabled_flag
--,        fu.user_name || DECODE(ppf.full_name,NULL,NULL,' (' || ppf.full_name || ')') "CREATED_BY"
,        cpt.description
,        cp.output_file_type
,        DECODE(efv.execution_method_code
               ,'I',  'PL/SQL Stored Procedure'
               ,'H',  'Host'
               ,'S',  'Immediate'
               ,'J',  'Java Stored Procedure'
               ,'K',  'Java Concurrent Program'
               ,'M',  'Multi Language Function'
               ,'P',  'Oracle Reports'
               ,'B',  'Request Set Stage Function'
               ,'A',  'Spawned'
               ,'L',  'SQL*Loader'
               ,'Q',  'SQL*Plus'
               ,'E',  'Pearl Concurrent Programm'
               ,'Unknown')                execution_method
,        efv.executable_name
,        efv.execution_file_name
,        efv.execution_file_path
--,        DECODE(rgu.request_unit_type,
--               'P', 'Program',
--               'S', 'Set',
--               rgu.request_unit_type
--               )                          unit_type
,        cp.concurrent_program_name
--,        rg.application_id
--,        rg.request_group_name
--,        fat1.application_name 	   		req_grp_app_name
--,        fa1.application_short_name 		req_grp_app_short_name
FROM     apps.fnd_concurrent_programs     cp
,        apps.fnd_concurrent_programs_tl  cpt
,        apps.fnd_executables_form_v      efv
,        apps.fnd_application             fa
,        apps.fnd_application_tl          fat
--,        apps.fnd_request_group_units     rgu
--,        apps.fnd_request_groups          rg
--,        apps.fnd_application             fa1
--,        apps.fnd_application_tl          fat1
--,        apps.fnd_user                    fu
--,        apps.per_all_people_f            ppf
WHERE    1=1
AND      cp.concurrent_program_id  =  cpt.concurrent_program_id
--AND      efv.application_id        =  fa.application_id
AND      efv.executable_id         =  cp.executable_id
--AND      efv.application_id        =  cp.application_id
AND      fa.application_id         =  cpt.application_id
AND      fa.application_id         =  fat.application_id
--AND      fa.application_short_name like 'SQLAP'
--AND      rgu.request_unit_id       =  cp.concurrent_program_id
--AND      rg.request_group_id       =  rgu.request_group_id
--AND      rg.application_id         =  fa1.application_id
--AND      fa1.application_id        =  fat1.application_id
--AND      cp.created_by             =  fu.user_id (+)
--AND      fu.employee_id            =  ppf.person_id (+)
and      efv.executable_name       = ''
--AND      cpt.user_concurrent_program_name like ''
;