VARIABLE id NUMBER;


    DECLARE

        name    VARCHAR2(100);
        descr   VARCHAR2(500);
        obj_id  NUMBER;

    BEGIN

        name := 'Manual_Employees';
        descr := 'Segment Advisor Example';
    
        DBMS_ADVISOR.CREATE_TASK (
          advisor_name     => 'Segment Advisor',
          task_id          => :id,
          task_name        => name,
          task_desc        => descr);

        DBMS_ADVISOR.CREATE_OBJECT (
          task_name        => name,
          object_type      => 'TABLE',
          attr1            => 'HR',
          attr2            => 'EMPLOYEES',
          attr3            => NULL,
          attr4            => NULL,
          attr5            => NULL,
          object_id        => obj_id);

        DBMS_ADVISOR.SET_TASK_PARAMETER(
          task_name        => name,
          parameter        => 'recommend_all',
          value            => 'TRUE');

        DBMS_ADVISOR.EXECUTE_TASK(name);

    END;
/

EXIT