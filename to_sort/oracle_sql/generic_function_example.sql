DECLARE
   v_ret VARCHAR2(2000);
   FUNCTION FN_GET_DIRECTORY(iv_directory_name IN  VARCHAR2)
   RETURN VARCHAR2
   IS
      v_retval VARCHAR(200);
   BEGIN
      SELECT   directory_path
      INTO     v_retval
      FROM     all_directories
      WHERE    1=1
      AND      directory_name = iv_directory_name;
      --v_retval := XXCRH_SYSTEM_PKG.GET_XXCRH_VALUE('XXCRH','XXCRH_SEPADANSKE_DIR');
      RETURN v_retval;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RAISE; -- e_sepa_dir_not_found;
   END FN_GET_DIRECTORY;
BEGIN
  v_ret := FN_GET_DIRECTORY('SEPA_OUT_DIR');
  dbms_output.put_line(v_ret);
END;