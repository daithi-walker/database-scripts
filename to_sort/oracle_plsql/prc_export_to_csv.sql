CREATE OR REPLACE PROCEDURE Pr_ExportToCSV( i_tname IN VARCHAR2
                                          , i_dir   IN VARCHAR2
                                          , i_filename IN VARCHAR2
                                          )
IS

   t_output         utl_file.file_type;
   vn_theCursor     INTEGER DEFAULT dbms_sql.open_cursor;
   vv_columnValue   VARCHAR2(4000);
   vn_status        INTEGER;
   vv_query         VARCHAR2(1000) DEFAULT 'select * from ' || i_tname;
   vn_colCnt        NUMBER := 0;
   vv_Sep           VARCHAR2(1);
   t_descTbl        dbms_sql.desc_tab;

BEGIN

   t_output := utl_file.fopen( i_dir, i_filename, 'w' );
   EXECUTE IMMEDIATE 'alter session set nls_date_format=''dd-mon-yyyy hh24:mi:ss''';
 
   dbms_sql.parse( vn_theCursor, vv_query, dbms_sql.native );
   dbms_sql.describe_columns( vn_theCursor, vn_colCnt, t_descTbl );

   <<column_count>>
   FOR i IN 1 .. vn_colCnt LOOP
      utl_file.put( t_output, vv_Sep || '"' || t_descTbl(i).col_name || '"' );
      dbms_sql.define_column( vn_theCursor, i, vv_columnValue, 4000 );
      vv_Sep := ',';
   END LOOP column_count;
 
   utl_file.new_line( t_output );
 
   vn_status := dbms_sql.execute(vn_theCursor);

   <<cursor_rows>>
   WHILE ( dbms_sql.fetch_rows(vn_theCursor) > 0 ) LOOP
      vv_Sep := '';
      <<column_count>>
      FOR i IN 1 .. vn_colCnt LOOP
         dbms_sql.column_value( vn_theCursor, i, vv_columnValue );
         utl_file.put( t_output, vv_Sep || vv_columnValue );
         vv_Sep := ',';
      END LOOP column_count;
      utl_file.new_line( t_output );
   END LOOP cursor_rows;
   dbms_sql.close_cursor(vn_theCursor);
   utl_file.fclose( t_output );

   EXECUTE IMMEDIATE 'alter session set nls_date_format=''dd-MON-yy'' ';

EXCEPTION
   WHEN utl_file.invalid_path THEN
      raise_application_error(-20100,'Invalid Path');
   WHEN utl_file.invalid_mode THEN
      raise_application_error(-20101,'Invalid Mode');
   WHEN utl_file.invalid_operation THEN
      raise_application_error(-20102,'Invalid Operation');
   WHEN utl_file.invalid_filehandle THEN
      raise_application_error(-20103,'Invalid FileHandle');
   WHEN utl_file.write_error THEN
      raise_application_error(-20104,'Write Error');
   WHEN utl_file.read_error THEN
      raise_application_error(-20105,'Read Error');
   WHEN utl_file.internal_error THEN
      raise_application_error(-20106,'Internal Error');
   WHEN OTHERS THEN
      utl_file.fclose( t_output );
      EXECUTE IMMEDIATE 'alter session set nls_date_format=''dd-MON-yy'' ';
      RAISE;

END Pr_ExportToCSV;