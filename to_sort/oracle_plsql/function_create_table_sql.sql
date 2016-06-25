create or replace function create_table_sql(r_owner in varchar2
                                           ,r_table_name in varchar2
                                           )
return varchar2
as
   starting boolean :=true;
begin
   dbms_output.put_line('CREATE TABLE '||r_owner||'.'||r_table_name);
   for r in (
            select   column_name
            ,        data_type
            ,        data_length
            ,        data_precision
            ,        data_scale
            ,        data_default
            ,        nullable
            from     all_tab_columns
            where    1=1
            and      table_name = upper(r_table_name)
            and      owner = upper(r_owner)
            order by column_id
            )
   loop

      if starting then
         dbms_output.put('(        ');
         starting:=false;
      else
         dbms_output.put(',        ');
      end if;
      
      if r.data_type = 'NUMBER' then
         if r.data_precision is null then
            dbms_output.put_line(rpad(r.column_name,30 ,' ')||' NUMBER');
         else
            if r.data_scale is null then
               dbms_output.put_line(rpad(r.column_name,30 ,' ')||' NUMBER('||r.data_precision||')');
            else
               dbms_output.put_line(rpad(r.column_name,30 ,' ')||'NUMBER('||r.data_precision||','||r.data_scale||')');
            end if;
         end if;
      else
         if r.data_type = 'DATE' then
            dbms_output.put_line(rpad(r.column_name,30 ,' ')||' DATE');
         else
            if instr(r.data_type, 'CHAR') > 0 then
               dbms_output.put_line(rpad(r.column_name,30 ,' ')||' '||r.data_type||'('||r.data_length||')');
            else
               dbms_output.put_line(rpad(r.column_name,30 ,' ')||' '||r.data_type);
            end if;
         end if;
      end if;

      if r.data_default is not null then
         dbms_output.put_line(' DEFAULT '||r.data_default);
      end if;
      
      if r.nullable = 'N' then
         dbms_output.put_line(' NOT NULL ');
      end if;

   end loop;

   dbms_output.put_line('); ');  
   return null;

 end;
 /

