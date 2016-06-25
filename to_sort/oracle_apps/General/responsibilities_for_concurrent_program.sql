--SELECT USERENV('LANG') FROM DUAL;
--ALTER SESSION SET NLS_LANGUAGE='AMERICAN';

SELECT   fcpt.user_concurrent_program_name
,        frt.responsibility_name
,        frs.responsibility_key
,        frg.request_group_name
,        frg.description
FROM     fnd_request_groups frg
,        fnd_request_group_units frgu
,        fnd_concurrent_programs fcp
,        fnd_concurrent_programs_tl fcpt
,        fnd_responsibility_tl frt
,        fnd_responsibility frs
WHERE    1=1
AND      frgu.unit_application_id = fcp.application_id
AND      frgu.request_unit_id = fcp.concurrent_program_id
AND      frg.request_group_id = frgu.request_group_id
AND      frg.application_id = frgu.application_id
AND      fcpt.source_lang = USERENV('LANG')
AND      fcp.application_id = fcpt.application_id
AND      fcp.concurrent_program_id = fcpt.concurrent_program_id
AND      frs.application_id = frt.application_id
AND      frs.responsibility_id = frt.responsibility_id
AND      frt.source_lang = USERENV('LANG')
AND      frs.request_group_id = frg.request_group_id
AND      frs.application_id = frg.application_id
AND      frs.end_date IS NULL
AND      fcp.concurrent_program_name = :concurrent_program_name
--AND      fcpt.user_concurrent_program_name LIKE <User concurrent program>
;
