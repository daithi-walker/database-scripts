http://satya-dba.blogspot.co.uk/2010/08/setting-sql-prompt-in-oracle.html

$ORACLE_HOME/sqlplus/admin/glogin.sql
set sqlprompt "&_user> "
set sqlprompt "_user'@'_connect_identifier>"

_connect_identifier will display connection identifier.
_date               will display date.
_editor             will display editor name used by the EDIT command.
_o_version          will display Oracle version.
_o_release          will display Oracle release.
_privilege          will display privilege such as SYSDBA, SYSOPER, SYSASM
_sqlplus_release    will display SQL*PLUS release.
_user               will display current user name.

set sqlprompt "&_connect_identifier> "
set sqlprompt "&_date> "
set sqlprompt "&_editor> "
set sqlprompt "&_o_version> "
set sqlprompt "&_o_release> "
set sqlprompt "&_privilege> "
set sqlprompt "&_sqlplus_release> "
set sqlprompt "&_user> "

