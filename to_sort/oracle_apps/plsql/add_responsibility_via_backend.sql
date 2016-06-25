ALTER SESSION SET NLS_LANGUAGE='AMERICAN';

DECLARE

   v_user_name                fnd_user.user_name%TYPE := 'WALKERD';
   v_resp_name                fnd_responsibility_tl.responsibility_name%TYPE := 'System Administrator';
   v_description              VARCHAR2(100) := 'Added by API';
   
   v_security_group           fnd_security_groups.security_group_key%TYPE := 'STANDARD';  -- usually STANDARD - check FND_SECURITY_GROUPS
   v_start_date               DATE := SYSDATE - 1;
   v_end_date                 DATE := NULL;
   
   CURSOR   c_prog_dets(b_resp_name VARCHAR2)
   IS
   SELECT   frt.responsibility_name
   ,        fa.application_short_name
   ,        fr.responsibility_key
   FROM     fnd_responsibility fr
   ,        fnd_responsibility_tl frt
   ,        fnd_application fa
   ,        fnd_user fu
   ,        fnd_user fu2
   WHERE    1=1
   ------------------------------------------
   --optional criteria
   --AND      fr.end_date is null
   --AND      fr.created_by NOT IN (0,1,2)
   --AND      fr.last_updated_by NOT IN (0,1,2)
   --AND      fr.responsibility_id = frt.responsibility_id
   --AND      UPPER(frt.responsibility_name) NOT LIKE 'ZZ%'
   --AND      fu.user_name NOT LIKE 'ORACLE%'
   --AND      fu2.user_name NOT LIKE 'ORACLE%'
   AND      frt.responsibility_name = NVL(b_resp_name,frt.responsibility_name)
   ------------------------------------------
   AND      fr.responsibility_id = frt.responsibility_id
   AND      fa.application_id = fr.application_id
   AND      fu.user_id = fr.created_by
   AND      fu2.user_id = fr.last_updated_by
   ;

BEGIN

   DBMS_OUTPUT.ENABLE(100000);

   DBMS_OUTPUT.PUT_LINE('-------------------------------------');
   DBMS_OUTPUT.PUT_LINE('v_resp_name            :'||v_resp_name);
   DBMS_OUTPUT.PUT_LINE('v_user_name            :'||v_user_name);
   DBMS_OUTPUT.PUT_LINE('v_security_group       :'||v_security_group);
   DBMS_OUTPUT.PUT_LINE('v_description          :'||v_description);
   DBMS_OUTPUT.PUT_LINE('v_start_date           :'||v_start_date);
   DBMS_OUTPUT.PUT_LINE('v_end_date             :'||v_end_date);
   DBMS_OUTPUT.PUT_LINE('-------------------------------------');
   
   FOR r_prog_dets in c_prog_dets(v_resp_name)
   LOOP      
      
      DBMS_OUTPUT.PUT_LINE('responsibility_name    :'||r_prog_dets.responsibility_name);
      --DBMS_OUTPUT.PUT_LINE('application_short_name :'||r_prog_dets.application_short_name);
      --DBMS_OUTPUT.PUT_LINE('responsibility_key     :'||r_prog_dets.responsibility_key);
      
      FND_USER_PKG.ADDRESP
         (v_user_name
         ,r_prog_dets.application_short_name
         ,r_prog_dets.responsibility_key
         ,v_security_group
         ,v_description
         ,v_start_date
         ,v_end_date
         );

      DBMS_OUTPUT.PUT_LINE('Success.');
      DBMS_OUTPUT.PUT_LINE('-------------------------------------');
         
   END LOOP;
   
   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
      DBMS_OUTPUT.PUT_LINE('-------------------------------------');
      ROLLBACK;
END;