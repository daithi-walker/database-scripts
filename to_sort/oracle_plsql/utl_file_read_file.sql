--select * from v$parameter where name = 'utl_file_dir';
DECLARE
   f     UTL_FILE.FILE_TYPE;
   uline VARCHAR2(200);
   udir  VARCHAR2(1000) := 'SEPA_OUTDIR';
   ufile VARCHAR2(100) := 'test';
BEGIN
   f := UTL_FILE.FOPEN(udir,ufile,'R');
   IF UTL_FILE.IS_OPEN(f) THEN
      LOOP
         BEGIN
            UTL_FILE.GET_LINE(f,uline);
            IF uline IS NULL THEN
               EXIT;
            END IF;
            dbms_output.put_line(uline);
         END;
      END LOOP;
      COMMIT;
   END IF;
END;