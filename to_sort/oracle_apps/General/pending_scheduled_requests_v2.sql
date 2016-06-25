SELECT   req.request_id 
,        decode (prg.user_concurrent_program_name, 'Report Set', 'Report Set:' || req.description, prg.user_concurrent_program_name) AS name
,        argument_text as parameters
,        req.resubmit_interval
,        nvl2(req.resubmit_interval, 'Periodically', nvl2(req.release_class_id, 'On specific days', 'Once')) AS schedule_type
,        decode(nvl2(req.resubmit_interval, 'Periodically', nvl2(req.release_class_id, 'On specific days', 'Once'))
               ,'Periodically', 'Every ' || req.resubmit_interval || ' ' || lower(req.resubmit_interval_unit_code) || ' from ' || lower(req.resubmit_interval_type_code) || ' of previous run'
               ,'Once', 'At :' || to_char (req.requested_start_date, 'DD-MON-RR HH24:MI')
               ,'Every: ' || crc.class_info
               ) as schedule 
,        fus.user_name as owner
,        to_char(requested_start_date,'DD-MON-YYYY HH24:MI:SS') as next_submission
FROM     apps.fnd_concurrent_programs_tl prg 
,        apps.fnd_concurrent_requests req
,        apps.fnd_user fus
,        apps.fnd_conc_release_classes crc 
WHERE    1=1
AND      prg.application_id = req.program_application_id 
AND      prg.concurrent_program_id = req.concurrent_program_id 
AND      req.requested_by = fus.user_id 
AND      req.phase_code = 'P' 
AND      req.requested_start_date > sysdate 
AND      prg.language = 'US' 
AND      crc.release_class_id(+) = req.release_class_id 
AND      crc.application_id(+) = req.release_class_app_id
ORDER BY name
