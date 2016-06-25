ALTER SESSION SET nls_language = 'american';

SELECT   rs.user_request_set_name
,        rss.display_sequence
,        rss.user_stage_name
,        rsp.sequence stage_sequence
,        cp.user_concurrent_program_name
,        e.executable_name
,        e.execution_file_name
,        lv.meaning file_type
,        fat.application_name
FROM     apps.fnd_request_sets_vl rs
,        apps.fnd_req_set_stages_form_v rss
,        applsys.fnd_request_set_programs rsp
,        apps.fnd_concurrent_programs_vl cp
,        apps.fnd_executables e
,        apps.fnd_lookup_values lv
,        apps.fnd_application_tl fat
WHERE    1 = 1
--AND      rs.user_request_set_name LIKE '%%'
AND      rs.end_date_active IS NULL
AND      rss.set_application_id = rs.application_id
AND      rss.request_set_id = rs.request_set_id
AND      rsp.set_application_id = rss.set_application_id
AND      rsp.request_set_id = rss.request_set_id
AND      rsp.request_set_stage_id = rss.request_set_stage_id
AND      e.application_id = fat.application_id
AND      rsp.program_application_id = cp.application_id
AND      rsp.concurrent_program_id = cp.concurrent_program_id
AND      cp.executable_id = e.executable_id
AND      cp.executable_application_id = e.application_id
AND      lv.lookup_type = 'CP_EXECUTION_METHOD_CODE'
AND      lv.lookup_code = e.execution_method_code
AND      lv.language = 'US'
AND      fat.language = 'US'
ORDER BY rs.user_request_set_name
,        rss.display_sequence
,        rsp.sequence