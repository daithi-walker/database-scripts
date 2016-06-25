-- select fn_calc_business_days(sysdate, sysdate + 6) from dual;
CREATE OR REPLACE FUNCTION fn_calc_business_days(p_start_date IN DATE
                                                ,p_end_date   IN DATE
                                                )
RETURN NUMBER
IS
   v_ret_val NUMBER;
BEGIN
   IF p_end_date >= p_start_date THEN
      SELECT   ROUND(SUM(p_end_date_cut - p_start_date_cut),2)
      INTO     v_ret_val
      FROM     (
               SELECT   CASE
                           WHEN
                              LEVEL = 1
                           THEN
                              p_start_date + LEVEL - 1
                           ELSE
                              TRUNC(p_start_date + LEVEL - 1,'DD')
                        END p_start_date_cut
               ,        CASE
                           WHEN
                              LEVEL = MAX(LEVEL) OVER (PARTITION BY NULL)
                           THEN
                              p_end_date
                           ELSE
                              TRUNC(p_start_date + LEVEL - (1/24/60/60),'DD')
                           END p_end_date_cut
               FROM     dual
               CONNECT BY LEVEL <= CEIL(p_end_date - p_start_date) + 1
               )
      WHERE    1=1
      AND      TO_CHAR(p_start_date_cut, 'DY') NOT IN ('SAT', 'SUN');
      RETURN v_ret_val;
   ELSE
      RETURN NULL;
   END IF;
END;