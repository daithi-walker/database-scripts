-- ---------------------------------------------------------- 
-- Add Responsibility to Oracle FND User 
-- ----------------------------------------------------------- 
DECLARE 
    lc_user_name                        VARCHAR2(100)    := 'PRAJ_TEST'; 
    lc_resp_appl_short_name   VARCHAR2(100)    := 'FND'; 
    lc_responsibility_key          VARCHAR2(100)    := 'APPLICATION_DEVELOPER'; 
    lc_security_group_key        VARCHAR2(100)    := 'STANDARD'; 
    ld_resp_start_date                DATE                        := TO_DATE('25-JUN-2012'); 
    ld_resp_end_date                 DATE                        := NULL; 

BEGIN 
     fnd_user_pkg.addresp 
     (   username           => lc_user_name, 
        resp_app             => lc_resp_appl_short_name, 
        resp_key             => lc_responsibility_key, 
        security_group  => lc_security_group_key, 
        description         => NULL, 
        start_date           => ld_resp_start_date, 
        end_date            => ld_resp_end_date 
    );

 COMMIT; 

EXCEPTION 
            WHEN OTHERS THEN 
                        ROLLBACK; 
                        DBMS_OUTPUT.PUT_LINE(SQLERRM); 
END; 
/