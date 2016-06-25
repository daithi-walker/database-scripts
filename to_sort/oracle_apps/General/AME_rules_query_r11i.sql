alter session set nls_language='AMERICAN';

SELECT   ar.rule_id
,        ar.description rule_name
,        ar.start_date
,        ar.end_date
,        acu.condition_id
,        ame_condition_pkg.GetDescription (acu.condition_id) as condition
,        aty.name action_type
,        ame_action_pkg.GetDescription (ameactionusageeo.action_id) AS approver_group
FROM     ame_rules ar
,        ame_condition_usages acu
,        ame_action_usages ameactionusageeo
,        ame_actions act
,        ame_action_types aty
,        (
         SELECT   *
         FROM     ame_action_type_usages
         WHERE    1=1
         AND      rule_type <> 2
         AND      SYSDATE BETWEEN start_date AND NVL(end_date - (1 / 86400), SYSDATE)
         ) atu
WHERE    1=1
AND      TRUNC (SYSDATE) BETWEEN ar.start_date AND NVL(ar.end_date, TO_DATE ('31-DEC-4712', 'DD-MON-YYYY'))
AND      acu.rule_id = ar.rule_id
AND      TRUNC (SYSDATE) BETWEEN acu.start_date AND NVL(acu.end_date,TO_DATE ('31-DEC-4712', 'DD-MON-YYYY'))
AND      (
         SYSDATE BETWEEN ameactionusageeo.start_date AND NVL (ameactionusageeo.end_date - (1 / 86400),SYSDATE)
         OR
            (
            SYSDATE < ameactionusageeo.start_date
            AND
            ameactionusageeo.start_date < NVL(ameactionusageeo.end_date,ameactionusageeo.start_date + (1 / 86400))
            )
         )
AND      SYSDATE BETWEEN act.start_date AND NVL (act.end_date - (1 / 86400), SYSDATE)
AND      SYSDATE BETWEEN aty.start_date AND NVL (aty.end_date - (1 / 86400), SYSDATE)
AND      aty.action_type_id = atu.action_type_id
AND      act.action_id = ameactionusageeo.action_id
AND      act.action_type_id = aty.action_type_id
AND      ameactionusageeo.rule_id = ar.rule_id
order by ar.rule_id
,        acu.condition_id;