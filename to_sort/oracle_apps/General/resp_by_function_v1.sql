alter session set nls_language='american';

SELECT   function_name
FROM     FND_FORM_FUNCTIONS_TL ffft
,        fnd_form_functions fff
WHERE    1=1
AND      ffft.user_function_name = 'SLA: Account Derivation Rules'
AND      ffft.function_id = fff.function_id;

SELECT   r.responsibility_name
,        f.function_name
,        f.user_function_name
FROM     fnd_responsibility_vl r
,        fnd_form_functions_vl f
WHERE    1=1
--AND     r.responsibility_name = 'Lipton Purchasing Maintenance - 5710'
AND      f.function_name = 'XLA_XLAABADR'
--AND      f.function_name = 'GLXOCPER'
--AND      f.user_function_name = 'Open and Close Periods'
AND      r.menu_id IN
         (
         SELECT   me.menu_id 
         FROM     fnd_menu_entries me 
         START WITH me.function_id = f.function_id 
         CONNECT BY PRIOR me.menu_id = me.sub_menu_id
         )
AND      r.menu_id NOT IN
         (
         SELECT   frf.action_id
         FROM     fnd_resp_functions frf
         WHERE    1=1
         AND      frf.action_id = r.menu_id 
         AND      frf.rule_type = 'M'
         )
AND      f.function_id NOT IN
         (
         SELECT   frf.action_id 
         FROM     fnd_resp_functions frf 
         WHERE    1=1
         AND      frf.action_id = f.function_id 
         AND      frf.rule_type = 'F'
         );