declare

  cursor c_tables
  is
  select    owner
  ,         table_name
  from      all_tables
  where     1=1
  and       table_name like 'xxx%'
  ;
  
  cursor c_indexes
  is
  select    owner
  ,         index_name
  from      all_indexes
  where     1=1
  and       table_name like 'xxx%'
  ;

begin

   for r_tables in c_tables
   loop
      dbms_stats.gather_table_stats(ownname          => r_tables.owner
                                   ,tabname          => r_tables.table_name
                                   );
   end loop;
   
   for r_indexes in c_indexes
   loop
      dbms_stats.gather_index_stats(ownname          => r_indexes.owner
                                   ,indname          => r_indexes.index_name
                                   );
   end loop;
   
end;