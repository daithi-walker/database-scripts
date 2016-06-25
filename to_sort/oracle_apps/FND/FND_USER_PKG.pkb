create or replace package body FND_USER_PKG as
/* $Header: AFSCUSRB.pls 120.48.12010000.13 2010/01/22 11:28:27 absandhw ship $ */

/* START PARTY */
C_PKG_NAME      CONSTANT VARCHAR2(30) := 'FND_USER_PKG';
C_LOG_HEAD      CONSTANT VARCHAR2(30) := 'fnd.plsql.FND_USER_PKG.';

/* One level cache for derive_person_party_id */
Z_EMPLOYEE_ID NUMBER := NULL;
Z_CUSTOMER_ID NUMBER := NULL;
Z_PERSON_PARTY_ID NUMBER := NULL;

/* One level cache for derive_customer_and_or_emp */
Z_REV_EMPLOYEE_ID NUMBER := NULL;
Z_REV_CUSTOMER_ID NUMBER := NULL;
Z_REV_PERSON_PARTY_ID NUMBER := NULL;
/* END PARTY */

/* bug 2504562 */
g_old_user_name varchar2(100) := NULL;

/* bug 4318754, 4352995 SSO related changes */
g_old_user_guid RAW(16) := NULL;
g_old_person_party_id NUMBER := NULL;

-- bug 8227171
g_event_controller varchar2(10);

----------------------------------------------------------------------------
--
-- boolRet (INTERNAL)
--   Translate Y/N to boolean
--
function boolRet(ret varchar2) return boolean is
begin
  if (ret = 'Y') then
    return TRUE;
  end if;
  return FALSE;
end;

---------------------------------------------------------------------------
-- ldap_wrapper_create_user (INTERNAL)
--
procedure ldap_wrapper_create_user(x_user_name in varchar2,
                                   x_unencrypted_password in varchar2,
                                   x_start_date in date,
                                   x_end_date in date,
                                   x_description in varchar2,
                                   x_email_address in varchar2,
                                   x_fax in varchar2,
                                   x_expire_pwd in pls_integer,
                                   x_user_guid in out nocopy raw,
                                   x_oid_pwd in out nocopy varchar2) is
l_result pls_integer;
reason varchar2(2000);
l_pwd varchar2(100);
pwdCaseOpt varchar2(1);
begin

  l_result := null;

  -- Bug 5161497
  l_pwd := x_unencrypted_password;
  pwdCaseOpt := null;
  -- Bug 5162136 Note: Creating user so use SITE level profile value.
  -- Bug 8664441 - pass in initial values for the security context to ensure the site value is used.
  pwdCaseOpt := fnd_profile.value_specific(name =>'SIGNON_PASSWORD_CASE',
                                           user_id => -1,
                                           responsibility_id => -1,
                                           application_id => -1,
                                           org_id => -1,
                                           server_id => -1);

  if (pwdCaseOpt is null) or (pwdCaseOpt = '1') then
    l_pwd := lower(x_unencrypted_password);
  end if;

  -- Bug: 5375111
  -- Calling ldap_wrapper_wrapper with the new expire_pwd flag.
  fnd_ldap_wrapper.create_user(x_user_name, l_pwd, x_start_date, x_end_date,
     x_description, x_email_address, x_fax, x_expire_pwd, x_user_guid,
     x_oid_pwd, l_result);

  if (l_result <> fnd_ldap_wrapper.G_SUCCESS) then
    reason := fnd_message.get;
    fnd_message.set_name('FND', 'LDAP_WRAPPER_CREATE_USER_FAIL');
    fnd_message.set_token('USER_NAME', x_user_name);
    fnd_message.set_token('REASON', reason);
    app_exception.raise_exception;
  end if;

exception
  when others then
    fnd_message.set_name('FND', 'LDAP_WRAPPER_CREATE_USER_FAIL');
    fnd_message.set_token('USER_NAME', x_user_name);
    fnd_message.set_token('REASON', sqlerrm);
    app_exception.raise_exception;
end;

----------------------------------------------------------------------^M
--
-- UpdateUserInternal (PRIVATE)
--   Internal api for UpdateUser and UpdateUserParty.
--   Not exposed publicly, use UpdateUser or UpdateUserParty wrappers.
--
procedure UpdateUserInternal (
  x_user_name                  in varchar2,
  x_owner                      in varchar2,
  x_unencrypted_password       in varchar2,
  x_session_number             in number,
  x_start_date                 in date,
  x_end_date                   in date,
  x_last_logon_date            in date,
  x_description                in varchar2,
  x_password_date              in date,
  x_password_accesses_left     in number,
  x_password_lifespan_accesses in number,
  x_password_lifespan_days     in number,
  x_employee_id                in number,
  x_email_address              in varchar2,
  x_fax                        in varchar2,
  x_customer_id                in number,
  x_supplier_id                in number,
  x_person_party_id            in number,
  x_old_password               in varchar2,
  x_mode                       in varchar2,
  x_last_update_date           in date default sysdate,
  x_user_guid                  in raw default null,
  x_change_source              in number default null)
is
  l_api_name varchar2(30) := 'UPDATEUSERINTERNAL';
  owner_id  number := 0;
  ret       varchar2(1);
  reason    varchar2(32000);
  l_session_number number;
  l_start_date date;
  l_end_date date;
  l_last_logon_date date;
  l_description varchar2(240);
  l_password_date date;
  l_password_accesses_left number;
  l_password_lifespan_accesses number;
  l_password_lifespan_days number;
  l_employee_id number;
  l_email_address varchar2(240);
  l_fax varchar2(80);
  l_customer_id number;
  l_supplier_id number;
  l_person_party_id number;
  -- Added for Function Security Cache Invalidation
  l_user_id number;
  l_user_guid raw(16);

  -- This cursor was added to fix Bug#3663908
  l_old_customer_id number;
  l_old_employee_id number;
  l_old_person_party_id number;
  l_old_user_guid RAW(16);

  l_parameter_list wf_parameter_list_t;  -- bug 8227171 WF event parameter list

  cursor usercur is
  select customer_id, employee_id, person_party_id, user_guid
  from fnd_user
  where user_name = upper(x_user_name);

  -- Bug 5235329
  l_expire_pwd pls_integer;

begin
  -- Bug 7687370
  if (x_owner is null) then
    owner_id := fnd_global.user_id;
  else
    owner_id := fnd_load_util.owner_id(x_owner);
  end if;

  -- This was added to fix Bug#3663908
  open usercur;
  fetch usercur into l_old_customer_id, l_old_employee_id,
                     l_old_person_party_id, l_old_user_guid;
  close usercur;

  -- bug 4318754 for SSO stuff
  g_old_person_party_id := l_old_person_party_id;
  g_old_user_guid := l_old_user_guid;
  -- end bug 4318754

  -- Bug4680643 get values for start_date and end_date from the database.
  -- Bug 7311525 get the user_id now so we can use it for identifying GUEST
  select start_date, end_date, user_id
     into l_start_date, l_end_date, l_user_id
     from fnd_user
  where user_name = upper(x_user_name);

  -- Bug4680643 Determine and set the value of start_date and end_date
  -- outside of the decode statement which was truncating the actual
  -- value when it is already set.

  if (x_start_date = fnd_user_pkg.null_date) then
    -- For this if condition error exception needs to be raised as
    -- start date cannot be null. This will be resolved through a new bug.
    l_start_date := null;
  elsif (x_start_date is not null) then
      -- bug 9054462 make sure we do not permit GUEST start_date to be
      -- post-dated which would cause the GUEST user account to expire.
      -- If start_date > sysdate, do not update the start_date for GUEST.
      if (l_user_id = 6) then
         if (x_start_date > sysdate) then
            -- throw the error message SECURITY-GUEST START DATE
            fnd_message.set_name('FND', 'SECURITY-GUEST START DATE');
            app_exception.raise_exception;
         else
            l_start_date := x_start_date;
         end if;
      else
         l_start_date := x_start_date;
      end if;
  end if;

  -- Bug 4901996. Truncate the time stamp
  l_start_date := trunc(l_start_date);

  if (x_end_date = fnd_user_pkg.null_date) then
      l_end_date := null;
  elsif (x_end_date is not null) then
    -- Bug 7311525 make sure we do not permit GUEST to be end-dated
    if (l_user_id <> 6) then
      l_end_date := x_end_date;
    else  -- unenddate GUEST
      l_end_date := null;
    end if;
  end if;
  -- Bug 4901996. Truncate the time stamp
  l_end_date := trunc(l_end_date);

  -- Translate *NULL* parameter values into real nulls,
  -- treat null values as no-change.
  begin
    select decode(x_session_number, fnd_user_pkg.null_number, null,
                  null, u.session_number,
                  x_session_number),
           -- bug 6608790 this preserves timestamp for iRecruitement
           decode(x_last_logon_date, fnd_user_pkg.null_date, to_date(null),
                  to_date(null), u.last_logon_date,
                  x_last_logon_date),
           decode(x_description, fnd_user_pkg.null_char, null,
                  null, u.description,
                  x_description),
           decode(x_password_date, fnd_user_pkg.null_date, null,
                  null, u.password_date,
                  x_password_date),
           decode(x_password_accesses_left, fnd_user_pkg.null_number, null,
                  null, u.password_accesses_left,
                  x_password_accesses_left),
           decode(x_password_lifespan_accesses, fnd_user_pkg.null_number, null,
                  null, u.password_lifespan_accesses,
                  x_password_lifespan_accesses),
           decode(x_password_lifespan_days, fnd_user_pkg.null_number, null,
                  null, u.password_lifespan_days,
                  x_password_lifespan_days),
           decode(x_employee_id, fnd_user_pkg.null_number, null,
                  null, u.employee_id,
                  x_employee_id),
           decode(x_email_address, fnd_user_pkg.null_char, null,
                  null, u.email_address,
                  x_email_address),
           decode(x_fax, fnd_user_pkg.null_char, null,
                  null, u.fax,
                  x_fax),
           decode(x_customer_id, fnd_user_pkg.null_number, null,
                  null, u.customer_id,
                  x_customer_id),
           decode(x_supplier_id, fnd_user_pkg.null_number, null,
                  null, u.supplier_id,
                  x_supplier_id),
           decode(x_person_party_id, fnd_user_pkg.null_number, null,
                  null, u.person_party_id,
                  x_person_party_id),
           decode(x_user_guid, fnd_user_pkg.null_raw, null,
                  null, u.user_guid,
                  x_user_guid )
    into l_session_number,
         l_last_logon_date, l_description, l_password_date,
         l_password_accesses_left, l_password_lifespan_accesses,
         l_password_lifespan_days, l_employee_id,
         l_email_address, l_fax, l_customer_id, l_supplier_id,
         l_person_party_id , l_user_guid
    from fnd_user u
    where u.user_name = upper(x_user_name);
  exception
    when others then
      fnd_message.set_name('FND', 'FND_INVALID_USER');
      fnd_message.set_token('USER_NAME', X_USER_NAME);
      app_exception.raise_exception;
  end;

  -- PARTY
  if (x_mode = 'PARTY') then
    -- Called from UpdateUserParty
    -- Derive customer/employee_ids from party_id
    -- This was added to fix Bug#3663908
    if (nvl(l_old_person_party_id, 0) <> nvl(l_person_party_id, 0)) then
      fnd_user_pkg.derive_customer_employee_id(x_user_name, l_person_party_id,
         l_customer_id, l_employee_id);
    end if;
  else
    -- Called from UpdateUser
    -- Derive the party_id from the customer/employee_ids.
    -- This was added to fix Bug#3663908
     if (nvl(l_old_customer_id, 0) <> nvl(l_customer_id, 0)) or (nvl(l_old_employee_id, 0) <> nvl(l_employee_id, 0)) then
        l_person_party_id := fnd_user_pkg.derive_person_party_id(
                                                        x_user_name, l_customer_id, l_employee_id);
     end if;
  end if;



SAVEPOINT update_user;

  if (x_unencrypted_password is not null) then

     -- If old_password is provided, change the password of an
     -- applications user after verifying the existing password.  This
     -- change is being added for bug 2658982 and 1722166.
     if (x_old_password is not null) then
        -- Add fifth argument to not use autonomous transaction when chaning
        -- passowrd. This is for bug 5087728
        ret := fnd_web_sec.change_password(x_user_name,
                                           x_old_password,
                                           x_unencrypted_password,
                                           x_unencrypted_password,
                                           FALSE);
     -- Otherwise, change the password of an applications user without
     -- verifying the existing password
     else
        -- Add third argument to not use autonomous transaction when chaning
        -- passowrd. This is for bug 5087728
        ret := fnd_web_sec.change_password(x_user_name,
                                           x_unencrypted_password, FALSE);
        -- Bug 5355566/5840007 reset unsuccessful logins start date since
        -- password is new and login with this password has not yet occurred.
        if (x_last_logon_date is null) then
          l_last_logon_date := sysdate;
        end if;

     end if;

    if (ret = 'N') then
      reason := fnd_message.get();
      fnd_message.set_name('FND', 'FND_CHANGE_PASSWORD_FAILED');
      fnd_message.set_token('USER_NAME', X_USER_NAME);
      fnd_message.set_token('REASON', reason);
      app_exception.raise_exception;
    end if;
  end if;

  -- Bug 8227171 UpdateUserInternal
  -- Raise WF event oracle.apps.fnd.pre.email.update
  begin
    wf_event.AddParameterToList('NEW_EMAIL', l_email_address, l_parameter_list);
    wf_event.raise3(p_event_name =>'oracle.apps.fnd.pre.email.update',
                  p_event_key => l_user_id,
                  p_event_data => NULL,
                  p_parameter_list => l_parameter_list,
                  p_send_date => Sysdate);
    exception
         when others then
          reason := fnd_message.get_encoded;
          if (reason is not null) then
            fnd_message.set_encoded(reason);
          else
            fnd_message.set_name('FND', 'FND_CREATE_A_SYNCH_MSG');
          end if;
          app_exception.raise_exception;
  end;

  if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
  fnd_log.string(FND_LOG.LEVEL_STATEMENT,
                     c_log_head || l_api_name || '.before_upduser',
                     'UpdateUser(): before updating user');
  end if;

  -- Update all of the non-password columns
  update fnd_user set
    last_update_date = x_last_update_date,
    last_updated_by = owner_id,
    last_update_login = owner_id,
    session_number =  l_session_number,
    start_date = l_start_date,
    end_date = l_end_date,
    last_logon_date = l_last_logon_date,
    description = l_description,
    password_date = l_password_date,
    password_accesses_left = l_password_accesses_left,
    password_lifespan_accesses = l_password_lifespan_accesses,
    password_lifespan_days = l_password_lifespan_days,
    employee_id = l_employee_id,
    email_address = l_email_address,
    fax = l_fax,
    customer_id = l_customer_id,
    supplier_id = l_supplier_id,
    person_party_id = l_person_party_id,
    user_guid = l_user_guid
  where user_name = upper(x_user_name);

  if (SQL%NOTFOUND) then
    fnd_message.set_name('FND', 'FND_INVALID_USER');
    fnd_message.set_token('USER_NAME', X_USER_NAME);
    app_exception.raise_exception;
  else
    -- bug 8227171 relocated the user_id fetch higher up.
    -- Added for Function Security Cache Invalidation
    fnd_function_security_cache.update_user(l_user_id);
  end if;


  if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
  fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                     'Start calling ldap_wrapper_update_user');
  fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                   'x_user_name = '||x_user_name);
  end if;

  -- Enhancement 5027812
  if (x_change_source is null or
      x_change_source <> fnd_user_pkg.change_source_oid ) then
    begin
      -- 5235329, 5375111 Let ldap/oid know whether to expire password
      -- But only if there is a new password.
      if (x_unencrypted_password is not null and
          x_unencrypted_password  <> FND_WEB_SEC.EXTERNAL_PWD) then
        begin
        select fnd_ldap_wrapper.G_TRUE
        into l_expire_pwd
        from fnd_user
        where user_name = upper(x_user_name)
        and (PASSWORD_DATE is NULL or
                (PASSWORD_LIFESPAN_ACCESSES is not NULL and
                     nvl(PASSWORD_ACCESSES_LEFT, 0) < 1) or
                (PASSWORD_LIFESPAN_DAYS is not NULL and
                 SYSDATE >= PASSWORD_DATE + PASSWORD_LIFESPAN_DAYS));
        exception
          when no_data_found then
            l_expire_pwd := fnd_ldap_wrapper.G_FALSE;
        end;
      end if;
      -- end 5235329, 5375111
      ldap_wrapper_update_user(upper(x_user_name), x_unencrypted_password,
                               x_start_date, x_end_date, x_description,
                               x_email_address, x_fax, l_expire_pwd);
    exception
    when others then
      ROLLBACK to update_user;
      reason := fnd_message.get();
      fnd_message.set_name('FND', 'FND_USER_UPDATE_FAILED');
      fnd_message.set_token('USERNAME', X_USER_NAME);
      fnd_message.set_token('USERID', l_user_id);
      fnd_message.set_token('REASON', reason);
      app_exception.raise_exception;
    end;
  end if;
  -- End bug 4318754, 4424225

  if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
  fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                     'After calling ldap_wrapper_update_user');
  end if;

  -- Enhancement 7311235 / Bug 8222658
  -- Just like the FND Define User form, add/modify default securing
  -- attributes to AK_WEB_USER_SEC_ATTR_VALUES as the final step
  -- in the process of creating or updating a user.
  -- Determine which attributes apply based on employee_id,
  -- customer_id, supplier_id.
  if (l_employee_id is not null) then
    begin
      -- ICX_HR_PERSON_ID
      update AK_WEB_USER_SEC_ATTR_VALUES set
        NUMBER_VALUE = l_employee_id,
        LAST_UPDATED_BY = owner_id,
        LAST_UPDATE_DATE = sysdate,
        LAST_UPDATE_LOGIN = owner_id
      where WEB_USER_ID = l_user_id
      and ATTRIBUTE_CODE = 'ICX_HR_PERSON_ID'
      and ATTRIBUTE_APPLICATION_ID = 178;

      if (sql%rowcount = 0) then
        insert into AK_WEB_USER_SEC_ATTR_VALUES (
          WEB_USER_ID,
          ATTRIBUTE_CODE,
          ATTRIBUTE_APPLICATION_ID,
          NUMBER_VALUE,
          CREATED_BY,
          CREATION_DATE,
          LAST_UPDATED_BY,
          LAST_UPDATE_DATE,
          LAST_UPDATE_LOGIN)
        values (
          l_user_id,
          'ICX_HR_PERSON_ID',
          178,
          l_employee_id,
          owner_id,
          sysdate,
          owner_id,
          sysdate,
          owner_id);
      end if;

      -- TO_PERSON_ID
      update AK_WEB_USER_SEC_ATTR_VALUES set
        NUMBER_VALUE = l_employee_id,
        LAST_UPDATED_BY = owner_id,
        LAST_UPDATE_DATE = sysdate,
        LAST_UPDATE_LOGIN = owner_id
      where WEB_USER_ID = l_user_id
      and ATTRIBUTE_CODE = 'TO_PERSON_ID'
      and ATTRIBUTE_APPLICATION_ID = 178;

      if (sql%rowcount = 0) then
        insert into AK_WEB_USER_SEC_ATTR_VALUES (
          WEB_USER_ID,
          ATTRIBUTE_CODE,
          ATTRIBUTE_APPLICATION_ID,
          NUMBER_VALUE,
          CREATED_BY,
          CREATION_DATE,
          LAST_UPDATED_BY,
          LAST_UPDATE_DATE,
          LAST_UPDATE_LOGIN)
        values (
          l_user_id,
          'TO_PERSON_ID',
          178,
          l_employee_id,
          owner_id,
          sysdate,
          owner_id,
          sysdate,
          owner_id);
      end if;

      exception
          when others then
           fnd_message.set_name( 'FND','SQL_PLSQL_ERROR' );
           fnd_message.set_token('ROUTINE', l_api_name);
	   fnd_message.set_token('ERRNO', SQLCODE);
 	   fnd_message.set_token('REASON', SQLERRM);
    end;
  end if;

  if (l_customer_id is not null) then
    begin
      update AK_WEB_USER_SEC_ATTR_VALUES set
        NUMBER_VALUE = l_customer_id,
        LAST_UPDATED_BY = owner_id,
        LAST_UPDATE_DATE = sysdate,
        LAST_UPDATE_LOGIN = owner_id
      where WEB_USER_ID = l_user_id
      and ATTRIBUTE_CODE = 'ICX_CUSTOMER_CONTACT_ID'
      and ATTRIBUTE_APPLICATION_ID = 178;

      if (sql%rowcount = 0) then
        insert into AK_WEB_USER_SEC_ATTR_VALUES (
          WEB_USER_ID,
          ATTRIBUTE_CODE,
          ATTRIBUTE_APPLICATION_ID,
          NUMBER_VALUE,
          CREATED_BY,
          CREATION_DATE,
          LAST_UPDATED_BY,
          LAST_UPDATE_DATE,
          LAST_UPDATE_LOGIN)
        values (
          l_user_id,
          'ICX_CUSTOMER_CONTACT_ID',
          178,
          l_customer_id,
          owner_id,
          sysdate,
          owner_id,
          sysdate,
          owner_id);
      end if;

      exception
          when others then
           fnd_message.set_name( 'FND','SQL_PLSQL_ERROR' );
           fnd_message.set_token('ROUTINE', l_api_name);
	   fnd_message.set_token('ERRNO', SQLCODE);
 	   fnd_message.set_token('REASON', SQLERRM);
    end;
  end if;

  if (l_supplier_id is not null) then
    begin
      update AK_WEB_USER_SEC_ATTR_VALUES set
        NUMBER_VALUE = l_supplier_id,
        LAST_UPDATED_BY = owner_id,
        LAST_UPDATE_DATE = sysdate,
        LAST_UPDATE_LOGIN = owner_id
      where WEB_USER_ID = l_user_id
      and ATTRIBUTE_CODE = 'ICX_SUPPLIER_CONTACT_ID'
      and ATTRIBUTE_APPLICATION_ID = 178;

      if (sql%rowcount = 0) then
        insert into AK_WEB_USER_SEC_ATTR_VALUES (
          WEB_USER_ID,
          ATTRIBUTE_CODE,
          ATTRIBUTE_APPLICATION_ID,
          NUMBER_VALUE,
          CREATED_BY,
          CREATION_DATE,
          LAST_UPDATED_BY,
          LAST_UPDATE_DATE,
          LAST_UPDATE_LOGIN)
        values (
          l_user_id,
          'ICX_SUPPLIER_CONTACT_ID',
          178,
          l_supplier_id,
          owner_id,
          sysdate,
          owner_id,
          sysdate,
          owner_id);
      end if;

      exception
          when others then
           fnd_message.set_name( 'FND','SQL_PLSQL_ERROR' );
           fnd_message.set_token('ROUTINE', l_api_name);
	   fnd_message.set_token('ERRNO', SQLCODE);
 	   fnd_message.set_token('REASON', SQLERRM);
    end;
  end if;

  -- Sync user change to LDAP
  fnd_user_pkg.user_synch(x_user_name);

  -- Bug 8227171 UpdateUserInternal
  -- Raise WF event oracle.apps.fnd.post.user.update
  if (nvl(g_event_controller, 'XXXX') <> 'CREATE') then
  begin
    -- Bug 8683723
    -- Passing some of the desired columns that may be updated to the Workflow
    -- event in case of special handling requirements.
    wf_event.AddParameterToList('NEW_EMAIL_ADDRESS', x_email_address, l_parameter_list);
    wf_event.AddParameterToList('NEW_DESCRIPTION', x_description, l_parameter_list);
    wf_event.AddParameterToList('NEW_CUSTOMER_ID', x_customer_id, l_parameter_list);
    wf_event.AddParameterToList('NEW_FAX', x_fax, l_parameter_list);
    wf_event.AddParameterToList('NEW_USER_GUID', x_user_guid, l_parameter_list);
    wf_event.AddParameterToList('NEW_END_DATE', x_end_date, l_parameter_list);
    wf_event.AddParameterToList('NEW_PERSON_PARTY_ID', x_person_party_id, l_parameter_list);
    wf_event.AddParameterToList('NEW_SUPPLIER_ID', x_supplier_id, l_parameter_list);
    wf_event.AddParameterToList('NEW_EMPLOYEE_ID', x_employee_id, l_parameter_list);
    wf_event.raise(p_event_name =>'oracle.apps.fnd.post.user.update',
                  p_event_key => l_user_id,
                  p_event_data => NULL,
                  p_parameters => l_parameter_list,
                  p_send_date => Sysdate);
    exception
      when others then
        reason := fnd_message.get_encoded;
        if (reason is not null) then
          fnd_message.set_encoded(reason);
        else
          fnd_message.set_name('FND', 'FND_RAISE_EVENT_FAILED');
        end if;
        app_exception.raise_exception;

  end;
  end if;

end UpdateUserInternal;

----------------------------------------------------------------------
--
-- LOAD_ROW (PRIVATE)
-- Overloaded version for backward compatibility only.
-- Use version below.
--
procedure LOAD_ROW (
  X_USER_NAME                           in      VARCHAR2,
  X_OWNER                               in      VARCHAR2,
  X_ENCRYPTED_USER_PASSWORD             in      VARCHAR2,
  X_SESSION_NUMBER                      in      VARCHAR2,
  X_START_DATE                          in      VARCHAR2,
  X_END_DATE                            in      VARCHAR2,
  X_LAST_LOGON_DATE                     in      VARCHAR2,
  X_DESCRIPTION                         in      VARCHAR2,
  X_PASSWORD_DATE                       in      VARCHAR2,
  X_PASSWORD_ACCESSES_LEFT              in      VARCHAR2,
  X_PASSWORD_LIFESPAN_ACCESSES          in      VARCHAR2,
  X_PASSWORD_LIFESPAN_DAYS              in      VARCHAR2,
  X_EMAIL_ADDRESS                       in      VARCHAR2,
  X_FAX                                 in      VARCHAR2 ) is

begin
      fnd_user_pkg.LOAD_ROW (
        X_USER_NAME=>X_USER_NAME,
        X_OWNER=> X_OWNER,
        X_ENCRYPTED_USER_PASSWORD=>X_ENCRYPTED_USER_PASSWORD,
        X_SESSION_NUMBER=> X_SESSION_NUMBER,
        X_START_DATE=> X_START_DATE,
        X_END_DATE=> X_END_DATE,
        X_LAST_LOGON_DATE=> X_LAST_LOGON_DATE,
        X_DESCRIPTION=> X_DESCRIPTION,
        X_PASSWORD_DATE=> X_PASSWORD_DATE,
        X_PASSWORD_ACCESSES_LEFT=> X_PASSWORD_ACCESSES_LEFT,
        X_PASSWORD_LIFESPAN_ACCESSES=> X_PASSWORD_LIFESPAN_ACCESSES,
        X_PASSWORD_LIFESPAN_DAYS=> X_PASSWORD_LIFESPAN_DAYS,
        X_EMAIL_ADDRESS=> X_EMAIL_ADDRESS,
        X_FAX=> X_FAX,
        X_CUSTOM_MODE=> '',
        X_LAST_UPDATE_DATE=> '');

end LOAD_ROW;

----------------------------------------------------------------------
--
-- LOAD_ROW (PRIVATE)
--   Insert/update a new row of data.
--   Only for use by FNDLOAD, other apis should use LoadUser below.
--
procedure LOAD_ROW (
  X_USER_NAME                           in      VARCHAR2,
  X_OWNER                               in      VARCHAR2,
  X_ENCRYPTED_USER_PASSWORD             in      VARCHAR2,
  X_SESSION_NUMBER                      in      VARCHAR2,
  X_START_DATE                          in      VARCHAR2,
  X_END_DATE                            in      VARCHAR2,
  X_LAST_LOGON_DATE                     in      VARCHAR2,
  X_DESCRIPTION                         in      VARCHAR2,
  X_PASSWORD_DATE                       in      VARCHAR2,
  X_PASSWORD_ACCESSES_LEFT              in      VARCHAR2,
  X_PASSWORD_LIFESPAN_ACCESSES          in      VARCHAR2,
  X_PASSWORD_LIFESPAN_DAYS              in      VARCHAR2,
  X_EMAIL_ADDRESS                       in      VARCHAR2,
  X_FAX                                 in      VARCHAR2,
  X_CUSTOM_MODE                         in      VARCHAR2,
  X_LAST_UPDATE_DATE                    in      VARCHAR2,
  X_PERSON_PARTY_NAME                   in      VARCHAR2 default NULL) is

  owner_id number := 0;
  ret boolean;
  f_luby    number;  -- entity owner in file
  f_ludate  date;    -- entity update date in file
  db_luby   number;  -- entity owner in db
  db_ludate date;    -- entity update date in db
  l_end_date date;
  l_last_logon_date date;
  l_password_date date;
  l_password_accesses_left number;
  l_password_lifespan_accesses number;
  l_password_lifespan_days number;
  l_person_party_id number;
  l_party_type      varchar2(30);

-- simple local proc to save redunant code - added for bug 3254311
PROCEDURE DoPassword_update( puser_name in varchar2, pcrypt_pass in varchar2 ) is
  encPwd varchar2(100);
BEGIN
    -- The insert/update didn't include the password, because
    -- those apis can't decrypt it.
    -- Set it directly now.

    -- NULL password means no update     -- bug 7687370
    if (pcrypt_pass is null) then
        return;
    end if;

    -- bug 4047740 - as a byproduct of FND_WEB_SEC.set_reencrypted_password
    -- NOT calling change_password we need this check to complete the checks
    -- below as in FND_WEB_SEC - also added update to both encrypted rows for
    -- the fnd_user update below for completeness.
    if(false = fnd_sso_manager.isPasswordChangeable(puser_name)) then
        encPwd := 'EXTERNAL';
    else
        encPwd := pcrypt_pass;
    end if;

    if (encPwd in ('EXTERNAL', 'INVALID')) then
        -- The password was 'EXTERNAL' or 'INVALID', just set it directly
        -- without trying to re-encrypt
        update fnd_user
        set encrypted_foundation_password = encPwd,
            encrypted_user_password = encPwd
        where user_name = puser_name;

        -- print warning in log file if it was 'INVALID'
        if (encPwd = 'INVALID') then
            fnd_file.put_line(fnd_file.Log,'Invalid password for user ' ||puser_name );
        end if;
    else
        ret := fnd_user_pkg.SetReEncryptedPassword(puser_name, encPwd, 'LOADER');
    end if;
END;

begin
  -- Translate owner to file_last_updated_by
  f_luby := fnd_load_util.owner_id(x_owner);

  -- Translate char last_update_date to date
  f_ludate := nvl(to_date(x_last_update_date, 'YYYY/MM/DD'), sysdate);

   /*Bug2896887 - Modified code to analyze and set up the correct value
                  for the nullable parameters to be passed to the
                  UpdateUser and CreateUser procedures. */

   if (X_END_DATE = fnd_user_pkg.null_char) then
        l_end_date := fnd_user_pkg.null_date;
   else -- bug 7311525 prevent upload of non-null end date for GUEST
       if (UPPER(x_user_name) <> 'GUEST') then
          l_end_date := to_date(X_END_DATE, 'YYYY/MM/DD');
       else
          l_end_date := null;
       end if;
   end if;

   if (X_PASSWORD_DATE = fnd_user_pkg.null_char) then
        l_password_date := fnd_user_pkg.null_date;
   else
        l_password_date := to_date(X_PASSWORD_DATE, 'YYYY/MM/DD');
   end if;

   if (X_LAST_LOGON_DATE = fnd_user_pkg.null_char) then
        l_last_logon_date := fnd_user_pkg.null_date;
   else
        l_last_logon_date := to_date(X_LAST_LOGON_DATE, 'YYYY/MM/DD');
   end if;

   if (X_PASSWORD_ACCESSES_LEFT = fnd_user_pkg.null_char) then
        l_password_accesses_left := fnd_user_pkg.null_number;
   else
        l_password_accesses_left := to_number(X_PASSWORD_ACCESSES_LEFT);
   end if;

   if (X_PASSWORD_LIFESPAN_ACCESSES = fnd_user_pkg.null_char) then
        l_password_lifespan_accesses := fnd_user_pkg.null_number;
   else
        l_password_lifespan_accesses := to_number(X_PASSWORD_LIFESPAN_ACCESSES);
   end if;

   if (X_PASSWORD_LIFESPAN_DAYS = fnd_user_pkg.null_char) then
        l_password_lifespan_days := fnd_user_pkg.null_number;
   else
        l_password_lifespan_days := to_number(X_PASSWORD_LIFESPAN_DAYS);
   end if;

  begin
    select LAST_UPDATED_BY, LAST_UPDATE_DATE
    into db_luby, db_ludate
    from FND_USER
    where USER_NAME = X_USER_NAME;

    /* PARTY */
    l_person_party_id := null;
    begin
      FND_OAM_USER_INFO.HZ_PARTY_NAME_TO_ID(x_person_party_name,
                                            l_person_party_id,
                                            l_party_type);
    exception
      when no_data_found then
        l_person_party_id := null;
    end;

    if (fnd_load_util.upload_test(f_luby, f_ludate, db_luby,
                                  db_ludate, X_CUSTOM_MODE)) then
        UpdateUserInternal(
            x_user_name => x_user_name,
            x_owner => x_owner,    -- bug 7687370
            x_unencrypted_password => '',
            x_session_number => to_number(x_session_number),
            x_start_date => to_date(X_START_DATE, 'YYYY/MM/DD'),
            x_end_date => L_END_DATE,
            x_last_logon_date => L_LAST_LOGON_DATE,
            x_description => X_DESCRIPTION,
            x_password_date => L_PASSWORD_DATE,
            x_password_accesses_left => L_PASSWORD_ACCESSES_LEFT,
            x_password_lifespan_accesses => L_PASSWORD_LIFESPAN_ACCESSES,
            x_password_lifespan_days => L_PASSWORD_LIFESPAN_DAYS,
            x_employee_id => null,
            x_email_address => x_email_address,
            x_fax => x_fax,
            x_customer_id => null,
            x_supplier_id => null,
            x_person_party_id => l_person_party_id,
            x_old_password => null,
            x_mode => 'EMPLOYEE',
            x_last_update_date => f_ludate);

        --  added for bug 3254311 by mskees
        DoPassword_update(X_USER_NAME, X_ENCRYPTED_USER_PASSWORD);
    end if;
  exception
    when no_data_found then
        -- bug 4047740 changed dummy password from 'welcome' to new FND_WEB_SEC
        -- constant, requires AFSCJAVS.pls 115.27 and AFSCJAVB.pls 115.63
        fnd_user_pkg.createuser(
            X_USER_NAME,
            X_OWNER,   -- bug 7687370
            FND_WEB_SEC.INVALID_PWD,
            to_number(X_SESSION_NUMBER),
            to_date(X_START_DATE, 'YYYY/MM/DD'),
            L_END_DATE,
            L_LAST_LOGON_DATE,
            X_DESCRIPTION,
            L_PASSWORD_DATE,
            L_PASSWORD_ACCESSES_LEFT,
            L_PASSWORD_LIFESPAN_ACCESSES,
            L_PASSWORD_LIFESPAN_DAYS,
            null,
            X_EMAIL_ADDRESS,
            X_FAX,
            null,
            null);
        --  added for bug 3254311 by mskees
        DoPassword_update(X_USER_NAME, X_ENCRYPTED_USER_PASSWORD);
  end;


end LOAD_ROW;

----------------------------------------------------------------------
--
-- CreateUserIdInternal (PRIVATE)
--   Internal wrapper for CreateUserId and CreateUserIdParty
--
function CreateUserIdInternal (
  x_user_name                  in varchar2,
  x_owner                      in varchar2,
  x_unencrypted_password       in varchar2,
  x_session_number             in number,
  x_start_date                 in date,
  x_end_date                   in date,
  x_last_logon_date            in date,
  x_description                in varchar2,
  x_password_date              in date,
  x_password_accesses_left     in number,
  x_password_lifespan_accesses in number,
  x_password_lifespan_days     in number,
  x_employee_id                in number,
  x_email_address              in varchar2,
  x_fax                        in varchar2,
  x_customer_id                in number,
  x_supplier_id                in number,
  x_person_party_id            in number,
  x_mode                       in varchar2,
  x_user_guid                  in raw default null,
  x_change_source              in number default null)
return number is
  l_api_name varchar2(30):= 'CREATEUSERIDINTERNAL';
  owner_id number := 0;
  user_id number;
  ret varchar2(1) := 'N';
  reason varchar2(32000);

  pwd varchar2(100); /* 4351689 */
  l_user_guid raw(16);
  l_oid_pwd varchar2(30);

  l_expire_pwd pls_integer;

begin
  -- Bug 7687370
  if (x_owner is null) then
    owner_id := fnd_global.user_id;
  else
    owner_id := fnd_load_util.owner_id(x_owner);
  end if;

  begin
    -- Before creating the user, we should validate the user_name
    -- to make sure that there is no special characters.
    validate_user_name(x_user_name);

    /* bug 4351689 - allow the create functions to pass in null for
                     External password control*/
    pwd := nvl( x_unencrypted_password, FND_WEB_SEC.EXTERNAL_PWD );

    SAVEPOINT create_user;

    ret := fnd_web_sec.create_user(x_user_name,pwd,user_id);

    if (ret = 'Y') then
      -- Enhancement 5027812
      if ((x_change_source is null or
           x_change_source <> fnd_user_pkg.CHANGE_SOURCE_OID) and
          pwd <> fnd_web_sec.external_pwd) then
      -- We need to translate the external constant to null. Otherwise
      -- fnd_ldap_wrapper.create_user will use that constant as real password.
      if (pwd = fnd_web_sec.external_pwd) then
        pwd := '';
      end if;

        -- Bug#4118749 - Create user in OID
        if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
        fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                     'Start calling ldap_wrapper_create_user');
        fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                   'x_user_name = '||x_user_name);
        end if;

        begin
          -- 5235329, 5375111 Let ldap/oid know whether to expire password
          if (x_password_date is null  or
             (x_password_lifespan_accesses is not null and
               nvl(x_password_accesses_left, 0) < 1) or
              (x_password_lifespan_days is not null and
               sysdate >= x_password_date + x_password_lifespan_days)) then
            l_expire_pwd := fnd_ldap_wrapper.G_TRUE;
          else
            l_expire_pwd := fnd_ldap_wrapper.G_FALSE;
          end if;
          -- end 5235329, 5375111

          -- Begin Bug 4318754, 4424225
          ldap_wrapper_create_user(upper(x_user_name), pwd, x_start_date,
                              x_end_date, x_description, x_email_address,
                              x_fax, l_expire_pwd, l_user_guid, l_oid_pwd);
          -- If wrapper gives back EXTERNAL password, we need to update
          -- the user with external password. l_oid_pwd will be used later
          -- in the UpdateUser call. setting to null means no change.
          if (l_oid_pwd <> fnd_web_sec.external_pwd) then
            l_oid_pwd := '';
          end if;
          -- End Bug 4318754, 4424225
        exception
          when others then
            ROLLBACK to create_user;
            reason := fnd_message.get();
            fnd_message.set_name('FND', 'FND_CREATE_USER_FAILED');
            fnd_message.set_token('USER_NAME', X_USER_NAME);
            fnd_message.set_token('REASON', reason);
            app_exception.raise_exception;
        end;

        if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
        fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                     'After calling ldap_wrapper_create_user');
        end if;
      else
        l_user_guid := x_user_guid;
      end if;

      -- the createuser java code uses the user_id as created_by which
      -- is not correct. We must correct here.
      update fnd_user
      set created_by = owner_id
      where user_name = upper(x_user_name);

      -- update the rest of the data except password
      if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
      fnd_log.string(FND_LOG.LEVEL_STATEMENT,
     c_log_head || l_api_name || '.call_upduser',
        'CreateUser(): calling fnd_user_pkg.UpdateUser');
      end if;

      -- bug 8227171 Use the event controller global to tell the
      -- update user event not to fire since the create event will
      -- fire.
      g_event_controller := 'CREATE';

      -- NOTE:  This bit is using UpdateUser (rather than direct sql update)
      --        so that the user synch code in UpdateUser is triggered.
      --        Don't change this without taking that into account.
      --
      if (x_mode = 'PARTY') then
--      fnd_user_pkg.UpdateUserParty(
-- Begin bug 4318754, 4424225
-- In order to handle user_guid, calls UpdateUserInternal directly
-- instead of UpdateUserParty which does not take user_guid as argument.
        fnd_user_pkg.UpdateUserInternal(
-- End bug 4318754, 4424225
          x_user_name => x_user_name,
          x_owner => x_owner,
          x_unencrypted_password => l_oid_pwd,
          x_session_number => x_session_number,
          x_start_date => x_start_date,
          x_end_date => x_end_date,
          x_last_logon_date => x_last_logon_date,
          x_description => x_description,
          x_password_date => x_password_date,
          x_password_accesses_left => x_password_accesses_left,
          x_password_lifespan_accesses => x_password_lifespan_accesses,
          x_password_lifespan_days => x_password_lifespan_days,
          x_employee_id => x_employee_id, -- 7311235 no need to pass null
          x_email_address => x_email_address,
          x_fax => x_fax,
          x_customer_id => x_customer_id, -- 7311235 no need to pass null
          x_supplier_id => x_supplier_id, -- 7311235 no need to pass null
          x_person_party_id => x_person_party_id,
          x_old_password => null,
          x_mode => 'PARTY',
          x_user_guid => l_user_guid,
          x_change_source => fnd_user_pkg.change_source_oid);
      else
        fnd_user_pkg.UpdateUser(
          x_user_name => x_user_name,
          x_owner => x_owner,
          x_unencrypted_password => l_oid_pwd,
          x_session_number => x_session_number,
          x_start_date => x_start_date,
          x_end_date => x_end_date,
          x_last_logon_date => x_last_logon_date,
          x_description => x_description,
          x_password_date => x_password_date,
          x_password_accesses_left => x_password_accesses_left,
          x_password_lifespan_accesses => x_password_lifespan_accesses,
          x_password_lifespan_days => x_password_lifespan_days,
          x_employee_id => x_employee_id,
          x_email_address => x_email_address,
          x_fax => x_fax,
          x_customer_id => x_customer_id,
          x_supplier_id => x_supplier_id,
          x_old_password => null,
          x_user_guid => l_user_guid,
          x_change_source => fnd_user_pkg.change_source_oid);
      end if;

      -- bug 8227171 CreateUserIdInternal
      -- Raise the WF event oracle.apps.fnd.post.user.create
      begin
         g_event_controller := NULL; -- we try once then reset
         wf_event.raise(p_event_name => 'oracle.apps.fnd.post.user.create',
                        p_event_key => to_char(user_id),
                        p_event_data => NULL,
                        p_send_date => Sysdate);

      exception
         when others then
          reason := fnd_message.get_encoded;
          if (reason is not null) then
            fnd_message.set_encoded(reason);
          else
            fnd_message.set_name('FND', 'FND_RAISE_EVENT_FAILED');
          end if;
          app_exception.raise_exception;
      end;

    else -- fnd_web_sec.create_user must have failed.
      -- The java layer puts message onto the message stack.
      reason := fnd_message.get();
      fnd_message.set_name('FND', 'FND_CREATE_USER_FAILED');
      fnd_message.set_token('USER_NAME', X_USER_NAME);
      fnd_message.set_token('REASON', reason);
      app_exception.raise_exception;
    end if;

    return (user_id);
   end;
end CreateUserIdInternal;

----------------------------------------------------------------------
--
-- CreateUserId (PUBLIC)
--   Insert new user record into FND_USER table.
--   If that user exists already, exception raised with the error message.
--   There are three input arguments must be provided. All the other columns
--   in FND_USER table can take the default value.
--
--   *** NOTE: This version accepts the old customer_id/employee_id
--   keys foreign keys to the "person".  Use CreateUserIdParty to create
--   a user with the new person_party_id key.
--
-- Input (Mandatory)
--  x_user_name:            The name of the new user
--  x_owner:                'SEED' or 'CUST'(customer)
--  x_unencrypted_password: The password for this new user
-- Returns
--   User_id of created user
--
function CreateUserId (
  x_user_name                  in varchar2,
  x_owner                      in varchar2,
  x_unencrypted_password       in varchar2 default null,
  x_session_number             in number default 0,
  x_start_date                 in date default sysdate,
  x_end_date                   in date default null,
  x_last_logon_date            in date default null,
  x_description                in varchar2 default null,
  x_password_date              in date default null,
  x_password_accesses_left     in number default null,
  x_password_lifespan_accesses in number default null,
  x_password_lifespan_days     in number default null,
  x_employee_id                in number default null,
  x_email_address              in varchar2 default null,
  x_fax                        in varchar2 default null,
  x_customer_id                in number default null,
  x_supplier_id                in number default null)
return number is
begin
  return CreateUserIdInternal(
    x_user_name => x_user_name,
    x_owner => x_owner,
    x_unencrypted_password => x_unencrypted_password,
    x_session_number => x_session_number,
    x_start_date => x_start_date,
    x_end_date => x_end_date,
    x_last_logon_date => x_last_logon_date,
    x_description => x_description,
    x_password_date => x_password_date,
    x_password_accesses_left => x_password_accesses_left,
    x_password_lifespan_accesses => x_password_lifespan_accesses,
    x_password_lifespan_days => x_password_lifespan_days,
    x_employee_id => x_employee_id,
    x_email_address => x_email_address,
    x_fax => x_fax,
    x_customer_id => x_customer_id,
    x_supplier_id => x_supplier_id,
    x_person_party_id => null,
    x_mode => 'EMPLOYEE');
end CreateUserId;

----------------------------------------------------------------------
--
-- CreateUserIdParty (PUBLIC)
--   Insert new user record into FND_USER table.
--   If that user exists already, exception raised with the error message.
--   There are three input arguments must be provided. All the other columns
--   in FND_USER table can take the default value.
--
--   *** NOTE: This version accepts the new person_party_id foreign key
--   to the "person".  Use CreateUserId to create a user with the old
--   customer_id/employee_id keys.
--
-- Input (Mandatory)
--  x_user_name:            The name of the new user
--  x_owner:                'SEED' or 'CUST'(customer)
--  x_unencrypted_password: The password for this new user
-- Returns
--   User_id of created user
--
function CreateUserIdParty (
  x_user_name                  in varchar2,
  x_owner                      in varchar2,
  x_unencrypted_password       in varchar2 default null,
  x_session_number             in number default 0,
  x_start_date                 in date default sysdate,
  x_end_date                   in date default null,
  x_last_logon_date            in date default null,
  x_description                in varchar2 default null,
  x_password_date              in date default null,
  x_password_accesses_left     in number default null,
  x_password_lifespan_accesses in number default null,
  x_password_lifespan_days     in number default null,
  x_email_address              in varchar2 default null,
  x_fax                        in varchar2 default null,
  x_person_party_id            in number default null)
return number is
begin
  return CreateUserIdInternal(
    x_user_name => x_user_name,
    x_owner => x_owner,
    x_unencrypted_password => x_unencrypted_password,
    x_session_number => x_session_number,
    x_start_date => x_start_date,
    x_end_date => x_end_date,
    x_last_logon_date => x_last_logon_date,
    x_description => x_description,
    x_password_date => x_password_date,
    x_password_accesses_left => x_password_accesses_left,
    x_password_lifespan_accesses => x_password_lifespan_accesses,
    x_password_lifespan_days => x_password_lifespan_days,
    x_employee_id => null,
    x_email_address => x_email_address,
    x_fax => x_fax,
    x_customer_id => null,
    x_supplier_id => null,
    x_person_party_id => x_person_party_id,
    x_mode => 'PARTY');
end CreateUserIdParty;

----------------------------------------------------------------------
--
-- CreateUser (PUBLIC)
--   Insert new user record into FND_USER table.
--   If that user exists already, exception raised with the error message.
--   There are three input arguments must be provided. All the other columns
--   in FND_USER table can take the default value.
--
--   *** NOTE: This version accepts the old customer_id/employee_id
--   keys foreign keys to the "person".  Use CreateUserParty to create
--   a user with the new person_party_id key.
--
-- Input (Mandatory)
--  x_user_name:            The name of the new user
--  x_owner:                'SEED' or 'CUST'(customer)
--  x_unencrypted_password: The password for this new user
--
procedure CreateUser (
  x_user_name                  in varchar2,
  x_owner                      in varchar2,
  x_unencrypted_password       in varchar2 default null,
  x_session_number             in number default 0,
  x_start_date                 in date default sysdate,
  x_end_date                   in date default null,
  x_last_logon_date            in date default null,
  x_description                in varchar2 default null,
  x_password_date              in date default null,
  x_password_accesses_left     in number default null,
  x_password_lifespan_accesses in number default null,
  x_password_lifespan_days     in number default null,
  x_employee_id                in number default null,
  x_email_address              in varchar2 default null,
  x_fax                        in varchar2 default null,
  x_customer_id                in number default null,
  x_supplier_id                in number default null)
is
  dummy number;
begin
  dummy := fnd_user_pkg.CreateUserId(
    x_user_name,
    x_owner,
    x_unencrypted_password,
    x_session_number,
    x_start_date,
    x_end_date,
    x_last_logon_date,
    x_description,
    x_password_date,
    x_password_accesses_left,
    x_password_lifespan_accesses,
    x_password_lifespan_days,
    x_employee_id,
    x_email_address,
    x_fax,
    x_customer_id,
    x_supplier_id);
end CreateUser;

----------------------------------------------------------------------
--
-- CreateUserParty (PUBLIC)
--   Insert new user record into FND_USER table.
--   If that user exists already, exception raised with the error message.
--   There are three input arguments must be provided. All the other columns
--   in FND_USER table can take the default value.
--
--   *** NOTE: This version accepts the new person_party_id foreign key
--   to the "person".  Use CreateUser to create a user with the old
--   customer_id/employee_id keys.
--
-- Input (Mandatory)
--  x_user_name:            The name of the new user
--  x_owner:                'SEED' or 'CUST'(customer)
--  x_unencrypted_password: The password for this new user
--
procedure CreateUserParty (
  x_user_name                  in varchar2,
  x_owner                      in varchar2,
  x_unencrypted_password       in varchar2 default null,
  x_session_number             in number default 0,
  x_start_date                 in date default sysdate,
  x_end_date                   in date default null,
  x_last_logon_date            in date default null,
  x_description                in varchar2 default null,
  x_password_date              in date default null,
  x_password_accesses_left     in number default null,
  x_password_lifespan_accesses in number default null,
  x_password_lifespan_days     in number default null,
  x_email_address              in varchar2 default null,
  x_fax                        in varchar2 default null,
  x_person_party_id            in number default null)
is
  dummy number;
begin
  dummy := fnd_user_pkg.CreateUserIdParty(
    x_user_name,
    x_owner,
    x_unencrypted_password,
    x_session_number,
    x_start_date,
    x_end_date,
    x_last_logon_date,
    x_description,
    x_password_date,
    x_password_accesses_left,
    x_password_lifespan_accesses,
    x_password_lifespan_days,
    x_email_address,
    x_fax,
    x_person_party_id);
end CreateUserParty;

----------------------------------------------------------------------
--
-- UpdateUser (Public)
--   Update any column for a particular user record. If that user does
--   not exist, exception raised with error message.
--   You can use this procedure to update a user's password for example.
--
--   *** NOTE: This version accepts the old customer_id/employee_id
--   keys foreign keys to the "person".  Use UpdateUserParty to update
--   a user with the new person_party_id key.
--
-- Usage Example in pl/sql
--   begin fnd_user_pkg.updateuser('SCOTT', 'SEED', 'DRAGON'); end;
--
-- Mandatory Input Arguments
--   x_user_name: An existing user name
--   x_owner:     'SEED' or 'CUST'(customer)
--
procedure UpdateUser (
  x_user_name                  in varchar2,
  x_owner                      in varchar2,
  x_unencrypted_password       in varchar2 default null,
  x_session_number             in number default null,
  x_start_date                 in date default null,
  x_end_date                   in date default null,
  x_last_logon_date            in date default null,
  x_description                in varchar2 default null,
  x_password_date              in date default null,
  x_password_accesses_left     in number default null,
  x_password_lifespan_accesses in number default null,
  x_password_lifespan_days     in number default null,
  x_employee_id                in number default null,
  x_email_address              in varchar2 default null,
  x_fax                        in varchar2 default null,
  x_customer_id                in number default null,
  x_supplier_id                in number default null,
  x_old_password               in varchar2 default null)
is
begin
  UpdateUserInternal(
    x_user_name => x_user_name,
    x_owner => x_owner,
    x_unencrypted_password => x_unencrypted_password,
    x_session_number => x_session_number,
    x_start_date => x_start_date,
    x_end_date => x_end_date,
    x_last_logon_date => x_last_logon_date,
    x_description => x_description,
    x_password_date => x_password_date,
    x_password_accesses_left => x_password_accesses_left,
    x_password_lifespan_accesses => x_password_lifespan_accesses,
    x_password_lifespan_days => x_password_lifespan_days,
    x_employee_id => x_employee_id,
    x_email_address => x_email_address,
    x_fax => x_fax,
    x_customer_id => x_customer_id,
    x_supplier_id => x_supplier_id,
    x_person_party_id => null,
    x_old_password => x_old_password,
    x_mode => 'EMPLOYEE');
end UpdateUser;

----------------------------------------------------------------------
--
-- UpdateUserParty (Public)
--   Update any column for a particular user record. If that user does
--   not exist, exception raised with error message.
--   You can use this procedure to update a user's password for example.
--
--   *** NOTE: This version accepts the new person_party_id foreign key
--   to the "person".  Use UpdateUser to update a user with the old
--   customer_id/employee_id keys.
--
-- Usage Example in pl/sql
--   begin fnd_user_pkg.updateuser('SCOTT', 'SEED', 'DRAGON'); end;
--
-- Mandatory Input Arguments
--   x_user_name: An existing user name
--   x_owner:     'SEED' or 'CUST'(customer)
--
procedure UpdateUserParty (
  x_user_name                  in varchar2,
  x_owner                      in varchar2,
  x_unencrypted_password       in varchar2 default null,
  x_session_number             in number default null,
  x_start_date                 in date default null,
  x_end_date                   in date default null,
  x_last_logon_date            in date default null,
  x_description                in varchar2 default null,
  x_password_date              in date default null,
  x_password_accesses_left     in number default null,
  x_password_lifespan_accesses in number default null,
  x_password_lifespan_days     in number default null,
  x_email_address              in varchar2 default null,
  x_fax                        in varchar2 default null,
  x_person_party_id            in number default null,
  x_old_password               in varchar2 default null)
is
begin
  UpdateUserInternal(
    x_user_name => x_user_name,
    x_owner => x_owner,
    x_unencrypted_password => x_unencrypted_password,
    x_session_number => x_session_number,
    x_start_date => x_start_date,
    x_end_date => x_end_date,
    x_last_logon_date => x_last_logon_date,
    x_description => x_description,
    x_password_date => x_password_date,
    x_password_accesses_left => x_password_accesses_left,
    x_password_lifespan_accesses => x_password_lifespan_accesses,
    x_password_lifespan_days => x_password_lifespan_days,
    x_employee_id => null,
    x_email_address => x_email_address,
    x_fax => x_fax,
    x_customer_id => null,
    x_supplier_id => null,
    x_person_party_id => x_person_party_id,
    x_old_password => x_old_password,
    x_mode => 'PARTY');
end UpdateUserParty;

----------------------------------------------------------------------------
--
-- LoadUser (Public)
--   Create or Update user, as appropriate.
--
--   *** NOTE: This version accepts the old customer_id/employee_id
--   keys foreign keys to the "person".  Use LoadUserParty to load
--   a user with the new person_party_id key.
--
procedure LoadUser(
  x_user_name                  in varchar2,
  x_owner                      in varchar2,
  x_unencrypted_password       in varchar2 default null,
  x_session_number             in number default null,
  x_start_date                 in date default null,
  x_end_date                   in date default null,
  x_last_logon_date            in date default null,
  x_description                in varchar2 default null,
  x_password_date              in date default null,
  x_password_accesses_left     in number default null,
  x_password_lifespan_accesses in number default null,
  x_password_lifespan_days     in number default null,
  x_employee_id                in number default null,
  x_email_address              in varchar2 default null,
  x_fax                        in varchar2 default null,
  x_customer_id                in number default null,
  x_supplier_id                in number default null) /* PARTY */
is
  l_api_name varchar2(30) := 'LOADUSER';
  exists_flag varchar2(1);
  reason varchar2(32000);
begin

  if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
  fnd_log.string(FND_LOG.LEVEL_STATEMENT,
                     c_log_head || l_api_name || '.before_updstmnt',
                     'LoadUser(): before update statement');
  end if;
  begin
    select 'Y'
    into exists_flag
    from fnd_user u
    where u.user_name = x_user_name;
  exception
    when no_data_found then
      exists_flag := 'N';
  end;

  if (exists_flag = 'Y') then
    fnd_user_pkg.UpdateUser(x_user_name,
                          x_owner,
                          x_unencrypted_password,
                          x_session_number,
                          x_start_date,
                          x_end_date,
                          x_last_logon_date,
                          x_description,
                          x_password_date,
                          x_password_accesses_left,
                          x_password_lifespan_accesses,
                          x_password_lifespan_days,
                          x_employee_id,
                          x_email_address,
                          x_fax,
                          x_customer_id,
                          x_supplier_id,
                          null);
  else  -- Must be new user
    -- insert the new user if x_session_number and x_start_date are provided
    if (x_unencrypted_password is not null) then

      if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
        fnd_log.string(FND_LOG.LEVEL_STATEMENT,
                     c_log_head || l_api_name || '.call_creatuser',
                    'LoadUser(): calling CreateUser');
      end if;
      fnd_user_pkg.createuser(x_user_name,
                          x_owner,
                          x_unencrypted_password,
                          x_session_number,
                          x_start_date,
                          x_end_date,
                          x_last_logon_date,
                          x_description,
                          x_password_date,
                          x_password_accesses_left,
                          x_password_lifespan_accesses,
                          x_password_lifespan_days,
                          x_employee_id,
                          x_email_address,
                          x_fax,
                          x_customer_id,
                          x_supplier_id);
    else
      fnd_message.set_name('FND', 'FND_NO_PASSWORD_PROVIDED');
      fnd_message.set_token('USER_NAME', X_USER_NAME);
      fnd_message.set_token('ROUTINE', 'FND_USER_PKG.LOADUSER');
      app_exception.raise_exception;
    end if;
  end if;
end LoadUser;

----------------------------------------------------------------------------
--
-- LoadUserParty (Public)
--   Create or Update user, as appropriate.
--
--   *** NOTE: This version accepts the new person_party_id foreign key
--   to the "person".  Use LoadUser to load a user with the old
--   customer_id/employee_id keys.
--
procedure LoadUserParty(
  x_user_name                  in varchar2,
  x_owner                      in varchar2,
  x_unencrypted_password       in varchar2 default null,
  x_session_number             in number default null,
  x_start_date                 in date default null,
  x_end_date                   in date default null,
  x_last_logon_date            in date default null,
  x_description                in varchar2 default null,
  x_password_date              in date default null,
  x_password_accesses_left     in number default null,
  x_password_lifespan_accesses in number default null,
  x_password_lifespan_days     in number default null,
  x_email_address              in varchar2 default null,
  x_fax                        in varchar2 default null,
  x_person_party_id            in number default null)
is
  l_api_name varchar2(30) := 'LOADUSERPARTY';
  exists_flag varchar2(1);
  reason varchar2(32000);
begin

  if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
  fnd_log.string(FND_LOG.LEVEL_STATEMENT,
                     c_log_head || l_api_name || '.before_updstmnt',
                     'LoadUser(): before update statement');
  end if;
  begin
    select 'Y'
    into exists_flag
    from fnd_user u
    where u.user_name = x_user_name;
  exception
    when no_data_found then
      exists_flag := 'N';
  end;

  if (exists_flag = 'Y') then
    fnd_user_pkg.UpdateUserParty(x_user_name,
                          x_owner,
                          x_unencrypted_password,
                          x_session_number,
                          x_start_date,
                          x_end_date,
                          x_last_logon_date,
                          x_description,
                          x_password_date,
                          x_password_accesses_left,
                          x_password_lifespan_accesses,
                          x_password_lifespan_days,
                          x_email_address,
                          x_fax,
                          x_person_party_id,
                          null);
  else  -- Must be new user
    -- insert the new user if x_session_number and x_start_date are provided
    if (x_unencrypted_password is not null) then

      if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
      fnd_log.string(FND_LOG.LEVEL_STATEMENT,
                     c_log_head || l_api_name || '.call_creatuser',
                    'LoadUser(): calling CreateUser');
      end if;
      fnd_user_pkg.createuserparty(x_user_name,
                          x_owner,
                          x_unencrypted_password,
                          x_session_number,
                          x_start_date,
                          x_end_date,
                          x_last_logon_date,
                          x_description,
                          x_password_date,
                          x_password_accesses_left,
                          x_password_lifespan_accesses,
                          x_password_lifespan_days,
                          x_email_address,
                          x_fax,
                          x_person_party_id);
    else
      fnd_message.set_name('FND', 'FND_NO_PASSWORD_PROVIDED');
      fnd_message.set_token('USER_NAME', X_USER_NAME);
      fnd_message.set_token('ROUTINE', 'FND_USER_PKG.LOADUSER');
      app_exception.raise_exception;
    end if;
  end if;
end LoadUserParty;

----------------------------------------------------------------------------
--
-- DisableUser (PUBLIC)
--   Sets end_date to sysdate for a given user. This is to terminate that user.
--   You longer can log in as this user anymore. If username is not valid,
--   exception raised with error message.
--
-- Usage example in pl/sql
--   begin fnd_user_pkg.disableuser('SCOTT'); end;
--
-- Input (Mandatory)
--  username:       User Name
--
procedure DisableUser(username varchar2) is
begin
--  bug 3043856 phase 1 of long term plan on Guest User
--  here we do not disable Guest account
  if( upper(username) = 'GUEST' ) then
      return;
  end if;
  fnd_user_pkg.UpdateUser(x_user_name => DisableUser.username,
                          x_owner     => null,
                          x_end_date  => sysdate);
end DisableUser;
----------------------------------------------------------------------------
--
-- ValidateLogin (PUBLIC)
--   Test if password is good for this given user.
--
-- Usage example in pl/sql
--   begin fnd_user_pkg.validatelogin('SCOTT', 'TIGER'); end;
--
-- Input (Mandatory)
--  username:       User Name
--  password:       User Password
--
function ValidateLogin(username   varchar2,
                       password   varchar2) return boolean is
begin
  return boolRet(fnd_web_sec.validate_login(username, password));
end ValidateLogin;
----------------------------------------------------------------------------
--
-- ChangePassword (PUBLIC)
--   Set new password for a given user without having to provide
--   the old password.
--
-- Usage example in pl/sql
--   begin fnd_user_pkg.changepassword('SCOTT', 'WELCOME'); end;
--
-- Input (Mandatory)
--  username:       User Name
--  newpassword     New Password
--
function ChangePassword(username      varchar2,
                        newpassword   varchar2) return boolean is
begin
  return boolRet(fnd_web_sec.Change_Password(username, newpassword, FALSE));
end;
----------------------------------------------------------------------------
--
-- ChangePassword (PUBLIC)
--   Set new password for a given user if the existing password needed to be
--   validated before changing to the new password.
--
-- Usage example in pl/sql
--   begin fnd_user_pkg.changepassword('SCOTT', 'TIGER', 'WELCOME'); end;
--
-- Input (Mandatory)
--  username:       User Name
--  oldpassword     Old Password
--  newpassword     New Password
--
function ChangePassword(username      varchar2,
                        oldpassword   varchar2,
                        newpassword   varchar2) return boolean is

begin
   return boolRet(fnd_web_sec.Change_Password(username, oldpassword,
                                             newpassword, newpassword, FALSE));
end;
----------------------------------------------------------------------------
--
-- GetReEncryptedPassword (PUBLIC)
--   Return user password encrypted with new key. This just returns the
--   newly encrypted password. It does not set the password in FND_USER table.
--
-- Usage example in pl/sql
--   declare
--     newpass varchar2(100);
--   begin
--     newpass := fnd_user_pkg.getreencryptedpassword('SCOTT', 'NEWKEY'); end;
--   end;
--
-- Input (Mandatory)
--   username:  User Name
--   newkey     New Key
--
function GetReEncryptedPassword(username varchar2,
                                newkey   varchar2) return varchar2 is
begin
  return (fnd_web_sec.get_reencrypted_password(username, newkey));
end;

----------------------------------------------------------------------------
-- SetReEncryptedPassword (PUBLIC)
--   Set user password from value returned from GetReEncryptedPassword.
--   This is to update column ENCRYPTED_USER_PASSWORD in table FND_USER
--
-- Usage example in pl/sql
--   declare
--     newpass varchar2(100);
--   begin
--     newpass := fnd_user_pkg.getreencryptedpassword('SCOTT', 'NEWKEY'); end;
--     fnd_user_pkg.setreencryptedpassword('SCOTT', newpass, 'NEWKEY'); end;
--   end;
--
-- Input (Mandatory)
--  username:       User Name
--  reencpwd:       Reencrypted Password
--  newkey          New Key
--
function SetReEncryptedPassword(username varchar2,
                              reencpwd varchar2,
                              newkey   varchar2) return boolean is
begin
  return boolRet(fnd_web_sec.set_reencrypted_password(username,reencpwd,newkey));
end;
----------------------------------------------------------------------------
-- MergeCustomer (PUBLIC)
--   This is the procedure being called during the Party Merge.
--   FND_USER.MergeCustomer() has been registered in Party Merge Data Dict.
--   The input/output arguments format matches the document PartyMergeDD.doc.
--   The goal is to fix the customer id in fnd_user table to point to the
--   same party when two similar parties are begin merged.
--
-- Usage example in pl/sql
--   This procedure should only be called from the PartyMerge utility.
--
procedure MergeCustomer(p_entity_name in varchar2,
                        p_from_id in number,
                        p_to_id in out nocopy number,
                        p_from_fk_id in number,
                        p_to_fk_id in number,
                        p_parent_entity_name in varchar2,
                        p_batch_id in number,
                        p_batch_party_id in number,
                        p_return_status in out nocopy varchar2) is
begin
  p_return_status := FND_API.G_RET_STS_SUCCESS;

  if (p_from_fk_id <> p_to_fk_id) then

    update fnd_user
    set customer_id = p_to_fk_id
    where customer_id = p_from_fk_id;

    -- Added for Function Security Cache Invalidation
    fnd_function_security_cache.update_user(p_from_id);

  end if;

end MergeCustomer;

--------------------------------------------------------------------------
--
-- user_change - The rule function for FND's subscription on the
--               oracle.apps.wf.entmgr.user.change event.  This function
--               retrieves the user's information and updates the
--               corresponding fnd_user as needed, if the user exists.
--
FUNCTION user_change(p_subscription_guid in            raw,
                     p_event             in out nocopy wf_event_t)
return varchar2 is
  my_ent_type  varchar2(50);
  my_username  varchar2(256); -- one-way code only
  my_mode      varchar2(256); -- one-way code only
  my_cachekey  varchar2(256);
  my_user      varchar2(256);
  my_user_id   number;
  l_allow_sync varchar2(1);
  l_local_login varchar(10);
  l_profile_defined boolean;
  my_guid      varchar2(256);
  old_desc     varchar2(256);
  new_desc     varchar2(256);
  old_email    varchar2(256);
  new_email    varchar2(256);
  old_fax      varchar2(256);
  new_fax      varchar2(256);
  new_email2   varchar2(256); -- one-way code only
  new_fax2     varchar2(256); -- one-way code only
  new_desc2    varchar2(256); -- one-way code only
  l_api_name     varchar2(30) := 'user_change';

  old_guid     raw(16);

  cursor existing_users(userGuid in varchar2) is
    select nvl(description,   '*NULL*'),
           nvl(email_address, '*NULL*'),
           nvl(fax,           '*NULL*'),
           user_name,
           user_id
    from   fnd_user
    where  user_guid = userGuid;

begin

  if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'Start user_change');
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'p_subscription_guid ='||p_subscription_guid);
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'event_name ='||p_event.GetEventName);
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'parameter CHANGE_SOURCE ='||
                  p_event.GetValueForParameter('CHANGE_SOURCE'));
  end if;

  -- Ignore our own changes
  if (p_event.GetValueForParameter('CHANGE_SOURCE') = 'FND_USR') then
    return 'SUCCESS';

  -- If CHANGE_SOURCE is LDAP, it means it's raised from one-way sync code.
  elsif (p_event.GetValueForParameter('CHANGE_SOURCE') = 'LDAP') then

    my_username := p_event.GetEventKey();
    my_mode := p_event.GetValueForParameter('CHANGE_TYPE');

    if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
      fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'LDAP - event_key ='||my_username);
      fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                'LDAP - parameter CHANGE_TYPE ='||my_mode);
    end if;

    if (my_mode = 'DELETE') then
      begin
        fnd_user_pkg.disableUser(my_username);
      exception
        when others then null;
      end;

    elsif (my_mode in ('ADD','MODIFY','LOAD')) then
      --
      -- First check to see if user exists and get the existing attribute
      -- values.  If the user does not exist, we're done.
      -- Convert nulls to *NULL* so that old values are either *NULL*
      -- or an actual value.
      --
      begin
        select nvl(description,   '*NULL*'),
               nvl(email_address, '*NULL*'),
               nvl(fax,           '*NULL*'),
               user_guid
        into   old_desc, old_email, old_fax, old_guid
        from   fnd_user
        where  user_name = my_username;
      exception
        when others then return 'SUCCESS';
      end;

      --
      -- Fetch the new values from the attribute cache
      -- New values can either be *NULL*, *UNKNOWN*, or an actual value
      --
      my_ent_type := wf_entity_mgr.get_entity_type(p_event.GetEventName());

      --     NOTE:  While we have the ability to distinguish between null
      --            and "known to be null", the standard apis do not.
      --            For now, we're must pass null regardless which is
      --            treated as a "don't change".  We do not yet support
      --            the ability to "null out" an attribute value.

      new_desc  := wf_entity_mgr.get_attribute_value(my_ent_type, my_username,
                                                  'DESCRIPTION');
      new_email := wf_entity_mgr.get_attribute_value(my_ent_type, my_username,
                                                  'MAIL');
      new_fax   := wf_entity_mgr.get_attribute_value(my_ent_type, my_username,
                                                  'FACSIMILETELEPHONENUMBER');
      --
      -- Determine if there are any changes to the attributes we're
      -- interested in.  And if so, update the user record.
      --

      if (wf_entity_mgr.isChanged(new_desc,  old_desc)   OR
          wf_entity_mgr.isChanged(new_email, old_email)  OR
          wf_entity_mgr.isChanged(new_fax,   old_fax))  then

        -- at least one of the attributes has changed -> update the user --

        --
        -- NOTE:  the following conversions are necessary until we resolve
        -- null and "null out"
        --
--Start bug 3147423 change null to null_char
        if (new_desc = '*NULL*' or new_desc = '*UNKNOWN*') then
          new_desc2 := null_char;
        else
          new_desc2 := new_desc;
        end if;

        if (new_fax = '*NULL*' or new_fax = '*UNKNOWN*') then
          new_fax2 := null_char;
        else
          new_fax2 := new_fax;
        end if;

        if (new_email = '*NULL*' or new_email = '*UNKNOWN*') then
          new_email2 := null_char;
        else
          new_email2 := new_email;
        end if;
--End bug 3147423
        -- end of conversions --

        fnd_user_pkg.UpdateUser(
          x_user_name     => my_username,
          x_owner         => 'CUST',
          x_description   => new_desc2,
          x_email_address => new_email2,
          x_fax           => new_fax2,
-- This api is called by LDAP so pass the change source so that we don't
-- start the synch loop.
          x_user_guid     => old_guid,
          x_change_source => fnd_user_pkg.change_source_oid);

      if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
        fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                  'LDAP - finished fnd_user_pkg.UpdateUser('||my_username||')');
      end if;
      end if;
    end if;

   -- If CHANGE_SOURCE is OID, it means it's raised from two-way sync code.
  elsif (p_event.GetValueForParameter('CHANGE_SOURCE') = 'OID') then

    my_cachekey := p_event.GetEventKey();
    my_ent_type := wf_entity_mgr.get_entity_type(p_event.GetEventName());
    my_guid     := wf_entity_mgr.get_attribute_value(my_ent_type, my_cachekey,
                                                  'ORCLGUID');
    if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
      fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'OID - event_key ='||my_cachekey);
      fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'OID - entity_type ='||my_ent_type);
      fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'OID - guid ='||my_guid);
    end if;

    open existing_users(my_guid);
    LOOP
      FETCH existing_users INTO old_desc, old_email, old_fax, my_user, my_user_id;
      EXIT WHEN existing_users%NOTFOUND;

      fnd_profile.get_specific(name_z => 'APPS_SSO_LDAP_SYNC',
                               user_id_z => my_user_id,
                               val_z => l_allow_sync,
                               defined_z => l_profile_defined);

      fnd_profile.get_specific(name_z => 'APPS_SSO_LOCAL_LOGIN',
                               user_id_z => my_user_id,
                               val_z => l_local_login,
                               defined_z => l_profile_defined);

      -- Don't sync users who have 'N' for profile value APPS_SSO_LDAP_SYNC
      -- or 'LOCAL' for profile value APPS_SSO_LOCAL_LOGIN

      if ( (l_allow_sync = 'Y') and (l_local_login <> 'LOCAL') ) then

        if (p_event.GetValueForParameter('CHANGE_TYPE') = 'DELETE') then
          begin
            fnd_user_pkg.disableUser(my_user);
          exception
            when others then null;
          end;

        else
          --
          -- Fetch the new values from the attribute cache.
          -- New values will be *NULL*, *UNKNOWN*, or an actual value.
          --
          --     NOTE:  While we have the ability to distinguish between null
          --            and "known to be null", the standard apis do not.
          --            For now, we're must pass null regardless which is
          --            treated as a "don't change".  fnd_user_pkg apis do
          --            not yet support the ability to "null out" an
          --            attribute value.  Weak.
          --
          new_desc  := wf_entity_mgr.get_attribute_value(my_ent_type, my_cachekey,
                                                   'DESCRIPTION');
          new_email := wf_entity_mgr.get_attribute_value(my_ent_type, my_cachekey,
                                                   'MAIL');
          new_fax   := wf_entity_mgr.get_attribute_value(my_ent_type, my_cachekey,
                                                   'FACSIMILETELEPHONENUMBER');
          --
          -- Determine if there are any changes to the attributes we're
          -- interested in.  And if so, update the user record.
          --
          if (wf_entity_mgr.isChanged(new_desc,  old_desc)   OR
              wf_entity_mgr.isChanged(new_email, old_email)  OR
              wf_entity_mgr.isChanged(new_fax,   old_fax)) then
--Start Bug 3147423
            if (new_desc in ('*NULL*', '*UNKNOWN*')) then
                new_desc := null_char;
            end if;

            if (new_fax in ('*NULL*', '*UNKNOWN*')) then
              new_fax := null_char;
            end if;

            if (new_email in ('*NULL*', '*UNKNOWN*')) then
              new_email := null_char;
            end if;

            fnd_user_pkg.UpdateUser(
              x_user_name     => my_user,
              x_owner         => 'CUST',
              x_description   => new_desc,
              x_email_address => new_email,
              x_fax           => new_fax);

            if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
              fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                  'OID - finished fnd_user_pkg.UpdateUser('||my_user||')');
      end if;
          end if;
        end if;
      else
        null;
      end if;
    END LOOP;
    CLOSE existing_users;
  end if;

  if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'End user_change');
  end if;
  return wf_rule.default_rule(p_subscription_guid, p_event);
end user_change;

--------------------------------------------------------------------------
--
-- user_create_rf - The rule function for FND's 2nd subscription on the
--               oracle.apps.wf.entmgr.user.change event.  This function
--               retrieves the user's information and creates the
--               corresponding fnd_user if the user does not already exist.
--
FUNCTION user_create_rf(p_subscription_guid in            raw,
                        p_event             in out nocopy wf_event_t)
         return varchar2
is
  my_ent_type   varchar2(50);
  my_cachekey   varchar2(256);
  my_username   varchar2(256); -- one-way code only
  existing_user varchar2(1);
  new_desc      varchar2(256);
  new_email     varchar2(256);
  new_fax       varchar2(256);
  new_guid      varchar2(256);
  new_email2    varchar2(256); -- one-way code only
  new_fax2      varchar2(256); -- one-way code only
  new_desc2     varchar2(256); -- one-way code only
  l_api_name     varchar2(30) := 'user_create_rf';

begin

  if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'Start user_create_rf');
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'p_subscription_guid ='||p_subscription_guid);
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'event_name ='||p_event.GetEventName);
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'parameter CHANGE_SOURCE ='||
                  p_event.GetValueForParameter('CHANGE_SOURCE'));
  end if;
  -- Ignore our own changes
  if (p_event.GetValueForParameter('CHANGE_SOURCE') = 'FND_USR') then
    return 'SUCCESS';

  -- If CHANGE_SOURCE is LDAP, it means it's raised from one-way sync code.
  elsif (p_event.GetValueForParameter('CHANGE_SOURCE') = 'LDAP') then
    my_username := p_event.GetEventKey();

    if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
      fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'LDAP - event_key ='||my_username);
    end if;

    begin
      select 'Y' into existing_user
      from   fnd_user
      where  user_name = my_username;

      return 'SUCCESS';
    exception
      when others then

      -- user doesn't exist yet, we have work to do --
      my_ent_type := wf_entity_mgr.get_entity_type(p_event.GetEventName());

      if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
        fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                  'LDAP - entity_type ='||my_ent_type);
      end if;

      --
      -- Fetch the new values from the attribute cache
      -- New values can either be *NULL*, *UNKNOWN*, or an actual value
      --
      new_desc  := wf_entity_mgr.get_attribute_value(my_ent_type, my_username,
                                                  'DESCRIPTION');
      new_email := wf_entity_mgr.get_attribute_value(my_ent_type, my_username,
                                                  'MAIL');
      new_fax   := wf_entity_mgr.get_attribute_value(my_ent_type, my_username,
                                                  'FACSIMILETELEPHONENUMBER');
      --
      -- NOTE:  the following conversions are necessary until we resolve
      -- null and "null out"
      --
--Start Bug 3147423
      if (new_desc = '*NULL*' or new_desc = '*UNKNOWN*') then
        new_desc2 := null_char;
      else
        new_desc2 := new_desc;
      end if;

      if (new_fax = '*NULL*' or new_fax = '*UNKNOWN*') then
        new_fax2 := null_char;
      else
        new_fax2 := new_fax;
      end if;

      if (new_email = '*NULL*' or new_email = '*UNKNOWN*') then
        new_email2 := null_char;
      else
        new_email2 := new_email;
      end if;

--End Bug 3147423

      -- end of conversions --

      fnd_user_pkg.CreateUser(
        x_user_name            => my_username,
        x_owner                => 'CUST',
        x_unencrypted_password => null,
        x_description          => new_desc2,
        x_email_address        => new_email2,
        x_fax                  => new_fax2);

      if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
        fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                  'LDAP - finished fnd_user_pkg.CreateUser('||my_username||')');
      end if;
    end;

  -- If CHANGE_SOURCE is OID, it means it's raised from two-way sync code.
  elsif (p_event.GetValueForParameter('CHANGE_SOURCE') = 'OID') then

    my_cachekey := p_event.GetEventKey();
    my_ent_type := wf_entity_mgr.get_entity_type(p_event.GetEventName());
    new_guid := wf_entity_mgr.get_attribute_value(my_ent_type, my_cachekey,
                                                'ORCLGUID');
    if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
      fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'OID - event_key ='||my_cachekey);
      fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'OID - entity_type ='||my_ent_type);
      fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'OID - guid ='||new_guid);
    end if;
    begin
      select 'Y' into existing_user
      from   fnd_user
      where  user_name = my_cachekey;

    return 'SUCCESS';

    exception
      when others then  -- CREATE NEW USER --

      new_desc  := wf_entity_mgr.get_attribute_value(my_ent_type, my_cachekey,
                                                  'DESCRIPTION');
      new_email := wf_entity_mgr.get_attribute_value(my_ent_type, my_cachekey,
                                                  'MAIL');
      new_fax   := wf_entity_mgr.get_attribute_value(my_ent_type, my_cachekey,
                                                  'FACSIMILETELEPHONENUMBER');
      if (new_desc in ('*NULL*', '*UNKNOWN*')) then
        new_desc := null;
      end if;

      if (new_fax in ('*NULL*', '*UNKNOWN*')) then
        new_fax := null;
      end if;

      if (new_email in ('*NULL*', '*UNKNOWN*')) then
        new_email := null;
      end if;

      fnd_user_pkg.CreateUser(
        x_user_name            => my_cachekey,
        x_owner                => 'CUST',
        x_unencrypted_password => null,
        x_description          => new_desc,
        x_email_address        => new_email,
        x_fax                  => new_fax);

      if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
        fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                  'OID - finished fnd_user_pkg.CreateUser('||my_cachekey||')');
      end if;

      --
      -- guid will eventually be managed centrally so didn't want to add it
      -- to the fnd_user_pkg apis...hence the separate update here
      --
      update fnd_user set user_guid = new_guid
      where user_name = my_cachekey;

    end;
  end if;

  if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                 'End user_create_rf');
  end if;

  return wf_rule.default_rule(p_subscription_guid, p_event);
end user_create_rf;

-- Private
-- Called by user_synch when user_name is changed
procedure UpdateUserNameChildren(old_name in varchar2,
                                 new_name in varchar2) is
  colnames fnd_dictionary_pkg.NameArrayTyp;
  colold fnd_dictionary_pkg.NameArrayTyp;
  colnew fnd_dictionary_pkg.NameArrayTyp;
  l_api_name  CONSTANT varchar2(30) := 'UpdateUsernameChildren';
  tmpbuf varchar2(240);
  reason varchar2(2000);
  ret boolean;
begin
  -- need to call pk update to do cascade foreign key children update
  colnames(0) := 'USER_NAME';
  colnames(1) := '';
  colold(0) := old_name;
  colold(1) := '';
  colnew(0) := new_name;
  colnew(1) := '';

  tmpbuf := 'Start calling fnd_dictionary_pkg.updatepkcolumns('||
             old_name||','||new_name||')';
  if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
  fnd_log.string(FND_LOG.LEVEL_STATEMENT, C_LOG_HEAD || l_api_name || '.',
               tmpbuf);
  end if;
  ret := fnd_dictionary_pkg.updatepkcolumns('FND', 'FND_USER', colnames, colold,
                                       colnew);
  tmpbuf := 'Finished fnd_dictionary_pkg.updatepkcolumns';
  if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
  fnd_log.string(FND_LOG.LEVEL_STATEMENT, C_LOG_HEAD || l_api_name || '.',
               tmpbuf);
  end if;
exception
  when others then
    reason := fnd_message.get;
    fnd_message.set_name('FND', 'FND_FAILED_UPDATE_UNAME_CHILD');
    fnd_message.set_token('OLD_NAME', old_name);
    fnd_message.set_token('NEW_NAME', new_name);
    fnd_message.set_token('REASON', reason);
    app_exception.raise_exception;
end UpdateUserNameChildren;
--------------------------------------------------------------------------
--
-- user_synch - The centralized routine for communicating user changes
--             with wf and entity mgr.
--
PROCEDURE user_synch(p_user_name in varchar2) is
  my_userid number;
  my_email  varchar2(240);
  my_desc   varchar2(240);
  my_fax    varchar2(80);
  my_pwd    varchar2(100);
  my_empid  number;
  my_partyid number;
  my_exp    date;
  my_start  date;
  my_guid   varchar2(32);
  myList    wf_parameter_list_t;
  ch_exp    varchar2(20);
  ch_start  varchar2(20);
  --<rwunderl:3203225>
  l_defined_z BOOLEAN;
  myLang      VARCHAR2(240);
  myTerr      VARCHAR2(240);
  l_userNTFPref   VARCHAR2(8); -- bug 3280951
  l_party_type    varchar2(30);
  --</rwunderl:3203225>
  dummy     number(1);
  -- <bug 2850261 (enhancement request) >
  ptyName varchar2(360);
  --</bug 2852061>

  l_api_name varchar2(30) := 'UserSynch';

begin
  -- fetch info for synch --

  if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                   'Start user_synch');
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                   'p_user_name = '||p_user_name);
  end if;

  select user_id, email_address, description, fax, employee_id,
         person_party_id,
         start_date, end_date, user_guid, encrypted_user_password,
         to_char(start_date, 'YYYYMMDDHH24MISS'),
         to_char(end_date, 'YYYYMMDDHH24MISS')
  into   my_userid, my_email, my_desc, my_fax, my_empid, my_partyid,
         my_start, my_exp, my_guid, my_pwd, ch_start, ch_exp
  from   fnd_user
  where  user_name = upper(p_user_name);

  -- construct attribute list for wf synch --
  -- unstubbed the code
  wf_event.AddParameterToList('MAIL', my_email, mylist);
  wf_event.AddParameterToList('DESCRIPTION', my_desc, mylist);
  wf_event.AddParameterToList('FACSIMILETELEPHONENUMBER', my_fax, mylist);
  wf_event.AddParameterToList('USER_NAME', upper(p_user_name), mylist);
  wf_event.AddParameterToList('CN', upper(p_user_name), mylist);
  wf_event.AddParameterToList('SN', upper(p_user_name), mylist);
  wf_event.AddParameterToList('ORCLACTIVESTARTDATE', ch_start, mylist);
  if ((my_exp is null) OR
     (trunc(sysdate) between my_start and my_exp)) then
    wf_event.AddParameterToList('ORCLISENABLED', 'ACTIVE', mylist);
  else
    wf_event.AddParameterToList('ORCLISENABLED', 'INACTIVE', mylist);
  end if;
  wf_event.AddParameterToList('ORCLACTIVEENDDATE', ch_exp, mylist);
  wf_event.AddParameterToList('ORCLGUID', my_guid, mylist);
  -- bug 4318754

  wf_event.AddParameterToList('OLD_ORCLGUID', g_old_user_guid, mylist);
  -- end bug 4318754

  wf_event.AddParameterToList('USERPASSWORD', my_pwd, mylist);
  wf_event.AddParameterToList('PER_PERSON_ID',
                  fnd_number.number_to_canonical(my_empid), mylist);
  wf_event.AddParameterToList('PERSON_PARTY_ID',
                  fnd_number.number_to_canonical(my_partyid), mylist);
  -- bug 4318754
  wf_event.AddParameterToList('OLD_PERSON_PARTY_ID',
                 fnd_number.number_to_canonical(g_old_person_party_id), mylist);
  -- end bug 4318754

  -- begin 2850261
  begin
    FND_OAM_USER_INFO.HZ_PARTY_ID_TO_NAME(my_partyid, ptyName, l_party_type);
  exception
    when no_data_found then
      ptyName := p_user_name;
  end;
  wf_event.AddParameterToList('DISPLAYNAME', upper(ptyName), mylist);
  -- end 2852061

  -- begin bug 2504562
  wf_event.AddParameterToList('OLD_USER_NAME', g_old_user_name, mylist);
  /* set g_old_user_name to null here to cover calls to user_synch initiated
     from Forms or from the fnd_user_pkg.change_user_name PL/SQL api */
  --Comment out this following call because I need it to do the pk children
  --later. After pk children update, then I will reset g_old_user_name.
  --dummy := fnd_user_pkg.set_old_user_name(NULL);
  -- end bug 2504562

  -- <rwunderl:3203225>
  -- Added calls for the lang/territory and notification preference.
  fnd_profile.get_specific(name_z=>'ICX_LANGUAGE', user_id_z=>my_userid,
                           val_z=>myLang, defined_z=>l_defined_z);
  wf_event.AddParameterToList('PREFERREDLANGUAGE', myLang, myList);

  fnd_profile.get_specific(name_z=>'ICX_TERRITORY', user_id_z=>my_userid,
                           val_z=>myTerr, defined_z=>l_defined_z);

  wf_event.AddParameterToList('ORCLNLSTERRITORY', myTerr, myList);

  -- begin bug 3280951
  -- Retrieve the notification preference for the user
  -- using substr since fnd_preference.get returns varchar2(240)
  -- and this maps to varchar2(8) column on WF side.
  l_userNTFPref := substr(fnd_preference.get(UPPER(p_user_name), 'WF', 'MAILTYPE'), 1, 8);

  if (l_userNTFPref is NULL) then
    --There is no preference for the user, so retrieving the global.
    l_userNTFPref := substr(fnd_preference.get('-WF_DEFAULT-', 'WF', 'MAILTYPE'), 1, 8);

  end if;

  wf_event.AddParameterToList('ORCLWORKFLOWNOTIFICATIONPREF',
                              nvl(l_userNTFPref, 'MAILHTML'), mylist);

  -- end bug 3280951

  --Bug 3277794
  --Add the over-write parameter to the attribute list
  wf_event.AddParameterToList('WFSYNCH_OVERWRITE','TRUE',mylist);

  -- </rwunderl:3203225>

  if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                   'Calling wf_local_synch.propagate_user');
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                   'ORCLGUID = '|| my_guid);
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                   'PER_PERSON_ID = '|| my_empid);
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                   'PERSON_PARTY_ID = '|| my_partyid);
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                   'DISPLAY_NAME(PARTY_NAME) = '|| ptyName);
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                   'OLD_USER_NAME = '|| g_old_user_name);
  end if;
  -- update wf and the entity manager --
  wf_local_synch.propagate_user('FND_USR',my_userid, myList, my_start, my_exp);
  -- end of unstub

  if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                   'Finished wf_local_synch.propagate_user');
  end if;
  -- -----------------------------------------------------------------
  -- since wf_local_synch is temporarily stubbed out, also make the
  -- direct calls to entity-mgr to compensate (jvc)
  -- -----------------------------------------------------------------

  -- don't make this call anymore - code unstubbed

--  wf_entity_mgr.put_attribute_value('USER', upper(p_user_name),
--                                     'MAIL', my_email);
--  wf_entity_mgr.put_attribute_value('USER', upper(p_user_name),
--                                     'DESCRIPTION', my_desc);
--  wf_entity_mgr.put_attribute_value('USER', upper(p_user_name),
--                                     'FACSIMILETELEPHONENUMBER', my_fax);
--  wf_entity_mgr.put_attribute_value('USER', upper(p_user_name),
--                                     'USER_NAME', upper(p_user_name));
--  wf_entity_mgr.put_attribute_value('USER', upper(p_user_name),
--                                     'SN', upper(p_user_name));
--  wf_entity_mgr.put_attribute_value('USER', upper(p_user_name),
--                                     'ORCLACTIVESTARTDATE', ch_start);
--  wf_entity_mgr.put_attribute_value('USER', upper(p_user_name),
--                                     'ORCLACTIVEENDDATE', ch_exp);
--  wf_entity_mgr.put_attribute_value('USER', upper(p_user_name),
--                                     'ORCLGUID', my_guid);
--  wf_entity_mgr.put_attribute_value('USER', upper(p_user_name),
--                                     'USERPASSWORD', my_pwd);
--  wf_entity_mgr.put_attribute_value('USER', upper(p_user_name),
--                                     'PER_PERSON_ID',
--                            fnd_number.number_to_canonical(my_empid));
--  wf_entity_mgr.process_changes('USER', upper(p_user_name), 'FND_USR');

  -- Added for bug 3804617
  -- If a user_name is changed, we need to update all foreign key children.
  if (g_old_user_name is not null) then
    UpdateUsernameChildren(g_old_user_name, p_user_name);
  end if;
  -- set g_old_user_name to null here to cover calls to user_synch initiated
  -- from Forms or from the fnd_user_pkg.change_user_name PL/SQL api
  dummy := fnd_user_pkg.set_old_user_name(NULL);
  dummy := fnd_user_pkg.set_old_person_party_id(NULL);
  dummy := fnd_user_pkg.set_old_user_guid(NULL);

  if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
    fnd_log.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name,
                   'End user_synch');
  end if;
exception
--  Bug 3617474: This NO_DATA_FOUND exception handler was placed in the event
--  that fnd_user_pkg.user_synch() was passed an invalid or null user_name,
--  i.e a user_name that does not exist in fnd_user.
    when NO_DATA_FOUND then
        null;

end user_synch;

--------------------------------------------------------------------------
--
-- DelResp (PUBLIC)
--   Detach a responsibility which is currently attached to this given user.
--   If any of the username or application short name or responsibility key or
--   security group is not valid, exception raised with error message.
--
-- Usage example in pl/sql
--   begin fnd_user_pkg.delresp('SCOTT', 'FND', 'APPLICATION_DEVELOPER',
--                              'STANDARD'); end;
-- Input (Mandatory)
--  username:       User Name
--  resp_app:       Application Short Name
--  resp_key:       Responsibility Key
--  security_group: Security Group Key
--
procedure DelResp(username       varchar2,
                  resp_app       varchar2,
                  resp_key       varchar2,
                  security_group varchar2) is
  userid number := -1;
  respid number := -1;
  appid  number := -1;
  secid  number := -1;
  startdate date;
begin
  begin
    select user_id into userid
    from   fnd_user
    where  user_name = DelResp.username;

    select application_id into appid
    from   fnd_application
    where  application_short_name = DelResp.Resp_app;

    /* Bug4600645 - Modified to get actual start_date instead of using */
    /* sysdate in call to fnd_user_resp_groups_api.update_assignment   */

    select responsibility_id
     into respid
    from   fnd_responsibility
    where  application_id = appid
    and    responsibility_key = DelResp.resp_key;

    select security_group_id into secid
    from   fnd_security_groups
    where  security_group_key = DelResp.security_group;

   /*Bug4600645 - Get actual start_date value*/

    select start_date into startdate
    from fnd_user_resp_groups_all
    where user_id = userid
    and responsibility_id = respid
    and responsibility_application_id = appid;

  exception
    when no_data_found then
      fnd_message.set_token('USER_NAME', username);
      fnd_message.set_name('FND', 'INVALID_RESPONSIBILITY_DATA');
      fnd_message.set_token('APPS_NAME', resp_app);
      fnd_message.set_token('RESP_KEY', resp_key);
      fnd_message.set_token('SECURITY_GROUP', security_group);
      app_exception.raise_exception;
  end;

  if (fnd_user_resp_groups_api.assignment_exists(
                  userid, respid, appid, secid)) then
    fnd_user_resp_groups_api.update_assignment(
      user_id                        => userid,
      responsibility_id              => respid,
      responsibility_application_id  => appid,
      security_group_id              => secid,
      start_date                     => startdate,
      end_date                       => sysdate,
      description                    => null);
  end if;
end DelResp;

--------------------------------------------------------------------------
--
-- AddResp (PUBLIC)
--   For a given user, attach a valid responsibility.
--   If user name or application short name or responsbility key name
--   or security group key is not valid, exception raised with error message.
--
-- Usage example in pl/sql
--   begin fnd_user_pkg.addresp('SCOTT', 'FND', 'APPLICATION_DEVELOPER',
--                              'STANDARD', 'DESCRIPTION', sysdate, null); end;
-- Input (Mandatory)
--  username:       User Name
--  resp_app:       Application Short Name
--  resp_key:       Responsibility Key
--  security_group: Security Group Key
--  description:    Description
--  start_date:     Start Date
--  end_date:       End Date
--
procedure AddResp(username       varchar2,
                  resp_app       varchar2,
                  resp_key       varchar2,
                  security_group varchar2,
                  description    varchar2,
                  start_date     date,
                  end_date       date) is
  userid number := -1;
  respid number := -1;
  appid  number := -1;
  secid  number := -1;
begin

  begin
    select user_id into userid
    from   fnd_user
    where  user_name = AddResp.username;

    select application_id into appid
    from   fnd_application
    where  application_short_name = AddResp.resp_app;

    select responsibility_id into respid
    from   fnd_responsibility
    where  application_id = appid
    and    responsibility_key = AddResp.resp_key;

    select security_group_id into secid
    from   fnd_security_groups
    where  security_group_key = AddResp.security_group;

    exception
    when no_data_found then
      fnd_message.set_token('USER_NAME', username);
      fnd_message.set_name('FND', 'INVALID_RESPONSIBILITY_DATA');
      fnd_message.set_token('APPS_NAME', resp_app);
      fnd_message.set_token('RESP_KEY', resp_key);
      fnd_message.set_token('SECURITY_GROUP', security_group);
      app_exception.raise_exception;
  end;

  if (fnd_user_resp_groups_api.assignment_exists(
                     userid, respid, appid, secid)) then
       fnd_user_resp_groups_api.update_assignment(
         user_id                        => userid,
         responsibility_id              => respid,
         responsibility_application_id  => appid,
         security_group_id              => secid,
         start_date                     => AddResp.start_date,
         end_date                       => AddResp.end_date,
         description                    => AddResp.description);
  else
       fnd_user_resp_groups_api.insert_assignment(
         user_id                        => userid,
         responsibility_id              => respid,
         responsibility_application_id  => appid,
         security_group_id              => secid,
         start_date                     => AddResp.start_date,
         end_date                       => AddResp.end_date,
         description                    => AddResp.description);
  end if;

end AddResp;

-------------------------------------------------------------------
-- Name:        isPasswordChangeable
-- Description: Checks if user us externally authenticatied
----------------------------------------------------------------------
Function isPasswordChangeable(
  p_user_name in varchar2)
return boolean
is
begin
  return(fnd_sso_manager.isPasswordChangeable(p_user_name));
end isPasswordChangeable;

-------------------------------------------------------------------
-- Name:        UpdatePassword_WF
-- Description: Calls FND_USER_PKG.UpdateUser
-------------------------------------------------------------------
 Procedure UpdatePassword_WF(itemtype  in varchar2,
                             itemkey   in varchar2,
                             actid     in number,
                             funcmode  in varchar2,
                             resultout in out nocopy varchar2) is

  begin

    if (funcmode = 'RUN') then
      FND_USER_PKG.UpdateUser(
           x_user_name=>
             WF_ENGINE.GetActivityAttrText(itemtype, itemkey, actid,
                                           'X_USER_NAME'),
           x_owner=>'CUST',
           x_unencrypted_password=>
             WF_ENGINE.GetActivityAttrText(itemtype, itemkey, actid,
                                                'X_UNENCRYPTED_PASSWORD',
                                                TRUE),
           x_password_date=>
             WF_ENGINE.GetActivityAttrDate(itemtype, itemkey, actid,
                                                'X_PASSWORD_DATE', TRUE),
           x_password_accesses_left=>
             WF_ENGINE.GetActivityAttrNumber(itemtype, itemkey, actid,
                                                'X_PASSWORD_ACCESSES_LEFT',
                                                TRUE),
         x_password_lifespan_accesses=>
            WF_ENGINE.GetActivityAttrNumber(itemtype, itemkey, actid,
                                                'X_PASSWORD_LIFESPAN_ACCESSES',
                                                TRUE),
           x_password_lifespan_days=>
             WF_ENGINE.GetActivityAttrNumber(itemtype, itemkey, actid,
                                                'X_PASSWORD_LIFESPAN_DAYS',
                                                TRUE));

      resultout := WF_ENGINE.eng_completed || ':' || WF_ENGINE.eng_null;

    else
      resultout := WF_ENGINE.eng_completed || ':' || WF_ENGINE.eng_null;

    end if;

  exception
    when others then
      Wf_Core.Context('FND_WF_STANDARD', 'UpdatePassword', itemtype, itemkey,
                      actid);
      raise;
end;

----------------------------------------------------------------------------
--
-- DERIVE_PERSON_PARTY_ID
--   Derive the person_party_id, given a customer_id and employee_id
-- IN
--   user_name - User name (used for error messages)
--   customer_id - Customer_id
--   employee_id - Employee_id
-- RETURNS
--   person_party_id - Derived party_id
--
Function DERIVE_PERSON_PARTY_ID(
  user_name in varchar2,
  customer_id in number,
  employee_id in number,
  log_exception in varchar2 default 'Y')
return number is
  l_api_name constant varchar2(30) := 'DERIVE_PERSON_PARTY_ID';
  l_employee_id number;
  l_customer_id number;
  l_cust_person_party_id number;
  l_cust_person_party_name varchar2(360);
  l_emp_person_party_id number;
  l_emp_person_party_name varchar2(360);
  l_party_type  varchar2(30);
  l_party_name  varchar2(360);
  l_err_to_raise boolean;
begin
  --  if we have the value cached, just return the cached value.
  if (    (   (z_customer_id = customer_id)
           or (z_customer_id is null and customer_id is null))
      and (   (z_employee_id = employee_id)
           or (z_employee_id is null and employee_id is null))) then
    return z_person_party_id;
  end if;

  l_employee_id := employee_id;
  l_customer_id := customer_id;
  l_cust_person_party_id := NULL;
  l_emp_person_party_id := NULL;

  -- *** Derive party for customer_id ***
  if (l_customer_id is not NULL) then
    -- Get party type of current customer_id
    begin
      FND_OAM_USER_INFO.HZ_PARTY_ID_TO_NAME(l_customer_id,
                                            l_party_name, l_party_type);
    exception
      when no_data_found then
        if (log_exception = 'Y') then
           fnd_message.set_name('FND', 'USER_INVALID_CUSTOMER');
           fnd_message.set_token('USER', user_name);
           fnd_message.set_token('CUSTID', l_customer_id);
           if (fnd_log.LEVEL_EXCEPTION >= fnd_log.g_current_runtime_level) then
            fnd_log.message(FND_LOG.LEVEL_EXCEPTION,
              c_log_head || l_api_name || '.not_in_hz_parties', FALSE);
           end if;
           app_exception.raise_exception;
        else
           return null;
        end if;
    end;

    if (l_party_type = 'PERSON') then
      -- Customer_id is already party, just copy value to party_id
      l_cust_person_party_id := l_customer_id;
    elsif (l_party_type = 'PARTY_RELATIONSHIP') then
      -- This is a relationship party.  Get the person_party
      -- associated with this relationship as the party_id
      begin
        l_cust_person_party_id :=
          FND_OAM_USER_INFO.GET_ORGANIZATION_ID(l_customer_id);
      exception
        when no_data_found then
          if (log_exception = 'Y') then
            fnd_message.set_name('FND', 'USER_INVALID_PARTY_REL');
            fnd_message.set_token('USER', user_name);
            fnd_message.set_token('PNAME', l_party_name);
            fnd_message.set_token('CUSTID', l_customer_id);
            if (fnd_log.LEVEL_EXCEPTION >= fnd_log.g_current_runtime_level) then
              fnd_log.message(FND_LOG.LEVEL_EXCEPTION,
              c_log_head || l_api_name || '.not_in_hz_party_relationships',
              FALSE);
            end if;
            app_exception.raise_exception;
          else
            return null;
          end if;
      end;
    else
      if (log_exception = 'Y') then
        -- Invalid party type, raise error
        fnd_message.set_name('FND', 'USER_INVALID_PARTY_TYPE');
        fnd_message.set_token('USER', user_name);
        fnd_message.set_token('PNAME', l_party_name);
        fnd_message.set_token('PARTYID', l_customer_id);
        fnd_message.set_token('PARTY_TYPE', l_party_type);
        if (fnd_log.LEVEL_EXCEPTION >= fnd_log.g_current_runtime_level) then
          fnd_log.message(FND_LOG.LEVEL_EXCEPTION,
          c_log_head || l_api_name || '.bad_party_type', FALSE);
        end if;
        app_exception.raise_exception;
      else
        return null;
      end if;
    end if;

  end if;

  -- *** Derive party for employee_id ***
  if (l_employee_id is not NULL) then
        begin
     /*
       select party_id
       into l_emp_person_party_id
       from per_all_people_f
       where person_id = l_employee_id
       and trunc(sysdate) between effective_start_date
                          and effective_end_date;
     */

     -- Modified above SQL for bug 3094664

     l_emp_person_party_id := FND_OAM_USER_INFO.GET_PARTY_ID(l_employee_id);
    exception
      when no_data_found then
        if (log_exception = 'Y') then
          fnd_message.set_name('FND', 'USER_INVALID_EMPLOYEE');
          fnd_message.set_token('USER', user_name);
          fnd_message.set_token('EMPID', l_employee_id);
          if (fnd_log.LEVEL_EXCEPTION >= fnd_log.g_current_runtime_level) then
            fnd_log.message(FND_LOG.LEVEL_EXCEPTION,
            c_log_head || l_api_name || '.bad_empid', FALSE);
          end if;
          app_exception.raise_exception;
        else
          return null;
        end if;
    end;
  end if;

  -- Get person_party_id from customer or employee version
  if (l_cust_person_party_id is not null) then
    if (l_emp_person_party_id is not null) then
      -- Both found, check for mismatch
      if (l_cust_person_party_id <> l_emp_person_party_id) then
        if (log_exception = 'Y') then
          begin
          FND_OAM_USER_INFO.HZ_PARTY_ID_TO_NAME(l_cust_person_party_id,
                                                l_cust_person_party_name,
                                                l_party_type);
          exception
            when no_data_found then
              fnd_message.set_name('FND', 'USER_CUST_PARTY_NOT_FOUND');
              fnd_message.set_token('USER', user_name);
              fnd_message.set_token('CUSTID', l_customer_id);
              if (fnd_log.LEVEL_EXCEPTION >=
                                 fnd_log.g_current_runtime_level) then
                fnd_log.message(FND_LOG.LEVEL_EXCEPTION,
                c_log_head || l_api_name || '.cust_emp_mismatch', FALSE);
              end if;
              app_exception.raise_exception;
          end;

          begin
          FND_OAM_USER_INFO.HZ_PARTY_ID_TO_NAME(l_emp_person_party_id,
                                                l_emp_person_party_name,
                                                l_party_type);
          exception
            when no_data_found then
              fnd_message.set_name('FND', 'USER_EMP_PARTY_NOT_FOUND');
              fnd_message.set_token('USER', user_name);
              fnd_message.set_token('EMPID', l_emp_person_party_id);
              if (fnd_log.LEVEL_EXCEPTION >=
                                 fnd_log.g_current_runtime_level) then
                fnd_log.message(FND_LOG.LEVEL_EXCEPTION,
                c_log_head || l_api_name || '.cust_emp_mismatch', FALSE);
              end if;
              app_exception.raise_exception;
          end;

          fnd_message.set_name('FND', 'USER_CUST_EMP_MISMATCH');
          fnd_message.set_token('USER', user_name);
          fnd_message.set_token('CUSTID', l_customer_id);
          fnd_message.set_token('CUSTPARTY', l_cust_person_party_name);
          fnd_message.set_token('EMPID', l_employee_id);
          fnd_message.set_token('EMPPARTY', l_emp_person_party_name);
          if (fnd_log.LEVEL_EXCEPTION >= fnd_log.g_current_runtime_level) then
            fnd_log.message(FND_LOG.LEVEL_EXCEPTION,
            c_log_head || l_api_name || '.cust_emp_mismatch', FALSE);
          end if;
          app_exception.raise_exception;
        else
          return null;
        end if;
      end if;
    end if;
    -- Either no empid, or a matching one, use customer version
    z_person_party_id := l_cust_person_party_id;
  else
    -- Use employee version
    z_person_party_id := l_emp_person_party_id;
  end if;

  -- Save away keys in cache and return
  z_customer_id := customer_id;
  z_employee_id := employee_id;
  return(z_person_party_id);
end DERIVE_PERSON_PARTY_ID;

----------------------------------------------------------------------
--
-- DERIVE_CUSTOMER_EMPLOYEE_ID
--   Update customer and employee ids if person_party_id is changed
-- IN
--   user_name - User name (used for error messages)
--   person_party_id - Party id
-- OUT
--   customer_id - Derived customer id
--   employee_id - Derived employee id
--
Procedure DERIVE_CUSTOMER_EMPLOYEE_ID(
  user_name in varchar2,
  person_party_id in number,
  customer_id out nocopy number,
  employee_id out nocopy number)
is
  l_api_name CONSTANT VARCHAR2(30) := 'DERIVE_CUSTOMER_EMPLOYEE_ID';
  l_person_party_id number;
  l_employee_id number;
  l_customer_id number;
  l_person_party_name varchar2(360);
  l_party_type varchar2(30);
  l_cursorid integer;
  l_blockstr varchar2(1000);
  l_dummy integer;
  l_party_id number;
  l_person_id number(30);
  l_matches varchar2(1);

begin
  l_person_party_id := person_party_id;

  -- if we have the value cached, just return the cached value.
  if (    (   (z_rev_person_party_id = l_person_party_id)
           or (z_rev_person_party_id is NULL and l_person_party_id is NULL)))
    then
       customer_id := z_rev_customer_id;
       employee_id := z_rev_employee_id;
       return;
  end if;

  -- Validate person_party_id is correct type
  if (l_person_party_id is not null) then
    begin
      FND_OAM_USER_INFO.HZ_PARTY_ID_TO_NAME(l_person_party_id,
                                            l_person_party_name,
                                            l_party_type);
    exception
      when no_data_found then
        fnd_message.set_name('FND', 'USER_INVALID_PARTY');
        fnd_message.set_token('USER', user_name);
        fnd_message.set_token('PARTYID', l_person_party_id);
        if (fnd_log.LEVEL_EXCEPTION >= fnd_log.g_current_runtime_level) then
          fnd_log.message(FND_LOG.LEVEL_EXCEPTION,
            c_log_head || l_api_name || '.not_in_hz_parties', FALSE);
        end if;
        app_exception.raise_exception;
    end;
    if (l_party_type <> 'PERSON') then
      fnd_message.set_name('FND', 'USER_INVALID_PARTY_TYPE');
      fnd_message.set_token('USER', user_name);
      fnd_message.set_token('PARTYID', l_person_party_id);
      fnd_message.set_token('PARTY_TYPE', l_party_type);
      if (fnd_log.LEVEL_EXCEPTION >= fnd_log.g_current_runtime_level) then
        fnd_log.message(FND_LOG.LEVEL_EXCEPTION,
        c_log_head || l_api_name || '.bad_party_type', FALSE);
      end if;
      app_exception.raise_exception;
    end if;
  end if;

  -- Set customer_id to new party_id
  l_customer_id := l_person_party_id;

  -- Fix for Bug#3776819 - Derive employee id
  -- Use Dynamic SQL to execute the HR API to derive the person id
  begin
    l_cursorid := dbms_sql.open_cursor;
    l_blockstr :=
              'BEGIN
                hr_tca_utility.get_person_id(p_party_id => :l_party_id, p_person_id => :l_person_id, p_matches => :l_matches);
              END;';

     dbms_sql.parse(l_cursorid, l_blockstr, dbms_sql.v7);

     dbms_sql.bind_variable(l_cursorid, ':l_party_id', l_person_party_id);
     dbms_sql.bind_variable(l_cursorid, ':l_person_id', l_person_id);
     dbms_sql.bind_variable(l_cursorid, ':l_matches', l_matches, 1);

     l_dummy := dbms_sql.execute(l_cursorid);

     dbms_sql.variable_value(l_cursorid, ':l_person_id', l_person_id);
     dbms_sql.variable_value(l_cursorid, ':l_matches', l_matches);
     dbms_sql.close_cursor(l_cursorid);

     -- Set the employee id
     if (l_person_id is not null) then
        l_employee_id := l_person_id;
     else
        -- Clear the employee_id
        l_employee_id := null;
     end if;

    -- Clear the employee_id
    --l_employee_id := null;

  exception
      when others then
        l_employee_id := null;
        dbms_sql.close_cursor(l_cursorid);
  end;

    -- Return
    customer_id := l_customer_id;
    employee_id := l_employee_id;

     -- Cache my new values
    z_rev_person_party_id := l_person_party_id;
    z_rev_customer_id := l_customer_id;
    z_rev_employee_id := l_employee_id;

end DERIVE_CUSTOMER_EMPLOYEE_ID;

----------------------------------------------------------------------------
--
-- EnableUser (PUBLIC)
--   Sets the start_date and end_date as requested. By default, the
--   start_date will be set to sysdate and end_date to null.
--   This is to enable that user.
--   You can log in as this user from now.
--   If username is not valid, exception raised with error message.
--
-- Usage example in pl/sql
--   begin fnd_user_pkg.enableuser('SCOTT'); end;
--   begin fnd_user_pkg.enableuser('SCOTT', sysdate+1, sysdate+30); end;
--
-- Input (Mandatory)
--  username:       User Name
-- Input (Non-Mandatory)
--  start_date:     Start Date
--  end_date:       End Date
--
procedure EnableUser(username varchar2,
                     start_date date default sysdate,
                     end_date date default fnd_user_pkg.null_date)  is
begin
  fnd_user_pkg.UpdateUser(x_user_name => EnableUser.username,
                          x_owner => NULL,
                          x_start_date => EnableUser.start_date,
                          x_end_date  => EnableUser.end_date);
end EnableUser;


----------------------------------------------------------------------------
--
-- CreatePendingUser (PUBLIC)
--   Create a user whose start_date and end_date = FND_API.G_MISS_DATE as
--   a pending user.
--   Pending user is created when a user registers a user account through
--   UMX with an aproval process.
--
--
-- Usage example in pl/sql
--   begin fnd_user_pkg.creatependinguser('SCOTT', 'SEED', 'welcome'); end;
--   begin fnd_user_pkg.creatependinguser('SCOTT', 'SEED'); end;
--
-- Input (Mandatory)
--  x_user_name:             User Name
--  x_owner:                 'SEED' or 'CUST'(customer)
--
function CreatePendingUser(
  x_user_name                  in varchar2,
  x_owner                      in varchar2,
  x_unencrypted_password       in varchar2 default null,
  x_session_number             in number default 0,
  x_description                in varchar2 default null,
  x_password_date              in date default null,
  x_password_accesses_left     in number default null,
  x_password_lifespan_accesses in number default null,
  x_password_lifespan_days     in number default null,
  x_email_address              in varchar2 default null,
  x_fax                        in varchar2 default null,
  x_person_party_id            in number default null)  return number
is
  uid number;
begin
  uid := fnd_user_pkg.CreateUserIdParty(
    x_user_name,
    x_owner,
    x_unencrypted_password,
    x_session_number,
    FND_API.G_MISS_DATE,
    FND_API.G_MISS_DATE,
    null,
    x_description,
    x_password_date,
    x_password_accesses_left,
    x_password_lifespan_accesses,
    x_password_lifespan_days,
    x_email_address,
    x_fax,
    x_person_party_id);
  return(uid);


end CreatePendingUser;


----------------------------------------------------------------------------
--
-- RemovePendingUser (PUBLIC)
--   Delete this user from fnd_user table only if this is a pending user.
--   If this is not a valid username or is not a pending user, raise error.
--   Pending user is created when a user registers a user account through
--   UMX with an aproval process.
--
-- Usage example in pl/sql
--   begin fnd_user_pkg.removependinguser('SCOTT'); end;
--
-- Input (Mandatory)
--  username:       User Name
--
procedure RemovePendingUser(username varchar2) is
  l_user_id number;
  retval pls_integer;
  l_user_guid raw(16);
begin

   -- Added for Function Security Cache Invalidation
   -- RSHEH: Need to have exception trapping for no_data_found exception
   begin
   select user_id, user_guid
   into l_user_id, l_user_guid
   from fnd_user
   where user_name = upper(username)
   and to_char(start_date) = to_char(FND_API.G_MISS_DATE)
   and to_char(end_date) = to_char(FND_API.G_MISS_DATE);

   exception
     when no_data_found then
     fnd_message.set_name('FND', 'FND_INVALID_USER');
     fnd_message.set_token('USER_NAME', username);
     app_exception.raise_exception;
   end;

  -- Bug 4318754. Synch up with SSO
  if (l_user_guid is not null) then
    begin
    fnd_ldap_wrapper.delete_user(l_user_guid, retval);
    if (retval <> fnd_ldap_wrapper.G_SUCCESS) then
        app_exception.raise_exception;
    end if;
    exception
      when others then
        app_exception.raise_exception;
    end;
  end if;

   -- Only allow to delete a PENDING user
   delete from fnd_user
   where user_name = upper(username)
   and to_char(start_date) = to_char(FND_API.G_MISS_DATE)
   and to_char(end_date) = to_char(FND_API.G_MISS_DATE);

   if (sql%rowcount = 0) then
     fnd_message.set_name('FND', 'FND_INVALID_USER');
     fnd_message.set_token('USER_NAME', username);
     app_exception.raise_exception;
   else
    -- Added for Function Security Cache Invalidation
    fnd_function_security_cache.delete_user(l_user_id);
   end if;

end RemovePendingUser;

----------------------------------------------------------------------------
--
-- AssignPartyToUser (PUBLIC)
--   Assign a TCA party to a given user
--
-- Usage example in pl/sql
--   begin fnd_user_pkg.assignpartytouser('SCOTT', 1001); end;
--
-- Input (Mandatory)
--  x_user_name:       User Name
--  x_party_id:        Party Name Id
--
procedure AssignPartyToUser(
  x_user_name                  in varchar2,
  x_party_id                   in number) is
pid number;
begin

--07/03/03: party_name in table hz_parties is not unique. Therefore, change
--the API to take party_id instead of party_name.
/*
 -- Get party id
  begin
    select party_id
    into pid
    from hz_parties
    where upper(party_name) = upper(x_party);
  exception
    when no_data_found then
    fnd_message.set_name('FND', 'FND_INVALID_PARTY');
    fnd_message.set_token('PARTY_NAME', x_party);
    app_exception.raise_exception;
  end;

  fnd_user_pkg.UpdateUserParty(x_user_name => x_user_name,
                               x_owner => 'SEED',
                               x_person_party_id => pid);
*/

  fnd_user_pkg.UpdateUserParty(x_user_name => x_user_name,
                               x_owner => 'SEED',
                               x_person_party_id => x_party_id);

end AssignPartyToUser;

-- Internal. Called by change_user_name and the two parameters
-- ldap_wrapper_change_user_name.
procedure ldap_wrapper_change_user_name(x_user_guid in raw,
                                        x_old_user_name in varchar2,
                                        x_new_user_name in varchar2) is

  l_result number;
  reason varchar2(2000);
begin

  l_result := null;

  fnd_ldap_wrapper.change_user_name(x_user_guid, x_old_user_name,
                                    x_new_user_name, l_result);
  if (l_result <> fnd_ldap_wrapper.G_SUCCESS) then
    reason := fnd_message.get();
    fnd_message.set_name('FND', 'LDAP_WRAPPER_CHANGE_USER_FAIL');
    fnd_message.set_token('REASON', reason);
      app_exception.raise_exception;
  end if;
exception
  when others then
    fnd_message.set_name('FND', 'LDAP_WRAPPER_CHANGE_USER_FAIL');
    fnd_message.set_token('REASON', sqlerrm);
    app_exception.raise_exception;
end;

-- begin bug 2504562

----------------------------------------------------------------------------
--
-- change_user_name (PUBLIC)
--   This api changes username, deals with encryption changes and
--   update foreign keys that were using the old username.
--
-- Usage example in pl/sql
--   begin fnd_user_pkg.change_user_name('SOCTT', 'SCOTT'); end;
--
-- Input (Mandantory)
--   x_old_user_name:     Old User Name
--   x_new_user_name:     New User Name
--
procedure change_user_name(x_old_user_name            in varchar2,
                           x_new_user_name            in varchar2,
                           x_change_source            in number default null) is
  newpass varchar2(100);
  dummy number(1);
  ret boolean;
  l_user_id number;
  l_user_guid raw(16);
  l_api_name  CONSTANT varchar2(30) := 'change_user_name';
  tmpbuf varchar2(240);
  reason varchar2(240);
  encpwd varchar2(100);
  l_parameter_list wf_parameter_list_t;  -- bug 8227171 WF event parameter list

begin
  -- 7311525 do not allow the username of GUEST to be changed
  if (upper(x_old_user_name) = 'GUEST') then
     fnd_message.set_name('FND', 'SECURITY-GUEST USERNAME');
     app_exception.raise_exception;
  end if;

  -- ensure x_old_user_name exists in fnd_user before we proceed
  select USER_GUID, encrypted_user_password
  into l_user_guid, encpwd
  from fnd_user
  where user_name = upper(x_old_user_name);

  begin
    -- ensure x_new_user_name doesn't already exist in fnd_user
    select null into dummy from fnd_user
      where user_name = upper(x_new_user_name);
    fnd_message.set_name('FND', 'SECURITY-DUPLICATE USER');
    app_exception.raise_exception;
  exception
    when no_data_found then
      -- bug 8227171 change_user_name
      validate_user_name(x_new_user_name);

      -- Start bug 5866089 just adding the following if check
      if (x_change_source is null) then
		-- Start bug 4625235
		-- Move ldap_wrapper synch call to here before we do FND user update
		begin
		  tmpbuf := 'Calling ldap_wrapper_change_user_name to change '||
					 x_old_user_name|| ' to '|| x_new_user_name;
		  if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
		  fnd_log.string(FND_LOG.LEVEL_STATEMENT, C_LOG_HEAD || l_api_name || '.',
					 tmpbuf);
		  end if;
		  if (l_user_guid is not null) then
		  ldap_wrapper_change_user_name(l_user_guid, upper(x_old_user_name),
									  upper(x_new_user_name));
		  end if;
		exception
		when others then
		  app_exception.raise_exception;
		end;
        -- end bug 4625235

      end if;
      -- end bug 5866089

      -- capture x_old_user_name in package variable g_old_user_name
      g_old_user_name := upper(x_old_user_name);

      -- change old username to new username
      update fnd_user set user_name = upper(x_new_user_name)
        where user_name = upper(x_old_user_name);

      -- This code was moved before updating FND_USER due to a change in
      -- FND_WEB_SEC.change_password having an autonomous transaction pragma.
      -- Password changes failed due to said change.  See bug 2426407.
      -- handle password encryption with new username
      tmpbuf := 'Recrypting '||x_new_user_name|| ' password';
      if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
      fnd_log.string(FND_LOG.LEVEL_STATEMENT, C_LOG_HEAD || l_api_name || '.',
                   tmpbuf);
      end if;

      -- Only have to do password reencryption if is not EXTERNAL, INVALID or Hash mode
      if ( (encpwd not in ('EXTERNAL', 'INVALID')) and (substr(encpwd, 1, 1) <> 'X') ) then
        newpass := fnd_user_pkg.GetReEncryptedPassword(x_new_user_name, 'NEWKEY');
        ret := fnd_user_pkg.SetReEncryptedPassword(x_new_user_name,newpass,'NEWKEY');
      end if;

      tmpbuf := 'updating fnd_user for new user_name '||x_new_user_name;
      if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
      fnd_log.string(FND_LOG.LEVEL_STATEMENT, C_LOG_HEAD || l_api_name || '.',
                   tmpbuf);
      end if;

      -- In the below WHERE clause, 'upper' is added, otherwise if the
      --  x_new_user_name contains any small case letters, it will enter into
      -- 'NO-DATA-FOUND' (since in the above statement, UPPER(x_new_user_name)
      --  is stored) exception and returns FND_CHANGE_USER_FAILED error.
      -- Added for Function Security Cache Invalidation
      select user_id
      into l_user_id
      from fnd_user
      where user_name = upper(x_new_user_name);

      fnd_function_security_cache.update_user(l_user_id);

      -- propagate username change to WF and entity mgr
      tmpbuf := 'Start calling fnd_user_pkg.user_synch('||x_new_user_name||')';
      if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
      fnd_log.string(FND_LOG.LEVEL_STATEMENT, C_LOG_HEAD || l_api_name || '.',
                   tmpbuf);
      end if;
      begin
      fnd_user_pkg.user_synch(upper(x_new_user_name));
      exception
        when others then
          reason := fnd_message.get;
          fnd_message.set_name('FND', 'FND_FAILED_WF_USER_SYNCH');
          fnd_message.set_token('OLD_NAME', x_old_user_name);
          fnd_message.set_token('NEW_NAME', x_new_user_name);
          fnd_message.set_token('REASON', reason);
          app_exception.raise_exception;
      end;

      -- Added for bug 4676568
      -- A temp fix to update fnd_grants.grantee_key
      -- No need to check SQL%NOTFOUND because if there is no data to be
      -- updated in fnd_grants.grantee_key, that is perfectly fine.
      update fnd_grants
      set grantee_key = x_new_user_name
      where grantee_key = x_old_user_name
      and grantee_type = 'USER';

      tmpbuf := 'Finished fnd_user_pkg.user_synch';
      if (fnd_log.LEVEL_STATEMENT >= fnd_log.g_current_runtime_level) then
      fnd_log.string(FND_LOG.LEVEL_STATEMENT, C_LOG_HEAD || l_api_name || '.',
                   tmpbuf);
      end if;

      -- bug 8227171 change_user_name
      -- Raise the WF event oracle.apps.fnd.post.username.change
      begin
        wf_event.AddParameterToList('OLD_USERNAME', x_old_user_name,
l_parameter_list);
        wf_event.raise3(p_event_name =>'oracle.apps.fnd.post.username.change',
                  p_event_key => x_new_user_name,
                  p_event_data => NULL,
                  p_parameter_list => l_parameter_list,
                  p_send_date => Sysdate);

      exception
         when others then
          reason := fnd_message.get_encoded;
          if (reason is not null) then
            fnd_message.set_encoded(reason);
          else
            fnd_message.set_name('FND', 'FND_RAISE_EVENT_FAILED');
          end if;
          app_exception.raise_exception;
      end;
  end;

exception
  when no_data_found then
    -- old username does not exist in fnd_user
    fnd_message.set_name('FND', 'FND_CHANGE_USER_FAILED');
    fnd_message.set_token('USER_NAME', x_old_user_name);
    app_exception.raise_exception;


end change_user_name;

----------------------------------------------------------------------------
--
-- set_old_user_name (PUBLIC)
--   This function is called from Forms to set the global variable,
--   g_old_user_name since this cannot be set directly from Forms.
--   This function returns a number which can be used to check for success
--   from Forms.
--
-- Usage example in pl/sql
--   declare
--     retval number := null;
--   begin retval := fnd_user_pkg.set_old_user_name('SOCTT'); end;
--
-- Input (Mandantory)
--   x_old_user_name:     Old User Name
--
function set_old_user_name(x_old_user_name in varchar2) return number is
  retval number := null;
begin
  g_old_user_name := x_old_user_name;
  if (g_old_user_name is not null) then
        retval := 1;
  else
        retval := 0;
  end if;
  return retval;
end;

-- end bug 2504562

----------------------------------------------------------------------------
-- MergePartyId (PUBLIC)
--   This is the procedure being called during the Party Merge.
--   FND_USER.MergePartyId() has been registered in Party Merge Data Dict.
--   The input/output arguments format matches the document PartyMergeDD.doc.
--   The goal is to fix the person_party_id in fnd_user table to point to the
--   same party when two similar parties are begin merged.
--
-- Usage example in pl/sql
--   This procedure should only be called from the PartyMerge utility.
--
procedure MergePartyId(p_entity_name in varchar2,
                       p_from_id in number,
                       p_to_id in out nocopy number,
                       p_from_fk_id in number,
                       p_to_fk_id in number,
                       p_parent_entity_name in varchar2,
                       p_batch_id in number,
                       p_batch_party_id in number,
                       p_return_status in out nocopy varchar2) is
begin
  p_return_status := FND_API.G_RET_STS_SUCCESS;

  if (p_from_fk_id <> p_to_fk_id) then

    update fnd_user
    set person_party_id = p_to_fk_id
    where person_party_id = p_from_fk_id;

    -- Added for Function Security Cache Invalidation
    fnd_function_security_cache.update_user(p_from_id);

  end if;

end MergePartyId;

-- Public function
-- Make sure that the user_name does not contain invalid character.
-- For now: We only care about '/' and ':' because they are known problem.
-- 01/19/05: we now have more invalid characters info from bug 4116239, so
--           I am adding more characters.
-- Rewrite later: checking for any non-printable character.
--                make sure multibyte character is ok.
procedure validate_user_name(x_user_name in varchar2) is
msg varchar2(2000);
uname varchar2(100);
begin
  if (x_user_name is null or
      rtrim(x_user_name, ' ') is null) then
    fnd_message.set_name('FND', 'INVALID_USER_NAME_NULL');
    app_exception.raise_exception;
  elsif (rtrim(x_user_name, ' ') <> x_user_name or
         ltrim(x_user_name, ' ') <> x_user_name) then
    fnd_message.set_name('FND', 'INVALID_USER_NAME_SPACE');
    app_exception.raise_exception;
  elsif (instr(x_user_name, '/') > 0 OR
      instr(x_user_name, '"') > 0 OR
      instr(x_user_name, '(') > 0 OR
      instr(x_user_name, ')') > 0 OR
      instr(x_user_name, '*') > 0 OR
      instr(x_user_name, '+') > 0 OR
      instr(x_user_name, ',') > 0 OR
      instr(x_user_name, ';') > 0 OR
      instr(x_user_name, '<') > 0 OR
      instr(x_user_name, '>') > 0 OR
      instr(x_user_name, '\') > 0 OR
      instr(x_user_name, '~') > 0 OR
      instr(x_user_name, ':') > 0 ) then
    fnd_message.set_name('FND', 'INVALID_USER_NAME');
    fnd_message.set_token('UNAME', x_user_name);
    app_exception.raise_exception;
  else
    -- we pass the generic validation, it is time to call any
    -- customized user name validation if there is any.
    begin
      wf_event.raise(p_event_name => 'oracle.apps.fnd.user.name.validate',
                     p_event_key => x_user_name,
                     p_event_data => NULL,
                     p_parameters => NULL,
                     p_send_date => Sysdate);
    exception
      when others then
        msg := fnd_message.get_encoded;
        if (msg is not null) then
          fnd_message.set_encoded(msg);
        else
          fnd_message.set_name('FND', 'FND_CUST_UNAME_VALIDATE_FAILED');
        end if;
        app_exception.raise_exception;
    end;
    -- past generic and customized validation
  end if;

end validate_user_name;

--
-- CreateUser (PUBLIC)
--
--   Bug#3904339 - SSO: Add user_guid parameter in fnd_user_pkg apis
--   Overloaded procedure to create user
--   Accepts  User GUID as a parameter in addition to the other parameters
--
--
procedure CreateUser (
  x_user_name                  in varchar2,
  x_owner                      in varchar2,
  x_unencrypted_password       in varchar2 default null,
  x_session_number             in number default 0,
  x_start_date                 in date default sysdate,
  x_end_date                   in date default null,
  x_last_logon_date            in date default null,
  x_description                in varchar2 default null,
  x_password_date              in date default null,
  x_password_accesses_left     in number default null,
  x_password_lifespan_accesses in number default null,
  x_password_lifespan_days     in number default null,
  x_employee_id                in number default null,
  x_email_address              in varchar2 default null,
  x_fax                        in varchar2 default null,
  x_customer_id                in number default null,
  x_supplier_id                in number default null,
  x_user_guid                  in raw,
  x_change_source              in number default null)
is
  l_result number;
begin
  l_result := fnd_user_pkg.CreateUserId(
    x_user_name,
    x_owner,
    x_unencrypted_password,
    x_session_number,
    x_start_date,
    x_end_date,
    x_last_logon_date,
    x_description,
    x_password_date,
    x_password_accesses_left,
    x_password_lifespan_accesses,
    x_password_lifespan_days,
    x_employee_id,
    x_email_address,
    x_fax,
    x_customer_id,
    x_supplier_id,
    x_user_guid,
    x_change_source);
end CreateUser;

----------------------------------------------------------------------
--
-- CreateUserId (PUBLIC)
--
--   Bug#3904339 - SSO: Add user_guid parameter in fnd_user_pkg apis
--   Overloaded procedure to create user
--   Accepts  User GUID as a parameter in addition to the other parameters
--
-- Returns
--   User_id of created user
--

function CreateUserId (
  x_user_name                  in varchar2,
  x_owner                      in varchar2,
  x_unencrypted_password       in varchar2 default null,
  x_session_number             in number default 0,
  x_start_date                 in date default sysdate,
  x_end_date                   in date default null,
  x_last_logon_date            in date default null,
  x_description                in varchar2 default null,
  x_password_date              in date default null,
  x_password_accesses_left     in number default null,
  x_password_lifespan_accesses in number default null,
  x_password_lifespan_days     in number default null,
  x_employee_id                in number default null,
  x_email_address              in varchar2 default null,
  x_fax                        in varchar2 default null,
  x_customer_id                in number default null,
  x_supplier_id                in number default null,
  x_user_guid                  in raw,
  x_change_source              in number default null)
return number is
begin
  return CreateUserIdInternal(
    x_user_name => x_user_name,
    x_owner => x_owner,
    x_unencrypted_password => x_unencrypted_password,
    x_session_number => x_session_number,
    x_start_date => x_start_date,
    x_end_date => x_end_date,
    x_last_logon_date => x_last_logon_date,
    x_description => x_description,
    x_password_date => x_password_date,
    x_password_accesses_left => x_password_accesses_left,
    x_password_lifespan_accesses => x_password_lifespan_accesses,
    x_password_lifespan_days => x_password_lifespan_days,
    x_employee_id => x_employee_id,
    x_email_address => x_email_address,
    x_fax => x_fax,
    x_customer_id => x_customer_id,
    x_supplier_id => x_supplier_id,
    x_person_party_id => null,
    x_mode => 'EMPLOYEE',
    x_user_guid => x_user_guid,
    x_change_source => x_change_source);
end CreateUserId;

----------------------------------------------------------------------
--
-- UpdateUser (Public)
--
--   Bug#3904339 - SSO: Add user_guid parameter in fnd_user_pkg apis
--   Overloaded procedure to update user
--   Accepts  User GUID as a parameter in addition to the other parameters
--
procedure UpdateUser (
  x_user_name                  in varchar2,
  x_owner                      in varchar2,
  x_unencrypted_password       in varchar2 default null,
  x_session_number             in number default null,
  x_start_date                 in date default null,
  x_end_date                   in date default null,
  x_last_logon_date            in date default null,
  x_description                in varchar2 default null,
  x_password_date              in date default null,
  x_password_accesses_left     in number default null,
  x_password_lifespan_accesses in number default null,
  x_password_lifespan_days     in number default null,
  x_employee_id                in number default null,
  x_email_address              in varchar2 default null,
  x_fax                        in varchar2 default null,
  x_customer_id                in number default null,
  x_supplier_id                in number default null,
  x_old_password               in varchar2 default null,
  x_user_guid                  in raw,
  x_change_source              in number default null)
is
begin
  UpdateUserInternal(
    x_user_name => x_user_name,
    x_owner => x_owner,
    x_unencrypted_password => x_unencrypted_password,
    x_session_number => x_session_number,
    x_start_date => x_start_date,
    x_end_date => x_end_date,
    x_last_logon_date => x_last_logon_date,
    x_description => x_description,
    x_password_date => x_password_date,
    x_password_accesses_left => x_password_accesses_left,
    x_password_lifespan_accesses => x_password_lifespan_accesses,
    x_password_lifespan_days => x_password_lifespan_days,
    x_employee_id => x_employee_id,
    x_email_address => x_email_address,
    x_fax => x_fax,
    x_customer_id => x_customer_id,
    x_supplier_id => x_supplier_id,
    x_person_party_id => null,
    x_old_password => x_old_password,
    x_mode => 'EMPLOYEE',
    x_user_guid => x_user_guid,
    x_change_source => x_change_source);
end UpdateUser;

----------------------------------------------------------------------
-- userExists (Public)
--
-- This function checks if the user exists and returnes 'True' or 'False'
-- Input (Mandatory)
--  username: User Name

function userExists(x_user_name in varchar2) return boolean is
 dummy number;
begin
 select 1 into dummy from fnd_user
 where user_name = upper(x_user_name);
 return TRUE;
exception
 when no_data_found then
 return FALSE;
end userExists;

-- begin bug 4318754, 4424225
----------------------------------------------------------------------------
--
-- TestUserName (PUBLIC)
--   This api test whether a username exists in FND and/or in OID.
--
-- Usage example in pl/sql
--   declare ret number;
--   begin ret := fnd_user_pkg.testusername('SOCTT'); end;
--
-- Input (Mandantory)
--   x_user_name:     User Name that you want to test
--
-- Output
--   USER_INVALID_NAME : User name is not valid
--   USER_OK_CREATE : User does not exist in either FND or OID
--   USER_EXISTS_IN_FND : User exists in FND
--   USER_SYNCH : User exists in OID and next time when this user gets created
--                in FND, the two will be synched together.
--   USER_EXISTS_NO_LINK_ALLOWED: User exists in OID and no synching allowed.
--
function TestUserName(x_user_name in varchar2) return pls_integer is
  pf varchar2(1);
  retval pls_integer;
begin

  pf := 'N';

  begin
    fnd_user_pkg.validate_user_name(x_user_name);
  exception
    when others then
    -- error message is already on the stack from validate_user_name()
    -- Either a generic validation error message or specific message from
    -- the subscriber of "fnd.user.name.validate"
    return(USER_INVALID_NAME);
  end;

  if (fnd_user_pkg.userExists(x_user_name)) then
    fnd_message.set_name('FND', 'FND_USER_EXISTS_IN_FND');
    return(USER_EXISTS_IN_FND);
  else
    begin
       retval := fnd_ldap_wrapper.user_exists(x_user_name);
    exception
      when others then
        app_exception.raise_exception;
    end;

    if (retval = 1) then
      -- The above check return that user exists in oid.
      fnd_profile.get('APPS_SSO_LINK_SAME_NAMES', pf);

      if(pf = 'Y') then
        fnd_message.set_name('FND', 'FND_USER_SYNCHED');
        fnd_message.set_token('USER_NAME', x_user_name);
        return(USER_SYNCHED);
        -- next time when this user gets created in fnd, it will be
        -- linked to each other.
      else
        fnd_message.set_name('FND', 'FND_USER_EXISTS_NO_LINK');
        return(USER_EXISTS_NO_LINK_ALLOWED);
      end if;
    else
      return(USER_OK_CREATE);
    end if;
  end if;

end TestUserName;


----------------------------------------------------------------------------
--
-- set_old_person_party_id (PUBLIC)
--   This function is called from Forms to set the global variable,
--   g_old_person_party_id since this cannot be set directly from Forms.
--   This function returns a number which can be used to check for success
--   from Forms.
--
-- Usage example in pl/sql
--   declare
--     retval number := null;
--   begin retval := fnd_user_pkg.set_old_person_party_id(12345); end;
--
-- Input (Mandantory)
--   x_old_person_party_id:     Old Person Party Id
--
function set_old_person_party_id(x_old_person_party_id in varchar2)
return number is
  retval number := null;
begin
  g_old_person_party_id := x_old_person_party_id;
  if (g_old_person_party_id is not null) then
        retval := 1;
  else
        retval := 0;
  end if;
  return retval;
end;


----------------------------------------------------------------------------
--
-- set_old_user_guid (PUBLIC)
--   This function is called from Forms to set the global variable,
--   g_old_user_guid since this cannot be set directly from Forms.
--   This function returns a number which can be used to check for success
--   from Forms.
--
-- Usage example in pl/sql
--   declare
--     retval number := null;
--     guid raw(16);
--   begin
--     guid := 'F9374D4B80AB1A86E034080020B2612C';
--     retval := fnd_user_pkg.set_old_user_guid(guid); end;
--
-- Input (Mandantory)
--   x_old_user_guid:     Old USER GUID
--
function set_old_user_guid(x_old_user_guid in raw)
return number is
  retval number := null;
begin
  g_old_user_guid := x_old_user_guid;
  if (g_old_person_party_id is not null) then
        retval := 1;
  else
        retval := 0;
  end if;
  return retval;
end;

-- Internal
function ldap_wrp_update_user_helper(x_user_name in varchar2,
                                   x_unencrypted_password in varchar2,
                                   x_start_date in date,
                                   x_end_date in date,
                                   x_description in varchar2,
                                   x_email_address in varchar2,
                                   x_fax in varchar2,
                                   x_expire_pwd in pls_integer) return varchar2
is
    l_user_guid raw(16);
    l_result number;
    reason varchar2(2000);
    l_pwd varchar2(1000);
    pwdCaseOpt varchar2(1);
    l_pwd_ret varchar2(1000);
    userid number; -- bug 5162136
	isOverrideFuncAssigned	boolean; /* 7043484 */
begin

  l_user_guid := null;
  l_result := null;
  l_pwd_ret := null;
  userid := null;

  -- bug 5162136 Obtain the user_id for later use
  select user_guid, user_id into l_user_guid, userid
  from fnd_user
  where user_name = x_user_name;

  if (l_user_guid is null) then
    return null;
  end if;

  -- Only check the profile and expiration if password is not null
  l_pwd := x_unencrypted_password;
  if (x_unencrypted_password is not null) then
    -- Bug 5161497
    -- If profile is not set or case insensitive, then password passed to
    -- sso/oid should be lower. This has been discussed with SSO to
    -- reach agreement because entering lower case is more common for case
    -- insensitive mode.
    pwdCaseOpt := null;
    -- 5162136 SIGNON_PASSWORD_CASE Profile Check
    -- Get the profile value at the user level for the affected user and
    -- encrypt accordingly.  If not set at the user level, this will default to
    -- the site level profile value.
    /* Code change for bug 7043484 */
    isOverrideFuncAssigned := fnd_function.test('OVERRIDE_PASSWORD_POLICY_PERM','N');
    if(isOverrideFuncAssigned = true) then
      pwdCaseOpt := fnd_profile.value('SIGNON_PASSWORD_CASE');
	else
	  pwdCaseOpt := fnd_profile.value_specific('SIGNON_PASSWORD_CASE', userid);
	end if;
    if (pwdCaseOpt is null) or (pwdCaseOpt = '1') then
      l_pwd := lower(x_unencrypted_password);
    end if;
  end if; -- End if x_unencrypted_password is not null

  begin

    fnd_ldap_wrapper.update_user(l_user_guid, x_user_name,
          l_pwd, x_start_date, x_end_date, x_description,
          x_email_address, x_fax, x_expire_pwd, l_pwd_ret, l_result);

    if (l_result <> fnd_ldap_wrapper.G_SUCCESS) then
      reason := fnd_message.get();
      fnd_message.set_name('FND', 'LDAP_WRAPPER_UPDATE_USER_FAIL');
      fnd_message.set_token('USER_NAME', x_user_name);
      fnd_message.set_token('REASON', reason);
      app_exception.raise_exception;
    -- Bug 5605892
    end if;

    -- Bug 5605892
    if (l_pwd_ret = fnd_web_sec.external_pwd) then
      return('EXTERNAL');
    else
      return(null);
    end if;
  exception
    when others then
      fnd_message.set_name('FND', 'LDAP_WRAPPER_UPDATE_USER_FAIL');
      fnd_message.set_token('USER_NAME', x_user_name);
      fnd_message.set_token('REASON', sqlerrm);
     app_exception.raise_exception;
  end;
exception
  when others then
    app_exception.raise_exception;
end;

----------------------------------------------------------------------------
--
-- ldap_wrapper_update_user (PUBLIC)
--   This is called by the fnd_user_pkg and fnd_web_sec
--   It serves as a helper routine to call fnd_ldap_wrapper.update_user
--   when we need to synch the user update to OID.
-- Note
--   Please note that even this is public procedure, it does not mean for
--   other public usage. This is mainly created as a helper routine to
--   service the user form and the user package.
procedure ldap_wrapper_update_user(x_user_name in varchar2,
                                   x_unencrypted_password in varchar2,
                                   x_start_date in date,
                                   x_end_date in date,
                                   x_description in varchar2,
                                   x_email_address in varchar2,
                                   x_fax in varchar2,
                                   x_expire_pwd in pls_integer default 0) is
    l_pwd_ret varchar2(100);
begin

    l_pwd_ret := null;

    l_pwd_ret := ldap_wrp_update_user_helper(x_user_name,
          x_unencrypted_password, x_start_date, x_end_date, x_description,
          x_email_address, x_fax, x_expire_pwd);
    if (l_pwd_ret is not null) then
      -- If the return password from ldap is not null, that means ldap
      -- is informing us that this user is externally managed so we need
      -- to update the password to EXTERNAL.
      update fnd_user
      set encrypted_foundation_password = l_pwd_ret,
          encrypted_user_password = l_pwd_ret
      where user_name = upper(x_user_name);
    end if;

end;


--
-- ldap_wrapper_create_user (PUBLIC)
--   This is called by user form and the fnd_user_pkg.
--   It serves as a helper routine to call fnd_ldap_wrapper.create_user
--   when we need to synch that new FND user to OID.
--   It also takes care of updating fnd_user with the user_guid and oid_pwd
--   coming back from ldap_wrapper layer.
-- Note
--   Please note that even this is public procedure, it does not mean for
--   other public usage. This is mainly created as a helper routine to
--   service the user form and the user package.

procedure ldap_wrapper_create_user(x_user_name in varchar2,
                                   x_unencrypted_password in varchar2,
                                   x_start_date in date,
                                   x_end_date in date,
                                   x_description in varchar2,
                                   x_email_address in varchar2,
                                   x_fax in varchar2,
                                   x_expire_pwd in pls_integer default 0) is
l_user_guid raw(16);
l_oid_pwd varchar2(30);
ret varchar2(1);
reason varchar2(2000);

begin

  l_user_guid := null;
  l_oid_pwd := null;
  ldap_wrapper_create_user(x_user_name, x_unencrypted_password,
                           x_start_date, x_end_date,
                           x_description,x_email_address,x_fax,x_expire_pwd,
                           l_user_guid, l_oid_pwd);
  if (l_user_guid is not null) then
    update fnd_user
    set user_guid = l_user_guid
    where user_name = x_user_name;
  end if;

  if (l_oid_pwd = fnd_web_sec.external_pwd) then
    -- Add third argument to not use autonomous transaction when chaning
    -- passowrd. This is for bug 5087728
    ret := fnd_web_sec.change_password(x_user_name, l_oid_pwd, FALSE);
    if (ret = 'N') then
      reason := fnd_message.get();
      fnd_message.set_name('FND', 'FND_CHANGE_PASSWORD_FAILED');
      fnd_message.set_token('USER_NAME', X_USER_NAME);
      fnd_message.set_token('REASON', reason);
      app_exception.raise_exception;
    end if;
  end if;

exception
  when others then
    app_exception.raise_exception;
end;

-- end bug 4318754

--
-- ldap_wrapper_change_user_name (PUBLIC)
--   This is called by user form. When there is user name changed inside
--   User form, we need to synch with ldap.
--
-- Note
--   Please note that even this is public procedure, it does not mean for
--   other public usage. This is mainly created as a helper routine to
--   service the user form and the user package.
procedure ldap_wrapper_change_user_name(x_old_user_name in varchar2,
                                        x_new_user_name in varchar2) is

  l_user_guid raw(16);
begin

  l_user_guid := null;

  select user_guid
  into l_user_guid
  from fnd_user
  where user_name = x_old_user_name;

  if (l_user_guid is not null) then
  ldap_wrapper_change_user_name(l_user_guid, x_old_user_name, x_new_user_name);
  end if;

exception
  when others then
    app_exception.raise_exception;
end;

----------------------------------------------------------------------------
--
-- form_ldap_wrapper_update_user (PUBLIC)
--   This is called by user form.
--   It serves as a helper routine to call fnd_ldap_wrapper.update_user
--   when we need to synch the user update to OID.
-- Note
--   Please note that even this is public procedure, it does not mean for
--   other public usage. This is mainly created as a helper routine to
--   service the user form.
procedure form_ldap_wrapper_update_user(x_user_name in varchar2,
                                        x_unencrypted_password in varchar2,
                                        x_start_date in date,
                                        x_end_date in date,
                                        x_description in varchar2,
                                        x_email_address in varchar2,
                                        x_fax in varchar2,
                                        x_out_pwd in out nocopy varchar2) is
    l_end_date date;
    l_description varchar2(240);
    l_email_address varchar2(240);
    l_fax varchar2(80);
    l_pwd_ret varchar2(1000);
begin

  -- Bug 5161134
  -- If is from Form, we can not use our rule about null means no change.
  -- If form passs in null value, that means change it to null.
  if (x_end_date is null) then
    l_end_date := fnd_user_pkg.null_date;
  else
    l_end_date := x_end_date;
  end if;

  if (x_description is null) then
    l_description := fnd_user_pkg.null_char;
  else
    l_description := x_description;
  end if;

  if (x_email_address is null) then
    l_email_address := fnd_user_pkg.null_char;
  else
    l_email_address := x_email_address;
  end if;

  if (x_fax is null) then
    l_fax := fnd_user_pkg.null_char;
  else
    l_fax := x_fax;
  end if;

  -- Call our wrapper update helper. Passing G_TRUE for expiring password
  -- because any password update in USER form should result password
  -- expiration.
  l_pwd_ret := ldap_wrp_update_user_helper(x_user_name,
          x_unencrypted_password, x_start_date, l_end_date, l_description,
          l_email_address, l_fax, fnd_ldap_wrapper.G_TRUE );

  -- Return the ldap out password to User form.
  x_out_pwd := l_pwd_ret;

exception
  when others then
    app_exception.raise_exception;
end;

----------------------------------------------------------------------------
-- This routine is for AOL INTERNAL USE ONLY !!!!!!!
--
-- ldap_wrp_update_user_loader
--   This is called by the fnd_user_pkg and fnd_web_sec.
--   It serves as a helper routine to call fnd_ldap_wrapper.update_user
--   when we need to synch the user update to OID.
procedure ldap_wrp_update_user_loader(x_user_name in varchar2,
                                   x_hashed_password in varchar2,
                                   x_start_date in date,
                                   x_end_date in date,
                                   x_description in varchar2,
                                   x_email_address in varchar2,
                                   x_fax in varchar2,
                                   x_expire_pwd in pls_integer default 1)
is
    l_pwd_ret varchar2(100);
    l_user_guid raw(16);
    l_result number;
    reason varchar2(2000);
    userid number; -- bug 5162136
begin

  l_user_guid := null;
  l_result := null;
  l_pwd_ret := null;
  userid := null;

  select user_guid, user_id into l_user_guid, userid
  from fnd_user
  where user_name = x_user_name;

  if (l_user_guid is null) then
    return;
  end if;

  fnd_ldap_wrapper.update_user(l_user_guid, x_user_name,
        x_hashed_password, x_start_date, x_end_date, x_description,
        x_email_address, x_fax, x_expire_pwd, l_pwd_ret, l_result);

  if (l_result <> fnd_ldap_wrapper.G_SUCCESS) then
    reason := fnd_message.get();
    fnd_message.set_name('FND', 'LDAP_WRAPPER_UPDATE_USER_FAIL');
    fnd_message.set_token('USER_NAME', x_user_name);
    fnd_message.set_token('REASON', reason);
    app_exception.raise_exception;
  end if;

  if (l_pwd_ret = fnd_web_sec.external_pwd) then
     update fnd_user
     set encrypted_foundation_password = 'EXTERNAL',
         encrypted_user_password = 'EXTERNAL'
     where user_name = upper(x_user_name);
  end if;

  exception
    when others then
      fnd_message.set_name('FND', 'LDAP_WRAPPER_UPDATE_USER_LOADER_FAIL');
      fnd_message.set_token('USER_NAME', x_user_name);
      fnd_message.set_token('REASON', sqlerrm);
     app_exception.raise_exception;

end;

end FND_USER_PKG;
