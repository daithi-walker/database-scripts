--SELECT USERENV('LANG') FROM DUAL;
--ALTER SESSION SET NLS_LANGUAGE='AMERICAN';

select   acf.name                            paymnent_format_name
--,        app1.program_name                   build_registered_name
--,        app1.friendly_name                  build_friendly_name
,        fcp1.user_concurrent_program_name   build_cp_name
,        app2.program_name                   format_registered_name
,        app2.friendly_name                  format_friendly_name
,        fcp2.user_concurrent_program_name   format_cp_name
,        efv2.executable_name                format_exec_short_name
,        efv2.user_executable_name           format_exec_friendly_name
,        DECODE(efv2.execution_method_code
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
,        efv2.execution_file_name            format_exec_file_name
--,        app3.program_name                   remit_registered_name
--,        app3.friendly_name                  remit_friendly_name
,        fcp3.user_concurrent_program_name   remit_cp_name
--,        app4.program_name                   create_registered_name
--,        app4.friendly_name                  create_friendly_name
,        fcp4.user_concurrent_program_name   create_cp_name
--,        app5.program_name                   confirm_registered_name
--,        app5.friendly_name                  confirm_friendly_name
,        fcp5.user_concurrent_program_name   confirm_cp_name
from     ap_check_formats acf
,        ap_payment_programs app1
,        fnd_concurrent_programs_vl fcp1
,        ap_payment_programs app2
,        fnd_concurrent_programs_vl fcp2
,        apps.fnd_concurrent_programs     cp2
,        apps.fnd_concurrent_programs_tl  cpt2
,        apps.fnd_executables_form_v      efv2
,        ap_payment_programs              app3
,        fnd_concurrent_programs_vl       fcp3
--,        apps.fnd_concurrent_programs     cp3
--,        apps.fnd_concurrent_programs_tl  cpt3
--,        apps.fnd_executables_form_v      efv3
,        ap_payment_programs app4
,        fnd_concurrent_programs_vl fcp4
,        ap_payment_programs app5
,        fnd_concurrent_programs_vl fcp5
where    1=1
--and      acf.name in ('GROUP CAPS  EUR','GROUP CAPS  GBP')
and      acf.name like ''
and      app1.program_id (+)              = acf.build_payments_program_id
and      fcp1.concurrent_program_name (+) = app1.program_name
and      app2.program_id (+)              = acf.format_payments_program_id
and      fcp2.concurrent_program_name (+) = app2.program_name
and      app2.program_name                = cp2.concurrent_program_name
and      cpt2.concurrent_program_id       = cp2.concurrent_program_id
and      efv2.executable_id               = cp2.executable_id
and      app3.program_id (+)              = acf.remittance_advice_program_id
and      fcp3.concurrent_program_name (+) = app3.program_name
--and      app3.program_name                = cp3.concurrent_program_name
--and      cpt3.concurrent_program_id       = cp3.concurrent_program_id
--and      efv3.executable_id               = cp3.executable_id
--and      fcp3.user_concurrent_program_name = ''
and      app4.program_id (+)              = acf.create_payments_program_id
and      fcp4.concurrent_program_name (+) = app4.program_name
and      app5.program_id (+)              = acf.confirm_payments_program_id
and      fcp5.concurrent_program_name (+) = app5.program_name
;