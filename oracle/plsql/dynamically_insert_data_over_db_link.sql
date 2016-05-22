CREATE OR REPLACE PROCEDURE "OLIVE"."PRC_REFRESH_DATA"(p_owner         IN VARCHAR2 DEFAULT 'OLIVE'
                                                      ,p_table_name    IN VARCHAR2 DEFAULT 'ALL'
                                                      ,p_debug         IN BOOLEAN  DEFAULT FALSE
                                                      ,p_tab_row_limit IN NUMBER   DEFAULT 100
                                                      )
AUTHID CURRENT_USER
AS

    /*
    SUMMARY:
    - This procedure takes a sample of the data from oracle test 
      and dumps it into the respective table in the Oracle XE 
      docker container.
    - It should only be run on inside a docker container as if will
      truncate tables. There is a check for this FN_CHECK_INSTANCE.
    - This prcioedure should be run as sys or a user with sysdba
      privileges. This is to disable the constraints on multiple schemas.

    TODO:
    - Only disable constraints if table exists.
    - Only disable constraints for single table if single table specified.
    - Output a list lob columns that are skipped 
    - Enable truncatign of source tables.
    - Parameterise procedure to allow database, schema or table
      level data to be transferred.
    - Fix ENABLE_CONSTRAINTS procedure?
    - If table doesn't contain a clob, can just 'select * from it
      rather than build list of columns dynamically.
    */

    E_CHECK_DB   EXCEPTION;

    v_sql        VARCHAR2(32767);
    v_prefix     VARCHAR2(30);
    v_lob        BOOLEAN := FALSE;
    v_long       BOOLEAN := FALSE;
    c_db_link    VARCHAR2(30) := 'ORATEST';
    c_lob        VARCHAR2(30) := 'LOB';
    c_long       VARCHAR2(30) := 'LONG';
    c_dq         VARCHAR2(1) := '"'; --need double quotes as some columns are reserved words!

    CURSOR  c_tabs(p_owner      dba_tables.owner%TYPE
                  ,p_table_name dba_tables.owner%TYPE
                  )
    IS
    SELECT  owner      AS "TAB_OWNER"
    ,       table_name AS "TAB_NAME"
    FROM    dba_tables
    WHERE   1=1
    AND     owner = p_owner
    AND     CASE
                WHEN (p_table_name = 'ALL' OR p_table_name = table_name) THEN 1
                ELSE 0
            END = 1
    AND     status = 'VALID'
    AND     table_name NOT IN ('TOAD_PLAN_TABLE')
    AND     table_name NOT IN
            (
            SELECT  table_name
            FROM    dba_external_tables
            WHERE   1=1
            AND     owner = p_owner
            )
    AND     table_name NOT IN
            (
            SELECT  mview_name
            FROM    dba_mviews
            WHERE   1=1
            AND     owner = p_owner
            )
    ORDER BY table_name;

    CURSOR  c_cols(p_owner      dba_tables.owner%TYPE 
                  ,p_table_name dba_tables.table_name%TYPE
                  )
    IS
    SELECT  ROW_NUMBER() OVER (PARTITION BY owner, table_name ORDER BY column_id) AS "COL_ID"
    ,       column_name AS "COL_NAME"
    ,       data_type   AS "COL_TYPE"
    FROM    dba_tab_cols
    WHERE   1=1
    AND     owner = p_owner
    AND     table_name = p_table_name
    AND     virtual_column = 'NO'
    ORDER BY column_id;

    PROCEDURE PRC_LOG(p_msg VARCHAR2)
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE(p_msg);
    END PRC_LOG;

    PROCEDURE PRC_DEBUG(p_msg VARCHAR2)
    IS
    BEGIN
        IF p_debug THEN
            PRC_LOG(p_msg);
        END IF;
    END PRC_DEBUG;

    FUNCTION FN_CHECK_INSTANCE
        RETURN BOOLEAN
    IS
        v_instance VARCHAR2(30);
        ret        BOOLEAN := FALSE; 
    BEGIN
        SELECT  SYS_CONTEXT('USERENV','DB_NAME') AS "INSTANCE"
        INTO    v_instance
        FROM    DUAL;
        IF v_instance = 'XE' THEN
            ret := TRUE;
        END IF;
        RETURN ret;
    END FN_CHECK_INSTANCE;

    PROCEDURE DISABLE_CONSTRAINTS
    IS
        v_sql   VARCHAR2(32767);
    BEGIN
        PRC_LOG('Disabling foreign key constraints on schema '||p_owner||'...');
        FOR c IN
            (
            SELECT  c.owner
            ,       c.table_name
            ,       c.constraint_name
            FROM    dba_constraints c
            ,       dba_tables t
            WHERE   1=1
            AND     c.owner IN ('OLIVE','SANFRAN') --need to cover both as fk constraints span schemas
            AND     t.table_name = c.table_name
            AND     t.table_name NOT IN ('DDL_AUDIT','DDL_DEPENDENCIES_AUDIT')
            AND     c.constraint_type = 'R'
            AND     c.status = 'ENABLED'
            AND     NOT
                    (
                    t.iot_type IS NOT NULL
                    AND
                    c.constraint_type = 'P'
                    )
            ORDER BY c.constraint_type DESC
            )
        LOOP
            v_sql := 'ALTER TABLE "' || c.owner || '"."' || c.table_name || '" DISABLE CONSTRAINT ' || c.constraint_name || ' CASCADE';
            PRC_DEBUG(v_sql||';');
            PRC_DEBUG('v_sql length:'||LENGTH(v_sql));
            DBMS_UTILITY.EXEC_DDL_STATEMENT(v_sql);
        END LOOP;
        PRC_LOG(RPAD('*',50,'*'));
    END DISABLE_CONSTRAINTS;

    PROCEDURE ENABLE_CONSTRAINTS
    IS
        v_sql VARCHAR2(32767);
    BEGIN
        --PRC_LOG('Enabling foreign key constraints on schema '||p_owner||'...');
        FOR c IN
            (
            SELECT  c.owner
            ,       c.table_name
            ,       c.constraint_name
            FROM    dba_constraints c
            ,       dba_tables t
            WHERE   1=1
            AND     t.table_name = c.table_name
            AND     c.owner IN ('OLIVE','SANFRAN') --need to cover both as fk constraints span schemas
            AND     c.status = 'DISABLED'
            AND     c.constraint_type = 'R'
            ORDER BY c.constraint_type
            )
        LOOP
            v_sql := 'ALTER TABLE "' || c.owner || '"."' || c.table_name || '" ENABLE CONSTRAINT ' || c.constraint_name;
            PRC_LOG(v_sql||';');
            PRC_LOG('v_sql length:'||LENGTH(v_sql));
            DBMS_UTILITY.EXEC_DDL_STATEMENT(v_sql);
        END LOOP;
        PRC_LOG(RPAD('*',50,'*'));
    END ENABLE_CONSTRAINTS;

    PROCEDURE PRC_TRUNCATE_TABLES(p_owner      IN VARCHAR2
                                 ,p_table_name IN VARCHAR2
                                 )
    IS
    BEGIN
        PRC_LOG('Truncating tables on schema '||p_owner||'...');
        FOR r_tabs IN c_tabs(p_owner
                            ,p_table_name
                            )
        LOOP
            PRC_LOG('Truncating table: '||r_tabs.tab_owner||'.'||r_tabs.tab_name);
            v_sql := 'TRUNCATE TABLE "'||r_tabs.tab_owner||'"."'||r_tabs.tab_name||'"';
            --v_sql := 'DELETE FROM '||r_tabs.tab_owner||'.'||r_tabs.tab_name;
            PRC_DEBUG(v_sql||';');
            PRC_DEBUG('v_sql length:'||LENGTH(v_sql));
            DBMS_UTILITY.EXEC_DDL_STATEMENT(v_sql);
        END LOOP;
        PRC_LOG(RPAD('*',50,'*'));
    END PRC_TRUNCATE_TABLES;

    PROCEDURE PRC_LOAD_TABLES(p_owner      IN VARCHAR2
                             ,p_table_name IN VARCHAR2
                             )
    IS
    BEGIN
        PRC_LOG('Loading data into tables on schema '||p_owner||'...');
        FOR r_tabs IN c_tabs(p_owner
                            ,p_table_name
                            )
        LOOP

            PRC_LOG('Processing table: '||r_tabs.tab_owner||'.'||r_tabs.tab_name);

            v_sql := 'INSERT  '||CHR(10)||
                     'INTO    '||c_dq||r_tabs.tab_owner||c_dq||'.'||c_dq||r_tabs.tab_name||c_dq||CHR(10);

            v_lob := FALSE;
            FOR r_cols IN c_cols(r_tabs.tab_owner
                                ,r_tabs.tab_name
                                )
            LOOP
                IF r_cols.col_type LIKE '%'||c_lob||'%' THEN
                    v_prefix := '--      ';
                    v_lob := TRUE;
                ELSIF r_cols.col_type = c_long THEN
                    v_prefix := '--      ';
                    v_long := TRUE;
                END IF;
                IF r_cols.col_id = 1 THEN
                    v_prefix := '(       ';
                ELSE
                    v_prefix := ',       ';
                END IF;
                v_sql := v_sql||v_prefix||c_dq||r_cols.col_name||c_dq||CHR(10);
            END LOOP;
            v_sql := v_sql||')'||CHR(10);
            FOR r_cols IN c_cols(r_tabs.tab_owner
                                ,r_tabs.tab_name
                                )
            LOOP
                IF r_cols.col_id = 1 THEN
                    v_prefix := 'SELECT  ';
                ELSE
                    v_prefix := ',       ';
                END IF;
                v_sql := v_sql||v_prefix||c_dq||r_cols.col_name||c_dq||CHR(10);
            END LOOP;
            v_sql := v_sql||
                     'FROM    '||c_dq||r_tabs.tab_owner||c_dq||'.'||c_dq||r_tabs.tab_name||c_dq||'@'||c_db_link||CHR(10)||
                     'WHERE   ROWNUM < '||p_tab_row_limit;
            PRC_DEBUG(v_sql||';');
            PRC_DEBUG('v_sql length:'||LENGTH(v_sql));
            execute immediate v_sql;

            -- I hate committing inside a loop with a cursor open 
            -- but dont have any alternative until i bulk collect 
            -- the tables into a collection.
            COMMIT;

            IF v_lob THEN
                PRC_LOG('*WARNING* '||c_lob||' ignored. Please review to ensure you have all required data.');
            END IF;
            IF v_long THEN
                PRC_LOG('*WARNING* '||c_long||' ignored. Please review to ensure you have all required data.');
            END IF;

            PRC_LOG(RPAD('*',50,'*'));

        END LOOP;
    END PRC_LOAD_TABLES;

BEGIN

    PRC_LOG(RPAD('*',50,'*'));
    PRC_LOG('Starting at: '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));

    IF NOT FN_CHECK_INSTANCE THEN
        RAISE E_CHECK_DB;
    END IF;

    -- Truncate with cascade option not available until
    -- 12c so have to disable constraintss for now.
    DISABLE_CONSTRAINTS;

    PRC_TRUNCATE_TABLES(p_owner
                       ,p_table_name
                       );

    PRC_LOAD_TABLES(p_owner
                   ,p_table_name
                   );

    -- Note: Pretty much can guarantee that ENABLE_CONSTRAINTS
    -- wont work as we're only getting sample of the test data
    --ENABLE_CONSTRAINTS;

    PRC_LOG('Completed at: '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    PRC_LOG(RPAD('*',50,'*'));

EXCEPTION
    WHEN E_CHECK_DB THEN
        RAISE_APPLICATION_ERROR(-20001,'Can only run this script inside docker container.');
END "PRC_REFRESH_DATA";
