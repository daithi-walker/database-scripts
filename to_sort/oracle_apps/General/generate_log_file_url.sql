DECLARE
   l_request_id   NUMBER   := 7770603; -- The request id
   l_two_task     VARCHAR2 (256);
   l_gwyuid       VARCHAR2 (256);
   l_url          VARCHAR2 (1024);
BEGIN
   -- Get the value of the profile option named, Gateway User ID (GWYUID)
   l_gwyuid := fnd_profile.VALUE ('GWYUID');
   /* Alternate SQL to get the value
   SELECT profile_option_value
     INTO l_gwyuid
     FROM fnd_profile_options o, fnd_profile_option_values ov
    WHERE profile_option_name = 'GWYUID' AND o.application_id = ov.application_id AND o.profile_option_id = ov.profile_option_id;
   */
 
   -- Get the value of the profile option named, Two Task(TWO_TASK)
   l_two_task := fnd_profile.VALUE ('TWO_TASK');
   /* Alternate SQL to get the value
   SELECT profile_option_value
     INTO l_two_task
     FROM fnd_profile_options o, fnd_profile_option_values ov
    WHERE profile_option_name = 'TWO_TASK' AND o.application_id = ov.application_id AND o.profile_option_id = ov.profile_option_id;
   */
 
   --
   l_url :=
      fnd_webfile.get_url (file_type                     => fnd_webfile.request_log, -- for log file. Use request_out to view output file
                           ID                            => l_request_id,
                           gwyuid                        => l_gwyuid,
                           two_task                      => l_two_task,
                           expire_time                   => 500   -- minutes, security!.
                          );
 
   DBMS_OUTPUT.put_line (l_url);
END;