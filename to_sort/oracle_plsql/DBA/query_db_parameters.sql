SELECT  *
FROM    pg_settings
WHERE   1=1
AND     name LIKE '%vacuum%'
--AND     category LIKE  '%vacuum%'
;