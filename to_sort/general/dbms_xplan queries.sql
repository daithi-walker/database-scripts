--displays last cursor
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR);

--displays what is in the plan table  (use EXPLAIN PLAN FOR ... before using)
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- if you have sql_id...
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','26hy1pd8qcpd1'));