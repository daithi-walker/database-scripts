WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;
WHENEVER OSERROR EXIT 9;

SET SERVEROUTPUT ON

PROMPT ***********************************************************
PROMPT ** prc_refresh_docker_data.sql
PROMPT ***********************************************************

CREATE OR REPLACE PROCEDURE "OLIVE"."PRC_REFRESH_DOCKER_DATA"
    (p_owner            IN VARCHAR2 DEFAULT 'ALL'
    ,p_table_name       IN VARCHAR2 DEFAULT 'ALL'
    ,p_filter_column    IN VARCHAR2 DEFAULT NULL
    ,p_filter_value1    IN VARCHAR2 DEFAULT NULL
    ,p_filter_value2    IN VARCHAR2 DEFAULT NULL
    ,p_filter_type      IN VARCHAR2 DEFAULT NULL
    ,p_date_format      IN VARCHAR2 DEFAULT 'YYYYMMDD'
    ,p_order_column     IN VARCHAR2 DEFAULT NULL
    ,p_order_type       IN VARCHAR2 DEFAULT 'ASC'
    ,p_debug            IN VARCHAR2 DEFAULT 'N'
    ,p_tab_row_limit    IN NUMBER   DEFAULT 100  --use 0 for all rows
    )
AUTHID CURRENT_USER
AS

-- ========================================================================
-- Author:      Dave Walker
--
-- Created:     18-MAY-2016
--
-- Description: This procedure takes a sample of the data from oracle test 
--              and dumps it into the respective table in the Oracle XE
--              docker container.
--              It should only be run on inside a docker container as if
--              will truncate tables. The check for this FN_CHECK_INSTANCE.
--              This procedure should be run as sys or a user with SYSDBA 
--              privileges. This privilege is to required to disable the 
--              constraints on multiple schemas.
--
-- To Do:       * Use bulk collects!
--              * Remove commit from cursor for loop once using bulk collects.
--              * Only disable constraints for single table if single table 
--                specified.
--              * Can this procedure be run on other schemas than SYS?
--              * Output a list lob columns that are skipped.
--              * Figure out if ENABLE_CONSTRAINTS procedure can be enabled.
--              * If table doesn't contain a clob, can just 'select * from
--                it rather than build list of columns dynamically.
--              * Program required that table_name and column name are case
--                sensitive because we have mixed case column an table names!
--                This can become case insenstive if columns are fixed on prod.
--              * Have added validation to ensure if column is date, the correct
--                value is sent in. But not added anything to check if number.
--                e.g. passing a date for a numeric column will cue an issue.
--              * In order to not completely disable all foreign keys, need to
--                add a check if a table has foreign keys and report back to 
--                user that they should copy data from this table first. This 
--                is a bit of crap workaround as this could lead to a lot of 
--                other calls being required before you get the data you want. 
--                Perhaps a disable constraints parameter would be better?
--
-- ========================================================================

    -- exceptions
    e_check_db                  EXCEPTION;
    e_predicate_not_allowed     EXCEPTION;
    e_order_not_allowed         EXCEPTION;
    e_invalid_predicate_parms   EXCEPTION;
    e_invalid_filter_type       EXCEPTION;

    -- global variables
    gv_constraints_disabled     BOOLEAN := FALSE;
    gv_skip_table               BOOLEAN := FALSE;
    gv_total_duration           NUMBER := 0;
    gv_errmsg                   VARCHAR2(1000);
    gv_debug                    VARCHAR2(1);

    -- constants
    c_db_link                   dba_db_links.db_link%TYPE := '@oratest';
    c_dq                        VARCHAR2(1) := '"'; --need double quotes as some columns are reserved words!
    c_pad_star                  VARCHAR2(60) := RPAD('*',60,'*');
    c_pad_dash                  VARCHAR2(60) := RPAD('-',60,'-');

    -- local variables to hold uppercase parameters
    v_owner                     dba_users.username%TYPE;
    v_table_name                dba_tables.table_name%TYPE;
    v_filter_column             dba_tab_columns.column_name%TYPE;
    v_filter_value1             VARCHAR2(100);
    v_filter_value2             VARCHAR2(100);
    v_filter_type               VARCHAR2(10);
    v_date_format               VARCHAR2(20);
    v_order_column              dba_tab_columns.column_name%TYPE;
    v_order_type                VARCHAR2(4);

    CURSOR  c_owner(p_owner      dba_users.username%TYPE)
    IS
    SELECT username
    FROM   dba_users
    WHERE  1=1
    AND    username IN ('OLIVE','SANFRAN')
    AND     CASE
                WHEN (p_owner = 'ALL' OR p_owner = username) THEN 1
                ELSE 0
            END = 1;


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
    AND     table_name NOT LIKE 'IMP%'
    AND     table_name NOT IN ('ML_RELEASE'
                              ,'DDL_AUDIT'
                              ,'DDL_DEPENDENCIES_AUDIT'
                              )
    AND     temporary = 'N'
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
    ,       nullable
    FROM    dba_tab_cols
    WHERE   1=1
    AND     owner = p_owner
    AND     table_name = p_table_name
    AND     virtual_column = 'NO'
    ORDER BY column_id;

-- ========================================================================

    PROCEDURE PRC_LOG(p_msg           IN VARCHAR2
                     ,p_add_blank_row IN VARCHAR2 DEFAULT 'N'
                     )
    IS
    BEGIN

        IF p_add_blank_row = 'Y' THEN
            DBMS_OUTPUT.NEW_LINE;
        END IF;

        DBMS_OUTPUT.PUT_LINE(p_msg);

    END PRC_LOG;

-- ========================================================================

    PROCEDURE PRC_DEBUG(p_msg VARCHAR2)
    IS
    BEGIN
        IF p_debug = 'Y' THEN
            PRC_LOG(p_msg,'N');
        END IF;
    END PRC_DEBUG;

-- ========================================================================

    FUNCTION FN_CHECK_INSTANCE
        RETURN BOOLEAN
    IS
    --  Only ever want to run this procedure on a docker instance.
    --  Added this function to ensure that happens.
        v_instance v$instance.instance_name%TYPE;
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

-- ========================================================================

    FUNCTION FN_CHECK_TABLE_EXISTS(p_owner      IN VARCHAR2
                                  ,p_table_name IN VARCHAR2
                                  )
        RETURN BOOLEAN
    IS
    --  Encountered issues in testing this initially where
    --  table exists on XE but not on TEST. 
        v_dummy dba_tables.table_name%TYPE;
        v_ret   BOOLEAN := TRUE;
    BEGIN

        -- log parameters
        PRC_DEBUG(' ');
        PRC_DEBUG('--------------------------------------');
        PRC_DEBUG('FN_CHECK_TABLE_EXISTS');
        PRC_DEBUG('p_owner      : '||p_owner);
        PRC_DEBUG('p_table_name : '||p_table_name);
        PRC_DEBUG('--------------------------------------');

        SELECT  table_name
        INTO    v_dummy
        FROM    dba_tables@oratest
        WHERE   1=1
        AND     owner = p_owner
        AND     table_name = p_table_name;

        RETURN v_ret;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            PRC_LOG('*WARNING* FN_CHECK_TABLE_EXISTS: Table '||p_owner||'.'||p_table_name||' does not exist on test!');
            v_ret := FALSE;
            RETURN v_ret;

    END FN_CHECK_TABLE_EXISTS;

-- ========================================================================

    FUNCTION FN_CHECK_PRIMARY_KEY(p_table_owner  VARCHAR2
                                 ,p_table_name   VARCHAR2
                                 ,p_column_name  VARCHAR2
                                 )
        RETURN BOOLEAN
    IS
    --  Need to check of the problematic column is part
    --  of a constraint. If it is, then we cant simply
    --  ignore the column. Originally, the function only 
    --  checked primary keys but not null constraints 
    --  also caused problems. Now the entire table is 
    --  skipped and a warning is issued.
        v_ret BOOLEAN := FALSE;
        v_cnt NUMBER;
    BEGIN

        -- log parameters
        PRC_DEBUG(' ');
        PRC_DEBUG('--------------------------------------');
        PRC_DEBUG('FN_CHECK_PRIMARY_KEY');
        PRC_DEBUG('p_table_owner : '||p_table_owner);
        PRC_DEBUG('p_table_name  : '||p_table_name);
        PRC_DEBUG('p_column_name : '||p_column_name);
        PRC_DEBUG('--------------------------------------');

        SELECT  COUNT(*)
        INTO    v_cnt
        FROM    dba_constraints c
        ,       dba_cons_columns cc
        WHERE   1=1
        AND     cc.owner = c.owner
        AND     cc.table_name = c.table_name
        AND     cc.constraint_name = c.constraint_name
        AND     cc.column_name = p_column_name
        AND     c.owner = p_table_owner
        AND     c.table_name = p_table_name
        AND     c.status = 'ENABLED';

        IF v_cnt <> 0 THEN
            PRC_LOG('Column ('||p_owner||'.'||p_table_name||'.'||p_column_name||') is part of primary key. Skipping table.');
            gv_skip_table := TRUE;
            v_ret := TRUE;
        END IF;

        RETURN v_ret;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- column is not a primary key. do nothing.
            RETURN v_ret;
        WHEN OTHERS THEN
            PRC_LOG(SQLERRM);
            PRC_LOG('*WARNING* FN_CHECK_PRIMARY_KEY: ('||p_owner||'.'||p_table_name||'.'||p_column_name||'). Skipping table.');
            gv_skip_table := TRUE;
            v_ret := TRUE;
            RETURN v_ret;

    END FN_CHECK_PRIMARY_KEY;

-- ========================================================================

    FUNCTION FN_CHECK_COLUMN(p_table_owner  VARCHAR2
                            ,p_table_name   VARCHAR2
                            ,p_column_name  VARCHAR2
                            ,p_data_type    VARCHAR2
                            ,p_nullable     VARCHAR2
                            )
        RETURN BOOLEAN
    IS
    --  Need to check the data type and nullablility 
    --  of each column to ensure that they are the 
    --  same on xe and test. Otherwise could end up
    --  with and error when inserting the data.
        e_dt_mismatch   EXCEPTION;
        e_null_mismatch EXCEPTION;
        v_dt_xe         dba_tab_columns.data_type%TYPE;
        v_dt_test       dba_tab_columns.data_type%TYPE;
        v_null_xe       dba_tab_columns.nullable%TYPE;
        v_null_test     dba_tab_columns.nullable%TYPE;
        v_ret           BOOLEAN := TRUE;
    BEGIN

        -- log parameters
        PRC_DEBUG(' ');
        PRC_DEBUG('--------------------------------------');
        PRC_DEBUG('FN_CHECK_COLUMN');
        PRC_DEBUG('p_table_owner : '||p_table_owner);
        PRC_DEBUG('p_table_name  : '||p_table_name);
        PRC_DEBUG('p_column_name : '||p_column_name);
        PRC_DEBUG('p_data_type   : '||p_data_type);
        PRC_DEBUG('p_nullable    : '||p_nullable);
        PRC_DEBUG('--------------------------------------');

        SELECT  data_type
        ,       nullable
        INTO    v_dt_xe
        ,       v_null_xe
        FROM    dba_tab_columns
        WHERE   1=1
        AND     owner = p_table_owner
        AND     table_name = p_table_name
        AND     column_name = p_column_name;

        SELECT  data_type
        ,       nullable
        INTO    v_dt_test
        ,       v_null_test
        FROM    dba_tab_columns@oratest
        WHERE   1=1
        AND     owner = p_table_owner
        AND     table_name = p_table_name
        AND     column_name = p_column_name;

        IF v_dt_xe <> v_dt_test THEN
            RAISE e_dt_mismatch;
        END IF;

        IF v_null_xe <> v_null_test THEN
            RAISE e_null_mismatch;
        END IF;

        RETURN v_ret;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            PRC_LOG('*WARNING* FN_CHECK_COLUMN: Column '||p_owner||'.'||p_table_name||'.'||p_column_name||' not found. Skipping column.');
            IF FN_CHECK_PRIMARY_KEY(p_table_owner
                                   ,p_table_name
                                   ,p_column_name
                                   )
            THEN
                gv_skip_table := TRUE;
            END IF;
            v_ret := FALSE;
            RETURN v_ret;
        WHEN e_dt_mismatch THEN
            PRC_LOG('*WARNING* FN_CHECK_COLUMN: Column '||p_owner||'.'||p_table_name||'.'||p_column_name||' DATA_TYPE mismatch. Skipping column.');
            PRC_DEBUG('XE: '||p_owner||'.'||p_table_name||'.'||p_column_name||': DATA_TYPE='||v_dt_xe);
            PRC_DEBUG('TEST: '||p_owner||'.'||p_table_name||'.'||p_column_name||': DATA_TYPE='||v_dt_test);
            IF FN_CHECK_PRIMARY_KEY(p_table_owner
                                   ,p_table_name
                                   ,p_column_name
                                   )
            THEN
                gv_skip_table := TRUE;
            END IF;
            v_ret := FALSE;
            RETURN v_ret;
        WHEN e_null_mismatch THEN
            PRC_LOG('*WARNING* FN_CHECK_COLUMN: Column '||p_owner||'.'||p_table_name||'.'||p_column_name||' NULLABLE mismatch. Skipping column.');
            PRC_DEBUG('XE: '||p_owner||'.'||p_table_name||'.'||p_column_name||': NULLABLE='||v_null_xe);
            PRC_DEBUG('TEST: '||p_owner||'.'||p_table_name||'.'||p_column_name||': NULLABLE='||v_null_test);
            IF FN_CHECK_PRIMARY_KEY(p_table_owner
                                   ,p_table_name
                                   ,p_column_name
                                   )
            THEN
                gv_skip_table := TRUE;
            END IF;
            v_ret := FALSE;
            RETURN v_ret;
        WHEN OTHERS THEN
            PRC_LOG(SQLERRM);
            PRC_LOG('*WARNING* FN_CHECK_COLUMN: ('||p_owner||'.'||p_table_name||'.'||p_column_name||'). Skipping column.');
            IF FN_CHECK_PRIMARY_KEY(p_table_owner
                                   ,p_table_name
                                   ,p_column_name
                                   )
            THEN
                gv_skip_table := TRUE;
            END IF;
            v_ret := FALSE;
            RETURN v_ret;

    END FN_CHECK_COLUMN;

-- ========================================================================

    FUNCTION FN_GET_COL_TYPE(p_table_owner     VARCHAR2
                            ,p_table_name      VARCHAR2
                            ,p_filter_column   VARCHAR2
                            )
        RETURN VARCHAR2
    IS
        v_col_type dba_tab_columns.data_type%TYPE := NULL;
    BEGIN

        -- log parameters
        PRC_DEBUG(' ');
        PRC_DEBUG('--------------------------------------');
        PRC_DEBUG('FN_GET_COL_TYPE');
        PRC_DEBUG('p_table_owner   : '||p_table_owner);
        PRC_DEBUG('p_table_name    : '||p_table_name);
        PRC_DEBUG('p_filter_column : '||p_filter_column);
        PRC_DEBUG('--------------------------------------');

        FOR r_cols IN c_cols(p_table_owner
                            ,p_table_name
                            )
        LOOP
            PRC_DEBUG('r_cols.col_name : '||r_cols.col_name);
            -- Loop though columns in the table to see if column
            -- is a match for the parameter.
            IF r_cols.col_name = p_filter_column THEN
                v_col_type := r_cols.col_type; 
            END IF;
        END LOOP;
        RETURN v_col_type;
    EXCEPTION
        WHEN OTHERS THEN
            PRC_LOG(SQLERRM);
            gv_errmsg := '*ERROR* FN_GET_COL_TYPE: General exception encountered.';
            PRC_LOG(gv_errmsg);
            RAISE;
    END FN_GET_COL_TYPE;

-- ========================================================================

    FUNCTION FN_COLUMN_EXISTS(p_table_owner     VARCHAR2
                             ,p_table_name      VARCHAR2
                             ,p_filter_column   VARCHAR2
                             )
        RETURN BOOLEAN
    IS
        v_col_exists BOOLEAN := FALSE;
    BEGIN

        -- log parameters
        PRC_DEBUG(' ');
        PRC_DEBUG('--------------------------------------');
        PRC_DEBUG('FN_COLUMN_EXISTS');
        PRC_DEBUG('p_table_owner   : '||p_table_owner);
        PRC_DEBUG('p_table_name    : '||p_table_name);
        PRC_DEBUG('p_filter_column : '||p_filter_column);
        PRC_DEBUG('--------------------------------------');

        FOR r_cols IN c_cols(p_table_owner
                            ,p_table_name
                            )
        LOOP
            -- Loop though columns in the table to see if column
            -- is a match for the parameter.
            IF r_cols.col_name = p_filter_column THEN
                v_col_exists := TRUE; 
                PRC_DEBUG(r_cols.col_name||' exists!');
            END IF;
        END LOOP;
        RETURN v_col_exists;
    EXCEPTION
        WHEN OTHERS THEN
            PRC_LOG(SQLERRM);
            gv_errmsg := '*ERROR* FN_COLUMN_EXISTS: General exception encountered.';
            PRC_LOG(gv_errmsg);
            RETURN v_col_exists;  --let calling procedure handle error.
    END FN_COLUMN_EXISTS;

-- ========================================================================
    
    FUNCTION FN_VALIDATE_DATE(p_input   VARCHAR2)
        RETURN BOOLEAN
    IS
        v_valid_date    BOOLEAN := TRUE;
        v_date_test     DATE;
    BEGIN

        -- log parameters
        PRC_DEBUG(' ');
        PRC_DEBUG('--------------------------------------');
        PRC_DEBUG('FN_VALIDATE_DATE');
        PRC_DEBUG('p_input : '||p_input);
        PRC_DEBUG('--------------------------------------');

        EXECUTE IMMEDIATE 'BEGIN SELECT '||p_input||' INTO :x FROM DUAL; END;' USING OUT v_date_test;
        RETURN v_valid_date;
    EXCEPTION
        WHEN OTHERS THEN
            PRC_LOG(SQLERRM);
            gv_errmsg := '*ERROR* FN_VALIDATE_DATE: General exception encountered.';
            PRC_LOG(gv_errmsg);
            v_valid_date := FALSE;
            RETURN v_valid_date;
    END FN_VALIDATE_DATE;

-- ========================================================================

    FUNCTION FN_GET_PREDICATE(p_table_owner     VARCHAR2
                             ,p_table_name      VARCHAR2
                             ,p_filter_column   VARCHAR2
                             ,p_filter_value1   VARCHAR2
                             ,p_filter_value2   VARCHAR2
                             ,p_filter_type     VARCHAR2
                             ,p_date_format     VARCHAR2
                             )
        RETURN VARCHAR2
    IS
        e_invalid_col_type      EXCEPTION;
        e_unhandled_datatype    EXCEPTION;
        e_invalid_date          EXCEPTION;
        v_predicate             VARCHAR2(1000);
        v_col_type              dba_tab_columns.data_type%TYPE := NULL;
        v_filter_value1         VARCHAR2(100);
        v_filter_value2         VARCHAR2(100);
        v_date_test             DATE;
    BEGIN

        -- log parameters
        PRC_DEBUG(' ');
        PRC_DEBUG('--------------------------------------');
        PRC_DEBUG('FN_GET_PREDICATE');
        PRC_DEBUG('p_table_owner    : '||p_table_owner);
        PRC_DEBUG('p_table_name     : '||p_table_name);
        PRC_DEBUG('p_filter_column  : '||p_filter_column);
        PRC_DEBUG('p_filter_value1  : '||p_filter_value1);
        PRC_DEBUG('p_filter_value2  : '||p_filter_value2);
        PRC_DEBUG('p_filter_type    : '||p_filter_type);
        PRC_DEBUG('p_date_format    : '||p_date_format);
        PRC_DEBUG('--------------------------------------');

        -- Only populate v_filter_value2 if we are procedding a BETWEEN.
        IF p_filter_type = 'BETWEEN' THEN 
            v_filter_value2 := p_filter_value2;
        END IF;

        v_col_type := FN_GET_COL_TYPE(p_table_owner
                                     ,p_table_name
                                     ,p_filter_column
                                     );

        PRC_DEBUG('v_col_type: '||v_col_type);

        IF v_col_type IS NOT NULL THEN

            IF v_col_type IN ('NUMBER') THEN

                -- We are happy that no additional manipulation is required.
                v_filter_value1 := p_filter_value1;
                v_filter_value2 := p_filter_value2;

            ELSIF v_col_type IN ('NVARCHAR2','VARCHAR2','NCHAR','CHAR') THEN

                -- Wrapping v_filter_value1 with quotes and percentage if LIKE 
                -- is the filter type. Only wrapping v_filter_value2 with quotes
                -- as this should not be used with LIKE anyway.
                IF p_filter_type = 'LIKE' THEN
                    v_filter_value1 := '''%'||p_filter_value1||'%''';
                    v_filter_value2 := NULL;
                ELSE
                    v_filter_value1 := ''''||p_filter_value1||'''';
                    v_filter_value2 := ''''||p_filter_value2||'''';
                END IF;

            ELSIF v_col_type IN ('DATE') THEN
    
                -- Wrap value in TO_DATE function with date format provided.
                v_filter_value1 := 'TO_DATE('''||p_filter_value1||''','''||p_date_format||''')';
                PRC_DEBUG('v_filter_value1: '||v_filter_value1);

                -- test v_filter_value1 will return a correct date when run in sql
                IF NOT FN_VALIDATE_DATE(v_filter_value1) THEN
                    gv_errmsg := '*ERROR* FN_GET_PREDICATE: Date ('||v_filter_value1||') is not comatible with the date format ('||p_date_format||').';
                    PRC_LOG(gv_errmsg);
                    RAISE e_invalid_date;
                END IF;

                -- Only test second date if BETWEEN is specified.
                IF p_filter_type = 'BETWEEN' THEN

                    IF p_filter_value2 IS NOT NULL THEN

                        -- Wrap value in TO_DATE function with date format provided.
                        v_filter_value2 := 'TO_DATE('''||p_filter_value2||''','''||p_date_format||''')';
                        PRC_DEBUG('v_filter_value2: '||v_filter_value2);

                        -- Test v_filter_value1 will return a correct date when run in sql
                        IF NOT FN_VALIDATE_DATE(v_filter_value2) THEN
                            gv_errmsg := '*ERROR* FN_GET_PREDICATE: Date ('||v_filter_value2||') is not comatible with the date format ('||p_date_format||').';
                            PRC_LOG(gv_errmsg);
                            RAISE e_invalid_date;
                        END IF;

                    ELSE
                        -- No error required here as previous test to ensure
                        -- if BETWEEN, then second parameter it passed.
                        NULL;
                    END IF;
                END IF;
            ELSE
                RAISE e_unhandled_datatype;
            END IF;

            -- buildbase predicate
            v_predicate := 'AND     '||p_filter_column||' '||p_filter_type||' '||v_filter_value1;

            IF p_filter_type = 'BETWEEN' THEN 
                v_predicate := v_predicate||' AND '||v_filter_value2;
            END IF;

            PRC_DEBUG('v_predicate: '||v_predicate);

        ELSE
            RAISE e_invalid_col_type;
        END IF;

        RETURN v_predicate;

    EXCEPTION
        WHEN e_invalid_col_type THEN
            gv_errmsg := '*ERROR* FN_GET_PREDICATE: Unable to determine the datatype for column ('||p_table_name||'.'||p_filter_column||').';
            PRC_LOG(gv_errmsg);
            RAISE;
        WHEN e_unhandled_datatype THEN
            gv_errmsg := '*ERROR* FN_GET_PREDICATE: Program does not know how to handle datatype ('||v_col_type||').';
            PRC_LOG(gv_errmsg);
            RAISE;
        WHEN e_invalid_date THEN
            -- Logging is handled when exception found as need parameterised value.
            RAISE;
        WHEN OTHERS THEN
            PRC_LOG(SQLERRM);
            gv_errmsg := '*ERROR* FN_GET_PREDICATE: Unhandled exception encountered.';
            PRC_LOG(gv_errmsg);
            RAISE;
    END FN_GET_PREDICATE;

-- ========================================================================

    FUNCTION TIMESTAMP_DIFF(p_start TIMESTAMP
                           ,p_end   TIMESTAMP
                           )
        RETURN NUMBER
    IS
        v_ts INTERVAL DAY TO SECOND;
    BEGIN

        -- log parameters
        PRC_DEBUG(' ');
        PRC_DEBUG('--------------------------------------');
        PRC_DEBUG('TIMESTAMP_DIFF');
        PRC_DEBUG('p_start : '||p_start);
        PRC_DEBUG('p_end   : '||p_end);
        PRC_DEBUG('--------------------------------------');

        v_ts := p_end - p_start;
        RETURN EXTRACT (DAY    FROM (v_ts))*24*60*60+
               EXTRACT (HOUR   FROM (v_ts))*60*60+
               EXTRACT (MINUTE FROM (v_ts))*60+
               EXTRACT (SECOND FROM (v_ts));
    END timestamp_diff;

-- ========================================================================

    -- Truncate with cascade option not available until 12c so have
    -- to disable constraintss for now.
    -- This procedured needs to cover both as fk constraints span schemas.
    PROCEDURE DISABLE_CONSTRAINTS
    IS
        v_sql   VARCHAR2(32767);

        CURSOR  c_constraints
        IS
        SELECT  c.owner
        ,       c.table_name
        ,       c.constraint_name
        FROM    dba_constraints c
        ,       dba_tables t
        WHERE   1=1
        AND     c.owner IN ('OLIVE','SANFRAN')
        AND     t.table_name = c.table_name
        AND     t.table_name NOT IN ('ML_RELEASE'
                                    ,'DDL_AUDIT'
                                    ,'DDL_DEPENDENCIES_AUDIT'
                                    )
        AND     c.constraint_type = 'R'
        AND     c.status = 'ENABLED'
        AND     NOT
                (
                t.iot_type IS NOT NULL
                AND
                c.constraint_type = 'P'
                )
        ORDER BY c.constraint_type DESC;

    BEGIN

        IF NOT gv_constraints_disabled THEN
        
            PRC_LOG('Disabling foreign key constraints on OLIVE and SANFRAN schemas...');

            FOR r_constraints IN c_constraints
            LOOP
                v_sql := 'ALTER TABLE "' || r_constraints.owner || '"."' || r_constraints.table_name || '" DISABLE CONSTRAINT ' || r_constraints.constraint_name || ' CASCADE';
                PRC_DEBUG(v_sql||';');
                PRC_DEBUG('v_sql length: '||LENGTH(v_sql));
                DBMS_UTILITY.EXEC_DDL_STATEMENT(v_sql);
            END LOOP;

            gv_constraints_disabled := TRUE;

        END IF;

    END DISABLE_CONSTRAINTS;

-- ========================================================================

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
            PRC_LOG('v_sql length: '||LENGTH(v_sql));
            DBMS_UTILITY.EXEC_DDL_STATEMENT(v_sql);
        END LOOP;

    END ENABLE_CONSTRAINTS;

-- ========================================================================

    PROCEDURE PRC_TRUNCATE_TABLE(p_owner      IN VARCHAR2
                                ,p_table_name IN VARCHAR2
                                )
    IS
        v_sql VARCHAR2(32767);
    BEGIN
        v_sql := 'TRUNCATE TABLE "'||p_owner||'"."'||p_table_name||'"';
        --v_sql := 'DELETE FROM '||p_owner||'.'||p_table_name;
        PRC_DEBUG(v_sql||';');
        PRC_DEBUG('v_sql length: '||LENGTH(v_sql));
        DBMS_UTILITY.EXEC_DDL_STATEMENT(v_sql);
    END PRC_TRUNCATE_TABLE;

-- ========================================================================

    PROCEDURE PRC_LOAD_TABLES(p_owner         IN VARCHAR2
                             ,p_table_name    IN VARCHAR2
                             ,p_filter_column IN VARCHAR2
                             ,p_filter_value1 IN VARCHAR2
                             ,p_filter_value2 IN VARCHAR2
                             ,p_filter_type   IN VARCHAR2
                             ,p_date_format   IN VARCHAR2
                             ,p_order_column  IN VARCHAR2
                             ,p_order_type    IN VARCHAR2
                             )
    IS
    --  PSEUDOCODE
    --  > loop through owners
    --    > loop through tables
    --      > derive filter predicate if required.
    --      > check table exists on TEST
    --      > loop through columns to build insert statement
    --        > validate column
    --      > loop through columns again to build select statement
    --        > validate column
    --      > Add filter predicate if required.
    --      > if no issues found, execute insert statement
        e_too_many_errors       EXCEPTION;
        e_invalid_order_type    EXCEPTION;
        e_invalid_order_column  EXCEPTION;

        v_sql                   VARCHAR2(32767);
        v_prefix                VARCHAR2(30);
        v_start                 TIMESTAMP;
        v_duration              NUMBER;
        v_cnt                   NUMBER;
        v_error_cnt             NUMBER;
        v_skip_column           BOOLEAN := FALSE;
        v_first_column          BOOLEAN := TRUE;
        v_lob                   BOOLEAN := FALSE;
        v_long                  BOOLEAN := FALSE;
        c_lob                   VARCHAR2(3) := 'LOB';
        c_long                  VARCHAR2(4) := 'LONG';
        c_error_limit           NUMBER := 3;
        v_predicate             VARCHAR2(1000);

    BEGIN

        FOR r_owner IN c_owner(p_owner)
        LOOP

            PRC_LOG('Loading data into tables on schema '||r_owner.username||'...');
            PRC_LOG(c_pad_dash);

            FOR r_tabs IN c_tabs(r_owner.username
                                ,p_table_name
                                )
            LOOP

                IF (p_filter_column IS NOT NULL AND p_filter_value1 IS NOT NULL) THEN
                    -- Want to call this first to validate the parameters.
                    -- Better to fail now if filter cannot be applied. If
                    -- ALL tables are being processed, then then previous
                    -- check that p_filter_column must be NULL will fail.
                    -- So FN_GET_PREDICATE should only ever run once, even 
                    -- though inside loop.
                    v_predicate := FN_GET_PREDICATE(r_owner.username
                                                   ,r_tabs.tab_name
                                                   ,p_filter_column
                                                   ,p_filter_value1
                                                   ,p_filter_value2
                                                   ,p_filter_type
                                                   ,p_date_format
                                                   );
                END IF;

                v_start := SYSTIMESTAMP;
                gv_skip_table := FALSE;

                PRC_LOG('Processing table: '||r_tabs.tab_owner||'.'||r_tabs.tab_name);

                IF FN_CHECK_TABLE_EXISTS(r_tabs.tab_owner
                                        ,r_tabs.tab_name
                                        )
                THEN
                    v_sql := 'INSERT  '||CHR(10)||
                             'INTO    '||c_dq||r_tabs.tab_owner||c_dq||'.'||c_dq||r_tabs.tab_name||c_dq||CHR(10);

                    -- Dont like the way this has to run through each column
                    -- twice but dont have time to fix it now.
                    -- write destination columns
                    v_first_column := TRUE;
                    FOR r_cols IN c_cols(r_tabs.tab_owner
                                        ,r_tabs.tab_name
                                        )
                    LOOP

                        v_skip_column := FALSE;
                        v_lob := FALSE;
                        v_long := FALSE;

                        IF FN_CHECK_COLUMN(r_tabs.tab_owner
                                          ,r_tabs.tab_name
                                          ,r_cols.col_name
                                          ,r_cols.col_type
                                          ,r_cols.nullable
                                          )
                        THEN


                            IF r_cols.col_type LIKE '%'||c_lob||'%' THEN
                                v_skip_column := TRUE;
                                v_lob := TRUE;
                            ELSIF r_cols.col_type = c_long THEN
                                v_skip_column := TRUE;
                                v_long := TRUE;
                            END IF;

                            IF v_skip_column THEN
                                v_prefix := '--      ';
                            ELSE
                                IF v_first_column THEN
                                    v_prefix := '(       ';
                                    v_first_column := FALSE;
                                ELSE
                                    v_prefix := ',       ';
                                END IF;
                            END IF;
                            
                            v_sql := v_sql||v_prefix||c_dq||r_cols.col_name||c_dq||CHR(10);

                        END IF;

                    END LOOP;

                    v_sql := v_sql||')'||CHR(10);

                    -- write source columns
                    v_first_column := TRUE;
                    FOR r_cols IN c_cols(r_tabs.tab_owner
                                        ,r_tabs.tab_name
                                        )
                    LOOP

                        v_skip_column := FALSE;
                        v_lob := FALSE;
                        v_long := FALSE;

                        IF FN_CHECK_COLUMN(r_tabs.tab_owner
                                          ,r_tabs.tab_name
                                          ,r_cols.col_name
                                          ,r_cols.col_type
                                          ,r_cols.nullable
                                          )
                        THEN


                            IF r_cols.col_type LIKE '%'||c_lob||'%' THEN
                                v_skip_column := TRUE;
                                v_lob := TRUE;
                            ELSIF r_cols.col_type = c_long THEN
                                v_skip_column := TRUE;
                                v_long := TRUE;
                            END IF;

                            IF v_skip_column THEN
                                v_prefix := '--      ';
                            ELSE
                                IF v_first_column THEN
                                    v_prefix := 'SELECT  ';
                                    v_first_column := FALSE;
                                ELSE
                                    v_prefix := ',       ';
                                END IF;
                            END IF;
                            
                            v_sql := v_sql||v_prefix||c_dq||r_cols.col_name||c_dq||CHR(10);

                        END IF;

                    END LOOP;

                    -- Add from clause
                    v_sql := v_sql||'FROM    '||c_dq||r_tabs.tab_owner||c_dq||'.'||c_dq||r_tabs.tab_name||c_dq||c_db_link||CHR(10);

                    -- Add default where clause which allows other predicates
                    -- to be added more easily.
                    v_sql := v_sql||'WHERE   1=1'||CHR(10);

                    -- Only add a limiting clause if user specifies one or
                    -- the default is accepted. Passing 0 or a negative number
                    -- as a parameter will cause all rows to be pulled.
                    IF p_tab_row_limit > 0 THEN
                        v_sql := v_sql||'AND     ROWNUM <= '||p_tab_row_limit||CHR(10);
                    END IF;

                    IF v_predicate IS NOT NULL THEN
                        v_sql := v_sql||v_predicate||CHR(10);
                    END IF;

                    -- Add an order by clause if one is provided.
                    IF p_order_column IS NOT NULL THEN
                        IF FN_COLUMN_EXISTS(r_tabs.tab_owner
                                           ,r_tabs.tab_name
                                           ,p_filter_column
                                           )
                        THEN
                            IF p_order_type NOT IN ('ASC','DESC') THEN
                                RAISE e_invalid_order_type;
                            END IF;
                        ELSE
                            RAISE e_invalid_order_column;
                        END IF;
                        v_sql := v_sql||'ORDER BY '||p_order_column||' '||p_order_type||CHR(10);
                    END IF;

                    PRC_DEBUG(v_sql||';');
                    PRC_DEBUG('SQL text length: '||LENGTH(v_sql));

                    -- only execute the sql if everything ok.
                    IF NOT gv_skip_table THEN

                        DISABLE_CONSTRAINTS;

                        PRC_TRUNCATE_TABLE(r_tabs.tab_owner,r_tabs.tab_name);

                        -- if an error is encountered, log it and continue on.
                        BEGIN
                            EXECUTE IMMEDIATE 'BEGIN ' || v_sql || '; :x := SQL%ROWCOUNT; END;' USING OUT v_cnt;
                        EXCEPTION
                            WHEN OTHERS THEN
                                PRC_LOG(SQLERRM);
                                PRC_LOG('*ERROR* encountered running sql but will continue if limit has not been reached.');
                                PRC_LOG(v_sql);
                                v_error_cnt := v_error_cnt+1;
                        END;

                    END IF;

                    PRC_LOG('Returned Rows = '||v_cnt);

                    -- I hate committing inside a loop with a cursor open 
                    -- but dont have any alternative until i bulk collect 
                    -- the tables into a collection.
                    COMMIT;

                END IF;

                IF v_lob THEN
                    PRC_LOG('*WARNING* '||c_lob||' ignored. Please review to ensure you have all required data.');
                END IF;

                IF v_long THEN
                    PRC_LOG('*WARNING* '||c_long||' ignored. Please review to ensure you have all required data.');
                END IF;

                v_duration := TIMESTAMP_DIFF(v_start,SYSTIMESTAMP);
                gv_total_duration := gv_total_duration + v_duration;
                PRC_LOG('Duration: '||v_duration);

                PRC_LOG(c_pad_dash);

                -- if too many errors are raised, then abort procedure.
                IF v_error_cnt >= c_error_limit THEN
                    RAISE e_too_many_errors;
                END IF;

            END LOOP;

        END LOOP;

    EXCEPTION 
        WHEN e_too_many_errors THEN
            gv_errmsg := '*ERROR* PRC_LOAD_TABLES: Aborting procedure as too many errors encountered.';
            PRC_LOG(gv_errmsg);
            v_duration := TIMESTAMP_DIFF(v_start,SYSTIMESTAMP);
            gv_total_duration := gv_total_duration + v_duration;
            PRC_LOG('Total time elapsed : '||gv_total_duration);
            RAISE;
        WHEN e_invalid_order_column THEN
            gv_errmsg := '*ERROR* PRC_LOAD_TABLES: Invalid parameter value for p_order_column ('||p_order_column||').';
            PRC_LOG(gv_errmsg);
            v_duration := TIMESTAMP_DIFF(v_start,SYSTIMESTAMP);
            gv_total_duration := gv_total_duration + v_duration;
            PRC_LOG('Total time elapsed : '||gv_total_duration);
            RAISE;
        WHEN e_invalid_order_type THEN
            gv_errmsg := '*ERROR* PRC_LOAD_TABLES: Invalid parameter value for p_order_type ('||p_order_type||').';
            PRC_LOG(gv_errmsg);
            v_duration := TIMESTAMP_DIFF(v_start,SYSTIMESTAMP);
            gv_total_duration := gv_total_duration + v_duration;
            PRC_LOG('Total time elapsed : '||gv_total_duration);
            RAISE;
        WHEN OTHERS THEN
            PRC_LOG(SQLERRM);
            gv_errmsg := '*ERROR* PRC_LOAD_TABLES: General exception encountered.';
            PRC_LOG(gv_errmsg);
            RAISE;

    END PRC_LOAD_TABLES;

-- ========================================================================

BEGIN

    PRC_LOG('Starting at: '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));

    v_owner := UPPER(p_owner);
    v_table_name := p_table_name; -- should be UPPER(p_table_name) but we have a few tables that are mixed case!.
    v_filter_column := p_filter_column; -- should be UPPER(p_filter_column) but we have lots of columns that are mixed case!.
    v_filter_value1 := p_filter_value1;
    v_filter_value2 := p_filter_value2;
    v_filter_type   := UPPER(p_filter_type);
    v_date_format   := UPPER(p_date_format);
    v_order_column  := p_order_column; -- should be UPPER(p_order_column) but we have lots of columns that are mixed case!.
    v_order_type    := UPPER(p_order_type);
    gv_debug        := UPPER(p_debug);

    -- log parameters
    PRC_DEBUG(' ');
    PRC_DEBUG('--------------------------------------');
    PRC_DEBUG('PRC_REFRESH_DOCKER_DATA');
    PRC_DEBUG('p_owner         : '||v_owner);
    PRC_DEBUG('p_table_name    : '||v_table_name);
    PRC_DEBUG('p_filter_value1 : '||v_filter_value1);
    PRC_DEBUG('p_filter_value2 : '||v_filter_value2);
    PRC_DEBUG('p_filter_type   : '||v_filter_type);
    PRC_DEBUG('p_date_format   : '||v_date_format);
    PRC_DEBUG('p_order_column  : '||v_order_column);
    PRC_DEBUG('p_debug         : '||gv_debug);
    PRC_DEBUG('p_tab_row_limit : '||p_tab_row_limit);
    PRC_DEBUG('--------------------------------------');

    IF NOT FN_CHECK_INSTANCE THEN
        RAISE e_check_db;
    END IF;

    -- If a filter or and order parameter is passed and owner 
    -- or table is 'ALL', then raise an error as this does not 
    -- make sense. Could default the filter column to NULL but 
    -- for now, force the user to decide.
    IF  (v_owner = 'ALL' OR v_table_name = 'ALL') THEN

        IF  (
            v_filter_column IS NOT NULL
            OR
            v_filter_value1 IS NOT NULL
            OR
            v_filter_value2 IS NOT NULL
            )
        THEN
            RAISE e_predicate_not_allowed;
        END IF;

        IF  (
            v_order_column IS NOT NULL
            OR
            v_order_type NOT IN ('ASC','DESC')
            )
        THEN
            RAISE e_order_not_allowed;
        END IF;

    ELSIF
        -- If user wants to filter on a column, then they must supply
        -- both the column name and the value they want to filter on.
        -- v_filter_value2 will be evaludated if predicate equality 
        -- type is BETWEEN.
        (
            v_filter_column IS NOT NULL
            AND
            (
                v_filter_value1 IS NULL
                OR
                (
                    v_filter_type = 'BETWEEN'
                    AND
                    v_filter_value2 IS NULL
                )
            )
        )
        OR
        (
            v_filter_column IS NULL
            AND
            (
                v_filter_value1 IS NOT NULL
                OR
                v_filter_value2 IS NOT NULL
                OR
                v_filter_type IS NOT NULL
            )
        )
    THEN
        RAISE e_invalid_predicate_parms;
    ELSIF v_filter_type NOT IN ('=','>','>=','<','<=','!=','<>','BETWEEN','LIKE') THEN
        RAISE e_invalid_filter_type;
    END IF;

    PRC_LOAD_TABLES(v_owner
                   ,v_table_name
                   ,v_filter_column
                   ,v_filter_value1
                   ,v_filter_value2
                   ,p_filter_type
                   ,p_date_format
                   ,v_order_column
                   ,v_order_type
                   );

    -- Note: Pretty much can guarantee that ENABLE_CONSTRAINTS
    -- wont work as we're only getting sample of the test data
    --ENABLE_CONSTRAINTS;

    PRC_LOG('Completed at: '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    PRC_LOG('Total time elapsed : '||gv_total_duration);
    PRC_LOG(c_pad_star);

EXCEPTION
    WHEN e_check_db THEN
        RAISE_APPLICATION_ERROR(-20001,'Can only run this script inside docker container.');
    WHEN e_predicate_not_allowed THEN
        RAISE_APPLICATION_ERROR(-20002,'Cannot filter on column '||v_filter_column||' across multiple tables. Change parameters and rerun.');
    WHEN e_order_not_allowed THEN
        RAISE_APPLICATION_ERROR(-20003,'Cannot order by column '||v_order_column||' across multiple tables. Change parameters and rerun.');
    WHEN e_invalid_predicate_parms THEN
        RAISE_APPLICATION_ERROR(-20004,'Required parameter p_filter_column or p_filter_column is NULL. If one of these is populated, then the other must be too.');
    WHEN e_invalid_filter_type THEN
        RAISE_APPLICATION_ERROR(-20005,'Program cannot currently handle filter type ('||p_filter_type||').');
    WHEN OTHERS THEN
        PRC_LOG(SQLERRM);
        RAISE_APPLICATION_ERROR(-20099,'Unhandled exception encountered.');

END "PRC_REFRESH_DOCKER_DATA";
/

EXIT;
