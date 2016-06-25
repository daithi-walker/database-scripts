declare

  l_user_name     fnd_user.user_name%TYPE := 'WALKERD';
  l_user_id       fnd_user.user_id%TYPE;
  l_resp_name     fnd_responsibility_tl.responsibility_name%TYPE := 'Receivables User Corp GUI';
  --'Lipton Payables Fire Fighter - 5710'
  l_resp_id       fnd_responsibility_tl.responsibility_id%TYPE;
  l_resp_appl_id  fnd_responsibility_tl.application_id%TYPE;

begin

  select responsibility_id
  ,      application_id
  into   l_resp_id
  ,      l_resp_appl_id
  from   fnd_responsibility_tl
  where  responsibility_name = l_resp_name;
  
  select user_id
  into   l_user_id
  from   fnd_user
  where  user_name = l_user_name;
  
  fnd_global.APPS_INITIALIZE(user_id      => l_user_id
                            ,resp_id      => l_resp_id
                            ,resp_appl_id => l_resp_appl_id
                            );

end;