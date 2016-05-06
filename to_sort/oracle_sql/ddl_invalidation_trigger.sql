drop procedure prc;
drop view v1;
drop table t1;
drop trigger befddl_trg;
drop table ddl_invalidations;
drop sequence ddl_invalidations_seq;

create sequence ddl_invalidations_seq;

create table ddl_invalidations (
  ddl_invalidation_id number,
  operation           varchar2(30),
  invalidating_object varchar2(30),
  invalidating_owner  varchar2(30),
  invalidating_type   varchar2(30),
  invalidated_object  varchar2(30),
  invalidated_owner   varchar2(30),
  invalidated_type    varchar2(30),
  invalidation_date   date,
  osuser              varchar2(30),
  host                varchar2(30),
  module              varchar2(30),
  dbuser              varchar2(30)
  );

create or replace trigger befddl_trg
before ddl
on schema
declare
  e_oops exception;
begin
  if (ora_sysevent='TRUNCATE') then
    null; -- I do not care about truncate
  elsif (ora_dict_obj_name = 'DDL_INVALIDATIONS') then 
    raise e_oops;
  else
  insert into ddl_invalidations
    select ddl_invalidations_seq.nextval
    ,      ora_sysevent
    ,      ora_dict_obj_name
    ,      ora_dict_obj_owner
    ,      ora_dict_obj_type
    ,      d.name
    ,      d.owner
    ,      d.type
    ,      sysdate
    ,      sys_context('USERENV','OS_USER')
    ,      sys_context('USERENV','HOST'),sys_context('USERENV','MODULE')
    ,      sys_context('USERENV','CURRENT_USER')
    from   all_dependencies d
    ,      all_objects o
    where  d.referenced_name = ora_dict_obj_name
    and    d.referenced_owner = ora_dict_obj_owner
    and    o.object_name = d.referenced_name
    and    o.owner = d.referenced_owner
    ;
  end if;

exception
   when e_oops then
      dbms_output.put_line('Dropping this table causes a lot of problems!');
      raise;
end befddl_trg;
/

create table t1 (x integer);

create view v1 as
  select * from t1;

create or replace procedure prc as 
begin
  for c in (select * from t1) loop
    null;
  end loop;
end;
/

alter table t1 add y integer;

select * from ddl_invalidations;