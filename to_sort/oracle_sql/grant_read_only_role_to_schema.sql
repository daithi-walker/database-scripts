CREATE ROLE READONLY_ROLE;
CREATE USER lohika IDENTIFIED BY lohika;
GRANT READONLY_ROLE TO lohika;

DECLARE
  v_user VARCHAR2(30) := 'OLIVE';
  vsql   VARCHAR2(1000);
BEGIN
  FOR x IN (SELECT owner, object_name, object_type FROM dba_objects WHERE owner = v_user and object_type in ('TABLE','VIEW') and status = 'VALID' order by object_type, object_name)
  LOOP
    vsql := 'GRANT SELECT ON ' || x.owner || '.' || x.object_name || ' TO READONLY_ROLE';
    DBMS_OUTPUT.PUT_LINE(x.object_type || ': ' || vsql);
    EXECUTE IMMEDIATE vsql;
  END LOOP;
END;
/