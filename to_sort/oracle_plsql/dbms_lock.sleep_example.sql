declare
 sleep_cnt        pls_integer := 0;
 sleep_duration   pls_integer := 1; --seconds to sleep
 max_sleep_time   pls_integer := 60; --one minute
 bl_continue      boolean := FALSE;
begin
   while (sleep_cnt < max_sleep_time and not bl_continue)
   loop
      DBMS_LOCK.sleep(sleep_duration);
      DBMS_OUTPUT.PUT_LINE('sleep_cnt: '||sleep_cnt);
         if sleep_cnt = 10 then
            bl_continue := TRUE;
            DBMS_OUTPUT.PUT_LINE('condition met. exit while loop.');
         end if;
      sleep_cnt := sleep_cnt + 1;
   end loop;
end;
