--This file should be symlinked to the main glogin.sql file or just overwrite it.
--sudo ln -s ~/git/database-scripts/oracle/sqlplus/glogin.sql $ORACLE_HOME/sqlplus/admin/glogin.sql

set pagesize 0
set linesize 160

define_editor=vi

--using a sqlquery to customise the prompt.
--column global_name new_value gname
--set termout off
--SELECT  LOWER(SYS_CONTEXT('USERENV','CURRENT_USER'))
--        ||'@'
--        ||SYS_CONTEXT('USERENV','SERVER_HOST')
--        ||':'
--        || SYS_CONTEXT('USERENV','DB_NAME')
--        AS global_name
--FROM DUAL;
--set termout on
--set sqlprompt '&gname> '

set sqlprompt "_user'@'_connect_identifier>"

