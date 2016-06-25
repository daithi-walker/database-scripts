   gv_debug   VARCHAR2(5);

   /* Procedure used to write to the log file */
   PROCEDURE WriteLog(pv_messStr  IN  VARCHAR2) IS
   BEGIN
      FND_FILE.PUT_LINE( FND_FILE.LOG, pv_messStr );
   END WriteLog;

   /* Procedure used to display debug messages */
   PROCEDURE Debug(pv_messStr IN  VARCHAR2) IS
      vv_message       VARCHAR2(200);
   BEGIN
      IF gv_debug = 'TRUE' THEN
         vv_message := SUBSTR(pv_messStr,1,200);
         WriteLog(vv_message);
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
      dbms_output.enable(1000000);
   END Debug;