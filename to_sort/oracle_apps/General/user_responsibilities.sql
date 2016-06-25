ALTER SESSION SET NLS_LANGUAGE='AMERICAN';

-- Query for R12
SELECT   fu.user_name
,        frt.responsibility_name
,        furgd.description
,        furgd.start_date
,        furgd.end_date
,        fr.responsibility_key
,        fa.application_short_name
FROM     fnd_user fu
,        fnd_user_resp_groups_direct furgd
,        fnd_responsibility_tl frt
,        fnd_responsibility fr
,        fnd_application_tl fat
,        fnd_application fa
WHERE    1=1
AND      fu.user_name = :user_name --WALKERD
AND      furgd.user_id = fu.user_id
AND      (
         furgd.end_date IS NULL
         OR
         furgd.end_date >= TRUNC(SYSDATE)
         )
AND      frt.responsibility_id = furgd.responsibility_id
AND      frt.language =  USERENV('LANG')
--AND      frt.responsibility_name LIKE '%Purchasing%' --Lipton Purchasing Fire Fighter - 5710
AND      fr.responsibility_id =  frt.responsibility_id
AND      fat.application_id = fr.application_id
AND      fa.application_id = fat.application_id
ORDER BY frt.responsibility_name;

/*Oracle 10g - Apps R11i*/
SELECT   fu.user_name
,        fu.employee_id
,        furg.responsibility_id
,        frv.responsibility_name
,        furg.start_date
,        furg.end_date
FROM     fnd_user fu
,        fnd_user_resp_groups frug
,        fnd_responsibility_vl frv
WHERE    1=1
AND      fu.user_name = :user_name --WALKERD
AND      furg.user_id = fu.user_id
AND      frv.responsibility_id  = furg.responsibility_id
ORDER BY frv.responsibility_name;

/*Oracle 8i - Apps R11*/
SELECT   fu.user_name
,        fu.employee_id
,        furg.responsibility_id
,        frv.responsibility_name
,        furg.start_date
,        furg.end_date
FROM     fnd_user fu
,        fnd_user_responsibility fur
,        fnd_responsibility_vl frv
WHERE    1=1
AND      fu.user_name = :user_name --WALKERD
AND      fur.user_id = fu.user_id
AND      frv.responsibility_id = fur.responsibility_id
ORDER BY frv.responsibility_name;