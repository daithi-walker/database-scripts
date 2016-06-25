/***********************************************************************
* PURPOSE: To Add a Concurrent Program to a Request Group from backend *
************************************************************************/
DECLARE
   l_program_short_name  VARCHAR2 (200);
   l_program_application VARCHAR2 (200);
   l_request_group       VARCHAR2 (200);
   l_group_application   VARCHAR2 (200);
   l_check               VARCHAR2 (2);
BEGIN
   --
   l_program_short_name  := 'XX';
   l_program_application := 'XXXXXX';   -- application short name
   l_request_group       := 'Receivables All';
   l_group_application   := 'Receivables';  -- application long name
   --
   --Calling API to assign concurrent program to a reqest group
   --
   apps.fnd_program.add_to_group(program_short_name  => l_program_short_name
                                ,program_application => l_program_application
                                ,request_group       => l_request_group
                                ,group_application   => l_group_application
                                );  
   --
   COMMIT;
   --
   BEGIN
      --
      --To check whether a paramter is assigned to a Concurrent Program or not
      --
      SELECT   'Y' l_check
      INTO     l_check
      FROM     fnd_request_groups frg
      ,        fnd_request_group_units frgu
      ,        fnd_concurrent_programs fcp
      ,        fnd_application fa2
      ,        fnd_application_tl fat2
      ,        fnd_application fa1
      ,        fnd_application_tl fat1
      WHERE    1=1
      AND      frg.request_group_id = frgu.request_group_id
      AND      frg.application_id = frgu.application_id
      AND      frgu.request_unit_id = fcp.concurrent_program_id
      AND      frgu.unit_application_id = fcp.application_id
      AND      fcp.concurrent_program_name = l_program_short_name
      AND      frg.request_group_name = l_request_group
      AND      fa1.application_id = frg.application_id
      AND      fat1.application_id = fa1.application_id
      AND      fat1.application_name = l_group_application
      AND      fa2.application_id = fcp.application_id
      AND      fa2.application_short_name = l_program_application
      AND      fat2.application_id = fa2.application_id;
      --
      dbms_output.put_line ('Adding Concurrent Program to Request Group Succeeded');
      --
   EXCEPTION
      WHEN no_data_found THEN
         dbms_output.put_line ('Adding Concurrent Program to Request Group Failed');
   END;

END;
/

EXIT;