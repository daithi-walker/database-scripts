WITH ds AS 
(
SELECT  LEVEL rel_id
FROM    dual CONNECT BY LEVEL <= 20
)        
SELECT  'incorrect' METHOD
,       listagg(rel_id,' ') WITHIN GROUP (ORDER BY 1) return_val
FROM    ds
UNION
SELECT  'correct' METHOD
,       listagg(rel_id,' ') WITHIN GROUP (ORDER BY rel_id) return_val
FROM    ds
;

METHOD    RETURN_VAL
--------- --------------------------------------------------
correct   1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
incorrect 1 10 11 12 13 14 15 16 17 18 19 2 20 3 4 5 6 7 8 9