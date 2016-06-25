CREATE OR REPLACE PROCEDURE dw_test1(p_dummy     IN  sys.dual.dummy%type,
                  p_recordset IN OUT SYS_REFCURSOR
                  )
AS
BEGIN 
  OPEN p_recordset FOR
    SELECT dummy
    FROM   dual
    WHERE  dummy = p_dummy;
END dw_test1;


DECLARE
  l_cursor  Pkgdefinitions.resultSet;
  l_dummy   sys.dual.dummy%TYPE;
BEGIN
  dw_test1(p_dummy    => 'X'
          ,p_recordset => l_cursor
          );
            
  LOOP 
    FETCH l_cursor
    INTO  l_dummy;
    EXIT WHEN l_cursor%NOTFOUND;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('ret:'||l_dummy);
  CLOSE l_cursor;
END;
/