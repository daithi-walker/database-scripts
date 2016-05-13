-- Source: http://blog.ronnyegner-consulting.de/2009/10/07/useful-asm-scripts-and-queries/
-- Command to run: sqlplus -s / as sysdba @/home/oracle/david.walker/asm_disk_information.sql

PROMPT 
PROMPT ASM Disk Information
PROMPT 

SET PAGES 40000
SET LINES 120
COL mount_status FOR A12
COL header_status FOR A13
COL mode_status FOR A11
COL path FOR A30

SELECT  disk_number
,       mount_status
,       header_status
,       mode_status
,       state
,       path
FROM    v$asm_disk;

EXIT