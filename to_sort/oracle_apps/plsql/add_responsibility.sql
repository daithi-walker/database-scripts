BEGIN
   fnd_user_pkg.addresp(
        '&User_Name', /*Application User Name */
        '&Responsablity_Application_Short_Name', /*get from Query Below */
        '&Responsibility_Key',/*get from Query Below */
        '&Security_Group', /* Most of cases it is 'STANDARD' so you can hard code it */
        '&Description', /* Any comments you want */
        '&Start_Date', /* Sysdate From Today */
        '&End_Date' ); /* Sysdate + 365 Rights for Next One Year*/
   COMMIT;
   dbms_output.put_line('Responsibility Added Successfully');
EXCEPTION
   WHEN OTHERS THEN
      dbms_output.put_line('Responsibility is not added due to ' || SQLCODE || SUBSTR(SQLERRM, 1, 100));
      ROLLBACK;
END;

BEGIN
   fnd_user_pkg.addresp('DWALKER'               -- User Name
                       ,'SYSADMIN'              -- Responsablity Application Short Name
                       ,'SYSTEM_ADMINISTRATOR'  -- Respsonsibility Key
                       ,'STANDARD'              -- Security Group
                       ,NULL                    -- Description
                       ,SYSDATE                 -- Start Date
                       ,NULL                    -- End Date
                       );
   COMMIT;
   DBMS_OUTPUT.put_line ('Responsibility Added Successfully');
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.put_line('Responsibility is not added due to '|| SQLCODE|| SUBSTR (SQLERRM, 1, 100));
      ROLLBACK;
END;


BEGIN
   fnd_user_pkg.addresp ('WALKERD','FND','FND_FUNC_ADMIN','STANDARD','Add Responsibility to USER using pl/sql',SYSDATE,NULL);
   COMMIT;
   DBMS_OUTPUT.put_line ('Responsibility Added Successfully');
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.put_line('Responsibility is not added due to '|| SQLCODE|| SUBSTR (SQLERRM, 1, 100));
      ROLLBACK;
END;