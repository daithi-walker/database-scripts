-- https://iamlegand.wordpress.com/category/fnd_user_pkg-addresp/
-- Add Responsibility to a User in oracle apps
-- 
-- Syntax:
-- fnd_user_pkg.addresp
--     (username       => v_user_name
--     ,resp_app       => 'SYSADMIN'
--     ,resp_key       => 'SYSTEM_ADMINISTRATOR'
--     ,security_group => 'STANDARD'
--     ,description    => 'Auto Assignment'
--     ,start_date     => SYSDATE – 10
--     ,end_date       => SYSDATE + 1000
--     );

BEGIN
    fnd_user_pkg.addresp
        ('COREID'
        ,'SYSADMIN'
        ,'SYSTEM_ADMINISTRATOR'
        ,'STANDARD'
        ,'Add Sysadmin Responsibility to OPERATIONS user using pl/sql'
        , SYSDATE
        , SYSDATE + 100
        );
    COMMIT;
    DBMS_OUTPUT.put_line ('Responsibility added successfully');
EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.put_line ('Responsibility not added. ' || SQLCODE || SUBSTR (SQLERRM, 1, 100));
    ROLLBACK;
END;