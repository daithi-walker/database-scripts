--http://oracle-randolf.blogspot.co.uk/2011/08/multi-column-joins-expressions-and-11g.html

create table t
as
select
       rownum as id
     , mod(rownum, 50) + 1 as id_50
     , 'ABC' || to_char(mod(rownum, 50) + 1) as id_char_50
     , case when mod(rownum, 2) = 0 then null else mod(rownum, 100) + 1 end as id_50_null
     , case when mod(rownum, 2) = 0 then null else 'ABC' || to_char(mod(rownum, 100) + 1) end as id_char_50_null
from
     dual
connect by
     level <= 1000
;

exec dbms_stats.gather_table_stats(null, 't', method_opt => 'for all columns size 1')

explain plan for
select  /*+ optimizer_features_enable('10.2.0.4') */
       /* opt_param('_optimizer_join_sel_sanity_check', 'false') */
       count(*)
from
       t t1
     , t t2
where
       t1.id_50 = t2.id_50
and     t1.id_char_50 = t2.id_char_50
;

select * from table(dbms_xplan.display(null, null, 'BASIC +ROWS'));

Plan hash value: 791582492
 
--------------------------------------------
| Id  | Operation           | Name | Rows  |
--------------------------------------------
|   0 | SELECT STATEMENT    |      |     1 |
|   1 |  SORT AGGREGATE     |      |     1 |
|   2 |   HASH JOIN         |      |  1000 |
|   3 |    TABLE ACCESS FULL| T    |  1000 |
|   4 |    TABLE ACCESS FULL| T    |  1000 |
--------------------------------------------