1.	Advanced tracing and problem finding
###Tracing own session###
#a. Finding your trace file#
select value from v$diag_info where name ='Default Trace File';
OR
oradebug setmypid
oradebug tracefile_name

b. Setting trace in your own session
alter session set events '10053 trace name context forever, level 1';
OR
oradebug event 10053 trace name context forever, level 1


###Tracing other session###
a. Finding session to be traced (simplified)
select spid
  from v$process p, v$session s
  where p.addr=s.paddr
  and s.username='HR';
  
b. Setting trace for found SPID
oradebug setospid 24503
oradebug event 10053 trace name context forever, level 1

c. Finding tracefile name
oradebug tracefile_name

### Getting trace file for specific SQL statement without tracing session###
exec dbms_sqldiag.dump_trace(p_sql_id=>'c0030m3fhpvgm',p_component=>'Compiler');

### Finding potential problematic SQL statements ###

#Finding SQL statements in HR schema which may not be using bind variables:
with v_sql as
	(
    select count(distinct sql_id) as cnt_sql, plan_hash_value
    from v$sql
    where plan_hash_value>0
	and parsing_schema_name='HR'
    group by plan_hash_value
  )
  select sql_text, sql_id
  from v$sql v, v_sql vs
  where v.plan_hash_value=vs.plan_hash_value and v.parsing_schema_name='HR';
  

# Finding all SQL statements in HR schema where there is more than 1 child cursor
select sql_id, count(child_number) as cnt
     , sum(count(child_number)) over () as ver_count
  from v$sql
 where parsing_schema_name='HR'
 and plan_hash_value>0
 group by sql_id
 having count(child_number)>1;

# Finding specific SQL statement in V$SQL by SQL_TEXT
select sql_id, child_number, plan_hash_value, hash_value, address
  from v$sql
  where parsing_schema_name='HR'
 and sql_text like 'select e.first_name, e.last_name, e.salary%';

 # Finding specific SQL statement in V$SQL by SQL_TEXT
 select sql_id, child_number, plan_hash_value, hash_value, address
  from v$sql
  where  sql_id = '7ntfbfbzy0fwz';
 
### Finding out why multiple cursors/plans are being created for specific SQL ID - look for <Reason> tag in the query result
set long 999999
 select child_number, reason
   from v$sql_shared_cursor
   where sql_id='7ntfbfbzy0fwz';
 
 
### Selective purge of SQL statement from shared pool [address, hash_value, 'c']
exec dbms_shared_pool.purge('0000000094E60460,4292885407','c');


  2.	Significance of context switching - simple example
### Context switching - scale effect

#PL/SQL and SQL mixed - context switching due to switching context to SQL interpreter 1000000 times

set tim on timi on
declare 
    v_x number;
  begin
   for i in 1..1000000 loop
     select 1 into v_x from dual;
   end loop;
  end;
/

#Duration - > 1 minute

#PL/SQL only - no embedded SQL code, yet end result is the same
 declare
    v_x number;
  begin
    for i in 1..1000000 loop
      v_x:=1;
    end loop;
 end;
/

#Duration - approx. 1 second

3.	SQL Execution plan management (SQL Plans, Outlines, SQL Patches)
### Finding execution plan for specific SQL ID [SQL_ID, CHILD_NUMBER]
set lines 250
set pages 300 
select * from table(dbms_xplan.display_cursor('7ntfbfbzy0fwz',0));


## Create SQL Plan using DBMS_SPM  - Enterprise Edition
variable x number;
exec :x:=dbms_spm.LOAD_PLANS_FROM_CURSOR_CACHE(sql_id=>'7ntfbfbzy0fwz',PLAN_HASH_VALUE=>'388878752',FIXED=>'YES',ENABLED=>'YES'); 

# If parameter FIXED is set to 'NO' plan baseline will get evolved during DBMS 'evolve baselines' nigthly maintenance task 

### Delete SQL Plan
variable x number;
exec :x:=dbms_spm.drop_sql_plan_baseline(sql_handle=>NULL, plan_name =>'SQL_PLAN_fhxnj4g706xqu66b56ef0');

### Create SQL Plan using DBMS OUTLN - Standard Edition, Deprecated in 11g !!!hash_value is SQL hash_value not SQL plan hash value!!!
exec dbms_outln.CREATE_OUTLINE(hash_value=>4292885407,child_number=>1);

#In 10g
alter system set use_stored_outlines=true scope=spfile;

#In 11g - outlines deprecated - cannot persist use_stored_oulines in parameter file.
alter system set use_stored_outlines=true;

#use_stored_outlines parameter needs to be set again after each database restart

### Creating SQL patch
begin
dbms_sqldiag_internal.i_create_patch(sql_text=>'select * from employees where employee_id=100',
 hint_text=>'FULL(@SEL$1 employees)',name=>'EMPLOYEES_FTS');
end;
 /

#In the above example, query 'select * from employees where employee_id=100' will always perform FULL TABLE SCAN even though index exists. SEL$1 is the name of the SQL query block being executed and can be found by tracing SQL Execution. For nested subqueries, SEL$2, SEL$3 and so on will represent each nested SELECT query block.

#For more complex queries SQL_TEXT can be acquired using the following PL/SQL block:
set serveroutput on
set lines 250
declare
  v_sql varchar2(32000);
  begin
  select sql_fulltext into v_sql
  from v$sql
  where sql_id='dth2rqt9r6w64'
  and child_number=0;
  dbms_output.put_line(v_sql);
 end;
 /
 
 # Creating one PL/SQL block with automated SQL_TEXT fetch.
 declare
  v_sql varchar2(32000);
  begin
  select sql_fulltext into v_sql
  from v$sql
  where sql_id='dth2rqt9r6w64'
  and child_number=0;
  dbms_sqldiag_internal.i_create_patch(sql_text=>v_sql,
 hint_text=>'FULL(@SEL$1 employees2)',name=>'EXAMPLE_PATCH');
 end;
 /

!!!Important: The above SQL Plan management functions will only work if table is not set for parallel queries ie. alter table employees2 parallel 4

### Executing query with bind variables used in previous execution - Example:

#Test case - the following query is executed by HR user:
create table employees2 as select * from employees;

variable d1 varchar2(30)
variable d2 varchar2(30)
variable d3 varchar2(30)

exec :d1:='Benefits'
exec :d2:='IT'
exec :d3:='Shipping'

select e.first_name, e.last_name, e.salary, d.department_name from
employees2 e, departments d where e.department_id=d.department_id and
d.department_name in (:d1,:d2,:d3);

# Database OPTIMIZER_MODE is set to ALL_ROWS but we would like this specific query to run with FIRST_ROWS optimization

## Finding out what bind variables were used
select name, value_string
from v$sql_bind_capture
where sql_id='2dx42nwadfdvp'
and child_number=0;

# The above will return d1=Benefits, d2=IT and d3=Shipping

# Log in as SYS
# Now we need to change system parameter OPTIMIZER_MODE to FIRST_ROWS, but only at session level

alter session set optimizer_mode=FIRST_ROWS;

# Then change current schema to HR and execute the exact same query to generate another child cursor.

 ### Executing SQL in user schema with binds
 alter session set current_schema=hr;

 declare
  v_sql varchar2(32000);
  begin
  select sql_fulltext into v_sql
  from v$sql
  where sql_id='2dx42nwadfdvp'
  and child_number=0;
  execute immediate v_sql using 'Benefits','IT','Shipping';
 end;

 # Executing the above will result in generating another child cursor with different SQL Execution Plan
 # If we are happy with the new plan and perfromance, we can use SQL Plan Baseline or DBMS Outline to permanently associate new plan with the above SQL statement
 
  
4.	Database parameters (documented and hidden) influencing performance and useful performance views and functions
### Controlling Direct Path Read behaviour with Full Table Scans
#Hidden parameter “_small_table_threshold” defines the number of blocks to consider a table as small. Parameter is set at instance startup and depends on db_cache_size.
#Any table having more blocks will automatically use direct path reads for serial full table scans (FTS).
#Extensive Direct Path Read activity may be observed in ie. STATSPACK report in top 5 Wait Events.

# Finding out small table threshold
select p.KSPPINM, v.KSPPSTVL
from x$ksppi p, x$ksppcv v
where p.INDX=v.INDX
and p.KSPPINM like '_small_table%'
/

#Hidden parameter can be modified but it is !!!! not recommended !!!!
alter system set "_small_table_threshold"=4609 scope=spfile;
#More suitable solution would be increasing the SGA_TARGET and/or setting minimum value for db_cache_size parameter


### Controlling I/O behavior with db_file_multiblock_read_count parameter
#db_file_multiblock_read_count parameter can be used to reduce database I/O during table scans
#Setting db_file_multiblock_read_count to a high value ie. 1024 does not have any negative impact on database operations, however may not improve anything either if table extents contain small number of blocks.
#In order to achieve real benefits from using high value for db_file_multiblock_read_count, tables being frequently accessed using FTS (Full Table Scan) must have their extents in uniform size of at least value of db_file_multiblock_read_count * db_block size ie. 1024*8192=8388608 (bytes) for 8k block size
#Example:
SQL> 
  1  select blocks, count(1)
  2  from dba_extents
  3  where segment_name='SALES2'
  4  group by blocks
  5* order by 1

    BLOCKS   COUNT(1)
---------- ----------
         8         16
       128         35

SQL> create tablespace sales2_1024b
  2  datafile size 256M
  3  autoextend on next 64M
  4  maxsize unlimited
  5  extent management local
  6  uniform size 8388608;

Tablespace created.

# Table needs to be moved to new tablespace to enforce rebuild with bigger extents.

SQL> alter table sh.sales2 move tablespace sales2_1024b;

SQL> select blocks, count(1) from dba_extents  where segment_name='SALES2' group by blocks;

    BLOCKS   COUNT(1)
---------- ----------
      1024          5


### Controlling sort operations - ie. avoiding soriting in temp
# In Oracle 11g _pga_max_size is set dynamically as 5% pga_aggregate_target value and denotes memory available to a workarea and to a single process.
# If a sort operation requires more RAM than 50% of _pga_max_size value, it will be 'flushed' to TEMP, what in turn may negatively impact perfromance.
	  
#Finding PGA Max size
select p.KSPPINM, v.KSPPSTVL
from x$ksppi p, x$ksppcv v
where p.INDX=v.INDX
and p.KSPPINM like '_pga_max%'; 

# pga_aggregate_target parameter can be increased to create bigger workarea for sort operations. pga_aggregate_target can even be incresed above avaialble server RAM memory, but !!! this is not recommended !!! and may crash the instance due to ORA-04030 errors

### Finding object latch contention (ie. hot tables)
  with v_latch as
 (
 select o.object_name, o.owner, o.object_type, l.GETS, l.MISSES, l.SLEEPS, l.name,
    row_number() over (order by l.misses desc) as rn
 from x$bh b, v$latch_children l, dba_objects o
 where b.obj=o.data_object_id
 and   o.owner not like '%SYS%'
 and   b.hladdr=l.addr
 )
select *
 from v_latch
 where rn<=10;
 
 # If for example contention is on 'cache buffers chains', one of resolution attempts may be increasing db_writer_processes parameter

5.	Adaptive Cursor Sharing
New content shortly

6.	New tool: OraTop
More info: oratop – utility for near real-time monitoring of databases, RAC and Single Instance (Doc ID 1500864.1)

7. Formatting of AWR HTML reports - AWR Formatter Chrome Plugin
