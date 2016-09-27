select  *
from    sys.databases
where   name NOT IN ('master', 'tempdb', 'model', 'msdb');