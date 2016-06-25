If you create Adhoc Roles, the following script is useful to remove them.

BEGIN
   WF_DIRECTORY.SetAdHocRoleExpiration('XXMUS_TEST_ROLE', SYSDATE -1 );
   COMMIT;
   WF_DIRECTORY.SETADHOCROLESTATUS( 'XXMUS_ TEST _ROLE', 'INACTIVE');
   COMMIT;
   WF_DIRECTORY.deleterole('XXMUS_ TEST _ROLE' , 'WF_LOCAL_ROLES' , 0);
   COMMIT;
END;
