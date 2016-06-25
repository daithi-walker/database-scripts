CREATE OR REPLACE PROCEDURE prc_reset_users_pwd(p_user_name    IN VARCHAR2
                                               ,p_new_password IN VARCHAR2
                                               )
AUTHID CURRENT_USER
AS

   CURSOR apps_users_c
   IS
   SELECT   user_name
   FROM     apps.fnd_user usr
   WHERE    1=1
   AND      encrypted_foundation_password != 'INVALID' 
   AND      encrypted_foundation_password != 'EXTERNAL'
   AND      user_name = p_user_name
   ORDER BY 1;

   tmp_res varchar2(1) DEFAULT 'N';
   nr_updated PLS_INTEGER DEFAULT 0;
   nr_failed PLS_INTEGER DEFAULT 0;
   v_failed VARCHAR2(4000) DEFAULT '';
   v_end_date date;
   b_ok boolean;

BEGIN

  b_ok := fnd_profile.save(x_name => 'SIGNON_PASSWORD_HARD_TO_GUESS', x_value => 'No', x_level_name => 'SITE');
  b_ok := fnd_profile.save(x_name => 'SIGNON_PASSWORD_NO_REUSE', x_value => '0', x_level_name => 'SITE');

  --commit;

   FOR apps_users IN apps_users_c
   LOOP

      SELECT   end_date
      INTO     v_end_date
      FROM     fnd_user
      WHERE    1=1
      AND      user_name = apps_users.user_name;

      IF v_end_date IS NOT NULL THEN

         UPDATE   apps.fnd_user
         SET      end_date = null
         WHERE    1=1
         AND      user_name = apps_users.user_name;

      END IF;

      tmp_res := apps.fnd_web_sec.change_password(apps_users.user_name,p_new_password,FALSE);
      
      IF tmp_res = 'Y' THEN

         UPDATE   apps.fnd_user
         SET      password_date = (SYSDATE-100)
         ,        password_lifespan_days = 90
         WHERE    1=1
         AND      user_name = apps_users.user_name;

         nr_updated := nr_updated +1;

      ELSE

         v_failed  := v_failed || '''' ||apps_users.user_name|| '''' ||', '; 
         nr_failed := nr_failed +1;

      END IF;

      IF v_end_date IS NOT NULL THEN

         UPDATE   apps.fnd_user
         SET      end_date = v_end_date
         WHERE    1=1
         AND      user_name = apps_users.user_name;

      END IF;

   END LOOP;

   IF nr_failed > 0 THEN

      v_failed := SUBSTR(v_failed,1,LENGTH(v_failed)-2);

   END IF;
   --COMMIT;

   dbms_output.put_line('');
   dbms_output.put_line('***************************************************');
   dbms_output.put_line('CHANGED: '|| nr_updated||' passworda');

   IF nr_failed > 0 THEN

      dbms_output.put_line('FAILED: '|| nr_failed||' passworda');
      dbms_output.put_line(v_failed);

   END IF;

   dbms_output.put_line('***************************************************');
   dbms_output.put_line('');

   b_ok := fnd_profile.save(x_name => 'SIGNON_PASSWORD_HARD_TO_GUESS', x_value => 'Yes', x_level_name => 'SITE');
   b_ok := fnd_profile.save(x_name => 'SIGNON_PASSWORD_NO_REUSE', x_value => '7', x_level_name => 'SITE');
   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      b_ok := fnd_profile.save(x_name => 'SIGNON_PASSWORD_HARD_TO_GUESS', x_value => 'Yes', x_level_name => 'SITE');
      b_ok := fnd_profile.save(x_name => 'SIGNON_PASSWORD_NO_REUSE', x_value => '7', x_level_name => 'SITE');
      COMMIT;

END prc_reset_users_pwd;