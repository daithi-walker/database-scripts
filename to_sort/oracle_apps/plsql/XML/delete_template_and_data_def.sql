DECLARE
   -- Change the following two parameters
   var_templateCode    VARCHAR2 (100) := 'APXSEPAUOME';     -- Template Code
   boo_deleteDataDef   BOOLEAN := FALSE;     -- delete the associated Data Def.
BEGIN
   FOR RS
      IN (SELECT T1.APPLICATION_SHORT_NAME TEMPLATE_APP_NAME,
                 T1.DATA_SOURCE_CODE,
                 T2.APPLICATION_SHORT_NAME DEF_APP_NAME
            FROM XDO_TEMPLATES_B T1, XDO_DS_DEFINITIONS_B T2
           WHERE T1.TEMPLATE_CODE = var_templateCode
                 AND T1.DATA_SOURCE_CODE = T2.DATA_SOURCE_CODE)
   LOOP
      XDO_TEMPLATES_PKG.DELETE_ROW (RS.TEMPLATE_APP_NAME, var_templateCode);

      DELETE FROM XDO_LOBS
            WHERE     LOB_CODE = var_templateCode
                  AND APPLICATION_SHORT_NAME = RS.TEMPLATE_APP_NAME
                  AND LOB_TYPE IN ('TEMPLATE_SOURCE', 'TEMPLATE');

      DELETE FROM XDO_CONFIG_VALUES
            WHERE     APPLICATION_SHORT_NAME = RS.TEMPLATE_APP_NAME
                  AND TEMPLATE_CODE = var_templateCode
                  AND DATA_SOURCE_CODE = RS.DATA_SOURCE_CODE
                  AND CONFIG_LEVEL = 50;

      DBMS_OUTPUT.PUT_LINE ('Selected template has been ' || var_templateCode || ' deleted.');

      IF boo_deleteDataDef
      THEN
         XDO_DS_DEFINITIONS_PKG.DELETE_ROW (RS.DEF_APP_NAME,
                                            RS.DATA_SOURCE_CODE);

         DELETE FROM XDO_LOBS
               WHERE LOB_CODE = RS.DATA_SOURCE_CODE
                     AND APPLICATION_SHORT_NAME = RS.DEF_APP_NAME
                     AND LOB_TYPE IN
                            ('XML_SCHEMA',
                             'DATA_TEMPLATE',
                             'XML_SAMPLE',
                             'BURSTING_FILE');

         DELETE FROM XDO_CONFIG_VALUES
               WHERE     APPLICATION_SHORT_NAME = RS.DEF_APP_NAME
                     AND DATA_SOURCE_CODE = RS.DATA_SOURCE_CODE
                     AND CONFIG_LEVEL = 30;

         DBMS_OUTPUT.PUT_LINE (
            'Selected Data Defintion has been ' || RS.DATA_SOURCE_CODE || ' deleted.');
      END IF;
   END LOOP;
  COMMIT;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE (
         'Unable to delete XML Publisher Template ' || var_templateCode);
      DBMS_OUTPUT.PUT_LINE (SUBSTR (SQLERRM, 1, 200));
END;
/