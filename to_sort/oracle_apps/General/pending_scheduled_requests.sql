select   fcr.request_id
,        fcpt.user_concurrent_program_name || nvl2(fcr.description,' ('||fcr.description||')',null) user_concurrent_program_name
,        fu.user_name             requestor
,        fcr.argument_text         arguments
,        to_char(fcr.requested_start_date,'DD-MON-YYYY HH24:MI:SS') next_run
,        to_char(fcr.last_update_date,'DD-MON-YYYY HH24:MI:SS') last_run
,        fcr.hold_flag             on_hold
,        fcr.increment_dates
,        decode(fcrc.class_type
               ,'P', 'Periodic'
               ,'S', 'On Specific Days'
               ,'X', 'Advanced'
               ,fcrc.class_type
               )  schedule_type
,        case
            when fcrc.class_type = 'P' then
               'Repeat every '
               ||
               substr(fcrc.class_info, 1, instr(fcrc.class_info, ':') - 1)
               ||
               decode(substr(fcrc.class_info, instr(fcrc.class_info, ':', 1, 1) + 1, 1)
                     ,'N', ' minutes'
                     ,'M', ' months'
                     ,'H', ' hours'
                     ,'D', ' days'
                     )
               ||
               decode(substr(fcrc.class_info, instr(fcrc.class_info, ':', 1, 2) + 1, 1)
                     ,'S', ' from the start of the prior run'
                     ,'C', ' from the completion of the prior run'
                     )
            when fcrc.class_type = 'S' then
               nvl2(dates.dates, 'Dates: ' || dates.dates || '. ', null)
               ||
               decode(substr(fcrc.class_info, 32, 1), '1', 'Last day of month ')
               ||
               decode(sign(to_number(substr(fcrc.class_info, 33)))
                     ,'1', 'Days of week: ' ||
                           decode(substr(fcrc.class_info, 33, 1), '1', 'Su ') ||
                           decode(substr(fcrc.class_info, 34, 1), '1', 'Mo ') ||
                           decode(substr(fcrc.class_info, 35, 1), '1', 'Tu ') ||
                           decode(substr(fcrc.class_info, 36, 1), '1', 'We ') ||
                           decode(substr(fcrc.class_info, 37, 1), '1', 'Th ') ||
                           decode(substr(fcrc.class_info, 38, 1), '1', 'Fr ') ||
                           decode(substr(fcrc.class_info, 39, 1), '1', 'Sa ')
                     )
         end as schedule
,        fcrc.date1 start_date
,        fcrc.date2 end_date
,        fcrc.class_info
from     apps.fnd_concurrent_requests fcr
,        apps.fnd_conc_release_classes fcrc
,        apps.fnd_concurrent_programs_tl fcpt
,        apps.fnd_user fu
,        (
         with date_schedules as
            (
            select   release_class_id
            ,        rank() over(partition by release_class_id order by s) a, s
            from     (
                     select   fcrc1.class_info
                     ,        l
                     ,        fcrc1.release_class_id
                     ,        decode(substr(fcrc1.class_info, l, 1), '1', to_char(l)) s
                     from     (
                              select   level l
                              from     dual
                              connect by level <= 31
                              )
                     ,        apps.fnd_conc_release_classes fcrc1
                     where    1=1
                     and      fcrc1.class_type = 'S'
                     and      instr(substr(fcrc1.class_info, 1, 31), '1') > 0
                     )
            where    1=1
            and      s is not null
            )
         select   release_class_id
         ,        substr(max(SYS_CONNECT_BY_PATH(s, ' ')), 2) dates
         from     date_schedules
         start with a = 1
         connect by nocycle prior a = a - 1
         group by release_class_id
         ) dates
where    1=1
and      fcr.phase_code = 'P'
and      fcrc.application_id = fcr.release_class_app_id
and      fcrc.release_class_id = fcr.release_class_id
and      nvl(fcrc.date2, sysdate + 1) > sysdate
and      fcrc.class_type is not null
and      fcpt.concurrent_program_id = fcr.concurrent_program_id
and      fcpt.application_id = fcr.program_application_id
--and      fcpt.language = 'US'
and      dates.release_class_id(+) = fcr.release_class_id
and      fcr.requested_by = fu.user_id
order by next_run
;