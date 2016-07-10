WITH delivery AS
  (
  SELECT  lvl
  ,       SYSDATE+lvl date_of_activity
  ,       lvl*100 spend
  FROM    (
          SELECT  LEVEL lvl
          FROM    dual
          CONNECT BY LEVEL <= 10
          MINUS
          SELECT 2 FROM dual
          MINUS
          SELECT 4 FROM dual
          MINUS
          SELECT 6 FROM dual
          MINUS
          SELECT 8 FROM dual
          )
  )
, EVENTS AS
  (
  SELECT  lvl
  ,       SYSDATE+lvl date_of_activity
  ,       lvl event1
  FROM    (
          SELECT  LEVEL lvl
          FROM    dual
          CONNECT BY LEVEL <= 10
          MINUS
          SELECT 2 FROM dual
          MINUS
          SELECT 3 FROM dual
          MINUS
          SELECT 9 FROM dual
          )
  )
SELECT COALESCE(delivery.lvl,EVENTS.lvl) lvl
,      delivery.lvl delivery_lvl
,      events.lvl event_level
,      date_of_activity
,      spend
,      event1
FROM delivery
FULL JOIN EVENTS USING (date_of_activity)
ORDER BY COALESCE(delivery.lvl,EVENTS.lvl)
;