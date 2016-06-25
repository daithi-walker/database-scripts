SELECT   DBMS_LOB.GETLENGTH(cnot.note_text)              CLOB_LEN
,        CEIL(DBMS_LOB.GETLENGTH(cnot.note_text)/4000)   NUM_SUBSTR
,        DBMS_LOB.SUBSTR(cnot.note_text,4000,1)          VARCHAR_VALID
,        cnot.note_text                                  CLOB_RAW
FROM     cmdseries.cnot
WHERE    1=1
AND      DBMS_LOB.GETLENGTH(cnot.note_text) > 4000;