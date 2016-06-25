SELECT   rs.user_request_set_name "Request Set"
,        rss.display_sequence Seq
,        cp.user_concurrent_program_name "Concurrent Program"
,        e.EXECUTABLE_NAME
,        e.execution_file_name
,        lv.meaning file_type
,        fat.application_name "Application Name"
--,        get_appl_name(e.application_id) "Application Name"
FROM     apps.fnd_request_sets_vl rs
,        apps.fnd_req_set_stages_form_v rss
,        applsys.fnd_request_set_programs rsp
,        apps.fnd_concurrent_programs_vl cp
,        apps.fnd_executables e
,        apps.fnd_lookup_values lv
,        apps.fnd_application_tl fat
WHERE    1=1
AND      rs.application_id = rss.set_application_id
AND      rs.request_set_id = rss.request_set_id
AND      rs.user_request_set_name like '%BIB%' -- :p_request_set_name
AND      e.application_id = fat.application_id
AND      rss.set_application_id = rsp.set_application_id
AND      rss.request_set_id = rsp.request_set_id
AND      rss.request_set_stage_id = rsp.request_set_stage_id
AND      rsp.program_application_id = cp.application_id
AND      rsp.concurrent_program_id = cp.concurrent_program_id
AND      cp.executable_id = e.executable_id
AND      cp.executable_application_id = e.application_id
AND      lv.lookup_type = 'CP_EXECUTION_METHOD_CODE'
AND      lv.lookup_code = e.execution_method_code
and      lv.language='US'
and      fat.language='US'
AND      rs.end_date_active IS NULL
ORDER BY rs.user_request_set_name
,        rss.display_sequence
;