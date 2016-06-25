SELECT   DISTINCT
         attribute3
FROM     hz_cust_accounts
WHERE    1=1
AND      attribute3 IS NOT NULL
AND      REGEXP_LIKE(attribute3, '^[[:digit:]]+$')
ORDER BY 1;