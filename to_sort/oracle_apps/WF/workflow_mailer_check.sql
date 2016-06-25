select   component_status
from     fnd_svc_components
where    1=1
and      component_name = 'Workflow Notification Mailer';

--might not work if id has changed.
select   component_status
from     fnd_svc_components
where    1=1
and      component_id=10006;