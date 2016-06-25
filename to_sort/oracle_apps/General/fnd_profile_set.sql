DECLARE
   stat   BOOLEAN;
BEGIN
   DBMS_OUTPUT.DISABLE;
   DBMS_OUTPUT.ENABLE (100000);
   stat := fnd_profile.SAVE ('ORG_ID', 85, 'SITE');
 
   IF stat
   THEN
      DBMS_OUTPUT.put_line ('Stat = TRUE - profile updated');
   ELSE
      DBMS_OUTPUT.put_line ('Stat = FALSE - profile NOT updated');
   END IF;
 
   COMMIT;
END;