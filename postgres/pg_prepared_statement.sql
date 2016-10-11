PREPARE dwtest (timestamp, int, text) as 
SELECT $1 as ts, $2 as num, $3 as txt;
EXECUTE dwtest(statement_timestamp() - interval '60 minute' , -123456789, 'test');
DEALLOCATE dwtest;