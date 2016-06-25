DECLARE

   l_function_name   VARCHAR2(100)  := 'AP_APXVDMVD'; -- Suppliers
   l_function_id     NUMBER;
   
   l_responsibility_name   VARCHAR2(100) := NULL;
   --l_responsibility_name   VARCHAR2(100) := 'PCIL Payables RSU - 5600';  --uncomment to check specific responsibility
   
   l_true            BOOLEAN;

   CURSOR   c_function
   IS
   SELECT   f.function_id
   FROM     fnd_form_functions_vl f
   WHERE    1=1
   AND      f.function_name = l_function_name;
   
   CURSOR   c_responsibility
   IS
   SELECT   r.menu_id
   ,        r.application_id
   ,        r.responsibility_id
   ,        r.responsibility_name
   FROM     apps.fnd_responsibility_vl r
   ,        fnd_user fu
   WHERE    1=1
   AND      fu.user_id = r.created_by
   AND      fu.created_by <> 1  -- AUTOINSTALL
   AND      r.responsibility_name = NVL(l_responsibility_name,r.responsibility_name)
   AND      NVL(r.end_date,SYSDATE) > TRUNC(SYSDATE,'DD')
   ORDER BY r.responsibility_name;

   FUNCTION fn_process_menu_tree(p_menu_id      IN NUMBER
                                ,p_function_id  IN NUMBER
                                ,p_appl_id      IN NUMBER
                                ,p_resp_id      IN NUMBER
                                )
   RETURN BOOLEAN
   IS

      l_sub_menu_id  NUMBER;

      /* Table to store the list of submenus that we are looking for */
      TYPE menulist_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
      menulist       menulist_type;

      TYPE number_table_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;

      TYPE varchar2_table_type IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;
      /* The table of exclusions. The index in is the action_id, and the */
      /* value stored in each element is the rule_type.*/
      exclusions     varchar2_table_type;

      /* Returns from the bulk collect (fetches) */
      tbl_menu_id    number_table_type;
      tbl_ent_seq    number_table_type;
      tbl_func_id    number_table_type;
      tbl_submnu_id  number_table_type;
      tbl_gnt_flg    varchar2_table_type;

      bl_bulk_collects_supported BOOLEAN  := TRUE;
      c_max_menu_entries         NUMBER   := 10000;

      /* Cursor to get exclusions */
      CURSOR   c_exclusions
      IS
      SELECT   rule_type
      ,        action_id
      FROM     apps.fnd_resp_functions
      WHERE    1=1
      AND      application_id    = p_appl_id
      AND      responsibility_id = p_resp_id;

      /* Cursor to get menu entries on a particular menu.*/
      CURSOR   c_menu_entries
      IS
      SELECT   menu_id
      ,        entry_sequence
      ,        function_id
      ,        sub_menu_id
      ,        grant_flag
      FROM     apps.fnd_menu_entries
      WHERE    1=1
      AND      menu_id = l_sub_menu_id;

      menulist_cur      PLS_INTEGER;
      menulist_size     PLS_INTEGER;

      bl_entry_excluded    BOOLEAN;
      last_index        PLS_INTEGER;
      i                 NUMBER;
      z                 NUMBER;

   BEGIN

      -- This routine processes the menu hierarchy and exclusion rules in PL/SQL rather than in the database.
      -- The basic algorithm of this routine is:
      -- Populate the list of exclusions by selecting from FND_RESP_FUNCTIONS
      -- menulist(1) = p_menu_id
      -- while (elements on menulist)
      -- {
      -- Remove first element off menulist
      -- if this menu is not excluded with a menu exclusion rule
      -- {
      -- Query all menu entry children of current menu
      -- for (each child) loop
      -- {
      -- If it's excluded by a func exclusion rule, go on to the next one.
      -- If we've got the function we're looking for,
      -- and grant_flag = Y, we're done- return TRUE;
      -- If it's got a sub_menu_id, add it to the end of menulist
      -- to be processed
      -- }
      -- Move to next element on menulist
      -- }
      -- }

      IF (p_appl_id IS NOT NULL) THEN
         /* Select the list of exclusion rules into our cache */
         FOR r_exclusions IN c_exclusions
         LOOP
            exclusions(r_exclusions.action_id) := r_exclusions.rule_type;
         END LOOP;
      END IF;

      -- Initialize menulist working list to parent menu
      menulist_cur := 0;
      menulist_size := 1;
      menulist(0) := p_menu_id;

      -- Continue processing until reach the end of list
      WHILE (menulist_cur < menulist_size)
      LOOP
         -- Check if recursion limit exceeded
         IF (menulist_cur > c_max_menu_entries) THEN
            RETURN FALSE;
         END IF;
         l_sub_menu_id := menulist(menulist_cur);
         -- See whether the current menu is excluded or not.
         bl_entry_excluded := FALSE;

         BEGIN
            IF (
               l_sub_menu_id IS NOT NULL
               AND
               exclusions(l_sub_menu_id) = 'M'
               )
            THEN
               bl_entry_excluded := TRUE;
            END IF;
         EXCEPTION
            WHEN no_data_found THEN
            NULL;
         END;

         IF bl_entry_excluded THEN
            last_index := 0; /* Indicate that no rows were returned */
         ELSE
            /* This menu isn't excluded, so find out whats entries are on it. */
            IF (bl_bulk_collects_supported) THEN
               OPEN  c_menu_entries;
               FETCH c_menu_entries BULK COLLECT INTO tbl_menu_id, tbl_ent_seq, tbl_func_id, tbl_submnu_id, tbl_gnt_flg;
               CLOSE c_menu_entries;
               -- See if we found any rows. If not set last_index to zero.
               BEGIN
                  IF (
                     tbl_menu_id.FIRST IS NULL
                     OR
                     tbl_menu_id.FIRST <> 1
                     )
                  THEN
                     last_index := 0;
                  ELSE
                     IF tbl_menu_id.FIRST IS NOT NULL THEN
                        last_index := tbl_menu_id.LAST;
                     ELSE
                        last_index := 0;
                     END IF;
                  END IF;
               EXCEPTION
                  WHEN OTHERS THEN
                     last_index := 0;
               END;
            ELSE
               z:= 0;
               FOR r_menu_entries IN c_menu_entries
               LOOP
                  z := z + 1;
                  tbl_menu_id(z) := r_menu_entries.menu_id;
                  tbl_ent_seq(z) := r_menu_entries.entry_sequence;
                  tbl_func_id(z) := r_menu_entries.function_id;
                  tbl_submnu_id(z):= r_menu_entries.sub_menu_id;
                  tbl_gnt_flg(z) := r_menu_entries.grant_flag;
               END LOOP;
               last_index := z;
            END IF;
         END IF; /* bl_entry_excluded */
         -- Process each of the child entries fetched
         FOR i IN 1 .. last_index
         LOOP
            -- Check if there is an exclusion rule for this entry
            bl_entry_excluded := FALSE;
            BEGIN
               IF (
                  tbl_func_id(i) IS NOT NULL
                  AND
                  exclusions(tbl_func_id(i)) = 'F'
                  )
               THEN
                  bl_entry_excluded := TRUE;
               END IF;
            EXCEPTION
               WHEN no_data_found THEN
                  NULL;
            END;
            -- Skip this entry if it's excluded
            IF NOT bl_entry_excluded THEN
               -- Check if this is a matching function. If so, return success.
               IF (
                  tbl_func_id(i) = p_function_id
                  AND
                  tbl_gnt_flg(i) = 'Y'
                  )
               THEN
                  RETURN TRUE;
               END IF;
               -- If this is a submenu, then add it to the end of the working list for processing.
               IF tbl_submnu_id(i) IS NOT NULL THEN
                  menulist(menulist_size) := tbl_submnu_id(i);
                  menulist_size := menulist_size + 1;
               END IF;
            END IF; -- End if not excluded
         END LOOP; -- For loop processing child entries
         -- Advance to next menu on working list
         menulist_cur := menulist_cur + 1;
      END LOOP;
      -- We couldn't find the function anywhere, so it's not available
      RETURN FALSE;

   END fn_process_menu_tree;

BEGIN

   dbms_output.put_line('******************************************');

   OPEN  c_function;
   FETCH c_function INTO l_function_id;
   CLOSE c_function;

   FOR r_responsibility IN c_responsibility
   LOOP
      l_true := FALSE;
      l_true := fn_process_menu_tree(r_responsibility.menu_id
                                 ,l_function_id
                                 ,r_responsibility.application_id
                                 ,r_responsibility.responsibility_id
                                 );
      IF l_true THEN
         dbms_output.put_line(r_responsibility.responsibility_name);
      END IF;
   END LOOP;

   dbms_output.put_line('******************************************');
   
END;