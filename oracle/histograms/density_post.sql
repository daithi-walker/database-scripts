-- Supporting code for www.adellera.it/blog
--
-- (c) Alberto Dell'Era, October 2009
-- Tested in 9.2.0.8, 11.1.0.7.

set echo on
set lines 150
set pages 9999
set serveroutput on size 1000000
set trimspool on 

drop table t;

variable db_version varchar2(30)
declare
  l_dummy varchar2(100);
begin
  dbms_utility.db_version (:db_version, l_dummy);
end;
/

col db_version new_value db_version
select replace ( rtrim(:db_version,'.0'), '.', '_') as db_version from dual;

spool density_post_&db_version..lst

-- the test table with an exponential value distribution
create table t (value int);

insert into t(value) select 1   from dual connect by level <= 1;
insert into t(value) select 2   from dual connect by level <= 2;
insert into t(value) select 4   from dual connect by level <= 4;
insert into t(value) select 8   from dual connect by level <= 8;
insert into t(value) select 16  from dual connect by level <= 16;
insert into t(value) select 64  from dual connect by level <= 64;
commit;

--alter session set "_optimizer_enable_density_improvements"=false;

-- gather stats and histogram
exec dbms_stats.gather_table_stats (user, 'T', method_opt=>'for all columns size 5', estimate_percent=>null);

-- a view to format dba_histograms for our example table
create or replace view formatted_hist as
with hist1 as (
  select endpoint_number ep, endpoint_value value
    from user_histograms 
   where table_name  = 'T'
     and column_name = 'VALUE'
), hist2 as (
  select ep, value, 
         lag (ep) over (order by ep) prev_ep,
         max (ep) over ()            max_ep
    from hist1
)
select value, ep, ep - nvl(prev_ep,0) as bkt,
       decode (ep - nvl (prev_ep, 0), 0, 0, 1, 0, 1) as popularity
 from hist2
order by ep;

-- views to automatically compute the NewDensity formula for HBs
create or replace view newdensity_factors as
select max(ep) as BktCnt, -- should be equal to sum(bkt)
       sum (case when popularity=1 then bkt else 0 end) as PopBktCnt,
       sum (case when popularity=1 then 1   else 0 end) as PopValCnt,
       max ((select num_distinct as NDV from user_tab_cols where table_name = 'T' and column_name = 'VALUE')) as NDV,
       max ((select density      from user_tab_cols where table_name = 'T' and column_name = 'VALUE')) as density
  from formatted_hist;
       
create or replace view newdensity as
select ( (BktCnt - PopBktCnt) / BktCnt ) / (NDV - PopValCnt) as newdensity, 
       density as OldDensity,
       BktCnt, PopBktCnt, PopValCnt, NDV
  from newdensity_factors;
  
-- calculate NewDensity  
select * from newdensity;

-- print (formatted) histograms
select * from formatted_hist;
       
-- print density and related figures
select c.density * t.num_rows, c.density
  from user_tab_columns c, user_tables t
 where c.table_name = 'T' and c.column_name = 'VALUE'
   and c.table_name = t.table_name;

-- 1) calculate density (aka OldDensity) on the NPS (Not Popular Subtable)
-- 2) calculate the theoretical precise NewDensity reading from the actual NPS
--    (the CBO approximates this figure mining the histogram)
with nps as (
  select value
    from t
   where value not in (select value from formatted_hist where popularity=1)
), nps_count as (
  select value, count(*) as cnt
    from nps 
   group by value
), results as (
select sum (cnt * cnt / (select count(*)  from nps  ) ) as old_density_times_nr,
       sum (cnt * 1   / (select count(distinct value) from nps) ) as new_density_precise_times_nr
  from nps_count
)
select old_density_times_nr, 
       old_density_times_nr / (select num_rows from user_tables where table_name = 'T') as old_density,
       new_density_precise_times_nr,
       new_density_precise_times_nr / (select num_rows from user_tables where table_name = 'T') as new_density_precise
  from results;

-- fire the CBO on the equality filter predicate
alter session set tracefile_identifier=density_post_&db_version.;
show parameter user_dump_dest;

set autotrace traceonly explain
alter session set events '10053 trace name context forever, level 1';
select * from t where value = 2.4; 
alter session set events '10053 trace name context off';
set autotrace off 
  
spool off

