-- Source: http://blog.ronnyegner-consulting.de/2009/10/07/useful-asm-scripts-and-queries/
-- Command to run: sqlplus -s / as sysdba @/home/oracle/david.walker/asm_disk_group_info.sql

PROMPT 
PROMPT ASM Disk Group Info
PROMPT 

SET PAGES 40000
SET LINES 120
COL name FOR A10

SELECT   group_number AS "GN"
,        name
,        allocation_unit_size AS "AU_SZ"
,        state
,        type
,        total_mb
,        free_mb
,        offline_disks
FROM     v$asm_diskgroup;

EXIT