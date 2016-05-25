-- Source: 
-- http://dba.stackexchange.com/questions/52691/how-can-i-create-readonly-user-for-backups-in-postgresql

CREATE USER backup_admin SUPERUSER password '<PASS>';
ALTER USER backup_admin SET default_transaction_read_only = on;