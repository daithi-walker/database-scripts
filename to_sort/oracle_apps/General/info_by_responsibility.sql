SELECT   lvl LVL
,        rownumber RN
,        fm.menu_id
,        fm.entry_sequence seq
,        (lvl || '.' || rownumber || '.' || fm.entry_sequence) menu_seq
,        fm.menu_name
,        fm.sub_menu_name
,        fmet.prompt
,        fmet.description
,        fff.type
,        fff.function_name
,        fff.user_function_name
,        fff.description form_description
 FROM    (
         SELECT   LEVEL lvl
         ,        ROW_NUMBER () OVER (PARTITION BY LEVEL, fmv.menu_id ORDER BY entry_sequence) AS rownumber
         ,        fmv.entry_sequence
         ,        (
                  SELECT   user_menu_name
                  FROM     fnd_menus_vl fmvl
                  WHERE    1 = 1
                  AND      fmvl.menu_id = fmv.menu_id
                  ) menu_name
         ,        (
                  SELECT   user_menu_name
                  FROM     fnd_menus_vl fmvl
                  WHERE    1 = 1
                  AND      fmvl.menu_id = fmv.sub_menu_id
                  ) sub_menu_name
         ,        fmv.function_id
         ,        fmv.menu_id
         --,        prompt
         --,        description
         --FROM     apps.fnd_menu_entries_vl fmv
         FROM     apps.fnd_menu_entries fmv
         WHERE    1=1
         START WITH menu_id =
                  (
                  SELECT   menu_id
                  FROM     apps.fnd_responsibility_vl
                  WHERE    1=1
                  AND      UPPER(responsibility_name) = UPPER (:resp_name) --PCIL Payables RSU - 5600
                  )
         CONNECT BY PRIOR sub_menu_id = menu_id
         ) fm
,        apps.fnd_form_functions_vl fff
,        fnd_menu_entries_tl fmet
WHERE    1=1
AND      fmet.menu_id = fm.menu_id
AND      fmet.entry_sequence = fm.entry_sequence
AND      fmet.language = USERENV('LANG')
AND      fff.function_id(+) = fm.function_id
--AND      fff.function_id = :function_id --1348
--AND      fm.menu_id = :menu_id
ORDER BY fm.lvl
,        fm.menu_id
,        fm.entry_sequence;