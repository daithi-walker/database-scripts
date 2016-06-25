SELECT DISTINCT far.request_id, SUBSTR (program, 1, 30), far.user_name,
                far.phase_code, far.status_code, phase, status,
                (CASE
                    WHEN far.phase_code = 'P' AND far.hold_flag = 'Y'
                       THEN 'Job is on Hold by user'
                    WHEN far.phase_code = 'P'
                    AND (far.status_code = 'I' OR far.status_code = 'Q')
                    AND far.requested_start_date > SYSDATE
                       THEN    'Job is scheduled to run at '
                            || TO_CHAR (far.requested_start_date,
                                        'DD-MON-RR HH24:MI:SS'
                                       )
                    WHEN far.phase_code = 'P'
                    AND (far.status_code = 'I' OR far.status_code = 'Q')
                    AND fcp.queue_control_flag = 'Y'
                       THEN 'ICM will run ths request on its next sleep cycle'
                    WHEN far.phase_code = 'P' AND far.status_code = 'P'
                       THEN 'Scheduled to be run by the Advanced Scheduler'
                    WHEN far.queue_method_code NOT IN ('I', 'B')
                       THEN    'Bad queue_method_code of: '
                            || far.queue_method_code
                    WHEN far.run_alone_flag = 'Y'
                       THEN 'Waiting on a run alone request'
                    WHEN far.queue_method_code = 'B'
                    AND far.status_code = 'Q'
                    AND EXISTS (
                           SELECT 1
                             FROM fnd_amp_requests_v farv
                            WHERE phase_code = 'P'
                              AND program_application_id =
                                                    fcps.to_run_application_id
                              AND concurrent_program_id =
                                             fcps.to_run_concurrent_program_id)
              THEN    'Incompatible request '
                  || (SELECT DISTINCT    farv.request_id
                                || ': '
                                || farv.program
                                || ' is Ruuning by : '
                                || farv.user_name
                      FROM fnd_amp_requests_v farv,fnd_concurrent_program_serial fcps1
                      WHERE phase_code = 'R'
                      AND program_application_id =fcps1.running_application_id
                      AND concurrent_program_id =fcps1.running_concurrent_program_id
                      AND fcps.to_run_application_id=fcps1.to_run_application_id
                      AND fcps.to_run_concurrent_program_id=fcps1.to_run_concurrent_program_id)
                    WHEN fcp.enabled_flag = 'N'
                       THEN 'Concurrent program is disabled'
                    WHEN far.queue_method_code = 'I' AND far.status_code = 'Q'
                       THEN 'This Standby request might not run'
                    WHEN far.queue_method_code = 'I' AND far.status_code = 'I'
                       THEN    'Waiting for next available '
                            || fcqt.user_concurrent_queue_name
                            || ' process to run the job. Estimate Wait time '
                            || fcq.sleep_seconds
                            || ' Seconds'
                    WHEN far.queue_method_code = 'I'
                    AND far.status_code IN ('A', 'Z')
                       THEN    'Waiting for Parent Request: '
                            || NVL (far.parent_request_id,
                                    'Could not locate Parent Request ID'
                                   )
                    WHEN far.queue_method_code = 'B' AND far.status_code = 'Q'
                       THEN 'Waiting on the Conflict Resolution Manager'
                    WHEN far.queue_method_code = 'B' AND far.status_code = 'I'
                       THEN    'Waiting for next available '
                            || fcqt.user_concurrent_queue_name
                            || ' process to run the job. Estimate Wait time '
                            || fcq.sleep_seconds
                            || ' Seconds'
                    WHEN far.phase_code = 'P' AND far.single_thread_flag = 'Y'
                       THEN 'Single-threaded request. Waiting on other requests for this user.'
                    WHEN far.phase_code = 'P' AND far.request_limit = 'Y'
                       THEN 'Concurrent: Active Request Limit is set. Waiting on other requests for this user.'
                 END
                ) reason
           FROM fnd_amp_requests_v far,
                fnd_concurrent_programs fcp,
                fnd_conflicts_domain fcd,
                fnd_concurrent_program_serial fcps,
                fnd_concurrent_queues fcq,
                fnd_concurrent_queue_content fcqc,
                fnd_concurrent_queues_tl fcqt
          WHERE far.phase_code = 'P'
            AND far.concurrent_program_id = fcp.concurrent_program_id
            AND fcd.cd_id = far.cd_id
            AND fcps.running_application_id(+) = far.program_application_id
            AND fcps.running_concurrent_program_id(+) = far.concurrent_program_id
            AND far.program_application_id = fcps.to_run_application_id(+)
            AND far.concurrent_program_id = fcps.to_run_concurrent_program_id(+)
            AND far.concurrent_program_id = fcqc.type_id(+)
            AND far.program_application_id = fcqc.type_application_id(+)
            AND fcq.concurrent_queue_id(+) = fcqc.concurrent_queue_id
            AND fcq.application_id(+) = fcqc.queue_application_id
            AND fcqt.concurrent_queue_id(+) = fcq.concurrent_queue_id
            AND fcqt.application_id(+) = fcq.application_id
       ORDER BY far.request_id DESC