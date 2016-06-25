--drop table dw_test;
--create table dw_test as select 'aaaaaaaaaaaaaaaaa' col1 from dual;
--select * from dw_test;
--rollback;

declare
  l_output_file		UTL_FILE.FILE_TYPE;
  i number; 
  l_out_dir         VARCHAR2(100);
  l_file_name 		VARCHAR2(100) := 'dw_test1.txt';
  v_str  varchar2(100);
begin
  dbms_output.enable(10000);
  l_out_dir := XXCRH_SYSTEM_PKG.GET_XXCRH_VALUE('XXCRH', 'XXCRH_COMMAND_DIR');
  l_output_file := UTL_FILE.FOPEN(l_out_dir, l_file_name,'W',32767);
  for i in 1..5
  loop
    v_str := 'dw_test - ' || i;
    UTL_FILE.PUT_LINE(l_output_file,v_Str);
    insert into dw_test values (v_str);
    dbms_output.put_line(v_str);
  end loop;
  UTL_FILE.FCLOSE(l_output_file);
  commit;
end;