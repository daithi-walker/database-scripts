SELECT   LPAD(' ', 3*(LEVEL-1)) || menu_entry.entry_sequence   SEQUENCE 
,        LPAD(' ', 3*(LEVEL-1)) || menu.user_menu_name         SUBMENU_DESCRIPTION 
,        LPAD(' ', 3*(LEVEL-1)) || func.user_function_name     FUNCTION_DESCRIPTION 
,        menu.menu_id                                          MENU_ID
,        func.function_id                                      FUNCTION_ID
,        menu_entry.grant_flag                                 GRANT_FLAG
,        DECODE(menu_entry.sub_menu_id
               , NULL, 'FUNCTION'
               , DECODE(menu_entry.function_id
                       ,NULL, 'SUBMENU'
                       ,'BOTH'
                       )
               )                                               TYPE
FROM     fnd_menu_entries menu_entry 
,        fnd_menus_tl menu 
,        fnd_form_functions_tl func 
WHERE    1=1
AND      menu_entry.sub_menu_id = menu.menu_id(+) 
AND      menu_entry.function_id = func.function_id(+) 
AND      grant_flag = 'Y' 
START WITH menu_entry.menu_id =
         (
         SELECT   menu_id 
         FROM     fnd_menus_tl menu2 
         WHERE    1=1
         AND      menu2.menu_id = 68071
         --AND      user_menu_name = '&Parent_Menu_User_Name'
         ) 
CONNECT BY menu_entry.menu_id = PRIOR menu_entry.sub_menu_id 
ORDER SIBLINGS BY menu_entry.entry_sequence;