DECLARE

   v_ret NUMBER;

   FUNCTION exec_host_command( lc_cmd IN VARCHAR2 )
   RETURN INTEGER
   IS
      ln_status NUMBER;
      lc_errormsg VARCHAR2(80);
      lc_pipe_name VARCHAR2(30);
   BEGIN
      lc_pipe_name := 'HOST_PIPE';
      dbms_pipe.pack_message( lc_cmd );
      ln_status := dbms_pipe.send_message(lc_pipe_name);
      RETURN ln_status;
   END;

BEGIN
   v_ret := exec_host_command('cp <source_file> <dest_file>');
   dbms_output.put_line('return_code: ' || v_ret);
END;