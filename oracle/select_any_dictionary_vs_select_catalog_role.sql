--Source: http://arup.blogspot.ca/2011/07/difference-between-select-any.html

Difference between Select Any Dictionary and Select_Catalog_Role
When you want to give a user the privilege to select from data dictionary and dynamic performance views such as V$DATAFILE, you have two options:

grant select any dictionary to ;
grant select_catalog_role to ;

Did you ever wonder why there are two options for accomplishing the same objective? Is one of them redundant? Won't it make sense for Oracle to have just one privilege? And, most important, do these two privileges produce the same result?

The short answer to the last question is -- no; these two do not produce the same result. Since they are fundamentally different, there is a place of each of these. One is not a replacement for the other. In this blog I will explain the subtle but important differences between the two seemingly similar privileges and how to use them properly.

Create the Test Case

First let me demonstrate the effects by a small example. Create two users called SCR and SAD:

SQL> create user scr identified by scr;
SQL> create user sad identified by sad;

Grant the necessary privileges to these users, taking care to grant a different one to each user.

SQL> grant create session, select any dictionary to sad;


Grant succeeded.

SQL> grant create session, select_catalog_role to scr;

Grant succeeded.

Let's test to make sure these privileges work as expected:

SQL> connect sad/sad
Connected.

SQL> select * from v$session;
 ... a bunch of rows come here ...

SQL> connect scr/scr
Connected.

SQL> select * from v$datafile;
 ... a bunch of rows come here ...

Both users have the privilege to select from the dictionary views as we expected. So, what is the difference between these two privileges? To understand that, let's create a procedure on the dictionary tables/views on each schema. Since we will create the same procedure twice, let's first create a script which we will call p.sql. Here is the script:

create or replace procedure p as
    l_num number;
begin
    select count(1)
    into l_num
    from v$session;
end;
/

The procedure is very simple; it merely counts the number of connected sessions by querying V$SESSION. When you connect as SAD and create the procedure by executing p.sql:

SQL> @p.sql


Procedure created.

The procedure was created properly; but when you connect as SCR and execute the script:


SQL> @p.sql


Warning: Procedure created with compilation errors.

SQL> show error
Errors for PROCEDURE P:


LINE/COL ERROR
-------- ------------------------------------------------
4/2      PL/SQL: SQL Statement ignored
6/7      PL/SQL: ORA-00942: table or view does not exist

That must be perplexing. We just saw that the user has the privilege to select from the V$SESSION view. You can double check that by selecting from the view one more time. So, why did it report ORA-942: table does not exist?

Not All Privileges have been Created Equal

The answer lies in the way Oracle performs compilations. To compile a code with a named object, the user must have been granted privileges by direct grants; not through the roles. Selecting or performing DML statements do not care how the privileges were received. The SQL will work as long as the privileges are there. The privilege SELECT ANY DICTIONARY is a system privilege, similar to create session or unlimited tablespace. This is why the user SAD, which had the system privilege, could successfully compile the   procedure P.

The user SCR had the role SELECT_CATALOG_ROLE, which allowed it to SELECT from V$SESSION but not to create the procedure. Remember, to create another object on the base object, the user must have the direct grant on the base object; not through a role. Since SCR had the role not the direct grant on V$DATAFILE, it can't compile the procedure.

So while both the privileges allow the users to select from v$datafile, the role does not allow the users to create objects; the system privilege does.

Why the Role?

Now that you know how the privileges are different, you maybe wondering why the role is even there. It seems that the system grant can do everything and there is no need for a role. Not quite.The role has a very different purpose. Roles provide privileges; but only when they are enabled. To see what roles are enabled in a session, use this query:


SQL> connect scr/oracle
Connected.
SQL> select * from session_roles
  2  /


ROLE
------------------------------
SELECT_CATALOG_ROLE
HS_ADMIN_SELECT_ROLE


2 rows selected.

We see that two roles - SELECT_CATALOG_ROLE and HS_ADMIN_SELECT_ROLE - have been enabled in the session. The first one was granted to the user. The other one is granted to the first one; so that was also enabled.

Just because a role was granted to the user does not necessarily mean that the role would be enabled. The roles which are marked DEFAULT by the user will be enabled; the others will not be. Let's see that with an example. As SYS user, execute the following:

SQL> alter user scr default role none;

User altered.

Now connect as SCR user and see which roles have been enabled:

SQL> connect scr/oracle
SQL> select * from session_roles;

no rows selected

None of the roles have been enabled. Why? That's  because none of the roles are default for the user (effected by the alter user statement by SYS). At this point when you select from a dynamic performance view:

SQL> select * from v$datafile;
select * from v$datafile
              *
ERROR at line 1:
ORA-00942: table or view does not exist

You will get this error because the role is not enabled, or active. Without the role the user does not have any privilege to select from the data dictionary or dynamic performance view. To enable the role, the user has to execute the SET ROLE command:

SQL> set role SELECT_CATALOG_ROLE;

Role set.

Checking the enabled roles:

SQL> select * from session_roles;

ROLE
------------------------------
SELECT_CATALOG_ROLE
HS_ADMIN_SELECT_ROLE

2 rows selected.


Now the roles have been enabled. Since the roles are not default, the user must explicitly enable them using the SET ROLE command. This is a very important characteristic of the roles. We can control how the user will get the privilege. Merely granting a role to a user will not enable the role; the user's action is required and that can be done programmatically. In security conscious environments, you may want to take advantage of that property. A user does not always have the to have to privilege; but when needed it will be able to do so.

The SET ROLE command is an SQL*Plus command. To call it from SQL, use this:

begin

   dbms_session.set_role ('SELECT_CATALOG_ROLE');
end;


You can also set a password for the role. So it will be set only when the correct password is given;


SQL> alter role SELECT_CATALOG_ROLE identified by l       
  2  /


Role altered.

To set the role, you have to give the correct password:

SQL> set role SELECT_CATALOG_ROLE identified by l;

Role set.

If you give the wrong password:

SQL> set role SELECT_CATALOG_ROLE identified by fl
  2  /
set role SELECT_CATALOG_ROLE identified by fl
*
ERROR at line 1:
ORA-01979: missing or invalid password for role 'SELECT_CATALOG_ROLE'

You can also revoke the execute privilege on dbms_session from public. After that the user will not be able to use it to set the role. You can construct another wrapper procedure to call it. Inside the wrapper, you can have all sort of checks and balances to make sure the call is acceptable.

We will close this discussion with a tip. How do you know which roles are default? Simply use the following query:


SQL> select GRANTED_ROLE, DEFAULT_ROLE
  2  from dba_role_privs
  3  where GRANTEE = 'SCR';


GRANTED_ROLE                   DEF
------------------------------ ---
SELECT_CATALOG_ROLE            NO


Update


Thanks to Randolph Geist (http://www.blogger.com/profile/13463198440639982695) and Pavel Ruzicka (http://www.blogger.com/profile/04746480312675833301) for pointing out yet another important difference. SELECT ANY DICTIONARY allows select from all SYS owner tables such as TAB$, USER$, etc. This is not possible in the SELECT_CATALOG_ROLE. This difference may seem trivial; but is actually quite important in some cases. For instance, latest versions of Oracle do not show the password column from DBA_USERS; but the hashed password is visible in USER$ table. It's not possible to reverse engineer the password from the hash value; but it is possible to match it to a similar entry and guess the password. A user with the system privilege will be able to do that; but a user with the role will not be.



Conclusion

In this blog entry I started with a simple question - what is the difference between two seemingly similar privileges - SELECT ANY DICTIONARY and SELECT_CATALOG_ROLE. The former is a system privilege, which remains active throughout the sessions and allows the user to create stored objects on objects on which it has privileges as a result of the grant. The latter is not a system grant; it's a role which does not allow the grantee to build stored objects on the granted objects. The role can also be non-default which means the grantee must execute a set role or equivalent command to enable it. The role can also be password protected, if desired.

The core message you should get from this is that roles are different from privileges. Privileges allow you to build stored objects such as procedures on the objects on which the privilege is based. Roles do not.
