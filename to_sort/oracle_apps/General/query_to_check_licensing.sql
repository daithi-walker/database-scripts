SELECT   fat.application_name
,        fa.application_id
,        fpi.patch_level
,        DECODE(fpi.STATUS
               ,'I','Licensed'
               ,'N','Not Licensed'
               ,'S','Shared'
               ,'Undetermined'
               ) STATUS
FROM     fnd_product_installations fpi
,        fnd_application fa
,        fnd_application_tl fat
WHERE    1=1
AND      fpi.application_id = fa.application_id
AND      fat.application_id = fa.application_id
AND      fat.LANGUAGE = 'US';
