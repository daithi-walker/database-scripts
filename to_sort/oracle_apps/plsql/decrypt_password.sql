CREATE OR REPLACE PACKAGE APPS.xxfnd_password_decrypt AUTHID CURRENT_USER
IS

FUNCTION validate_login(
  p_user        IN VARCHAR2,
  p_apps_pword  IN VARCHAR2)
RETURN VARCHAR2;

END xxfnd_password_decrypt;
/
CREATE OR REPLACE PACKAGE BODY APPS.xxfnd_password_decrypt
IS

FUNCTION decrypt(
  KEY    IN VARCHAR2,
  VALUE  IN VARCHAR2)
RETURN VARCHAR2
AS LANGUAGE JAVA
  NAME 'oracle.apps.fnd.security.WebSessionManagerProc.decrypt(java.lang.String,java.lang.String) return java.lang.String';

--------------------------------------------------------------------------------

FUNCTION validate_login(
  p_user        IN VARCHAR2,
  p_apps_pword  IN VARCHAR2)
RETURN VARCHAR2
IS
--
user        VARCHAR2(100) := UPPER(p_user);
encuserpwd  VARCHAR2(100);
fndpwd      VARCHAR2(100);
encfndpwd   VARCHAR2(100);
userid      NUMBER;
loginid     NUMBER;
expired     VARCHAR2(1);
upwd        VARCHAR2(200);
--
BEGIN
  userid := -1;

  SELECT user_id,
         encrypted_foundation_password,
         encrypted_user_password
  INTO   userid,
         encfndpwd,
         encuserpwd
  FROM   fnd_user
  WHERE  user_name = user;
--  AND    start_date   <= SYSDATE
--  AND    (   end_date   IS NULL
--          OR end_date  > SYSDATE);

  upwd := decrypt(UPPER(p_apps_pword), encUserPwd);
  
  RETURN(upwd);
END validate_login;

END xxfnd_password_decrypt;
/

select xxfnd_password_decrypt.validate_login('APPS','enterappspassword') from dual;

drop package APPS.xxfnd_password_decrypt;