https://blogs.oracle.com/priminout/entry/exporting_schema_statistics

Exporting Schema Statistics
By Brian Diehl on May 07, 2013

While most of us are familiar with the schema statistics used by the Cost-Based Optimizer (CBO), something not so well know is the ability to export/import these statistics using the DBMS_STATS package. This can be an invaluable aid in diagnosing query plan differences as these statistics are the primary information used by CBO. It is also a way to save and restore statistics in your own Primavera database.

Exporting statistics is a three step process. The result is a single table containing schema statistics (table, index and column) and system statistics (workload and non-workload). The first step creates a physical version of a StatTable. The StatTable is a consolidated table to hold all types of statistics, so the format is very generic. First, create an instance of the table using DBMS_STATS.CREATE_STAT_TABLE:

begin
  dbms_stats.CREATE_STAT_TABLE( ownname=>user
                             , stattab=>'MY_STATS_TABLE'
                              );
end;
/
The result is a physical table called MY_STATS_TABLE

SQL>  desc MY_STATS_TABLE
 Name                                      Null?    Type
 ----------------------------------------- -------- ----------------------------
 STATID                                             VARCHAR2(30 CHAR)
 TYPE                                               CHAR(1 CHAR)
 VERSION                                            NUMBER
 FLAGS                                              NUMBER
 C1                                                 VARCHAR2(30 CHAR)
 C2                                                 VARCHAR2(30 CHAR)
 C3                                                 VARCHAR2(30 CHAR)
 C4                                                 VARCHAR2(30 CHAR)
 C5                                                 VARCHAR2(30 CHAR)
 N1                                                 NUMBER
 N2                                                 NUMBER
 N3                                                 NUMBER
 N4                                                 NUMBER
 N5                                                 NUMBER
 N6                                                 NUMBER
 N7                                                 NUMBER
 N8                                                 NUMBER
 N9                                                 NUMBER
 N10                                                NUMBER
 N11                                                NUMBER
 N12                                                NUMBER
 D1                                                 DATE
 R1                                                 RAW(32)
 R2                                                 RAW(32)
 CH1                                                VARCHAR2(1000 CHAR)
 CL1                                                CLOB
The next two steps are to export data from the current schema. The column STATID identifies a particular set of statistics within this table. It is possible to do multiple exports into a single StatTable by using a different STATID. In this case I am using "CURRENT_STATS" as the STATID.

--Export the Table, Index, and Column Statistics 
begin
  dbms_stats.export_schema_stats( ownname=>user
                                , stattab=>'MY_STATS_TABLE'
                                , statid=>'CURRENT_STATS'
                                );
end;
/

--Export system statistics (sys.aux_stats$)
begin
  dbms_stats.export_system_stats( stattab=>'MY_STATS_TABLE'
                                , statid=>'CURRENT_STATS'
                                );
end;
/
If we look at the contents of MY_STATS_TABLE, we will see rows for each different statistic type (T=Table, I=Index, C=Column, S=System).

select statid, type, count(*)
from my_stats_table
group by statid, type
/

STATID                         T   COUNT(*)
------------------------------ - ----------
CURRENT_STATS                  S          2
CURRENT_STATS                  C       4216
CURRENT_STATS                  I        884
CURRENT_STATS                  T        277
This table can be exported (Export or Datapump) and imported into another database. If the schema is the same, then the statistics can be imported. (Remember to clear the shared pool anytime statistics are updated.)

 
begin
  dbms_stats.import_schema_stats( ownname=>user
                                , stattab=>'MY_STATS_TABLE'
                                , statid=>'CURRENT_STATS'
                                );
end;
/

begin
  dbms_stats.import_system_stats( stattab=>'MY_STATS_TABLE'
                                , statid=>'CURRENT_STATS'
                                );
end;
/
In this way we can guarantee that queries are using the same statistics for optimization. This is the case even if the underlying data is different. Oracle only uses the stored statistics to perform query optimization (except in the case where there are no statistics; then dynamic sampling is used). This technique is an invaluable way to share optimizer statistics and diagnose query plan problems.