http://www.alberton.info/postgresql_meta_info.html#.VsQbWHWLTCI

Following my tutorial on how to extract meta informations from Firebird SQL, I'm now going to show how to retrieve the same informations from PostgreSQL, using the INFORMATION_SCHEMA (available since PostgreSQL 7.4) and with system catalogs (pg_class, pg_user, pg_view, etc).
NB: as you probably know, you can list tables/indices/sequences/views from the command line with the \d{t|i|s|v} command, but here I want to show how to extract these informations using standard SQL queries.

Test data
We need a few sample tables, indices and views to test the following queries, so let's create them. We also create a sample TRIGGER and a function.

-- sample data to test PostgreSQL INFORMATION_SCHEMA
 
-- TABLE TEST
CREATE TABLE TEST (
TEST_NAME CHAR(30) NOT NULL,
TEST_ID INTEGER DEFAULT '0' NOT NULL,
TEST_DATE TIMESTAMP NOT NULL
);
ALTER TABLE TEST ADD CONSTRAINT PK_TEST PRIMARY KEY (TEST_ID);
 
-- TABLE TEST2 with some CONSTRAINTs and an INDEX
CREATE TABLE TEST2 (
ID INTEGER NOT NULL,
FIELD1 INTEGER,
FIELD2 CHAR(15),
FIELD3 VARCHAR(50),
FIELD4 INTEGER,
FIELD5 INTEGER,
ID2 INTEGER NOT NULL
);
ALTER TABLE TEST2 ADD CONSTRAINT PK_TEST2 PRIMARY KEY (ID2);
ALTER TABLE TEST2 ADD CONSTRAINT TEST2_FIELD1ID_IDX UNIQUE (ID, FIELD1);
ALTER TABLE TEST2 ADD CONSTRAINT TEST2_FIELD4_IDX UNIQUE (FIELD4);
CREATE INDEX TEST2_FIELD5_IDX ON TEST2(FIELD5);
 
-- TABLE NUMBERS
CREATE TABLE NUMBERS (
NUMBER INTEGER DEFAULT '0' NOT NULL,
EN CHAR(100) NOT NULL,
FR CHAR(100) NOT NULL
);
 
-- TABLE NEWTABLE
CREATE TABLE NEWTABLE (
ID INT DEFAULT 0 NOT NULL,
SOMENAME VARCHAR (12),
SOMEDATE TIMESTAMP NOT NULL
);
ALTER TABLE NEWTABLE ADD CONSTRAINT PKINDEX_IDX PRIMARY KEY (ID);
CREATE SEQUENCE NEWTABLE_SEQ INCREMENT 1 START 1;
 
42.
-- VIEW on TEST
43.
CREATE VIEW "testview"(
44.
TEST_NAME,
45.
TEST_ID,
46.
TEST_DATE
47.
) AS
48.
SELECT *
49.
FROM TEST
50.
WHERE TEST_NAME LIKE 't%';
51.
 
52.
-- VIEW on NUMBERS
53.
CREATE VIEW "numbersview"(
54.
NUMBER,
55.
TRANS_EN,
56.
TRANS_FR
57.
) AS
58.
SELECT *
59.
FROM NUMBERS
60.
WHERE NUMBER > 100;
61.
 
62.
-- TRIGGER on NEWTABLE
63.
CREATE FUNCTION add_stamp() RETURNS OPAQUE AS '
64.
BEGIN
65.
IF (NEW.somedate IS NULL OR NEW.somedate = 0) THEN
66.
NEW.somedate := CURRENT_TIMESTAMP;
67.
RETURN NEW;
68.
END IF;
69.
END;
70.
' LANGUAGE 'plpgsql';
71.
 
72.
CREATE TRIGGER ADDCURRENTDATE
73.
BEFORE INSERT OR UPDATE
74.
ON newtable FOR EACH ROW
75.
EXECUTE PROCEDURE add_stamp();
76.
 
77.
-- TABLEs for testing CONSTRAINTs
78.
CREATE TABLE testconstraints (
79.
someid integer NOT NULL,
80.
somename character varying(10) NOT NULL,
81.
CONSTRAINT testconstraints_id_pk PRIMARY KEY (someid)
82.
);
83.
CREATE TABLE testconstraints2 (
84.
ext_id integer NOT NULL,
85.
modified date,
86.
uniquefield character varying(10) NOT NULL,
87.
usraction integer NOT NULL,
88.
CONSTRAINT testconstraints_id_fk FOREIGN KEY (ext_id)
89.
REFERENCES testconstraints (someid) MATCH SIMPLE
90.
ON UPDATE CASCADE ON DELETE CASCADE,
91.
CONSTRAINT unique_2_fields_idx UNIQUE (modified, usraction),
92.
CONSTRAINT uniquefld_idx UNIQUE (uniquefield)
93.
);
List TABLEs
Here's the query that will return the names of the tables defined in the current database:

SELECT relname
FROM pg_class
WHERE relname !~ '^(pg_|sql_)'
AND relkind = 'r';
<!--
SELECT c.relname AS "Name"
FROM pg_class c, pg_user u
WHERE c.relowner = u.usesysid
AND c.relkind = 'r'
AND NOT EXISTS (
SELECT 1
FROM pg_views
WHERE viewname = c.relname
)
AND c.relname !~ '^(pg_|sql_)'
UNION
SELECT c.relname AS "Name"
FROM pg_class c
WHERE c.relkind = 'r'
AND NOT EXISTS (
SELECT 1
FROM pg_views
WHERE viewname = c.relname
)
AND NOT EXISTS (
SELECT 1
FROM pg_user
WHERE usesysid = c.relowner
)
AND c.relname !~ '^pg_';
-->
-- using INFORMATION_SCHEMA:
 
SELECT table_name
FROM information_schema.tables
WHERE table_type = 'BASE TABLE'
AND table_schema NOT IN
('pg_catalog', 'information_schema');
List VIEWs
Here's the query that will return the names of the VIEWs defined in the current database:

-- with postgresql 7.2:
 
SELECT viewname
FROM pg_views
WHERE viewname !~ '^pg_';
 
-- with postgresql 7.4 and later:
 
SELECT viewname
FROM pg_views
WHERE schemaname NOT IN
('pg_catalog', 'information_schema')
AND viewname !~ '^pg_';
 
-- using INFORMATION_SCHEMA:
 
SELECT table_name
FROM information_schema.tables
WHERE table_type = 'VIEW'
AND table_schema NOT IN
('pg_catalog', 'information_schema')
AND table_name !~ '^pg_';
 
-- or
 
SELECT table_name
FROM information_schema.views
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
AND table_name !~ '^pg_';
<!--
# show only the VIEWs referencing a given table
 
SELECT viewname
FROM pg_views
NATURAL JOIN pg_tables
WHERE tablename ='test';
-->
List users
1.
SELECT usename
2.
FROM pg_user;
List table fields
Here's the query that will return the names of the fields of the TEST2 table:

SELECT a.attname
FROM pg_class c, pg_attribute a, pg_type t
WHERE c.relname = 'test2'
AND a.attnum > 0
AND a.attrelid = c.oid
AND a.atttypid = t.oid
 
-- with INFORMATION_SCHEMA:
 
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'test2';
Detailed table field info
If you want some more info about the field definitions, you can retrieve a larger subset of the fields available in the schema:

SELECT a.attnum AS ordinal_position,
a.attname AS column_name,
t.typname AS data_type,
a.attlen AS character_maximum_length,
a.atttypmod AS modifier,
a.attnotnull AS notnull,
a.atthasdef AS hasdefault
FROM pg_class c,
pg_attribute a,
pg_type t
WHERE c.relname = 'test2'
AND a.attnum > 0
AND a.attrelid = c.oid
AND a.atttypid = t.oid
ORDER BY a.attnum;
 
-- with INFORMATION_SCHEMA:
 
SELECT ordinal_position,
column_name,
data_type,
column_default,
is_nullable,
character_maximum_length,
numeric_precision
FROM information_schema.columns
WHERE table_name = 'test2'
ORDER BY ordinal_position;
List INDICES
Here's the query that will return the names of the INDICES defined in the TEST2 table. Unfortunately I have no idea how to extract them from the INFORMATION_SCHEMA. If you do, please let me know.
NB: the CONSTRAINTs are not listed

SELECT relname
FROM pg_class
WHERE oid IN (
SELECT indexrelid
FROM pg_index, pg_class
WHERE pg_class.relname='test2'
AND pg_class.oid=pg_index.indrelid
AND indisunique != 't'
AND indisprimary != 't'
);
 
-- Alternative using JOINs (thanks to William Stevenson):
 
SELECT
c.relname AS index_name
FROM
pg_class AS a
JOIN pg_index AS b ON (a.oid = b.indrelid)
JOIN pg_class AS c ON (c.oid = b.indexrelid)
WHERE
a.relname = 'test2';
Detailed INDEX info
If you want to know which table columns are referenced by an index, you can do it in two steps: first you get the table name and field(s) position with this query:

SELECT relname, indkey
FROM pg_class, pg_index
WHERE pg_class.oid = pg_index.indexrelid
AND pg_class.oid IN (
SELECT indexrelid
FROM pg_index, pg_class
WHERE pg_class.relname='test2'
AND pg_class.oid=pg_index.indrelid
AND indisunique != 't'
AND indisprimary != 't'
);
Then, using your favorite language, you explode the indkey (the key separator is a space), and for each key you run this query:

SELECT t.relname, a.attname, a.attnum
FROM pg_index c
LEFT JOIN pg_class t
ON c.indrelid  = t.oid
LEFT JOIN pg_attribute a
ON a.attrelid = t.oid
AND a.attnum = ANY(indkey)
WHERE t.relname = 'test2'
AND a.attnum = 6; -- this is the index key
List CONSTRAINTs
Here's the query that will return the names of the CONSTRAINTs defined in the TEST2 table:

SELECT relname
FROM pg_class
WHERE oid IN (
SELECT indexrelid
FROM pg_index, pg_class
WHERE pg_class.relname='test2'
AND pg_class.oid=pg_index.indrelid
AND (   indisunique = 't'
OR indisprimary = 't'
)
);
 
-- with INFORMATION_SCHEMA:
 
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'test2';
<!--
SELECT *
FROM information_schema.constraint_column_usage
-->
Detailed CONSTRAINT info
If you want to retrieve detailed info from any constraint (fields, type, rules, referenced table and fields for FOREIGN KEYs, etc.) given its name and table, here's the query to do so:

SELECT c.conname AS constraint_name,
CASE c.contype
WHEN 'c' THEN 'CHECK'
WHEN 'f' THEN 'FOREIGN KEY'
WHEN 'p' THEN 'PRIMARY KEY'
WHEN 'u' THEN 'UNIQUE'
END AS "constraint_type",
CASE WHEN c.condeferrable = 'f' THEN 0 ELSE 1 END AS is_deferrable,
CASE WHEN c.condeferred = 'f' THEN 0 ELSE 1 END AS is_deferred,
t.relname AS table_name,
array_to_string(c.conkey, ' ') AS constraint_key,
CASE confupdtype
WHEN 'a' THEN 'NO ACTION'
WHEN 'r' THEN 'RESTRICT'
WHEN 'c' THEN 'CASCADE'
WHEN 'n' THEN 'SET NULL'
WHEN 'd' THEN 'SET DEFAULT'
END AS on_update,
CASE confdeltype
WHEN 'a' THEN 'NO ACTION'
WHEN 'r' THEN 'RESTRICT'
WHEN 'c' THEN 'CASCADE'
WHEN 'n' THEN 'SET NULL'
WHEN 'd' THEN 'SET DEFAULT'
END AS on_delete,
CASE confmatchtype
WHEN 'u' THEN 'UNSPECIFIED'
WHEN 'f' THEN 'FULL'
WHEN 'p' THEN 'PARTIAL'
END AS match_type,
t2.relname AS references_table,
array_to_string(c.confkey, ' ') AS fk_constraint_key
FROM pg_constraint c
LEFT JOIN pg_class t  ON c.conrelid  = t.oid
LEFT JOIN pg_class t2 ON c.confrelid = t2.oid
WHERE t.relname = 'testconstraints2'
AND c.conname = 'testconstraints_id_fk';
 
-- with INFORMATION_SCHEMA:
 
SELECT tc.constraint_name,
42.
tc.constraint_type,
43.
tc.table_name,
44.
kcu.column_name,
45.
tc.is_deferrable,
46.
tc.initially_deferred,
47.
rc.match_option AS match_type,
48.
rc.update_rule AS on_update,
49.
rc.delete_rule AS on_delete,
50.
ccu.table_name AS references_table,
51.
ccu.column_name AS references_field
52.
FROM information_schema.table_constraints tc
53.
LEFT JOIN information_schema.key_column_usage kcu
54.
ON tc.constraint_catalog = kcu.constraint_catalog
55.
AND tc.constraint_schema = kcu.constraint_schema
56.
AND tc.constraint_name = kcu.constraint_name
57.
LEFT JOIN information_schema.referential_constraints rc
58.
ON tc.constraint_catalog = rc.constraint_catalog
59.
AND tc.constraint_schema = rc.constraint_schema
60.
AND tc.constraint_name = rc.constraint_name
61.
LEFT JOIN information_schema.constraint_column_usage ccu
62.
ON rc.unique_constraint_catalog = ccu.constraint_catalog
63.
AND rc.unique_constraint_schema = ccu.constraint_schema
64.
AND rc.unique_constraint_name = ccu.constraint_name
65.
WHERE tc.table_name = 'testconstraints2'
66.
AND tc.constraint_name = 'testconstraints_id_fk';
The "constraint_key" and "fk_constraint_key" fields returned by the first query are space-separated strings containing the position of the fields involved (in the FOREIGN KEY constraint and those referenced by it), so you may need to retrieve them with another query on the respective tables. Since the field positions are stored as arrays, you can't (to the best of my knowledge) get all the field names with an unique query (well, you could with a stored procedure).
The second query, the one using the INFORMATION_SCHEMA, is certainly more straightforward, albeit slower.

List sequences
A SEQUENCE is an object that automatically generate sequence numbers. A SEQUENCE is often used to ensure a unique value in a PRIMARY KEY that must uniquely identify the associated row.

SELECT relname
FROM pg_class
WHERE relkind = 'S'
AND relnamespace IN (
SELECT oid
FROM pg_namespace
WHERE nspname NOT LIKE 'pg_%'
AND nspname != 'information_schema'
);
List TRIGGERs
SELECT trg.tgname AS trigger_name
FROM pg_trigger trg, pg_class tbl
WHERE trg.tgrelid = tbl.oid
AND tbl.relname !~ '^pg_';
-- or
SELECT tgname AS trigger_name
FROM pg_trigger
WHERE tgname !~ '^pg_';
 
-- with INFORMATION_SCHEMA:
 
SELECT DISTINCT trigger_name
FROM information_schema.triggers
WHERE trigger_schema NOT IN
('pg_catalog', 'information_schema');
List only the triggers for a given table:

SELECT trg.tgname AS trigger_name
FROM pg_trigger trg, pg_class tbl
WHERE trg.tgrelid = tbl.oid
AND tbl.relname = 'newtable';
 
-- with INFORMATION_SCHEMA:
 
SELECT DISTINCT trigger_name
FROM information_schema.triggers
WHERE event_object_table = 'newtable'
AND trigger_schema NOT IN
('pg_catalog', 'information_schema');
Detailed TRIGGER info
Show more informations about the trigger definitions:

SELECT trg.tgname AS trigger_name,
tbl.relname AS table_name,
p.proname AS function_name,
CASE trg.tgtype & cast(2 as int2)
WHEN 0 THEN 'AFTER'
ELSE 'BEFORE'
END AS trigger_type,
CASE trg.tgtype & cast(28 as int2)
WHEN 16 THEN 'UPDATE'
WHEN  8 THEN 'DELETE'
WHEN  4 THEN 'INSERT'
WHEN 20 THEN 'INSERT, UPDATE'
WHEN 28 THEN 'INSERT, UPDATE, DELETE'
WHEN 24 THEN 'UPDATE, DELETE'
WHEN 12 THEN 'INSERT, DELETE'
END AS trigger_event,
CASE trg.tgtype & cast(1 as int2)
WHEN 0 THEN 'STATEMENT'
ELSE 'ROW'
END AS action_orientation
FROM pg_trigger trg,
pg_class tbl,
pg_proc p
WHERE trg.tgrelid = tbl.oid
AND trg.tgfoid = p.oid
AND tbl.relname !~ '^pg_';
 
-- with INFORMATION_SCHEMA:
 
SELECT *
FROM information_schema.triggers
WHERE trigger_schema NOT IN
('pg_catalog', 'information_schema');
List FUNCTIONs
SELECT proname
FROM pg_proc pr,
pg_type tp
WHERE tp.oid = pr.prorettype
AND pr.proisagg = FALSE
AND tp.typname <> 'trigger'
AND pr.pronamespace IN (
SELECT oid
FROM pg_namespace
WHERE nspname NOT LIKE 'pg_%'
AND nspname != 'information_schema'
);
 
-- with INFORMATION_SCHEMA:
 
SELECT routine_name
FROM information_schema.routines
WHERE specific_schema NOT IN
('pg_catalog', 'information_schema')
AND type_udt_name != 'trigger';
Albe Laurenz sent me the following function that is even more informative: for a function name and schema, it selects the position in the argument list, the direction, the name and the data-type of each argument. This procedure requires PostgreSQL 8.1 or later.

CREATE OR REPLACE FUNCTION public.function_args(
IN funcname character varying,
IN schema character varying,
OUT pos integer,
OUT direction character,
OUT argname character varying,
OUT datatype character varying)
RETURNS SETOF RECORD AS $$DECLARE
rettype character varying;
argtypes oidvector;
allargtypes oid[];
argmodes "char"[];
argnames text[];
mini integer;
maxi integer;
BEGIN
/* get object ID of function */
SELECT INTO rettype, argtypes, allargtypes, argmodes, argnames
CASE
WHEN pg_proc.proretset
THEN 'setof ' || pg_catalog.format_type(pg_proc.prorettype, NULL)
ELSE pg_catalog.format_type(pg_proc.prorettype, NULL) END,
pg_proc.proargtypes,
pg_proc.proallargtypes,
pg_proc.proargmodes,
pg_proc.proargnames
FROM pg_catalog.pg_proc
JOIN pg_catalog.pg_namespace
ON (pg_proc.pronamespace = pg_namespace.oid)
WHERE pg_proc.prorettype <> 'pg_catalog.cstring'::pg_catalog.regtype
AND (pg_proc.proargtypes[0] IS NULL
OR pg_proc.proargtypes[0] <> 'pg_catalog.cstring'::pg_catalog.regtype)
AND NOT pg_proc.proisagg
AND pg_proc.proname = funcname
AND pg_namespace.nspname = schema
AND pg_catalog.pg_function_is_visible(pg_proc.oid);
 
/* bail out if not found */
IF NOT FOUND THEN
RETURN;
END IF;
42.
 
43.
/* return a row for the return value */
44.
pos = 0;
45.
direction = 'o'::char;
46.
argname = 'RETURN VALUE';
47.
datatype = rettype;
48.
RETURN NEXT;
49.
 
50.
/* unfortunately allargtypes is NULL if there are no OUT parameters */
51.
IF allargtypes IS NULL THEN
52.
mini = array_lower(argtypes, 1); maxi = array_upper(argtypes, 1);
53.
ELSE
54.
mini = array_lower(allargtypes, 1); maxi = array_upper(allargtypes, 1);
55.
END IF;
56.
IF maxi < mini THEN RETURN; END IF;
57.
 
58.
/* loop all the arguments */
59.
FOR i IN mini .. maxi LOOP
60.
pos = i - mini + 1;
61.
IF argnames IS NULL THEN
62.
argname = NULL;
63.
ELSE
64.
argname = argnames[pos];
65.
END IF;
66.
IF allargtypes IS NULL THEN
67.
direction = 'i'::char;
68.
datatype = pg_catalog.format_type(argtypes[i], NULL);
69.
ELSE
70.
direction = argmodes[i];
71.
datatype = pg_catalog.format_type(allargtypes[i], NULL);
72.
END IF;
73.
RETURN NEXT;
74.
END LOOP;
75.
 
76.
RETURN;
77.
END;$$ LANGUAGE plpgsql STABLE STRICT SECURITY INVOKER;
78.
COMMENT ON FUNCTION public.function_args(character varying, character
79.
varying)
80.
IS $$For a function name and schema, this procedure selects for each
81.
argument the following data:
82.
- position in the argument list (0 for the return value)
83.
- direction 'i', 'o', or 'b'
84.
- name (NULL if not defined)
85.
- data type$$;
Show PROCEDURE definition
SELECT p.proname AS procedure_name,
p.pronargs AS num_args,
t1.typname AS return_type,
a.rolname AS procedure_owner,
l.lanname AS language_type,
p.proargtypes AS argument_types_oids,
prosrc AS body
FROM pg_proc p
LEFT JOIN pg_type t1 ON p.prorettype=t1.oid  
LEFT JOIN pg_authid a ON p.proowner=a.oid
LEFT JOIN pg_language l ON p.prolang=l.oid
WHERE proname = :PROCEDURE_NAME;
pg_proc.proargtypes contains an array of oids pointing to pg_type.oid. You can use unnest(), generate_procedure() or the function in the previous paragraph to retrieve the data type of each parameter.

