SET SERVEROUTPUT ON 

CREATE OR REPLACE PACKAGE test
AS
    PROCEDURE proc1;
    PROCEDURE proc2;
END test;
/

CREATE OR REPLACE PACKAGE BODY test
AS

    sleep_time NUMBER := 1;

    PROCEDURE proc1
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('inside proc1');
        DBMS_LOCK.SLEEP(sleep_time);
    END proc1;

    PROCEDURE proc2
    IS
    BEGIN
        DBMS_OUTPUT.ENABLE;
        DBMS_OUTPUT.PUT_LINE('inside proc2');
        proc1;
        DBMS_LOCK.SLEEP(sleep_time);
    END proc2;

END test;
/

BEGIN
    test.proc2;
END;
/

EXIT
