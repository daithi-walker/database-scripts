-- Source: http://blog.ronnyegner-consulting.de/2009/10/07/useful-asm-scripts-and-queries/
-- Command to run: sqlplus -s / as sysdba @/home/oracle/david.walker/asm_comb_disk_and_diskgroup_info.sql

PROMPT 
PROMPT Combined ASM Disk And ASM Diskgroup Information
PROMPT 

SET PAGES 40000
SET LINES 120

-- The following query combines ASM disk and diskgroup information.
-- You can edit this query to suit your needs easily. If you use 
-- ASM files instead of disks you have to use v$asm_file instead
-- of v$asm_disk. If you use ASM files you have to add v$asm_file
-- to the query.

COL dg_name FOR A10
COL dg_state FOR A10
COL type FOR A10
COL dsk_no FOR 999999
COL path FOR A15
COL mount_status FOR A11
COL failgroup FOR A9
COL state  FOR A10

SELECT  dg.name AS "DG_NAME"
,       dg.state AS "DG_STATE"
,       dg.type
,       d.disk_number AS "DSK_NO"
,       d.path
,       d.mount_status
,       d.failgroup
,       d.state 
FROM    v$asm_diskgroup dg
,       v$asm_disk d
WHERE   1=1
AND     dg.group_number = d.group_number
ORDER BY dg_name
,       dsk_no;

EXIT
