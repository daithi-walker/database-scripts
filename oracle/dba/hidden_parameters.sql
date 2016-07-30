--Source: http://oracleinaction.com/category/uncategorized/page/17/

SELECT  a.ksppinm  "Parameter"
,       decode(p.isses_modifiable,'FALSE',NULL,NULL,NULL,b.ksppstvl) "Session"
,       c.ksppstvl "Instance"
,       decode(p.isses_modifiable,'FALSE','F','TRUE','T') "S"
,       decode(p.issys_modifiable,'FALSE','F','TRUE','T','IMMEDIATE','I','DEFERRED','D') "I"
,       decode(p.isdefault,'FALSE','F','TRUE','T') "D"
,       a.ksppdesc "Description"
FROM    x$ksppi a
,       x$ksppcv b
,       x$ksppsv c
,       v$parameter p
WHERE   1=1
AND     a.indx = b.indx
AND     a.indx = c.indx
AND     p.name(+) = a.ksppinm
--AND     upper(A.ksppinm) LIKE upper('%&1%')
ORDER BY a.ksppinm;

-- or
-- Source: http://www.oracle-training.cc/oracle_tips_hidden_parameters.htm
SELECT  a.ksppinm                   AS "NAME"
,       b.ksppstvl                  AS "VALUE"
,       b.ksppstdf                  AS "DEFAULT"
,       decode(a.ksppity, 1
              ,'boolean', 2
              ,'string', 3
              ,'number', 4
              ,'file', a.ksppity
              )                     AS "TYPE"
,       a.ksppdesc                       AS "DESCRIPTION"
from    sys.x$ksppi a
,       sys.x$ksppcv b
where   1=1
and     a.indx = b.indx
and     a.ksppinm like '\_%' escape '\'
ORDER BY name;