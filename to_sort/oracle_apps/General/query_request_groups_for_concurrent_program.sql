-------------------------------------------------------------------------------
-- Query to find request group and application name for a concurrent program
-------------------------------------------------------------------------------
SELECT   cpt.user_concurrent_program_name     "Concurrent Program Name"
,        DECODE(rgu.request_unit_type
               ,'P', 'Program'
               ,'S', 'Set'
               ,rgu.request_unit_type
               )                              "Unit Type"
,        cp.concurrent_program_name           "Concurrent Program Short Name"
,        rg.application_id                    "Application ID"
,        rg.request_group_name                "Request Group Name"
,        fat.application_name                 "Application Name"
,        fa.application_short_name            "Application Short Name"
,        fa.basepath                          "Basepath"
FROM     fnd_request_groups          rg
,        fnd_request_group_units     rgu
,        fnd_concurrent_programs     cp
,        fnd_concurrent_programs_tl  cpt
,        fnd_application             fa
,        fnd_application_tl          fat
WHERE    1=1
AND      rg.request_group_id        =  rgu.request_group_id
AND      rgu.request_unit_id        =  cp.concurrent_program_id
AND      cp.concurrent_program_id   =  cpt.concurrent_program_id
AND      rg.application_id          =  fat.application_id
AND      fa.application_id          =  fat.application_id
AND      cpt.language               =  USERENV('LANG')
AND      fat.language               =  USERENV('LANG')
--AND      cpt.user_concurrent_program_name  = 'Active Users'
--AND      cp.concurrent_program_name = ''
;