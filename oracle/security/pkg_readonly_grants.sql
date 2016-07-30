CREATE OR REPLACE PACKAGE pkg_readonly_grants
IS
    PROCEDURE prc_check_user(p_user VARCHAR2);
    PROCEDURE prc_process_grants(p_grantee VARCHAR2, p_granter VARCHAR2);
END pkg_readonly_grants;
/

CREATE OR REPLACE PACKAGE BODY pkg_readonly_grants
IS
    PROCEDURE prc_check_user(p_user VARCHAR2)
    IS
        v_user VARCHAR2(30);
    BEGIN
        SELECT  username
        INTO    v_user
        FROM    dba_users
        WHERE   1=1
        AND     username = p_user;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            raise_application_error(-20000, 'User ' || p_user || ' does not exist!');
    END prc_check_user;
    
    PROCEDURE prc_process_grants(p_grantee VARCHAR2, p_granter VARCHAR2)
    IS
    BEGIN
      prc_check_user(p_grantee);
      prc_check_user(p_granter);
      FOR x IN
          (
          SELECT owner, table_name FROM dba_tables WHERE owner = p_granter
          UNION ALL
          SELECT owner, view_name FROM dba_views WHERE owner = p_granter
          )
      LOOP
          BEGIN
              EXECUTE IMMEDIATE 'GRANT SELECT ON ' || x.owner || '.' || x.table_name || ' TO ' || p_grantee;
          EXCEPTION
              WHEN OTHERS THEN NULL;
          END;
      END LOOP;
    END prc_process_grants;

END pkg_readonly_grants;
/