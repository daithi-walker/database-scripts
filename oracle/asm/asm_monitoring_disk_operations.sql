-- Source: http://blog.ronnyegner-consulting.de/2009/10/07/useful-asm-scripts-and-queries/
-- Command to run: sqlplus -s / as sysdba @/home/oracle/david.walker/asm_monitoring_disk_operations.sql

-- If there is a operating going on (like rebalancing) the query will return some rows.
-- For instance for our just added disk the query yields:

PROMPT 
PROMPT 	Monitoring ASM Disk Operations
PROMPT 

SET PAGES 40000
SET LINES 120
COL group_number FOR A12
COL operation FOR A10
COL state FOR A6
COL actual FOR 999999999.99
COL sofar FOR 999999999.99
COL est_minutes FOR 999999999.99

SELECT 	group_number
,       operation
,       state
,       actual
,       sofar
,       est_minutes
FROM 	v$asm_operation;

EXIT