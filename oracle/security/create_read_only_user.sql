--Source: http://stackoverflow.com/questions/7502438/oracle-how-to-create-a-readonly-user

CREATE ROLE read_only;

CREATE USER user_ro
 IDENTIFIED BY user_ro
 DEFAULT TABLESPACE users
 TEMPORARY TABLESPACE temp;
 
GRANT CREATE SESSION TO user_ro;
 
GRANT READ_ONLY TO user_ro;
 
DECLARE
  c_role_ro VARCHAR2(20) := 'read_only';
BEGIN
  FOR x IN
  (
  SELECT owner, table_name FROM dba_tables WHERE owner IN ('<schema>')
  UNION ALL
  SELECT owner, view_name FROM dba_views WHERE owner IN ('<schema>')
  )
  loop
    BEGIN
      EXECUTE IMMEDIATE 'GRANT SELECT ON ' || x.owner || '.' || x.table_name || ' TO ' || c_role_ro;
    EXCEPTION
      WHEN OTHERS THEN NULL; END;
  END LOOP;
END;

-- or

-- grant create session, select any table, select any dictionary to ro_role;
