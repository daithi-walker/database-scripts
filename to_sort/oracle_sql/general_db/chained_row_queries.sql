@..../utlchain.sql

--drop table test_objects;
--truncate table chained_rows;

create table test_objects(data varchar2(4000));

insert into test_objects (select object_name from dba_objects where rownum < 100);
commit;

analyze table test_objects list chained rows;
select count(*) from chained_rows where table_name='TEST_OBJECTS';

update test_objects set data = rpad('x', 3000, 'x');
commit;

analyze table test_objects list chained rows;
select count(*) from chained_rows where table_name='TEST_OBJECTS';

select * from chained_rows where head_rowid = 'AALn+AAIiAAC4gnAAC'; --table_name='TEST_OBJECTS';
select * from test_objects where rowid = 'AALn+AAIiAAC4gnAAC'
update test_objects set data = 'dw_test' where rowid = 'AALn+AAIiAAC4gnAAC';
commit;

alter table test_objects move;

truncate table chained_rows;

analyze table test_objects list chained rows;
select count(*) from chained_rows where table_name='TEST_OBJECTS';