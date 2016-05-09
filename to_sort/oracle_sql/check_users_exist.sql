with usr_lst as
(
select 'ICL' ORG, 'andrew doyle' username from dual union all
select 'ICL' ORG, 'ben mohan' username from dual union all
select 'ICL' ORG, 'cormac everitt' username from dual union all
select 'ICL' ORG, 'shane dundon' username from dual union all
select 'ICL' ORG, 'david griffin' username from dual union all
select 'ICL' ORG, 'stephen p keating' username from dual union all
select 'ICL' ORG, 'garry foran' username from dual union all
select 'ICL' ORG, 'thomas ryan' username from dual union all
select 'ICL' ORG, 'robert campbell' username from dual union all
select 'ICL' ORG, 'thomas fay' username from dual union all
select 'ICL' ORG, 'sanna luhtala' username from dual union all
select 'ICL' ORG, 'fintan obrien' username from dual union all
select 'ICL' ORG, 'niall okelly' username from dual union all
select 'ICL' ORG, 'jason gilbert' username from dual union all
select 'ICL' ORG, 'francis mcinerney' username from dual union all
select 'ICL' ORG, 'eike richter' username from dual union all
select 'ICL' ORG, 'clariane sales tabosa' username from dual union all
select 'ICL' ORG, 'joao santos-vitor' username from dual union all
select 'ICL' ORG, 'hazel mcardle' username from dual union all
select 'ICL' ORG, 'marko vidakovic' username from dual union all
select 'ICL' ORG, 'john spellman' username from dual union all
select 'ICL' ORG, 'lukasz gortad' username from dual union all
select 'ICL' ORG, 'eamonn matthews' username from dual union all
select 'ICL' ORG, 'jane tormey' username from dual union all
select 'ICL' ORG, 'don conroy' username from dual union all
select 'ICL' ORG, 'anthony williams' username from dual union all
select 'ICL' ORG, 'damien mason' username from dual union all
select 'ICL' ORG, 'eamonn hayes' username from dual union all
select 'ICL' ORG, 'oliver farrell' username from dual union all
select 'ICL' ORG, 'arthur oriordan' username from dual union all
select 'ICL' ORG, 'hugh devereaux' username from dual union all
select 'RW' ORG, 'jack dempsey' username from dual union all
select 'RW' ORG, 'kieran shannon' username from dual union all
select 'RW' ORG, 'sean hearte' username from dual union all
select 'RW' ORG, 'john malone' username from dual union all
select 'RW' ORG, 'nigel feeney' username from dual union all
select 'RW' ORG, 'joseph porter ' username from dual union all
select 'RW' ORG, 'ronan griffin' username from dual union all
select 'RW' ORG, 'aaron rath' username from dual union all
select 'RW' ORG, 'michelle odonnell' username from dual union all
select 'RW' ORG, 'aaron lowe' username from dual union all
select 'RW' ORG, 'aoife power' username from dual union all
select 'RW' ORG, 'stephen dunne' username from dual union all
select 'RW' ORG, 'paul brady' username from dual union all
select 'RW' ORG, 'lorraine toner' username from dual union all
select 'RW' ORG, 'brian dempsey' username from dual union all
select 'RW' ORG, 'dara aherne' username from dual union all
select 'RW' ORG, 'dean harte' username from dual union all
select 'RW' ORG, 'sean dunne' username from dual union all
select 'RW' ORG, 'gerard kearney' username from dual union all
select 'RW' ORG, 'james kingston' username from dual union all
select 'RW' ORG, 'bernard mccormack' username from dual union all
select 'RW' ORG, 'ray dunne' username from dual union all
select 'RW' ORG, 'liam galvin' username from dual union all
select 'RW' ORG, 'kar kin lim' username from dual union all
select 'RW' ORG, 'roisin bownes' username from dual union all
select 'RW' ORG, 'james healy' username from dual union all
select 'RW' ORG, 'joe moloney' username from dual union all
select 'RW' ORG, 'craig carey' username from dual union all
select 'RW' ORG, 'malachy garland' username from dual union all
select 'RW' ORG, 'mary dromey' username from dual union all
select 'RW' ORG, 'john smith' username from dual union all
select 'RW' ORG, 'charles ankettell' username from dual union all
select 'RW' ORG, 'barth cronin' username from dual union all
select 'RW' ORG, 'anthony hobbs' username from dual union all
select 'RW' ORG, 'oliver kerrisk' username from dual union all
select 'RW' ORG, 'patrick kissane' username from dual union all
select 'RW' ORG, 'john lynch' username from dual union all
select 'RW' ORG, 'oliver sweeney' username from dual union all
select 'RW' ORG, 'gerard wogan' username from dual union all
select 'ISAC' ORG, 'pierre-yves fiorasa' username from dual union all
select 'ISAC' ORG, 'blain curtis' username from dual union all
select 'ISAC' ORG, 'brian lilly' username from dual union all
select 'ISAC' ORG, 'rod oconnor' username from dual union all
select 'ISAC' ORG, 'daniel molloy' username from dual union all
select 'ISAC' ORG, 'ronan machugh' username from dual union all
select 'ISAC' ORG, 'adam ennis' username from dual union all
select 'ISAC' ORG, 'derek hughes' username from dual union all
select 'ISAC' ORG, 'nathan judge' username from dual union all
select 'ISAC' ORG, 'sinead callaghan' username from dual union all
select 'ISAC' ORG, 'robert warren' username from dual union all
select 'ISAC' ORG, 'dary philips' username from dual union all
select '' ORG, 'dave walker' username from dual union all
select 'dummy', 'dummy' from dual where 1=2
)
select   sub1.org
,        sub1.badoo_lst
,        sub1.user_id
,        case
            when nvl2(fu.user_id,'Y','N') = 'Y' then 
               case
                  when
                     (
                     fu.end_date is not null
                     or
                     fu.end_date < sysdate
                     )
                  then
                     'N'
                  else
                     'Y'
               end
            else
               null
         end active_flag
,        nvl2(fu.user_id,'Y','N') exist_on_oracle_flag
,        papf.last_name
,        papf.first_name
,        fu.email_address
,        fu.user_name
,        fu.description "User Description"
,        fu.end_date "User End Date"
,        fu.last_logon_date
from     (
         select   org
         ,        upper(username) badoo_lst
         ,        (
                  select   max(user_id)
                  from     apps.fnd_user fu
                  where    1=1
                  and      upper(fu.description) like upper('%'||replace(usr_lst.username,' ','%')||'%')
                  ) user_id
         from     usr_lst
         ) sub1
,        fnd_user fu
,        per_all_people_f papf
where    1=1
--and      sub1.badoo_lst like '%PHILL%'
and      fu.user_id (+) = sub1.user_id
and      papf.person_id (+) = fu.employee_id
order by sub1.org
,        sub1.badoo_lst;