-------------------------------------------------------------------------------
-- Query to find concurrent programs by respsonsibility
-------------------------------------------------------------------------------
SELECT   frt.responsibility_name              "Responsibility Name"
,        cpt.user_concurrent_program_name     "Concurrent Program Name"
,        DECODE(rgu.request_unit_type
               ,'P', 'Program'
               ,'S', 'Set'
               ,rgu.request_unit_type
               )                              "Program/Set"
,        rg.request_group_name                "Request Group Name"
,        fat.application_name                 "Application Name"
FROM     fnd_request_groups          rg
,        fnd_request_group_units     rgu
,        fnd_concurrent_programs     cp
,        fnd_concurrent_programs_tl  cpt
,        fnd_application             fa
,        fnd_application_tl          fat
,        fnd_responsibility          fr
,        fnd_responsibility_tl       frt
WHERE    1=1
AND      frt.RESPONSIBILITY_ID      = fr.RESPONSIBILITY_ID
AND      frt.application_id         = fr.application_id
AND      fr.application_id          = rg.application_id
AND      fr.request_group_id        = rg.request_group_id
AND      rg.request_group_id        = rgu.request_group_id
AND      rgu.request_unit_id        = cp.concurrent_program_id
AND      cp.concurrent_program_id   = cpt.concurrent_program_id
AND      rg.application_id          = fat.application_id
AND      fa.application_id          = fat.application_id
--AND      cpt.language               = USERENV('LANG')
--AND      fat.language               = USERENV('LANG')
--AND      cp.concurrent_program_name LIKE 'XX%'
--AND      cpt.user_concurrent_program_name LIKE '%%'
AND      NVL(fr.end_date,SYSDATE)   = SYSDATE
ORDER BY frt.responsibility_name
,        cpt.user_concurrent_program_name
,        rg.request_group_name
,        fat.application_name       
;