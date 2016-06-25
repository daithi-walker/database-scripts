declare
    p_username VARCHAR2(30) := 'username';
    p_date      
begin
    fnd_user_pkg.enableuser(p_username
                           ,SYSDATE
                           ,NULL
                           );
  if fnd_user_pkg.changepassword('username','password') then
    dbms_output.put_line('password updated');
  else
    dbms_output.put_line('password not updated');
  end if;
  commit;
end;

begin
  fnd_user_pkg.updateuser(x_user_name            => 'username'
                         ,x_owner                =>'APPS'
                         ,x_unencrypted_password =>'password'
                         --,x_password_date        =>to_date('2','J')
                         );
  commit;
end;

-- http://funoracleapps.blogspot.co.uk/2013/09/how-to-enabledisable-large-number-of.html
-- enable multiple users
declare cursor cur1 is
select user_name from apps.fnd_user where LOWER(user_name) Not IN ('username','username', .......);
begin
for all_user in cur1 loop
apps.fnd_user_pkg.EnableUser(all_user.user_name);
commit;
end loop;
End

-- disable multiple users
DECLARE
   CURSOR cur1
   IS
      SELECT user_name
        FROM fnd_user
       WHERE person_party_id IS NOT NULL;
BEGIN
   FOR all_user IN cur1
   LOOP
      apps.fnd_user_pkg.DisableUser (all_user.user_name);
      COMMIT;
   END LOOP;
END;