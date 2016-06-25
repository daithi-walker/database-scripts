create or replace package FND_PROFILE AUTHID CURRENT_USER as
/* $Header: AFPFPROS.pls 115.23 2009/01/28 16:36:34 pdeluna ship $ */
/*#
 * APIs to manipulate values stored in client
 * and server user profile caches.Any changes you make to profile option
 * values using these routines affect only the run-time environment. The
 * effect of these settings end when the program ends, because the database
 * session (which holds the profile cache) is terminated.
 * @rep:scope public
 * @rep:product FND
 * @rep:displayname Profile Management APIs
 * @rep:category BUSINESS_ENTITY FND_PROFILE
 * @rep:compatibility S
 * @rep:lifecycle active
 * @rep:ihelp FND/@prof_plsql#prof_plsql See the related online help
 */
    /*
    ** PUT - sets a profile option to a value for this session,
    **       but doesn't save to the database
    */
   /*#
    * Puts a value to the specified user profile option. If the option
    * does not exist, you can also create it with PUT. A PUT on the server
    * affects only the server-side profile cache, and a PUT on the client
    * affects only the client-side cache. By using PUT, you destroy the
    * synchrony between server-side and client-side profile caches. As a
    * result, we do not recommend widespread use of PUT.
    * @param name Profile name
    * @param val Profile value
    * @rep:scope public
    * @rep:displayname Put Profile
    * @rep:compatibility S
    * @rep:lifecycle active
    * @rep:ihelp FND/@prof_plsql See related online help.
    */


    procedure PUT(NAME in varchar2, VAL in varchar2);
    pragma restrict_references(PUT, WNDS, RNDS,TRUST);

    /*
    ** DEFINED - returns TRUE if a profile option has been stored
    */
    function  DEFINED(NAME in varchar2) return boolean;
    pragma restrict_references(DEFINED, WNDS, TRUST);

    /*
    ** GET - gets the value of a profile option
    */
    /*#
     * Gets the current value of the specified user profile option, or
     * NULL if the profile does not exist. All GET operations are
     * satisfied locally. In other words, a GET on the server is satisfied
     * from the server-side cache, and a GET on the client is satisfied from
     * the client-side cache.
     * @param name Profile name
     * @param val  Profile value as set by PUT
     * @rep:scope public
     * @rep:displayname Get Profile
     * @rep:compatibility S
     * @rep:lifecycle active
     * @rep:ihelp FND/@prof_plsql See related online help.
     */

    procedure GET(NAME in varchar2, VAL out NOCOPY varchar2);
    pragma restrict_references(GET, WNDS, TRUST);

    /*
    ** VALUE - returns the value of a profile options
    */
   /*#
    * Works exactly like GET, except it returns the value of the
    * specified profile option as a function result.
    * @param name Profile name
    * @return specified profile option value
    * @rep:scope public
    * @rep:displayname Get Profile Value
    * @rep:compatibility S
    * @rep:lifecycle active
    * @rep:ihelp FND/@prof_plsql See related online help.
    */
    function  VALUE(NAME in varchar2) return varchar2;
    pragma restrict_references(VALUE, WNDS, TRUST);

    /*
    ** VALUE_WNPS - returns the value of a profile option without caching it.
    **
    **            The main usage for this routine would be in a SELECT
    **            statement where VALUE() is not allowed since it
    **            writes package state.
    **
    **            This routine does the same thing as VALUE(); it returns
    **            a profile value from the profile cache, or from the database
    **            if it isn't already in the profile cache already.  The only
    **            difference between this and VALUE() is that this will not
    **            put the value into the cache if it is not already there, so
    **            repeated calls to this can be slower because it will have
    **            to hit the database each time for the profile value.
    **
    **            In most cases, however, you can and should use VALUE()
    **            instead of VALUE_WNPS(), because VALUE() will give
    **            better performance.
    */
    function  VALUE_WNPS(NAME in varchar2) return varchar2;
    pragma restrict_references(VALUE_WNPS, WNDS,WNPS, TRUST);

    /*
    ** SAVE_USER - Sets the value of a profile option permanently
    **             to the database, at the user level for the current user.
    **             Also saves in the profile cache for this database session.
    **             Note that this will not save in the profile caches
    **             for any other database sessions that may be up, so those
    **             could potentially be out of sync. This routine will not
    **             actually commit the changes; the caller must commit.
    **
    **  returns: TRUE if successful, FALSE if failure.
    **
    */
    function SAVE_USER(
         X_NAME in varchar2,  /* Profile name you are setting */
         X_VALUE in varchar2 /* Profile value you are setting */
    ) return boolean;

    /*
    ** SAVE - sets the value of a profile option permanently
    **        to the database, at any level.  This routine can be used
    **        at runtime or during patching.  This routine will not
    **        actually commit the changes; the caller must commit.
    **
    **        ('SITE', 'APPL', 'RESP', 'USER', 'SERVER', 'ORG', or 'SERVRESP').
    **
    **        Examples of use:
    **        FND_PROFILE.SAVE('P_NAME', 'P_VAL', 'SITE');
    **        FND_PROFILE.SAVE('P_NAME', 'P_VAL', 'APPL', 321532);
    **        FND_PROFILE.SAVE('P_NAME', 'P_VAL', 'RESP', 321532, 345234);
    **        FND_PROFILE.SAVE('P_NAME', 'P_VAL', 'USER', 123321);
    **        FND_PROFILE.SAVE('P_NAME', 'SERVER', 25);
    **        FND_PROFILE.SAVE('P_NAME', 'ORG', 204);
    **        FND_PROFILE.SAVE('P_NAME', 'SERVRESP', 321532, 345234, 25);
    **        FND_PROFILE.SAVE('P_NAME', 'SERVRESP', 321532, 345234, -1);
    **        FND_PROFILE.SAVE('P_NAME', 'SERVRESP', -1, -1, 25);
    **
    **  returns: TRUE if successful, FALSE if failure.
    **
    */
    function SAVE(
      X_NAME in varchar2,
        /* Profile name you are setting */
      X_VALUE in varchar2,
        /* Profile value you are setting */
      X_LEVEL_NAME in varchar2,
        /* Level that you're setting at: 'SITE','APPL','RESP','USER', etc. */
      X_LEVEL_VALUE in varchar2 default NULL,
        /* Level value that you are setting at, e.g. user id for 'USER' level.
           X_LEVEL_VALUE is not used at site level. */
      X_LEVEL_VALUE_APP_ID in varchar2 default NULL,
        /* Used for 'RESP' and 'SERVRESP' level; Resp Application_Id. */
      X_LEVEL_VALUE2 in varchar2 default NULL
        /* 2nd Level value that you are setting at.  This is for the 'SERVRESP'
           hierarchy. */
    ) return boolean;

    /*
    ** GET_SPECIFIC - Get profile value for a specific user/resp/appl combo
    **   Default is user/resp/appl is current login.
    */
    procedure GET_SPECIFIC(NAME_Z              in varchar2,
                           USER_ID_Z           in number default null,
                           RESPONSIBILITY_ID_Z in number default null,
                           APPLICATION_ID_Z    in number default null,
                           VAL_Z               out NOCOPY varchar2,
                           DEFINED_Z           out NOCOPY boolean,
                           ORG_ID_Z            in number default null,
                           SERVER_ID_Z         in number default null);

    pragma restrict_references(GET_SPECIFIC, WNDS, WNPS, TRUST);

    /*
    ** VALUE_SPECIFIC - Get profile value for a specific user/resp/appl combo
    **   Default is user/resp/appl is current login.
    */
    function VALUE_SPECIFIC(NAME              in varchar2,
                            USER_ID           in number default null,
                            RESPONSIBILITY_ID in number default null,
                            APPLICATION_ID    in number default null,
                            ORG_ID            in number default null,
                            SERVER_ID         in number default null)
    return varchar2;
    pragma restrict_references(VALUE_SPECIFIC, WNDS, WNPS, TRUST);

    /*
    ** FOR AOL INTERNAL USE ONLY
    **
    ** initialize_org_context - Initializes the org context used by profiles.
    */
    procedure INITIALIZE_ORG_CONTEXT;

    /*
    ** AOL INTERNAL USE ONLY
    */
    procedure INITIALIZE(USER_ID_Z           in number default NULL,
                         RESPONSIBILITY_ID_Z in number default NULL,
                         APPLICATION_ID_Z    in number default NULL,
                         SITE_ID_Z           in number default NULL);
--    pragma restrict_references(INITIALIZE, WNDS);

    procedure PUTMULTIPLE(NAMES in varchar2, VALS in varchar2, NUM in number);
    pragma restrict_references(PUTMULTIPLE, WNDS, RNDS, TRUST);

    /*
    ** GET_TABLE_VALUE - get the value of a profile option from the table
    **
    ** [NOTE: THIS FUNCTION IS FOR AOL INTERNAL USE ONLY.]
    */
    function GET_TABLE_VALUE(NAME in varchar2) return varchar2;
    pragma restrict_references(GET_TABLE_VALUE, WNDS, WNPS, RNDS, TRUST);

    /*
    ** GET_ALL_TABLE_VALUES - get all the values from the table
    **   The varchar2 returned can be up to 32767 characters long.
    **
    ** [NOTE: THIS FUNCTION IS FOR AOL INTERNAL USE ONLY.]
    */
    function GET_ALL_TABLE_VALUES(DELIM in varchar2) return varchar2;
    pragma restrict_references(GET_ALL_TABLE_VALUES, WNDS, WNPS, RNDS, TRUST);

    /*
     * bumpCacheVersion_RF
     *      The rule function for FND's subscription on the
     *      oracle.apps.fnd.profile.value.update event.  This function calls
     *      FND_CACHE_VERSION_PKG.bump_version to increase the version of the
     *      appropriate profile level cache.
     */
    function bumpCacheVersion_RF (p_subscription_guid in raw,
                                  p_event in out NOCOPY WF_EVENT_T)
    return varchar2;

     /*
     ** DELETE - deletes the value of a profile option permanently from the
     **          database, at any level.  This routine serves as a wrapper to
     **          the SAVE routine which means that this routine can be used at
     **          runtime or during patching.  Like the SAVE routine, this
     **          routine will not actually commit the changes; the caller must
     **          commit.
     **
     **        ('SITE', 'APPL', 'RESP', 'USER', 'SERVER', 'ORG', or 'SERVRESP').
     **
     **        Examples of use:
     **        FND_PROFILE.DELETE('P_NAME', 'SITE');
     **        FND_PROFILE.DELETE('P_NAME', 'APPL', 321532);
     **        FND_PROFILE.DELETE('P_NAME', 'RESP', 321532, 345234);
     **        FND_PROFILE.DELETE('P_NAME', 'USER', 123321);
     **        FND_PROFILE.DELETE('P_NAME', 'SERVER', 25);
     **        FND_PROFILE.DELETE('P_NAME', 'ORG', 204);
     **        FND_PROFILE.DELETE('P_NAME', 'SERVRESP', 321532, 345234, 25);
     **        FND_PROFILE.DELETE('P_NAME', 'SERVRESP', 321532, 345234, -1);
     **        FND_PROFILE.DELETE('P_NAME', 'SERVRESP', -1, -1, 25);
     **
     **  returns: TRUE if successful, FALSE if failure.
     **
     */
     function DELETE(
          X_NAME in varchar2,
               /* Profile name you are setting */
          X_LEVEL_NAME in varchar2,
               /* Level that you're setting at: 'SITE','APPL','RESP','USER', etc. */
          X_LEVEL_VALUE in varchar2 default NULL,
               /* Level value that you are setting at, e.g. user id for 'USER' level.
                  X_LEVEL_VALUE is not used at site level. */
          X_LEVEL_VALUE_APP_ID in varchar2 default NULL,
               /* Used for 'RESP' and 'SERVRESP' level; Resp Application_Id. */
          X_LEVEL_VALUE2 in varchar2 default NULL
               /* 2nd Level value that you are setting at.  This is for the 'SERVRESP'
                  hierarchy only. */
          ) return boolean;

end FND_PROFILE;
/

create or replace package body FND_PROFILE as
/* $Header: AFPFPROB.pls 115.103 2009/01/28 16:38:42 pdeluna ship $ */

   type VAL_TAB_TYPE    is table of varchar2(255) index by binary_integer;
   type NAME_TAB_TYPE   is table of varchar2(80)  index by binary_integer;

   /*
   ** define the internal table that will cache the profile values
   ** val_tab(x) is associated with name_tab(x) and dbflag(x)
   */
   VAL_TAB     VAL_TAB_TYPE; /* the table of values for the Generic PUT cache */
   NAME_TAB    NAME_TAB_TYPE; /* the table of names for the Generic PUT cache */
   TABLE_SIZE  binary_integer := 8192;             /* the size of above tables*/
   INSERTED    boolean := FALSE;            /*if at least a profile is stored */

   /*
   ** define the internal tables that will cache the profile values
   ** for the different levels.
   */
   USER_VAL_TAB    VAL_TAB_TYPE;    /* the user-level cache table of values */
   USER_NAME_TAB   NAME_TAB_TYPE;   /* the user-level cache table of names */
   RESP_VAL_TAB    VAL_TAB_TYPE;    /* the resp-level cache table of values */
   RESP_NAME_TAB   NAME_TAB_TYPE;   /* the resp-level cache table of names */
   APPL_VAL_TAB    VAL_TAB_TYPE;    /* the appl-level cache table of values */
   APPL_NAME_TAB   NAME_TAB_TYPE;   /* the appl-level cache table of names */
   SITE_VAL_TAB    VAL_TAB_TYPE;    /* the site-level cache table of values */
   SITE_NAME_TAB   NAME_TAB_TYPE;   /* the site-level cache table of names */
   SERVER_VAL_TAB  VAL_TAB_TYPE;    /* the server-level cache table of values */
   SERVER_NAME_TAB NAME_TAB_TYPE;   /* the server-level cache table of names */
   ORG_VAL_TAB     VAL_TAB_TYPE;    /* the appl-level cache table of values */
   ORG_NAME_TAB    NAME_TAB_TYPE;   /* the appl-level cache table of names */

   /*
   ** Define the current level context
   */
   PROFILES_USER_ID    number := -1;
   PROFILES_RESP_ID    number := -1;
   PROFILES_APPL_ID    number := -1;
   PROFILES_SERVER_ID  number := -1;
   PROFILES_ORG_ID     number := -1;
   PROFILES_SESSION_ID number := -1;

   /*
   ** Constant string used to indicate that a cache entry is undefined.
   */
   FND_UNDEFINED_VALUE VARCHAR2(30) := '**FND_UNDEFINED_VALUE**';

   /*
   ** Save the enabled flags and hierarchy of the last fetched profile
   ** option.
   */
   PROFILE_OPTION_NAME VARCHAR2(80);
   PROFILE_OPTION_ID   NUMBER;
   PROFILE_AID         NUMBER;
   USER_CHANGEABLE     VARCHAR2(1) := 'N';  -- Bug 4257739
   USER_ENABLED        VARCHAR2(1) := 'N';
   RESP_ENABLED        VARCHAR2(1) := 'N';
   APP_ENABLED         VARCHAR2(1) := 'N';
   SITE_ENABLED        VARCHAR2(1) := 'N';
   SERVER_ENABLED      VARCHAR2(1) := 'N';
   ORG_ENABLED         VARCHAR2(1) := 'N';
   HIERARCHY           VARCHAR2(8) := 'SECURITY';

   /*
   ** Version number to be used to invalidate cache when a change in
   ** version is detected.
   */
   USER_CACHE_VERSION      number := 0;
   RESP_CACHE_VERSION      number := 0;
   APPL_CACHE_VERSION      number := 0;
   SITE_CACHE_VERSION      number := 0;
   SERVER_CACHE_VERSION    number := 0;
   ORG_CACHE_VERSION       number := 0;

   /*
   ** Constant strings for the cache names being stored in
   ** FND_CACHE_VERSIONS.
   */
   USER_CACHE VARCHAR2(30)   := 'USER_PROFILE_CACHE';
   RESP_CACHE VARCHAR2(30)   := 'RESP_PROFILE_CACHE';
   APPL_CACHE VARCHAR2(30)   := 'APPL_PROFILE_CACHE';
   SITE_CACHE VARCHAR2(30)   := 'SITE_PROFILE_CACHE';
   SERVER_CACHE VARCHAR2(30) := 'SERVER_PROFILE_CACHE';
   ORG_CACHE  VARCHAR2(30)   := 'ORG_PROFILE_CACHE';

   /*
   ** Declarations for Server/Resp Level.  These were intentionally kept
   ** separate from the other level declarations.
   */
   /* the server/resp-level table of values */
   SERVRESP_VAL_TAB        VAL_TAB_TYPE;
   /* the server/resp-level table of names */
   SERVRESP_NAME_TAB       NAME_TAB_TYPE;
   SERVRESP_ENABLED        VARCHAR2(1) := 'N';
   SERVRESP_CACHE_VERSION  NUMBER := 0;
   SERVRESP_CACHE          VARCHAR2(30) := 'SERVRESP_PROFILE_CACHE';

   /*
   ** Global variable used to identify if a profile option exists or not.
   ** This will determine whether the query for the profile_info cursor is
   ** to be executed.
   */
   PROFILE_OPTION_EXISTS   boolean := TRUE;

   /*
   ** Global variable used to identify core logging is enabled or not.
   ** Added for Bug 5599946: APPSPERF:FND:LOGGING CALLS IN FND_PROFILE CAUSING
   ** PERFORMANCE REGRESSION
   */
   CORELOG_IS_ENABLED      boolean := FND_CORE_LOG.IS_ENABLED;

   /*
   ** Global variable that stores Applications Release Version
   */
   RELEASE_VERSION         number := fnd_release.major_version;

   /*
   ** CORELOG - wrapper to CORELOG with defaulting current profile context.
   */
   procedure CORELOG(
        LOG_PROFNAME          in varchar2,
        LOG_PROFVAL           in varchar2 default NULL,
        CURRENT_API           in varchar2,
        LOG_USER_ID           in number default PROFILES_USER_ID,
        LOG_RESPONSIBILITY_ID in number default PROFILES_RESP_ID,
        LOG_APPLICATION_ID    in number default PROFILES_APPL_ID,
        LOG_ORG_ID            in number default PROFILES_ORG_ID,
        LOG_SERVER_ID         in number default PROFILES_SERVER_ID)
   is
   begin
      FND_CORE_LOG.WRITE_PROFILE(
         LOG_PROFNAME,
         LOG_PROFVAL,
         CURRENT_API,
         LOG_USER_ID,
         LOG_RESPONSIBILITY_ID,
         LOG_APPLICATION_ID,
         LOG_ORG_ID,
         LOG_SERVER_ID);
   end CORELOG;

   /*
   ** CHECK_CACHE_VERSIONS
   **
   ** Bug 5477866: INCONSISTENT VALUES RETURNED BY FND_PROFILE.VALUE_SPECIFIC
   ** Broke this algorithm out of INITIALIZE so that VALUE_SPECIFIC can use
   ** the algorithm also.
   */
   procedure CHECK_CACHE_VERSIONS
   is
   begin
      /*
      ** Bug 4864218: CU2: DATE FORMAT CHANGE IN PREFERENCES DOES NOT TAKE
      ** EFFECT IMMEDIATELY
      **
      ** Profile option value cache invalidation relies on cache versions
      ** to signal whether level caches should be purged.  Cache versions
      ** are stored in PL/SQL tables to utilize bulk loading for better
      ** performance.  Due to the performance enhancements made for bug
      ** 3901095, a cache refresh issue was introduced.  The PL/SQL tables
      ** used for cache versions were not being refreshed properly, so the
      ** profile option value cache invalidation was not performing properly.
      **
      ** The following call refreshes the cache version PL/SQL tables so that
      ** the version check, used to determine whether level caches are to be
      ** purged, are performed properly.
      **
      ** This change will introduce a slight performance hit but should not
      ** be as severe as the performance levels that bug 3901095 had.
      */
      FND_CACHE_VERSIONS_PKG.get_values;

      /*
      ** Add cache(s) entries in FND_CACHE_VERSIONS if one does not exist.
      ** If a cache exists however, we will check to see if there has been any
      ** changes within that profile level to refresh it (delete it).
      */
      if (FND_CACHE_VERSIONS_PKG.check_version(USER_CACHE,USER_CACHE_VERSION)
         = FALSE) then
         if (USER_CACHE_VERSION = -1) then
            FND_CACHE_VERSIONS_PKG.add_cache_name(USER_CACHE);
            USER_CACHE_VERSION := 0;
         else
            USER_NAME_TAB.DELETE();
            USER_VAL_TAB.DELETE();
         end if;
      end if;

      if (FND_CACHE_VERSIONS_PKG.check_version(RESP_CACHE,RESP_CACHE_VERSION)
         = FALSE) then
         if (RESP_CACHE_VERSION = -1) then
            FND_CACHE_VERSIONS_PKG.add_cache_name(RESP_CACHE);
            RESP_CACHE_VERSION := 0;
         else
            RESP_NAME_TAB.DELETE();
            RESP_VAL_TAB.DELETE();
         end if;
      end if;

      if (FND_CACHE_VERSIONS_PKG.check_version(APPL_CACHE,APPL_CACHE_VERSION)
         = FALSE) then
         if (APPL_CACHE_VERSION = -1) then
            FND_CACHE_VERSIONS_PKG.add_cache_name(APPL_CACHE);
            APPL_CACHE_VERSION := 0;
         else
            APPL_NAME_TAB.DELETE();
            APPL_VAL_TAB.DELETE();
         end if;
      end if;

      if (FND_CACHE_VERSIONS_PKG.check_version(ORG_CACHE,ORG_CACHE_VERSION)
         = FALSE) then
         if (ORG_CACHE_VERSION = -1) then
            FND_CACHE_VERSIONS_PKG.add_cache_name(ORG_CACHE);
            ORG_CACHE_VERSION := 0;
         else
            ORG_NAME_TAB.DELETE();
            ORG_VAL_TAB.DELETE();
         end if;
      end if;

      if (FND_CACHE_VERSIONS_PKG.check_version
         (SERVER_CACHE, SERVER_CACHE_VERSION) = FALSE) then
         if (SERVER_CACHE_VERSION = -1) then
            FND_CACHE_VERSIONS_PKG.add_cache_name(SERVER_CACHE);
            SERVER_CACHE_VERSION := 0;
         else
            SERVER_NAME_TAB.DELETE();
            SERVER_VAL_TAB.DELETE();
         end if;
      end if;

      if (FND_CACHE_VERSIONS_PKG.check_version
         (SERVRESP_CACHE,SERVRESP_CACHE_VERSION) = FALSE) then
         if (SERVRESP_CACHE_VERSION = -1) then
            FND_CACHE_VERSIONS_PKG.add_cache_name(SERVRESP_CACHE);
            SERVRESP_CACHE_VERSION := 0;
         else
            SERVRESP_NAME_TAB.DELETE();
            SERVRESP_VAL_TAB.DELETE();
         end if;
      end if;

      if (FND_CACHE_VERSIONS_PKG.check_version(SITE_CACHE,SITE_CACHE_VERSION)
         = FALSE) then
         if (SITE_CACHE_VERSION = -1) then
            FND_CACHE_VERSIONS_PKG.add_cache_name(SITE_CACHE);
            SITE_CACHE_VERSION := 0;
         else
            SITE_NAME_TAB.DELETE();
            SITE_VAL_TAB.DELETE();
         end if;
      end if;

   end CHECK_CACHE_VERSIONS;


   /*
   ** FIND - find index of a profile option name in the given cache table
   **
   ** RETURNS
   **    table index if found, TABLE_SIZE if not found.
   */
   function FIND(
      NAME_UPPER           in varchar2,
      nameTable            in NAME_TAB_TYPE,
      PROFILE_HASH_VALUE   in binary_integer)
   return binary_integer is

      TAB_INDEX  binary_integer;
      FOUND      boolean;
      HASH_VALUE number;

      /* Bug 4271555: UPPER function is not to be called in FIND.  Instead, the
      ** API calling find passes UPPER(profile option name).
      ** NAME_UPPER varchar2(80);
      */
   begin

      /* Bug 4271555: UPPER function is not to be called in FIND.  Instead, the
      ** API calling find passes UPPER(profile option name).
      ** NAME_UPPER := upper(NAME);
      */

      /* Bug 5603664: APPSPERF:FND:OPTIMIZE FND_PROFILE.VALUE
      ** This is a failsafe. PROFILE_HASH_VALUE should always be passed by the
      ** calling api.
      **
      ** TAB_INDEX := dbms_utility.get_hash_value(NAME_UPPER,1,TABLE_SIZE);
      */
      if (PROFILE_HASH_VALUE is NULL) then
         TAB_INDEX := dbms_utility.get_hash_value(NAME_UPPER,1,TABLE_SIZE);
      else
         TAB_INDEX := PROFILE_HASH_VALUE;
      end if;

      if (nameTable.EXISTS(TAB_INDEX)) then
         if (nameTable(TAB_INDEX) = NAME_UPPER) then
            return TAB_INDEX;
         else
            HASH_VALUE := TAB_INDEX;
            FOUND := false;

            while (TAB_INDEX < TABLE_SIZE) and (not FOUND) loop
               if (nameTable.EXISTS(TAB_INDEX)) then
                  if nameTable(TAB_INDEX) = NAME_UPPER then
                     FOUND := true;
                  else
                     TAB_INDEX := TAB_INDEX + 1;
                  end if;
               else
                  return TABLE_SIZE+1;
               end if;
            end loop;

            if (not FOUND) then -- Didn't find any till the end
               TAB_INDEX := 1;  -- Start from the beginning
               while (TAB_INDEX < HASH_VALUE)  and (not FOUND) loop
                  if (nameTable.EXISTS(TAB_INDEX)) then
                     if nameTable(TAB_INDEX) = NAME_UPPER then
                        FOUND := true;
                     else
                        TAB_INDEX := TAB_INDEX + 1;
                     end if;
                  else
                     return TABLE_SIZE+1;
                  end if;
               end loop;
            end if;

            if (not FOUND) then
               return TABLE_SIZE+1; -- Return a higher value
            end if;
         end if;
      else
         return TABLE_SIZE+1;
      end if;

      return TAB_INDEX;

   exception
      when others then -- The entry doesn't exist
         return TABLE_SIZE+1;
   end FIND;


   /*
   ** FIND - find index of a profile option name in the Generic PUT cache table
   ** NAME_TAB, not the level cache tables.
   **
   ** RETURNS
   **    table index if found, TABLE_SIZE if not found.
   */
   function FIND(NAME in varchar2) return binary_integer is
   begin
       /* Bug 5603664: APPSPERF:FND:OPTIMIZE FND_PROFILE.VALUE
       ** UPPER function call removed, calling API would have done UPPER before
       ** calling FIND
       ** return FIND(UPPER(NAME),NAME_TAB);
       */
      return FIND(NAME,NAME_TAB,
         dbms_utility.get_hash_value(NAME,1,TABLE_SIZE));
   exception
      when others then -- The entry doesn't exist
         return TABLE_SIZE+1;
   end FIND;

   /*
   ** PUT - Set or Insert a profile option value in cache
   */
   procedure PUT(
      NAME                 in   varchar2, -- should be passed UPPER value
      VAL                  in   varchar2,
      nameTable            in out NOCOPY NAME_TAB_TYPE,
      valueTable           in out NOCOPY VAL_TAB_TYPE,
      PROFILE_HASH_VALUE   in binary_integer) is

      TABLE_INDEX binary_integer;
      STORED      boolean;
      HASH_VALUE  number;

   begin
      /* Bug 5603664: APPSPERF:FND:OPTIMIZE FND_PROFILE.VALUE
      ** Assignment removed since calling API would have used UPPER and passed
      ** resulting value for NAME into PUT
      **
      ** NAME_UPPER := upper(NAME);
      */

      -- Log API entry
      if CORELOG_IS_ENABLED then
         CORELOG(NAME,VAL,'Enter FP.P');
      end if;

      /* Bug 5603664: APPSPERF:FND:OPTIMIZE FND_PROFILE.VALUE
      ** This is a failsafe. PROFILE_HASH_VALUE should always be passed by the
      ** calling api.
      **
      ** TABLE_INDEX := dbms_utility.get_hash_value(NAME,1,TABLE_SIZE);
      */
      if (PROFILE_HASH_VALUE is NULL) then
         TABLE_INDEX := dbms_utility.get_hash_value(NAME,1,TABLE_SIZE);
      else
         TABLE_INDEX := PROFILE_HASH_VALUE;
      end if;

      -- Search for the option name
      STORED := FALSE;

      if (nameTable.EXISTS(TABLE_INDEX)) then
         if (nameTable(TABLE_INDEX) = NAME) then -- Found the profile
            valueTable(TABLE_INDEX) := VAL;      -- Store the new value
            STORED := TRUE;
         else -- Collision
            HASH_VALUE := TABLE_INDEX;           -- Store the current spot
            while (TABLE_INDEX < TABLE_SIZE) and (not STORED) loop
               if (nameTable.EXISTS(TABLE_INDEX)) then
                  if (nameTable(TABLE_INDEX) = NAME) then
                     valueTable(TABLE_INDEX) := VAL;
                     STORED := TRUE;
                  else
                     TABLE_INDEX := TABLE_INDEX + 1;
                  end if;
               else
                  valueTable(TABLE_INDEX) := VAL;
                  nameTable(TABLE_INDEX) := NAME;
                  STORED := TRUE;
               end if;
            end loop;

            if (not STORED) then -- Didn't find any free bucket till the end
               TABLE_INDEX := 1;
               while (TABLE_INDEX < HASH_VALUE) and (not STORED) loop
                  if (nameTable.EXISTS(TABLE_INDEX)) then
                     if (nameTable(TABLE_INDEX) = NAME) then
                        valueTable(TABLE_INDEX) := VAL;
                        STORED := TRUE;
                     else
                        TABLE_INDEX := TABLE_INDEX + 1;
                     end if;
                  else
                     valueTable(TABLE_INDEX) := VAL;
                     nameTable(TABLE_INDEX) := NAME;
                     STORED := TRUE;
                  end if;
               end loop;
            end if;
         end if;
      else
         nameTable(TABLE_INDEX) := NAME; -- Enter the profile
         valueTable(TABLE_INDEX) := VAL; -- Store its value
         STORED := TRUE;
      end if;

      if (STORED) then
         INSERTED := TRUE; /* At least, a profile is stored */
      -- AFPFPROB.pls 115.90 erroneously added an else condition that sets
      -- INSERTED := FALSE;
      end if;

      -- Log API exit
      if CORELOG_IS_ENABLED then
         CORELOG(NAME,VAL,'Exit FP.P');
      end if;

   exception
      when others then
         null;
   end PUT;


   /*
   ** PUT - Set or Insert a profile option value into the generic PUT cache
   */
   procedure PUT(
      NAME in varchar2,
      VAL in varchar2)
   is
      /* Bug 5603664: APPSPERF:FND:OPTIMIZE FND_PROFILE.VALUE
      ** UPPER call is done early and value is passed on, which minimizes
      ** number of UPPER calls
      */
      NAME_UPPER  varchar2(80) := UPPER(NAME);
   begin

      -- Log GENERIC PUT Entry
      if CORELOG_IS_ENABLED then
         CORELOG(NAME_UPPER,VAL,'Enter Generic FP.P');
      end if;

      /* Bug 5603664: APPSPERF:FND:OPTIMIZE FND_PROFILE.VALUE
      ** Call dbms_utility.get_hash_value and pass as an argument to PUT
      */
      -- Private PUT call
      PUT(NAME_UPPER,VAL,NAME_TAB,VAL_TAB,
         dbms_utility.get_hash_value(NAME_UPPER,1,TABLE_SIZE));
      -- Log GENERIC PUT Exit
      if CORELOG_IS_ENABLED then
         CORELOG(NAME_UPPER,VAL,'Exit Generic FP.P');
      end if;

   end PUT;

   /*
   ** GET_SPECIFIC_LEVEL_WNPS -
   **   Get a profile value for a specific user/resp/appl level without
   **   changing package state.
   */
   procedure GET_SPECIFIC_LEVEL_WNPS(
      name_z                     in varchar2, -- should be passed UPPER value
      level_id_z                 in number,
      level_value_z              in number,
      level_value_application_z  in number,
      val_z                      out NOCOPY varchar2,
      cached_z                   out NOCOPY boolean,
      level_value2_z             in number default null,
      PROFILE_HASH_VALUE         in binary_integer) is

      tableIndex           binary_integer;
      contextLevelValue    number;
      nameTable            NAME_TAB_TYPE;
      valueTable           VAL_TAB_TYPE;
      contextLevelValue2   number;         -- Added for Server/Resp Hierarchy
      hashValue            binary_integer;

   begin

      val_z := NULL;
      cached_z := FALSE;

      /* Bug 3679441:  The collection assignments, i.e. assigning the entire
      ** collection SITE_NAME_TAB to nameTable, was causing a performance
      ** degradation and should be avoided.  The suggestions put forth in bug
      ** 3679441 by OM Product Team are being implemented as the solution.
      ** Specifically, instead of assigning the entire collection to local
      ** variables nameTable and valueTable, just pass the 'name' collection
      ** into FIND to determine the tableIndex and if applicable, use the
      ** 'value' collection to obtain the value using the tableIndex
      ** obtained. This fix was approved by the ATG Performance Team.
      */

      /* Bug 5603664: APPSPERF:FND:OPTIMIZE FND_PROFILE.VALUE
      ** This is a failsafe. PROFILE_HASH_VALUE should always be passed by the
      ** calling api.
      */
      if PROFILE_HASH_VALUE is NULL then
         hashValue := dbms_utility.get_hash_value(name_z,1,TABLE_SIZE);
      else
         hashValue := PROFILE_HASH_VALUE;
      end if;

      /* Bug 5603664: APPSPERF:FND:OPTIMIZE FND_PROFILE.VALUE
      ** Removed all UPPER in FIND calls since calling API would have already
      ** used UPPER and passed in resulting name_z. This minimizes UPPER calls.
      */
      if(level_id_z = 10001) then
         contextLevelValue := 0;
         if (contextLevelValue = level_value_z) then
            tableIndex := FIND(name_z,SITE_NAME_TAB,hashValue);
            if (tableIndex < TABLE_SIZE) then
               val_z := SITE_VAL_TAB(tableIndex);
               cached_z := TRUE;
               return;
            end if;
         end if;
      elsif (level_id_z = 10002) then
         contextLevelValue := PROFILES_APPL_ID;
         if (contextLevelValue = level_value_z) then
            tableIndex := FIND(name_z,APPL_NAME_TAB,hashValue);
            if (tableIndex < TABLE_SIZE) then
               val_z := APPL_VAL_TAB(tableIndex);
               cached_z := TRUE;
               return;
            end if;
         end if;
      elsif (level_id_z = 10003) then
         contextLevelValue := PROFILES_RESP_ID;
         if ((contextLevelValue = level_value_z) and
            -- Level-value application ID needs to be taken into account for
            -- Resp-level cache if level_id = 10003
            (PROFILES_APPL_ID = level_value_application_z)) then
            tableIndex := FIND(name_z,RESP_NAME_TAB,hashValue);
            if (tableIndex < TABLE_SIZE) then
               val_z := RESP_VAL_TAB(tableIndex);
               cached_z := TRUE;
               return;
            end if;
         end if;
      elsif (level_id_z = 10004) then
         contextLevelValue := PROFILES_USER_ID;
         if (contextLevelValue = level_value_z) then
            tableIndex := FIND(name_z,USER_NAME_TAB,hashValue);
            if (tableIndex < TABLE_SIZE) then
               val_z := USER_VAL_TAB(tableIndex);
               cached_z := TRUE;
               return;
            end if;
         end if;
      elsif (level_id_z = 10005) then
         contextLevelValue := PROFILES_SERVER_ID;
         if (contextLevelValue = level_value_z) then
            tableIndex := FIND(name_z,SERVER_NAME_TAB,hashValue);
            if (tableIndex < TABLE_SIZE) then
               val_z := SERVER_VAL_TAB(tableIndex);
               cached_z := TRUE;
               return;
            end if;
         end if;
      elsif (level_id_z = 10006) then
         contextLevelValue := PROFILES_ORG_ID;
         if (contextLevelValue = level_value_z) then
            tableIndex := FIND(name_z,ORG_NAME_TAB,hashValue);
            if (tableIndex < TABLE_SIZE) then
               val_z := ORG_VAL_TAB(tableIndex);
               cached_z := TRUE;
               return;
            end if;
         end if;
      elsif (level_id_z = 10007) then  -- Added for Server/Resp Hierarchy
         contextLevelValue := PROFILES_RESP_ID;
         contextLevelValue2 := PROFILES_SERVER_ID;
         if ((contextLevelValue = level_value_z) and
             (contextLevelValue2 = level_value2_z) and
            -- Level-value application ID needs to be taken into account for
            -- ServResp-level cache if level_id = 10007
             (PROFILES_APPL_ID = level_value_application_z)) then
            tableIndex := FIND(name_z,SERVRESP_NAME_TAB,hashValue);
            if (tableIndex < TABLE_SIZE) then
               val_z := SERVRESP_VAL_TAB(tableIndex);
               cached_z := TRUE;
               return;
            end if;
         end if;
      end if;

   end GET_SPECIFIC_LEVEL_WNPS;


   procedure GET_SPECIFIC_LEVEL_DB(
      profile_id_z        in number,
      application_id_z    in number default null,
      level_id_z          in number,
      level_value_z       in number,
      level_value_aid     in number default null,
      val_z               out NOCOPY varchar2,
      defined_z           out NOCOPY boolean,
      level_value2_z      in number default null) is

      --
      -- this cursor fetches profile option values for site, application,
      -- and user levels (10001/10002/10004)
      --
      cursor value_uas(pid number, aid number, lid number, lval number) is
      select profile_option_value
      from   fnd_profile_option_values
      where  profile_option_id = pid
      and    application_id    = aid
      and    level_id          = lid
      and    level_value       = lval
      and    profile_option_value is not null;
      --
      -- this cursor fetches profile option values at the responsibility
      -- level (10003)
      --
      cursor value_resp(pid number, aid number, lval number, laid number) is
      select profile_option_value
      from   fnd_profile_option_values
      where  profile_option_id = pid
      and    application_id = aid
      and    level_id = 10003
      and    level_value = lval
      and    level_value_application_id = laid
      and    profile_option_value is not null;
      --
      -- this cursor fetches profile option values at the server/resp
      -- level (10007)
      --
      cursor value_servresp(pid number, aid number, lval number, laid number,
      lval2 number) is
      select profile_option_value
      from   fnd_profile_option_values
      where  profile_option_id = pid
      and    application_id = aid
      and    level_id = 10007
      and    level_value = lval
      and    level_value_application_id = laid
      and    level_value2 = lval2
      and    profile_option_value is not null;

   begin
      -- Added for Server/Resp Hierarchy
      -- If the level_value_aid is not NULL, then check if the level is for
      -- RESP or for SERVRESP.
      if (level_value_aid is not NULL) then
         -- If SERVRESP level, use value_servresp cursor.
         if (level_id_z = 10007) then

            open value_servresp(profile_id_z,application_id_z,level_value_z,
               level_value_aid,level_value2_z);
            fetch value_servresp into val_z;

            if (value_servresp%NOTFOUND) then
               defined_z := FALSE;
               val_z := NULL;
            else
               defined_z := TRUE;
            end if; -- Found

            close value_servresp;

         else
            -- Use value_resp cursor instead.
            open value_resp(profile_id_z,application_id_z,level_value_z,
               level_value_aid);
            fetch value_resp into val_z;

            if (value_resp%NOTFOUND) then
               defined_z := FALSE;
               val_z := NULL;
            else
               defined_z := TRUE;
            end if; -- Found

            close value_resp;

         end if;
      else
         -- level_value_aid is null, use value_uas cursor.
         open value_uas(profile_id_z,application_id_z,level_id_z,
            level_value_z);
         fetch value_uas into val_z;

         if (value_uas%NOTFOUND) then
            defined_z := FALSE;
            val_z := NULL;
         else
            defined_z := TRUE;
         end if; -- Found

         close value_uas;

      end if;

   END GET_SPECIFIC_LEVEL_DB;


   procedure GET_SPECIFIC_DB(
      name_z               in varchar2, -- UPPER value should be passed in
      user_id_z            in number default null,
      responsibility_id_z  in number default null,
      application_id_z     in number default null,
      val_z                out NOCOPY varchar2,
      defined_z            out NOCOPY boolean,
      org_id_z             in number default null,
      server_id_z          in number default null,
      level_id_z           in number,
      PROFILE_HASH_VALUE   in binary_integer) is

      --
      -- this cursor fetches profile information that will allow subsequent
      -- fetches to be more efficient
      --
      cursor profile_info is
      select profile_option_id,
         application_id,
         site_enabled_flag ,
         app_enabled_flag ,
         resp_enabled_flag ,
         user_enabled_flag,
         org_enabled_flag ,
         server_enabled_flag,
         SERVERRESP_ENABLED_FLAG,
         hierarchy_type,
         user_changeable_flag     -- Bug 4257739
      from fnd_profile_options
      where profile_option_name = name_z --  Bug 5599946: Removed UPPER call
      and start_date_active  <= sysdate
      and nvl(end_date_active, sysdate) >= sysdate;

      hashValue   binary_integer;

   begin

      -- Log API Entry
      if CORELOG_IS_ENABLED then
         CORELOG(name_z,nvl(val_z,'NOVAL'),'Enter FP.GSD',user_id_z,
            responsibility_id_z,application_id_z,org_id_z,server_id_z);
      end if;

      /* Bug 5603664: APPSPERF:FND:OPTIMIZE FND_PROFILE.VALUE
      ** This is a failsafe. PROFILE_HASH_VALUE should always be passed by the
      ** calling api.
      */
      if PROFILE_HASH_VALUE is NULL then
         hashValue := dbms_utility.get_hash_value(name_z,1,TABLE_SIZE);
      else
         hashValue := PROFILE_HASH_VALUE;
      end if;

      /* Check if the current profile option stored in PROFILE_OPTION_NAME is
      ** being evaluated.  If not, then open the cursor and store those values
      ** into the GLOBAL variables.
      */
      if ((PROFILE_OPTION_NAME is null) or
          ((PROFILE_OPTION_NAME is NOT null) and
           (name_z <> PROFILE_OPTION_NAME))) then

         -- Get profile info from database
         open profile_info;
         fetch profile_info into
            PROFILE_OPTION_ID,
            PROFILE_AID,
            SITE_ENABLED,
            APP_ENABLED,
            RESP_ENABLED,
            USER_ENABLED,
            ORG_ENABLED,
            SERVER_ENABLED,
            SERVRESP_ENABLED,
            HIERARCHY,
            USER_CHANGEABLE;   -- Bug 4257739

         if (profile_info%NOTFOUND) then
            val_z := NULL;
            defined_z := FALSE;
            PROFILE_OPTION_EXISTS := FALSE;
            close profile_info;

            -- Log cursor executed but no profile found
            if CORELOG_IS_ENABLED then
               CORELOG(name_z,nvl(val_z,'NOVAL'),
                  'CURSOR EXEC in FP.GSD, NOPROF',user_id_z,
                  responsibility_id_z,application_id_z,org_id_z,server_id_z);
            end if;
            return;
         end if; -- profile_info%NOTFOUND

         -- Log cursor executed and profile found
         if CORELOG_IS_ENABLED then
            CORELOG(name_z,nvl(val_z,'NOVAL'),'CURSOR EXEC in FP.GSD, PROF'
               ||':'||name_z||':'||PROFILE_OPTION_NAME,
               user_id_z,responsibility_id_z,application_id_z,org_id_z,
               server_id_z);
            -- Log profile definition
            FND_CORE_LOG.PUT_LINE(name_z,PROFILE_OPTION_ID||':'||
               PROFILE_AID||':'||SITE_ENABLED||':'||APP_ENABLED||':'||
               RESP_ENABLED||':'||USER_ENABLED||':'||ORG_ENABLED||':'||
               SERVER_ENABLED||':'||SERVRESP_ENABLED||':'||HIERARCHY||':'||USER_CHANGEABLE);
         end if;

         close profile_info;
         PROFILE_OPTION_NAME := name_z;
         PROFILE_OPTION_EXISTS := TRUE;

      else

         /* Bug 5209533: FND_GLOBAL.INITIALIZE RAISES APP-FND-02500 EXECUTING
         ** RULE FUNCTIONS FOR WF EVENT
         ** Setting PROFILE_OPTION_EXISTS = TRUE explicitly IF the condition is
         ** not satisfied.  This guarantees that the profile gets evaluated if
         ** PROFILE_OPTION_EXISTS is not FALSE, e.g. NULL;
         */
         PROFILE_OPTION_EXISTS := TRUE;

         -- Log cursor NOT executed and profile found
         if CORELOG_IS_ENABLED then
            CORELOG(name_z,nvl(val_z,'NOVAL'),
               'CURSOR *NOEXEC* in FP.GSD, PROF',user_id_z,responsibility_id_z,
               application_id_z,org_id_z,server_id_z);
         end if;
      end if;  -- SAME profile option is being evaluated

      if PROFILE_OPTION_EXISTS then

         -- Go through each level, based on HIERARCHY
         -- User-level with Security hierarchy
         if ((user_id_z <> -1) and (HIERARCHY = 'SECURITY') and
            ((USER_ENABLED ='Y') or (USER_CHANGEABLE='Y')) and   -- Bug 4257739
            (level_id_z = 10004)) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'UL Sec in FP.GSD');
            end if;
            get_specific_level_db(PROFILE_OPTION_ID,PROFILE_AID,10004,
               user_id_z,NULL,val_z,defined_z);

            if defined_z then
               -- Log value found at user-level and cached
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),
                     'GSLD VAL cached in USER_TABS FP.GSD, Exit FP.GSD',
                     user_id_z,responsibility_id_z,application_id_z,org_id_z,
                     server_id_z);
               end if;
               PUT(name_z,val_z,USER_NAME_TAB,USER_VAL_TAB,hashValue);
               return;
            end if;
         end if;

         -- Resp-level with Security hierarchy
         if ((responsibility_id_z <> -1) and
            (HIERARCHY = 'SECURITY' and RESP_ENABLED = 'Y') and
            (level_id_z = 10003)) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'RL Sec in FP.GSD');
            end if;
            get_specific_level_db(PROFILE_OPTION_ID,PROFILE_AID,10003,
               nvl(responsibility_id_z,PROFILES_RESP_ID),
               nvl(application_id_z,PROFILES_APPL_ID),val_z,defined_z);

            if defined_z then
               -- Log value found at resp-level and cached
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),
                     'GSLD VAL cached in RESP_TABS FP.GSD, Exit FP.GSD',
                     user_id_z,responsibility_id_z,application_id_z,org_id_z,
                     server_id_z);
               end if;
               PUT(name_z,val_z,RESP_NAME_TAB,RESP_VAL_TAB,hashValue);
               return;
            end if;
         end if;

         -- Appl-level with Security hierarchy
         if ((application_id_z <> -1) and
            (HIERARCHY = 'SECURITY' and APP_ENABLED = 'Y') and
            (level_id_z = 10002)) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'AL Sec in FP.GSD');
            end if;
            get_specific_level_db (PROFILE_OPTION_ID,PROFILE_AID,10002,
               application_id_z,NULL,val_z,defined_z);

            if defined_z then
               -- Log value found at appl-level and cached
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),
                     'GSLD VAL cached in APPL_TABS FP.GSD, Exit FP.GSD',
                     user_id_z,responsibility_id_z,application_id_z,org_id_z,
                     server_id_z);
               end if;
               PUT(name_z,val_z,APPL_NAME_TAB,APPL_VAL_TAB,hashValue);
               return;
            end if;
         end if;

         --
         -- If none of the context levels are set, i.e. user_id=-1, etc., then
         -- this is the only situation wherein we check the site-level value to
         -- ensure that context-level calls do not inadvertently return the
         -- site-level value.  This is only done for the SECURITY hierarchy.
         --
         -- Site-level with Security hierarchy --
         if ((HIERARCHY = 'SECURITY') and
             (SITE_ENABLED = 'Y') and
             (level_id_z = 10001)) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'SL Sec in FP.GSD');
            end if;
            get_specific_level_db(PROFILE_OPTION_ID,PROFILE_AID,10001,0,NULL,
               val_z,defined_z);

            if defined_z then
               /* Log value found at site-level and cached */
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),
                     'GSLD VAL cached in SITE_TABS FP.GSD, Exit FP.GSD',
                     user_id_z,responsibility_id_z,application_id_z,org_id_z,
                     server_id_z);
               end if;
               PUT(name_z,val_z,SITE_NAME_TAB,SITE_VAL_TAB,hashValue);
               return;
            end if;
         end if;

         -- User-level with Organization hierarchy
         if ((user_id_z <> -1) and (HIERARCHY = 'ORG') and
            ((USER_ENABLED ='Y') or (USER_CHANGEABLE='Y')) and  -- Bug 4257739
            (level_id_z = 10004)) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'UL Org in FP.GSD');
            end if;
            get_specific_level_db(PROFILE_OPTION_ID,PROFILE_AID,10004,
               user_id_z,NULL,val_z,defined_z);

            if defined_z then
               -- Log value found at user-level and cached
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),
                     'GSLD VAL cached in USER_TABS FP.GSD, Exit FP.GSD',
                     user_id_z,responsibility_id_z,application_id_z,org_id_z,
                     server_id_z);
               end if;
               PUT(name_z,val_z,USER_NAME_TAB,USER_VAL_TAB,hashValue);
               return;
            end if;
         end if;

         -- Org-level with Organization hierarchy
         if ((org_id_z <> -1) and
            (HIERARCHY = 'ORG' and ORG_ENABLED ='Y') and
            (level_id_z = 10006)) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'OL Org in FP.GSD');
            end if;
            get_specific_level_db(PROFILE_OPTION_ID,PROFILE_AID,10006,org_id_z,
               NULL,val_z,defined_z);

            if defined_z then
               -- Log value found at org-level and cached
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),
                     'GSLD VAL cached in ORG_TABS FP.GSD, Exit FP.GSD',
                     user_id_z,responsibility_id_z,application_id_z,org_id_z,
                     server_id_z);
               end if;
               PUT(name_z,val_z,ORG_NAME_TAB,ORG_VAL_TAB,hashValue);
               return;
            end if;
         end if;

         -- Site-level with Organization hierarchy
         if (HIERARCHY = 'ORG' and SITE_ENABLED = 'Y' and
            level_id_z = 10001) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'SL Org in FP.GSD');
            end if;
            get_specific_level_db (PROFILE_OPTION_ID,PROFILE_AID,10001,0,NULL,
               val_z,defined_z);

            if defined_z then
               -- Log value found at site-level and cached
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),
                     'GSLD VAL cached in SITE_TABS FP.GSD, Exit FP.GSD',
                     user_id_z,responsibility_id_z,application_id_z,org_id_z,
                     server_id_z);
               end if;
               PUT(name_z,val_z,SITE_NAME_TAB,SITE_VAL_TAB,hashValue);
               return;
            end if;
         end if;

         -- User-level with Server hierarchy
         if ((user_id_z <> -1) and (HIERARCHY = 'SERVER') and
            ((USER_ENABLED ='Y') or (USER_CHANGEABLE='Y')) and   -- Bug 4257739
            (level_id_z = 10004)) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'UL Server in FP.GSD');
            end if;
            get_specific_level_db (PROFILE_OPTION_ID,PROFILE_AID,10004,
               user_id_z,NULL,val_z,defined_z);

            if defined_z then
               -- Log value found at user-level and cached
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),
                     'GSLD VAL cached in USER_TABS FP.GSD, Exit FP.GSD',
                     user_id_z,responsibility_id_z,application_id_z,org_id_z,
                     server_id_z);
               end if;
               PUT(name_z,val_z,USER_NAME_TAB,USER_VAL_TAB,hashValue);
               return;
            end if;

         end if;

         -- Server-level with Server hierarchy
         if ((server_id_z <> -1) and
            (HIERARCHY = 'SERVER' and SERVER_ENABLED ='Y') and
            (level_id_z = 10005))then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'SRVL Server in FP.GSD');
            end if;
            get_specific_level_db(PROFILE_OPTION_ID,PROFILE_AID,10005,
               server_id_z,NULL,val_z,defined_z);

            if defined_z then
               -- Log value found at server-level and cached
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),
                     'GSLD VAL cached in SERVER_TABS FP.GSD, Exit FP.GSD',
                     user_id_z,responsibility_id_z,application_id_z,org_id_z,
                     server_id_z);
               end if;
               PUT(name_z,val_z,SERVER_NAME_TAB,SERVER_VAL_TAB,hashValue);
               return;
            end if;
         end if;

         -- Site-level with Server hierarchy
         if (HIERARCHY = 'SERVER' and SITE_ENABLED ='Y' and
            level_id_z = 10001) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'SL Server in FP.GSD');
            end if;
            get_specific_level_db(PROFILE_OPTION_ID,PROFILE_AID,10001,0,NULL,
               val_z,defined_z);

            if defined_z then
               -- Log value found at site-level and cached
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),
                     'GSLD VAL cached in SITE_TABS FP.GSD, Exit FP.GSD',
                     user_id_z,responsibility_id_z,application_id_z,org_id_z,
                     server_id_z);
               end if;
               PUT(name_z,val_z,SITE_NAME_TAB,SITE_VAL_TAB,hashValue);
               return;
            end if;
         end if;

         -- User-level with Server/Resp hierarchy
         if ((user_id_z <> -1) and (HIERARCHY = 'SERVRESP') and
            ((USER_ENABLED ='Y') or (USER_CHANGEABLE='Y')) and   -- Bug 4257739
            (level_id_z = 10004)) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'UL ServResp in FP.GSD');
            end if;
            get_specific_level_db(PROFILE_OPTION_ID,PROFILE_AID,10004,
               user_id_z,NULL,val_z,defined_z);

            if defined_z then
               -- Log value found at user-level and cached
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),
                     'GSLD VAL cached in USER_TABS FP.GSD, Exit FP.GSD',
                     user_id_z,responsibility_id_z,application_id_z,org_id_z,
                     server_id_z);
               end if;
               PUT(name_z,val_z,USER_NAME_TAB,USER_VAL_TAB,hashValue);
               return;
            end if;
         end if;

         -- Server-level with Server/Resp hierarchy
         if (HIERARCHY = 'SERVRESP' and SERVRESP_ENABLED ='Y' and
            level_id_z = 10007) then
            --
            -- This IF block may not really be required since the call to
            -- get_specific_level_db, as is, is likely able to handle all
            -- situations without the IF-ELSIF conditions.  That is:
            --   get_specific_level_db(PROFILE_OPTION_ID,PROFILE_AID,10007,
            --      responsibility_id_z,NULL,val_z,defined_z,server_id_z);
            -- should be able to return the correct value no matter what
            -- server_id_z and responsibility_id_z values are, even when value
            -- is -1 for any or both.
            --
            -- However, the IF block was placed to illustrate the order of
            -- precedence that the SERVRESP level has:
            --    Server/Responsibility > Responsibility > Server > Site
            --
            -- Accordingly, the calls to get_specific_level_db were
            -- deliberately coded depending on precedence.
            --

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'ServRespL ServResp in FP.GSD');
            end if;

            -- Responsibility ID and Server ID
            if (responsibility_id_z <> -1 and server_id_z <> -1) then
               get_specific_level_db(PROFILE_OPTION_ID,PROFILE_AID,10007,
                  responsibility_id_z,nvl(application_id_z,PROFILES_APPL_ID),
                  val_z,defined_z,server_id_z);

               if defined_z then
                  -- Log value found at servresp-level and cached
                  if CORELOG_IS_ENABLED then
                     CORELOG(name_z,nvl(val_z,'NOVAL'),
                        'GSLD VAL cached in SERVRESP_TABS FP.GSD, Exit FP.GSD',
                        user_id_z,responsibility_id_z,application_id_z,
                        org_id_z,server_id_z);
                  end if;
                  PUT(name_z,val_z,SERVRESP_NAME_TAB,SERVRESP_VAL_TAB,
                     hashValue);
                  return;
               else
                  -- Responsibility ID and -1 for Server
                  get_specific_level_db(PROFILE_OPTION_ID,PROFILE_AID,10007,
                     responsibility_id_z,
                     nvl(application_id_z,PROFILES_APPL_ID),val_z,
                     defined_z,-1);

                  if defined_z then
                     -- Log value found at servresp-level and cached
                     if CORELOG_IS_ENABLED then
                        CORELOG(name_z,nvl(val_z,'NOVAL'),
                           'GSLD VAL cached in SERVRESP_TABS FP.GSD,'||
                           'Exit FP.GSD',
                           user_id_z,responsibility_id_z,application_id_z,
                           org_id_z,
                     server_id_z);
                     end if;
                     PUT(name_z,val_z,SERVRESP_NAME_TAB,SERVRESP_VAL_TAB,
                        hashValue);
                     return;
                  else
                     -- -1 for Responsibility and Server ID
                     get_specific_level_db(PROFILE_OPTION_ID,PROFILE_AID,10007,
                        -1,-1,val_z,defined_z,server_id_z);

                     if defined_z then
                        -- Log value found at servresp-level and cached
                        if CORELOG_IS_ENABLED then
                           CORELOG(name_z,nvl(val_z,'NOVAL'),
                              'GSLD VAL cached in SERVRESP_TABS FP.GSD,'||
                              'Exit FP.GSD');
                        end if;
                        PUT(name_z,val_z,SERVRESP_NAME_TAB,SERVRESP_VAL_TAB,
                           hashValue);
                        return;
                     end if; -- -1 for Responsibility and Server ID
                  end if; -- Responsibility ID and -1 for Server
               end if;  -- Responsibility ID and Server ID

            -- Responsibility ID and -1 for Server
            elsif (responsibility_id_z <> -1 and server_id_z = -1) then
               get_specific_level_db(PROFILE_OPTION_ID,PROFILE_AID,10007,
                  responsibility_id_z,nvl(application_id_z,PROFILES_APPL_ID),
                  val_z,defined_z,-1);

               if defined_z then
                  -- Log value found at servresp-level and cached
                  if CORELOG_IS_ENABLED then
                     CORELOG(name_z,nvl(val_z,'NOVAL'),
                        'GSLD VAL cached in SERVRESP_TABS FP.GSD,'||
                        'Exit FP.GSD',
                        user_id_z,responsibility_id_z,application_id_z,
                        org_id_z,server_id_z);
                  end if;
                  PUT(name_z,val_z,SERVRESP_NAME_TAB,SERVRESP_VAL_TAB,
                     hashValue);
                  return;
               else
                  -- -1 for Responsibility and Server ID
                  get_specific_level_db(PROFILE_OPTION_ID,PROFILE_AID,10007,
                     -1,-1,val_z,defined_z,server_id_z);

                  if defined_z then
                     -- Log value found at servresp-level and cached
                     if CORELOG_IS_ENABLED then
                     CORELOG(name_z,nvl(val_z,'NOVAL'),
                        'GSLD VAL cached in SERVRESP_TABS FP.GSD,'||
                        'Exit FP.GSD',
                        user_id_z,responsibility_id_z,application_id_z,
                        org_id_z,server_id_z);
                     end if;
                     PUT(name_z,val_z,SERVRESP_NAME_TAB,SERVRESP_VAL_TAB,
                        hashValue);
                     return;
                  end if; -- -1 for Responsibility and Server ID
               end if; -- Responsibility ID and -1 for Server

            -- -1 for Responsibility and Server ID
            elsif (server_id_z <> -1 and responsibility_id_z = -1) then
               get_specific_level_db(PROFILE_OPTION_ID,PROFILE_AID,10007,-1,-1,
                  val_z,defined_z,server_id_z);

               if defined_z then
                  -- Log value found at servresp-level and cached
                  if CORELOG_IS_ENABLED then
                     CORELOG(name_z,nvl(val_z,'NOVAL'),
                        'GSLD VAL cached in SERVRESP_TABS FP.GSD,'||
                        'Exit FP.GSD',
                        user_id_z,responsibility_id_z,application_id_z,
                        org_id_z,server_id_z);
                  end if;
                  PUT(name_z,val_z,SERVRESP_NAME_TAB,SERVRESP_VAL_TAB,
                     hashValue);
                  return;
               end if; -- -1 for Responsibility and Server ID
            end if;
         end if;

         -- Site-level with Server/Resp hierarchy --
         if (HIERARCHY = 'SERVRESP' and SITE_ENABLED ='Y' and
            level_id_z = 10001) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'SL ServResp in FP.GSD');
            end if;
            get_specific_level_db(PROFILE_OPTION_ID,PROFILE_AID,10001,0,NULL,
               val_z,defined_z);

            if defined_z then
               -- Log value found at site-level and cached
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),
                     'GSLD VAL cached in SITE_TABS FP.GSD, Exit FP.GSD',
                     user_id_z,responsibility_id_z,application_id_z,org_id_z,
                     server_id_z);
               end if;
               PUT(name_z,val_z,SITE_NAME_TAB,SITE_VAL_TAB,hashValue);
               return;
            end if;
         end if;

      end if;  -- PROFILE_OPTION_EXISTS if-then block

      -- If the call gets here, then no value was found.
      val_z := NULL;
      defined_z := FALSE;

      -- Log value not found at any level
      if CORELOG_IS_ENABLED then
         CORELOG(name_z,nvl(val_z,'NOVAL'),'Exit FP.GSD',
            user_id_z,responsibility_id_z,application_id_z,org_id_z,
            server_id_z);
      end if;
   END GET_SPECIFIC_DB;


   /*
   ** This procedure is needed to get around the WNPS pragma.
   */
   procedure GET_SPECIFIC_DB_WNPS (
      name_z              in varchar2,
      user_id_z           in number default null,
      responsibility_id_z in number default null,
      application_id_z    in number default null,
      val_z               out NOCOPY     varchar2,
      defined_z           out NOCOPY     boolean,
      org_id_z            in number   default null,
      server_id_z         in number   default null,
      level_id_z          in number) is

      --
      -- this cursor fetches profile information that will allow subsequent
      -- fetches to be more efficient
      --
      cursor profile_info is
         select   profile_option_id,
                  application_id,
                  site_enabled_flag ,
                  app_enabled_flag ,
                  resp_enabled_flag ,
                  user_enabled_flag,
                  org_enabled_flag ,
                  server_enabled_flag,
                  serverresp_enabled_flag,
                  hierarchy_type,
                  user_changeable_flag     -- Bug 4257739
         from fnd_profile_options
         where   profile_option_name = name_z
         and  start_date_active  <= sysdate
         and  nvl(end_date_active, sysdate) >= sysdate;

      --
      -- this cursor fetches profile option values for site, application,
      -- and user levels (10001/10002/10004)
      --
      cursor value_uas(pid number, aid number, lid number, lval number) is
         select profile_option_value
         from   fnd_profile_option_values
         where  profile_option_id = pid
         and  application_id = aid
         and  level_id = lid
         and  level_value = lval
         and  profile_option_value is not null;
      --
      -- this cursor fetches profile option values at the responsibility
      -- level (10003)
      --
      cursor value_resp(pid number, aid number, lval number, laid number) is
         select profile_option_value
         from fnd_profile_option_values
         where profile_option_id = pid
         and  application_id = aid
         and  level_id = 10003
         and  level_value = lval
         and  level_value_application_id = laid
         and  profile_option_value is not null;
      --
      -- this cursor fetches profile option values at the server+responsibility
      -- level (10007)
      --
      cursor value_servresp(pid number, aid number, lval number, laid number,
         lval2 number) is
         select profile_option_value
         from fnd_profile_option_values
         where profile_option_id = pid
         and  application_id = aid
         and  level_id = 10007
         and  level_value = lval
         and  level_value_application_id = laid
         and  level_value2 = lval2
         and  profile_option_value is not null;

   begin

      -- Log API Entry
      if CORELOG_IS_ENABLED then
         CORELOG(
            name_z,
            nvl(val_z,'NOVAL'),
            'Enter FP.GSDW',
            user_id_z,
            responsibility_id_z,
            application_id_z,
            org_id_z,
            server_id_z);
      end if;

      val_z := NULL;
      defined_z := FALSE;

      --
      -- Check if the same profile option is being evaluated.  If not, then
      -- open the cursor and store those values into the GLOBAL variables.
      --
      if ((PROFILE_OPTION_NAME is null) or (name_z <> PROFILE_OPTION_NAME))
         then

         -- Get profile info from database
         open profile_info;
         fetch profile_info into
            PROFILE_OPTION_ID,
            PROFILE_AID,
            SITE_ENABLED,
            APP_ENABLED,
            RESP_ENABLED,
            USER_ENABLED,
            ORG_ENABLED,
            SERVER_ENABLED,
            SERVRESP_ENABLED,
            HIERARCHY,
            USER_CHANGEABLE;   -- Bug 4257739

         if (profile_info%NOTFOUND) then
            val_z := NULL;
            defined_z := FALSE;
            PROFILE_OPTION_EXISTS := FALSE;
            close profile_info;

            -- Log cursor executed but no profile
            if CORELOG_IS_ENABLED then
               CORELOG(
                  name_z,
                  nvl(val_z,'NOVAL'),
                  'CURSOR EXEC in FP.GSDW, NOPROF',
                  user_id_z,
                  responsibility_id_z,
                  application_id_z,
                  org_id_z,
                  server_id_z);
            end if;

            return;
         end if; -- profile_info%NOTFOUND

         close profile_info;
         PROFILE_OPTION_NAME := name_z;
         PROFILE_OPTION_EXISTS := TRUE;

         -- Log cursor executed and profile found
         if CORELOG_IS_ENABLED then
            CORELOG(
               name_z,
               nvl(val_z,'NOVAL'),
               'CURSOR EXEC in FP.GSDW, PROF',
               user_id_z,
               responsibility_id_z,
               application_id_z,
               org_id_z,
               server_id_z);
         -- Log profile definition
            FND_CORE_LOG.PUT_LINE(name_z,PROFILE_OPTION_ID||':'||
               PROFILE_AID||':'||SITE_ENABLED||':'||APP_ENABLED||':'||
               RESP_ENABLED||':'||USER_ENABLED||':'||ORG_ENABLED||':'||
               SERVER_ENABLED||':'||SERVRESP_ENABLED||':'||HIERARCHY||':'||
               USER_CHANGEABLE);
            end if;
      else

         /* Bug 5209533: FND_GLOBAL.INITIALIZE RAISES APP-FND-02500 EXECUTING
         ** RULE FUNCTIONS FOR WF EVENT
         ** Setting PROFILE_OPTION_EXISTS = TRUE explicitly IF the condition is
         ** not satisfied.  This guarantees that the profile gets evaluated if
         ** PROFILE_OPTION_EXISTS is not FALSE, e.g. NULL;
         */
         PROFILE_OPTION_EXISTS := TRUE;

         -- Log cursor NOT executed and profile found
         if CORELOG_IS_ENABLED then
            CORELOG(
               name_z,
               nvl(val_z,'NOVAL'),
               'CURSOR *NOEXEC* in FP.GSDW, PROF',
               user_id_z,
               responsibility_id_z,
               application_id_z,
               org_id_z,
               server_id_z);
         end if;

      end if;  -- SAME profile option is being evaluated
      --
      -- The conditions have been modelled after GET_SPECIFIC_DB to make
      -- behavior consistent between GET_SPECIFIC_DB and GET_SPECIFIC_DB_WNPS.
      --
      if PROFILE_OPTION_EXISTS then

         -- USER level with Security hierarchy
         if ((user_id_z <> -1) and (HIERARCHY = 'SECURITY') and
             ((USER_ENABLED ='Y') or (USER_CHANGEABLE='Y')) and -- Bug 4257739
             (level_id_z = 10004)) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'UL Sec in FP.GSDW');
            end if;
            open value_uas(PROFILE_OPTION_ID,PROFILE_AID,10004,nvl(user_id_z,
               PROFILES_USER_ID));
            fetch value_uas into val_z;
            if (value_uas%NOTFOUND) then
               defined_z := FALSE;
               close value_uas;
            else
               defined_z := TRUE;
               close value_uas;
               -- Log value found at user-level
               if CORELOG_IS_ENABLED then
                  CORELOG(
                     name_z,
                     nvl(val_z,'NOVAL'),
                     'UL VAL in GSDW',
                     user_id_z,
                     responsibility_id_z,
                     application_id_z,
                     org_id_z,
                     server_id_z);
               end if;
               return;
            end if; -- value_uas%NOTFOUND

         end if;

         -- RESP level with Security hierarchy
         if ((responsibility_id_z <> -1) and (HIERARCHY = 'SECURITY'
            and RESP_ENABLED = 'Y')  and (level_id_z = 10003)) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'RL Sec in FP.GSDW');
            end if;
            open value_resp(PROFILE_OPTION_ID,PROFILE_AID,
               nvl(responsibility_id_z,PROFILES_RESP_ID),
               nvl(application_id_z,PROFILES_APPL_ID));
            fetch value_resp into val_z;
            if (value_resp%NOTFOUND) then
               defined_z := FALSE;
               close value_resp;
            else
               defined_z := TRUE;
               close value_resp;
               -- Log value found at resp-level
               if CORELOG_IS_ENABLED then
                  CORELOG(
                     name_z,
                     nvl(val_z,'NOVAL'),
                     'RL VAL in GSDW',
                     user_id_z,
                     responsibility_id_z,
                     application_id_z,
                     org_id_z,
                     server_id_z);
               end if;
               return;
            end if; -- value_resp%NOTFOUND

         end if;

         -- APPL level with Security hierarchy
         if ((application_id_z <> -1) and (HIERARCHY = 'SECURITY'
            and APP_ENABLED = 'Y') and (level_id_z = 10002)) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'AL Sec in FP.GSDW');
            end if;
            open value_uas(PROFILE_OPTION_ID,PROFILE_AID,10002,
               nvl(application_id_z,PROFILES_APPL_ID));
            fetch value_uas into val_z;
            if (value_uas%NOTFOUND) then
               defined_z := FALSE;
               close value_uas;
            else
               defined_z := TRUE;
               close value_uas;
               -- Log value found at appl-level
               if CORELOG_IS_ENABLED then
                  CORELOG(
                     name_z,
                     nvl(val_z,'NOVAL'),
                     'AL VAL in GSDW',
                     user_id_z,
                     responsibility_id_z,
                     application_id_z,
                     org_id_z,
                     server_id_z);
               end if;
               return;
            end if; -- value_uas%NOTFOUND

         end if;

         --
         -- If none of the context levels are set, i.e. user_id= -1, etc., then
         -- this is the only situation wherein we check the site-level value to
         -- ensure that context-level calls do not inadvertently return the
         -- site-level value.  This is only done for the SECURITY hierarchy.
         --
         -- Site level with Security hierarchy
         if (HIERARCHY = 'SECURITY' and SITE_ENABLED = 'Y' and
            level_id_z = 10001) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'SL Sec in FP.GSDW');
            end if;
            open value_uas(PROFILE_OPTION_ID,PROFILE_AID,10001,0);
            fetch value_uas into val_z;
            if (value_uas%NOTFOUND) then
               defined_z := FALSE;
               close value_uas;
            else
               defined_z := TRUE;
               close value_uas;
               -- Log value found at site-level
               if CORELOG_IS_ENABLED then
                  CORELOG(
                     name_z,
                     nvl(val_z,'NOVAL'),
                     'SL VAL in GSDW',
                     user_id_z,
                     responsibility_id_z,
                     application_id_z,
                     org_id_z,
                     server_id_z);
               end if;
               return;
            end if; -- value_uas%NOTFOUND
         end if;

         -- USER level with Organization hierarchy
         if ((user_id_z <> -1) and (HIERARCHY = 'ORG') and
             ((USER_ENABLED ='Y') or (USER_CHANGEABLE='Y')) and -- Bug 4257739
             (level_id_z = 10004)) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'UL Org in FP.GSDW');
            end if;
            open value_uas(PROFILE_OPTION_ID,PROFILE_AID,10004,nvl(user_id_z,
               PROFILES_USER_ID));
            fetch value_uas into val_z;
            if (value_uas%NOTFOUND) then
               defined_z := FALSE;
               close value_uas;
            else
               defined_z := TRUE;
               close value_uas;
               -- Log value found at user-level
               if CORELOG_IS_ENABLED then
                  CORELOG(
                     name_z,
                     nvl(val_z,'NOVAL'),
                     'UL VAL in GSDW',
                     user_id_z,
                     responsibility_id_z,
                     application_id_z,
                     org_id_z,
                     server_id_z);
               end if;
               return;
            end if; -- value_uas%NOTFOUND

         end if;

         -- ORG level with Organization hierarchy
         if ((org_id_z <> -1) and (HIERARCHY = 'ORG' and ORG_ENABLED ='Y')
         and (level_id_z = 10006)) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'OL Org in FP.GSDW');
            end if;
            open value_uas(PROFILE_OPTION_ID,PROFILE_AID,10006,
               nvl(org_id_z,PROFILES_ORG_ID));
            fetch value_uas into val_z;
            if (value_uas%NOTFOUND) then
               close value_uas;
               defined_z := FALSE;
            else
               defined_z := TRUE;
               close value_uas;
               -- Log value found at org-level
               if CORELOG_IS_ENABLED then
                  CORELOG(
                     name_z,
                     nvl(val_z,'NOVAL'),
                     'OL VAL in GSDW',
                     user_id_z,
                     responsibility_id_z,
                     application_id_z,
                     org_id_z,
                     server_id_z);
               end if;
               return;
            end if; -- value_uas%NOTFOUND

         end if;

         -- SITE level with Organization hierarchy
         if (HIERARCHY = 'ORG' and SITE_ENABLED = 'Y' and
            level_id_z = 10001) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'SL Org in FP.GSDW');
            end if;
            open value_uas(PROFILE_OPTION_ID,PROFILE_AID,10001,0);
            fetch value_uas into val_z;
            if (value_uas%NOTFOUND) then
               defined_z := FALSE;
               close value_uas;
            else
               defined_z := TRUE;
               close value_uas;
               -- Log value found at site-level
               if CORELOG_IS_ENABLED then
                  CORELOG(
                     name_z,
                     nvl(val_z,'NOVAL'),
                     'SL VAL in GSDW',
                     user_id_z,
                     responsibility_id_z,
                     application_id_z,
                     org_id_z,
                     server_id_z);
               end if;
               return;
            end if; -- value_uas%NOTFOUND

         end if;

         -- USER level with Server hierarchy
         if ((user_id_z <> -1) and (HIERARCHY = 'SERVER') and
           ((USER_ENABLED ='Y') or (USER_CHANGEABLE='Y')) and   -- Bug 4257739
           (level_id_z = 10004)) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'UL Server in FP.GSDW');
            end if;
            open value_uas(PROFILE_OPTION_ID,PROFILE_AID,10004,nvl(user_id_z,
               PROFILES_USER_ID));
            fetch value_uas into val_z;
            if (value_uas%NOTFOUND) then
               defined_z := FALSE;
               close value_uas;
            else
               defined_z := TRUE;
               close value_uas;
               -- Log value found at user-level
               if CORELOG_IS_ENABLED then
                  CORELOG(
                     name_z,
                     nvl(val_z,'NOVAL'),
                     'UL VAL in GSDW',
                     user_id_z,
                     responsibility_id_z,
                     application_id_z,
                     org_id_z,
                     server_id_z);
               end if;
               return;
            end if; -- value_uas%NOTFOUND

         end if;

         -- SERVER level with Server hierarchy
         if ((server_id_z <> -1) and
             (HIERARCHY = 'SERVER' and SERVER_ENABLED ='Y') and
             (level_id_z = 10005)) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'SRVL Server in FP.GSDW');
            end if;
            open value_uas(PROFILE_OPTION_ID,PROFILE_AID,10005,nvl(server_id_z,
               PROFILES_SERVER_ID));
            fetch value_uas into val_z;
            if (value_uas%NOTFOUND) then
               defined_z := FALSE;
               close value_uas;
            else
               defined_z := TRUE;
               close value_uas;
               -- Log value found at server-level
               if CORELOG_IS_ENABLED then
                  CORELOG(
                     name_z,
                     nvl(val_z,'NOVAL'),
                     'SRVL VAL in GSDW',
                     user_id_z,
                     responsibility_id_z,
                     application_id_z,
                     org_id_z,
                     server_id_z);
               end if;
               return;
            end if; -- value_uas%NOTFOUND

         end if;

         -- SITE level with Server hierarchy
         if (HIERARCHY = 'SERVER' and SITE_ENABLED ='Y' and
            level_id_z = 10001) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'SL Server in FP.GSDW');
            end if;
            open value_uas(PROFILE_OPTION_ID,PROFILE_AID,10001,0);
            fetch value_uas into val_z;
            if (value_uas%NOTFOUND) then
               defined_z := FALSE;
               close value_uas;
            else
               defined_z := TRUE;
               close value_uas;
               -- Log value found at site-level
               if CORELOG_IS_ENABLED then
                  CORELOG(
                     name_z,
                     nvl(val_z,'NOVAL'),
                     'SL VAL in GSDW',
                     user_id_z,
                     responsibility_id_z,
                     application_id_z,
                     org_id_z,
                     server_id_z);
               end if;
               return;
            end if; -- value_uas%NOTFOUND

         end if;

         -- USER level with Server/Responsibility hierarchy
         if ((user_id_z <> -1) and (HIERARCHY = 'SERVRESP') and
             ((USER_ENABLED ='Y') or (USER_CHANGEABLE='Y')) and -- Bug 4257739
             (level_id_z = 10004)) then

            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'UL ServResp in FP.GSDW');
            end if;
            open value_uas(PROFILE_OPTION_ID,PROFILE_AID,10004,nvl(user_id_z,
               PROFILES_USER_ID));
            fetch value_uas into val_z;
            if (value_uas%NOTFOUND) then
               defined_z := FALSE;
               close value_uas;
            else
               defined_z := TRUE;
               close value_uas;
               -- Log value found at user-level
               if CORELOG_IS_ENABLED then
                  CORELOG(
                     name_z,
                     nvl(val_z,'NOVAL'),
                     'UL VAL in GSDW',
                     user_id_z,
                     responsibility_id_z,
                     application_id_z,
                     org_id_z,
                     server_id_z);
               end if;
               return;
            end if; -- value_uas%NOTFOUND

         end if;

         -- SERVRESP level with Server/Responsibility hierarchy
         if (HIERARCHY = 'SERVRESP' and SERVRESP_ENABLED = 'Y' and
            level_id_z = 10007) then
            -- Responsibility and Server
            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'ServRespL ServResp in FP.GSDW');
            end if;
            if (responsibility_id_z <> -1 and server_id_z <> -1) then
              if CORELOG_IS_ENABLED then
                 FND_CORE_LOG.PUT_LINE('ServRespL:R <> -1 and S <> -1');
              end if;
               open value_servresp(PROFILE_OPTION_ID,PROFILE_AID,
                  nvl(responsibility_id_z,PROFILES_RESP_ID),
                  nvl(application_id_z,PROFILES_APPL_ID),
                  nvl(server_id_z,PROFILES_SERVER_ID));
               -- Bug 4017612
               fetch value_servresp into val_z;
               if (value_servresp%NOTFOUND) then
                  defined_z := FALSE;
                  close value_servresp;
               else
                  defined_z := TRUE;
                  close value_servresp;
                  -- Log value found at user-level
                  if CORELOG_IS_ENABLED then
                     CORELOG(
                        name_z,
                        nvl(val_z,'NOVAL'),
                        'ServRespL VAL in GSDW',
                        user_id_z,
                        responsibility_id_z,
                        application_id_z,
                        org_id_z,
                        server_id_z);
                  end if;
                  return;
               end if; -- value_servresp%NOTFOUND
            -- Responsibility and -1 for Server
            elsif (responsibility_id_z <> -1 and server_id_z = -1) then
               if CORELOG_IS_ENABLED then
                 FND_CORE_LOG.PUT_LINE('ServRespL:R <> -1 and S = -1');
               end if;
               open value_servresp(PROFILE_OPTION_ID,PROFILE_AID,
                  nvl(responsibility_id_z,PROFILES_RESP_ID),
                  nvl(application_id_z,PROFILES_APPL_ID),
                  -1);
               -- Bug 4017612
               fetch value_servresp into val_z;
               if (value_servresp%NOTFOUND) then
                  defined_z := FALSE;
                  close value_servresp;
               else
                  defined_z := TRUE;
                  close value_servresp;
                  -- Log value found at user-level
                  if CORELOG_IS_ENABLED then
                     CORELOG(
                        name_z,
                        nvl(val_z,'NOVAL'),
                        'ServRespL VAL in GSDW',
                        user_id_z,
                        responsibility_id_z,
                        application_id_z,
                        org_id_z,
                        server_id_z);
                  end if;
                  return;
               end if; -- value_servresp%NOTFOUND
            -- Server and -1 for Responsibility
            elsif (server_id_z <> -1 and responsibility_id_z = -1) then
               if CORELOG_IS_ENABLED then
                 FND_CORE_LOG.PUT_LINE('ServRespL:R = -1 and S <> -1');
               end if;
               open value_servresp(PROFILE_OPTION_ID,PROFILE_AID,
                  -1,
                  -1,
                  nvl(server_id_z,PROFILES_SERVER_ID));
               -- Bug 4017612
               fetch value_servresp into val_z;
               if (value_servresp%NOTFOUND) then
                  defined_z := FALSE;
                  close value_servresp;
               else
                  defined_z := TRUE;
                  close value_servresp;
                  -- Log value found at user-level
                  if CORELOG_IS_ENABLED then
                     CORELOG(
                        name_z,
                        nvl(val_z,'NOVAL'),
                        'ServRespL VAL in GSDW',
                        user_id_z,
                        responsibility_id_z,
                        application_id_z,
                        org_id_z,
                        server_id_z);
                  end if;
                  return;
               end if; -- value_servresp%NOTFOUND
            else
               -- Context does not fit into the 3 *valid* servresp-level
               -- contexts.
               defined_z := FALSE;
            end if;
         end if;

         -- SITE level with Server hierarchy
         if (HIERARCHY = 'SERVRESP' and SITE_ENABLED ='Y' and
            level_id_z = 10001) then
            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(name_z,'SL ServResp in FP.GSDW');
            end if;
            open value_uas(PROFILE_OPTION_ID,PROFILE_AID,10001,0);
            fetch value_uas into val_z;
            if (value_uas%NOTFOUND) then
               defined_z := FALSE;
               close value_uas;
            else
               defined_z := TRUE;
               close value_uas;

               -- Log value found at site-level
               if CORELOG_IS_ENABLED then
                  CORELOG(
                     name_z,
                     nvl(val_z,'NOVAL'),
                     'SL VAL in GSDW',
                     user_id_z,
                     responsibility_id_z,
                     application_id_z,
                     org_id_z,
                     server_id_z);
               end if;
               return;
            end if; -- value_uas%NOTFOUND

         end if;

      end if; -- PROFILE_OPTION_EXISTS if-then block

      -- If the call gets here, then no value was found.
      val_z := NULL;
      defined_z := FALSE;

      -- Log value not found at any level
      if CORELOG_IS_ENABLED then
         CORELOG(
            name_z,
            nvl(val_z,'NOVAL'),
            'Exit FP.GSDW',
            user_id_z,
            responsibility_id_z,
            application_id_z,
            org_id_z,
            server_id_z);
      end if;

   END GET_SPECIFIC_DB_WNPS;

  /*
  ** GET_SPECIFIC_WNPS -
  **   Get the profile option value for a specific context (without changing
  **   package state).
  **
  **   Context arguments (user_id_z, responsibility_id_z, application_id_z,
  **   org_id_z, server_id_z) specify what context to use to determine the
  **   profile option value.  Context arguments are interpreted as follows:
  **
  **        NULL - use current session context value (default)
  **          -1 - override current context with "undefined" value
  **     <value> - override current context with specified value
  **
  **   Special Notes:
  **     - Context override values are only used for determining the profile
  **       option value in this function call, the user session context is not
  **       changed.
  **
  **     - An undefined context value (-1) causes that context level to be
  **       skipped during processing, meaning that any profile option values
  **       set at that context level are ignored.
  **
  **     - Regardless of which context levels are defined, the profile option
  **       HIERARCHY_TYPE and '%_ENABLED_FLAG' flags determine which context
  **       levels are searched to find the value.
  **
  **     - Dynamic profile option values (PUT()) are NOT considered in this
  **       function, we only search values that are stored in the database.
  **
  */
  procedure GET_SPECIFIC_WNPS(
    name_z               in varchar2, -- calling api should pass UPPER value
    user_id_z            in number default null,
    responsibility_id_z  in number default null,
    application_id_z     in number default null,
    val_z                out NOCOPY     varchar2,
    defined_z            out NOCOPY     boolean,
    org_id_z             in number default null,
    server_id_z          in number default null) is

    value       varchar2(240);
    cached      boolean;
    hashValue   binary_integer;
    userLevelSkip boolean := FALSE;
    respLevelSkip boolean := FALSE;
    applLevelSkip boolean := FALSE;
    orgLevelSkip boolean := FALSE;
    serverLevelSkip boolean := FALSE;
    servrespLevelSkip boolean := FALSE;

  begin

    if CORELOG_IS_ENABLED then
       CORELOG(name_z,nvl(val_z, 'NOVAL'),'Enter FP.GSW',user_id_z,
          responsibility_id_z,application_id_z,org_id_z,server_id_z);
    end if;

    val_z := NULL;
    defined_z := FALSE;

    /* Bug 5603664: APPSPERF:FND:OPTIMIZE FND_PROFILE.VALUE
    ** Generate hashValue and pass it on to FIND and PUT calls.
    */
    hashValue := dbms_utility.get_hash_value(name_z,1,TABLE_SIZE);

    -- Determine if any of the context parameters, passed in, is equal to -1.
    -- -1 means that the level will be skipped for evaluation. These boolean
    -- flags replace the context conditions that check whether the context is
    -- <> -1. These conditions do not work when the context value is NUsLL since
    -- the comparison condition NULL <> -1 will equal FALSE even when NULL is
    -- not equal to -1. NULL cannot be directly compared with a number.
    --
    -- Skip user level if user_id_z = -1
    if user_id_z = -1 then
      userLevelSkip := TRUE;
    end if;

    -- Skip responsibility level if responsibility_id_z = -1 and
    -- application_id_z = -1
    if (responsibility_id_z = -1 and application_id_z = -1) then
      respLevelSkip := TRUE;
    end if;

    -- Skip application level if application_id_z = -1
    if application_id_z = -1 then
      applLevelSkip := TRUE;
    end if;

    -- Skip organization level if org_id_z = -1
    if org_id_z = -1 then
      orgLevelSkip := TRUE;
    end if;

    -- Skip server level if server_id_z = -1
    if server_id_z = -1 then
      serverLevelSkip := TRUE;
    end if;

    -- Skip servresp level if responsibility_id_z, application_id_z and
    -- server_id_z all equal to -1
    if (responsibility_id_z = -1 and application_id_z = -1) and
      server_id_z = -1 then
      servrespLevelSkip := TRUE;
    end if;

    --
    -- The algorithm checks the context-level caches before going to the DB.
    -- If no value was obtained from context-level cache, then it checks the
    -- DB to ensure that accurate values are returned.
    --
    -- User-level cache is initially evaluated. If there is no level cache
    -- value at the user-level, then a database fetch is done. If no DB value is
    -- found at the user-level AND the context passed in is EQUAL to the
    -- current context, then the string **FND_UNDEFINED_VALUE** is placed at the
    -- user-level cache. This does 2 things: it prevents another DB fetch for
    -- the level and it also says that the level applies to the profile without
    -- having the profile option's definition. The code then "drops" to the next
    -- level and performs the same algorithm.
    --
    -- The benefit of just "dropping" to the next level without knowing whether
    -- the level applies to the profile or not is that a DB fetch can be avoided
    -- IF the levels have values already cached. Again, if a level has a value
    -- cached, then the level probably applies to the profile. Otherwise, there
    -- would not be a value cached.
    --
    -- This is a similar algorithm used in GET_CACHED to return accurate values.
    --
    -- By design, PROFILE_OPTION_EXISTS is not being checked here so that the
    -- code allows the profile to be *initially* (at least once) evaluated
    -- in GET_SPECIFIC_DB_WNPS which determines whether the profile exists.
    --
    --
    -- Evaluate User-level starting with the level cache if the context passed
    -- in <> -1.
    if userLevelSkip then
      -- If user context = -1, then user level should not be evaluated.
      -- This GET_SPECIFIC_DB_WNPS call will allow the profile option's
      -- definition to be fetched and used by the other applicable levels.
      -- The db fetch will also set PROFILE_OPTION_EXISTS accordingly.
      --
      -- NOTE: Should a value be found with the database fetch, the value is
      -- likely from the site-level and may not accurately represent the return
      -- value given the context passed in. The variables that hold the return
      -- values are reset just to be safe.
      GET_SPECIFIC_DB_WNPS(name_z,-1,-1,-1,val_z,defined_z,-1,-1,10004);
      -- Logging that user_id = -1 and that values were reset
      if CORELOG_IS_ENABLED then
        CORELOG(name_z,nvl(val_z,'RESET'),'user_id_z=-1 in FP.GSW',
          user_id_z,responsibility_id_z,application_id_z,org_id_z,server_id_z);
      end if;
      val_z := NULL;
      defined_z := FALSE;
    else
      -- Check the user-level cache for a value.
      GET_SPECIFIC_LEVEL_WNPS(name_z,10004,nvl(user_id_z,PROFILES_USER_ID),0,
        value,cached,NULL,hashValue);
      if (value is not null) then
        -- Profile exists because a value is cached.
        PROFILE_OPTION_EXISTS := TRUE;
        -- Log value found in user-level cache
        if CORELOG_IS_ENABLED then
          CORELOG(name_z,nvl(value,'NOVAL'),'UL Cache not null in FP.GSW',
            user_id_z,responsibility_id_z,application_id_z,org_id_z,
            server_id_z);
        end if;

        if (value <> FND_UNDEFINED_VALUE) then
          val_z := value;
          defined_z := TRUE;
          -- Log value found in user-level cache
          if CORELOG_IS_ENABLED then
            CORELOG(name_z,nvl(val_z,'NOVAL'),'UL Cache VAL in FP.GSW',
              user_id_z,responsibility_id_z,application_id_z,org_id_z,
              server_id_z);
          end if;
          return;
        end if;
      else
        -- If no value was found in cache, i.e. NULL was returned, then
        -- see if user-level context has a value in database.
        GET_SPECIFIC_DB_WNPS(name_z,nvl(user_id_z,PROFILES_USER_ID),-1,-1,val_z,
          defined_z,-1,-1,10004);
        if defined_z then -- Value found at user-level
          -- Log value found
          if CORELOG_IS_ENABLED then
            CORELOG(name_z,nvl(val_z,'NOVAL'),'UL VAL via GSDW in FP.GSW',
              user_id_z,responsibility_id_z,application_id_z,org_id_z,
              server_id_z);
          end if;
          return;
        elsif (user_id_z = PROFILES_USER_ID) then
          -- Cache '**FND_UNDEFINED_VALUE**' value for profile at user-level
          -- if context is the same, i.e. user_id_z = PROFILES_USER_ID.
          PUT(name_z,FND_UNDEFINED_VALUE,USER_NAME_TAB,USER_VAL_TAB,hashValue);
        end if;
      end if;
    end if;

    -- Evaluate Responsibility-level and see if the cache has a value.
    -- Bypass if responsibility_id_z and/or application_id_z = -1.
    if PROFILE_OPTION_EXISTS and not respLevelSkip then
      -- Check Responsibility-level cache
      GET_SPECIFIC_LEVEL_WNPS(name_z,10003,
        nvl(responsibility_id_z,PROFILES_RESP_ID),
        nvl(application_id_z,PROFILES_APPL_ID),value,cached,NULL,hashValue);
      if (value is not null) then
        -- Log value found in resp-level cache
        if CORELOG_IS_ENABLED then
          CORELOG(name_z,nvl(value,'NOVAL'),'RL Cache not null in FP.GSW',
            user_id_z,responsibility_id_z,application_id_z,org_id_z,
            server_id_z);
        end if;

        if (value <> FND_UNDEFINED_VALUE) then
          val_z := value;
          defined_z := TRUE;
          -- Log value found in resp-level cache
          if CORELOG_IS_ENABLED then
            CORELOG(name_z,nvl(value,'NOVAL'),'RL Cache VAL in FP.GSW',
              user_id_z,responsibility_id_z,application_id_z,org_id_z,
              server_id_z);
          end if;
          return;
        end if;
      else
        -- See if Responsibility-level context has a value in database.
        GET_SPECIFIC_DB_WNPS(name_z,-1,
          nvl(responsibility_id_z,PROFILES_RESP_ID),
          nvl(application_id_z,PROFILES_APPL_ID),val_z,defined_z,-1,-1,10003);
        if defined_z then -- Value found at responsibility-level
          -- Log value found
          if CORELOG_IS_ENABLED then
            CORELOG(name_z,nvl(val_z,'NOVAL'),'RL VAL via GSDW in FP.GSW',
              user_id_z,responsibility_id_z,application_id_z,org_id_z,
              server_id_z);
          end if;
          return;
        elsif ((responsibility_id_z = PROFILES_RESP_ID) and
          (application_id_z = PROFILES_APPL_ID)) then
          -- Cache '**FND_UNDEFINED_VALUE**' value for profile at
          -- resp-level if context is the same, i.e. responsibility_id_z =
          -- PROFILES_RESP_ID and application_id_z = PROFILES_APPL_ID.
          PUT(name_z,FND_UNDEFINED_VALUE,RESP_NAME_TAB,RESP_VAL_TAB,hashValue);
        end if;
      end if;
    end if;

    -- Evaluate the Application-level and see if the cache has a value.
    -- Bypass if application_id_z = -1.
    if PROFILE_OPTION_EXISTS and not applLevelSkip then
      -- Check Application-level cache
      GET_SPECIFIC_LEVEL_WNPS(name_z,10002,
        nvl(application_id_z,PROFILES_APPL_ID),0,value,cached,NULL,hashValue);
      if (value is not null) then
        -- Log value found in appl-level cache
        if CORELOG_IS_ENABLED then
          CORELOG(name_z,nvl(value,'NOVAL'),'AL Cache not null in FP.GSW',
            user_id_z,responsibility_id_z,application_id_z,org_id_z,
            server_id_z);
        end if;

        if (value <> FND_UNDEFINED_VALUE) then
          val_z := value;
          defined_z := TRUE;
          -- Log value found in appl-level cache
          if CORELOG_IS_ENABLED then
          CORELOG(name_z,nvl(value,'NOVAL'),'AL Cache VAL in FP.GSW',
            user_id_z,responsibility_id_z,application_id_z,org_id_z,
            server_id_z);
          end if;
          return;
        end if;
      else
        -- See if Application-level context has a value in DB
        GET_SPECIFIC_DB_WNPS(name_z,-1,-1,
          nvl(application_id_z,PROFILES_APPL_ID),val_z,defined_z,-1,-1,10002);
        if defined_z then -- Value found at application-level
          -- Log value found
          if CORELOG_IS_ENABLED then
            CORELOG( name_z,nvl(val_z,'NOVAL'),'AL VAL via GSDW in FP.GSW',
              user_id_z,responsibility_id_z,application_id_z,org_id_z,
              server_id_z);
          end if;
          return;
        elsif (application_id_z = PROFILES_APPL_ID) then
          -- Cache '**FND_UNDEFINED_VALUE**' value for profile at
          -- appl-level if context is the same, i.e. application_id_z =
          -- PROFILES_APPL_ID.
          PUT(name_z,FND_UNDEFINED_VALUE,APPL_NAME_TAB,APPL_VAL_TAB,hashValue);
        end if;
      end if;
    end if;

    -- Evaluate the Organization-level and see if the cache has a value.
    if PROFILE_OPTION_EXISTS and not orgLevelSkip then
      -- Bug 7526805: get_specific_wnps MUST USE current context
      -- (PROFILES_ORG_ID) in the absence of a context passed in
      -- (org_id_z)
      if (PROFILES_ORG_ID is not null) or (org_id_z is not null) then
        -- Check Organization-level cache
        GET_SPECIFIC_LEVEL_WNPS(name_z,10006,
          nvl(org_id_z,PROFILES_ORG_ID),0,value,cached,NULL,hashValue);
        if (value is not null) then
          -- Log value found in org-level cache
          if CORELOG_IS_ENABLED then
            CORELOG(name_z,nvl(value,'NOVAL'),'OL Cache not null in FP.GSW',
              user_id_z,responsibility_id_z,application_id_z,org_id_z,
              server_id_z);
          end if;

          if (value <> FND_UNDEFINED_VALUE) then
            val_z := value;
            defined_z := TRUE;
            -- Log value found in org-level cache
            if CORELOG_IS_ENABLED then
              CORELOG(name_z,nvl(value,'NOVAL'),'OL Cache VAL in FP.GSW',
                user_id_z,responsibility_id_z,application_id_z,org_id_z,
                server_id_z);
            end if;
            return;
          end if;
        else
          -- See if Organization-level context has a value in DB
          GET_SPECIFIC_DB_WNPS(name_z,-1,-1,-1,val_z,defined_z,
            nvl(org_id_z,PROFILES_ORG_ID),-1,10006);
          if defined_z then -- Value found at organization-level
            -- Log value found
            if CORELOG_IS_ENABLED then
              CORELOG(name_z,nvl(val_z,'NOVAL'),'OL VAL via GSDW in FP.GSW',
                user_id_z,responsibility_id_z,application_id_z,org_id_z,
                server_id_z);
            end if;
            return;
          elsif (org_id_z = PROFILES_ORG_ID) then
            -- Cache '**FND_UNDEFINED_VALUE**' value for profile at
            -- org-level if context is the same, i.e.
            -- org_id_z = PROFILES_ORG_ID.
            PUT(name_z,FND_UNDEFINED_VALUE,ORG_NAME_TAB,ORG_VAL_TAB,hashValue);
          end if;
        end if;
      end if;
    end if;

    -- Evaluate the Server-level and see if the cache has a value.
    if PROFILE_OPTION_EXISTS and not serverLevelSkip then
      -- Bug 7526805: get_specific_wnps MUST USE current context
      -- (PROFILES_SERVER_ID) in the absence of a context passed in
      -- (server_id_z).
      if ((PROFILES_SERVER_ID is not null) or (server_id_z is not null)) then
        -- Check Server-level cache
        GET_SPECIFIC_LEVEL_WNPS(name_z,10005,
          nvl(server_id_z,PROFILES_SERVER_ID),0,value,cached,NULL,hashValue);
        if (value is not null) then
        -- Log value found in server-level cache
          if CORELOG_IS_ENABLED then
            CORELOG(name_z,nvl(value,'NOVAL'),'SRVL Cache not null in FP.GSW',
              user_id_z,responsibility_id_z,application_id_z,org_id_z,
              server_id_z);
          end if;

          if (value <> FND_UNDEFINED_VALUE) then
            val_z := value;
            defined_z := TRUE;
            -- Log value found in server-level cache
            if CORELOG_IS_ENABLED then
              CORELOG(name_z,nvl(value,'NOVAL'),'SRVL Cache VAL in FP.GSW',
                user_id_z,responsibility_id_z,application_id_z,org_id_z,
                server_id_z);
            end if;
            return;
          end if;
        else
          -- See if Server-level context has a value in DB
          GET_SPECIFIC_DB_WNPS(name_z,-1,-1,-1,val_z,defined_z,-1,
            nvl(server_id_z,PROFILES_SERVER_ID),10005);
          if defined_z then -- Value found at server-level
            -- Log value found
            if CORELOG_IS_ENABLED then
              CORELOG(name_z,nvl(val_z,'NOVAL'),'SRVL VAL via GSDW in FP.GSW',
                user_id_z,responsibility_id_z,application_id_z,org_id_z,
                server_id_z);
            end if;
            return;
          elsif (server_id_z = PROFILES_SERVER_ID) then
            -- Cache '**FND_UNDEFINED_VALUE**' value for profile at
            -- server-level if context is the same,
            -- i.e. server_id_z = PROFILES_SERVER_ID.
            PUT(name_z,FND_UNDEFINED_VALUE,SERVER_NAME_TAB,SERVER_VAL_TAB,
            hashValue);
          end if;
        end if;
      end if;
    end if;

    -- Evaluate the Servresp-level and see if the cache has a value.
    if PROFILE_OPTION_EXISTS and not servrespLevelSkip then
      -- Check Servresp-level cache
      GET_SPECIFIC_LEVEL_WNPS(name_z,10007,
        nvl(responsibility_id_z,PROFILES_RESP_ID),
        nvl(application_id_z,PROFILES_APPL_ID),value,cached,
        nvl(server_id_z,PROFILES_SERVER_ID),hashValue);
      if (value is not null) then
      -- Log value found in server-level cache
        if CORELOG_IS_ENABLED then
          CORELOG(name_z,nvl(value,'NOVAL'),
            'ServRespL Cache not null in FP.GSW',user_id_z,responsibility_id_z,
            application_id_z,org_id_z,server_id_z);
        end if;

        if (value <> FND_UNDEFINED_VALUE) then
          val_z := value;
          defined_z := TRUE;
          -- Log value found in servresp-level cache
          if CORELOG_IS_ENABLED then
            CORELOG(name_z,nvl(value,'NOVAL'),
              'ServRespL Cache VAL in FP.GSW',
              user_id_z,responsibility_id_z,application_id_z,org_id_z,
              server_id_z);
          end if;
          return;
        end if;
      else
        -- See if Servresp-level context has a value in DB
        /* Bug 4021624: FND_RUN_FUNCTION.GET_JSP_AGENT calls
        ** FND_PROFILE.VALUE_SPECIFIC and site value is consistently
        ** returned, given a Resp ID and Server ID. GET_SPECIFIC_DB_WNPS
        ** was being called for the Resp ID + Server ID combination ONLY
        ** and was missing the values set for Resp ID + (Server ID = -1)
        ** and (Resp ID = -1) + Server ID combos. GET_SPECIFIC_DB_WNPS
        ** needs to be called for those combinations, as well.
        */
        -- Start with Resp ID + Server ID combination --
        GET_SPECIFIC_DB_WNPS(name_z,-1,
          nvl(responsibility_id_z,PROFILES_RESP_ID),
          nvl(application_id_z,PROFILES_APPL_ID),
          val_z,defined_z,-1,
          nvl(server_id_z,PROFILES_SERVER_ID),10007);
        if defined_z then -- Value found at servresp-level
          -- Log value found in servresp-level cache
          if CORELOG_IS_ENABLED then
            CORELOG(name_z,nvl(val_z,'NOVAL'),
              'ServRespL R+S VAL via GSDW in FP.GSW',user_id_z,
              responsibility_id_z,application_id_z,org_id_z,server_id_z);
          end if;
          return;
        else
          /* Bug 4021624: SERVERLEVEL CONTEXT NOT INITALIZED BEFORE
          ** FND_RUN_FUNCTION IN ICX_PORTLET
          ** If Resp ID + Server ID combination yields no results, try
          ** Resp ID + (Server ID = -1) combination
          */
          GET_SPECIFIC_DB_WNPS(name_z,-1,
            nvl(responsibility_id_z,PROFILES_RESP_ID),
            nvl(application_id_z,PROFILES_APPL_ID),val_z,defined_z,-1,-1,10007);
          if defined_z then -- Value found at servresp-level
            -- Log value found in servresp-level cache
            if CORELOG_IS_ENABLED then
            CORELOG(name_z,nvl(val_z,'NOVAL'),
              'ServRespL R+-1 VAL via GSDW in FP.GSW',user_id_z,
              responsibility_id_z,application_id_z,org_id_z,server_id_z);
            end if;
            return;
          else
            /* Bug 4021624: SERVERLEVEL CONTEXT NOT INITALIZED BEFORE
            ** FND_RUN_FUNCTION IN ICX_PORTLET
            ** If Resp ID + (Server ID = -1) combination yields no
            ** results, try (Resp ID = -1) + Server ID combination
            */
            GET_SPECIFIC_DB_WNPS(name_z,-1,-1,-1,val_z,defined_z,-1,
              nvl(server_id_z,PROFILES_SERVER_ID),10007);
            if defined_z then -- Value found at servresp-level */
              -- Log value found in servresp-level cache */
              if CORELOG_IS_ENABLED then
                CORELOG(name_z,nvl(val_z,'NOVAL'),
                  'ServRespL S+-1 VAL via GSDW in FP.GSW',user_id_z,
                  responsibility_id_z,application_id_z,org_id_z,server_id_z);
              end if;
              return;
            elsif ((responsibility_id_z = PROFILES_RESP_ID)
              and (server_id_z = PROFILES_SERVER_ID)) then
              -- Cache '**FND_UNDEFINED_VALUE**' value for profile at
              -- server-level. If context is the same,
              -- i.e. server_id_z = PROFILES_SERVER_ID.
              PUT(name_z,FND_UNDEFINED_VALUE,SERVRESP_NAME_TAB,SERVRESP_VAL_TAB,
                hashValue);
            end if; -- servresp-level
          end if;
        end if;
      end if;
    end if;

    -- Evaluate site-level if none of the levels yield a value.
    if PROFILE_OPTION_EXISTS then
      -- Finally, check Site-level cache
      GET_SPECIFIC_LEVEL_WNPS(name_z,10001,0,0,value,cached,NULL,hashValue);
      if (value is not null) then
        -- Log value found in site-level cache
        if CORELOG_IS_ENABLED then
        CORELOG(name_z,nvl(value,'NOVAL'),'SL Cache not null in FP.GSW',
          user_id_z,responsibility_id_z,application_id_z,org_id_z,
          server_id_z);
        end if;

        if (value <> FND_UNDEFINED_VALUE) then
          val_z := value;
          defined_z := TRUE;
          -- Log value found in site-level cache
          if CORELOG_IS_ENABLED then
            CORELOG(name_z,nvl(value,'NOVAL'),'SL Cache VAL in FP.GSW',
              user_id_z,responsibility_id_z,application_id_z,org_id_z,
              server_id_z);
          end if;
          return;
        end if;
      else
        -- See if site-level has a value in DB
        GET_SPECIFIC_DB_WNPS(name_z,-1,-1,-1,val_z,defined_z,-1,-1,10001);
        if defined_z then -- Value found at site-level
          -- Log value found
          if CORELOG_IS_ENABLED then
            CORELOG(name_z,nvl(val_z,'NOVAL'),'SL VAL via GSDW in FP.GSW',
              user_id_z,responsibility_id_z,application_id_z,org_id_z,
              server_id_z);
          end if;
          return;
        else
          -- Cache '**FND_UNDEFINED_VALUE**' value for profile at
          -- site-level
          PUT(name_z,FND_UNDEFINED_VALUE,SITE_NAME_TAB,SITE_VAL_TAB,hashValue);
        end if;
      end if;
    end if;
    --
    -- End of Cache calls
    -- If the call gets here, then no value was found in cache or in DB
    --
    val_z := null;
    defined_z := FALSE;

    -- Log value not found at any level
    if CORELOG_IS_ENABLED then
      CORELOG(name_z,nvl(val_z, 'NOVAL'),'Exit FP.GSW',user_id_z,
        responsibility_id_z,application_id_z,org_id_z,server_id_z);
    end if;

   end GET_SPECIFIC_WNPS;

   /*
   ** GET_CACHED -
   **   Get the profile value for the current user/resp/appl.
   **   This API will also save the profile value in its appropriate level
   **   cache.
   */
   procedure GET_CACHED(
      name_z      in varchar2, -- should be passed UPPER value
      val_z       out NOCOPY varchar2,
      defined_z   out NOCOPY boolean) is

      value       varchar2(240);
      cached      boolean;
      hashValue   binary_integer;

   begin

      -- Log API Entry
      if CORELOG_IS_ENABLED then
         CORELOG(name_z,nvl(val_z,'NOVAL'),'Enter FP.GC');
      end if;

      val_z := NULL;
      defined_z := FALSE;

      /* Bug 5603664: APPSPERF:FND:OPTIMIZE FND_PROFILE.VALUE
      ** Generate hashValue and pass it on to FIND and PUT calls.
      */
      hashValue := dbms_utility.get_hash_value(name_z,1,TABLE_SIZE);

      --
      -- The algorithm is to check the cache first, if a profile option has
      -- been cached before, we will check if the tables were updated since it
      -- was last cached. If they were, then we need to refresh the cache, by
      -- deleting and repopulating via GET_SPECIFIC_DB. The algorithm also
      -- follows the profile hierarchy.  If the the profile option/value has
      -- never been cached, we will go to the DB after the cached calls.
      --

      /* Bug 3637977: FND_PROFILE:CONTEXT-LEVEL CHANGES NOT REFLECTED BY RETURN
      ** VALUES
      ** For each level, a call to GET_SPECIFIC_DB was added to
      ** ensure that a context-level value does not exist, if no value was
      ** found at context-level cache.  The GET_SPECIFIC_DB call done is
      ** context-level specific, i.e. if user-level is the value that needs to
      ** be obtained, only the user-id is passed.  The GET_SPECIFIC_DB call for
      ** the site-level is done with no context taken into account.
      **
      ** Bug 3714184 and 3733896: The suggestion by the ATG Performance Team is
      ** to cache null or '**FND_UNDEFINED_VALUE**' via a PUT() call for
      ** profiles that return no values or are undefined.  This will minimize
      ** the GET_SPECIFIC_DB calls.
      */

      --
      -- By design, PROFILE_OPTION_EXISTS is not being checked here so that the
      -- code allows the profile to be evaluated, at least once, in
      -- GET_SPECIFIC_DB which determines whether the profile exists.
      --

      -- Check User-level cache
      GET_SPECIFIC_LEVEL_WNPS(name_z,10004,PROFILES_USER_ID,0,value,cached,NULL,
         hashValue);
      if (value is not null) then
         -- Profile exists because a value is cached.
         PROFILE_OPTION_EXISTS := TRUE;
         -- Log value found in user-level cache
         if CORELOG_IS_ENABLED then
            CORELOG(name_z,nvl(value,'NOVAL'),'UL Cache not null in FP.GC');
         end if;
         if (value <> FND_UNDEFINED_VALUE) then
            val_z := value;
            defined_z := TRUE;
            -- Log value found in user-level cache
            if CORELOG_IS_ENABLED then
               CORELOG(name_z,nvl(val_z,'NOVAL'),'UL Cache VAL in FP.GC');
            end if;
            return;
         end if;
      else
         /* Bug 3637977, see if user-level context has a value in DB */
         GET_SPECIFIC_DB(name_z,PROFILES_USER_ID,-1,-1,val_z,defined_z,-1,-1,
            10004,hashValue);
         if defined_z then -- Value found at user-level
            -- Log value found
            if CORELOG_IS_ENABLED then
               CORELOG(name_z,nvl(val_z,'NOVAL'),'UL VAL via GSD in FP.GC');
            end if;
            return;
         else
            -- Cache '**FND_UNDEFINED_VALUE**' value for profile at user-level
            PUT(name_z,FND_UNDEFINED_VALUE,USER_NAME_TAB,USER_VAL_TAB,
               hashValue);
         end if;
      end if;

      if PROFILE_OPTION_EXISTS then
         -- Check Responsibility-level cache
         GET_SPECIFIC_LEVEL_WNPS(name_z,10003,PROFILES_RESP_ID,
            PROFILES_APPL_ID,value,cached,NULL,hashValue);
         if (value is not null) then
            -- Log value found in resp-level cache
            if CORELOG_IS_ENABLED then
               CORELOG(name_z,nvl(value,'NOVAL'),'RL Cache not null in FP.GC');
            end if;
            if (value <> FND_UNDEFINED_VALUE) then
               val_z := value;
               defined_z := TRUE;
               -- Log value found in resp-level cache
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),'RL Cache VAL in FP.GC');
               end if;
               return;
            end if;
         else
            /* Bug 3637977, see if resp-level context has a value in DB */
            GET_SPECIFIC_DB(name_z,-1,PROFILES_RESP_ID,PROFILES_APPL_ID,val_z,
               defined_z,-1,-1, 10003,hashValue);
            if defined_z then -- Value found at resp-level
               -- Log value found
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),'RL VAL via GSD in FP.GC');
               end if;
               return;
            else
               -- Cache '**FND_UNDEFINED_VALUE**' value for profile at
               -- resp-level
               PUT(name_z,FND_UNDEFINED_VALUE,RESP_NAME_TAB,RESP_VAL_TAB,
                  hashValue);
            end if;
         end if;
      end if;

      if PROFILE_OPTION_EXISTS then
         -- Check Application-level cache --
         GET_SPECIFIC_LEVEL_WNPS(name_z,10002,PROFILES_APPL_ID,0,value,cached,
            NULL,hashValue);
         if (value is not null) then
            -- Log value found in appl-level cache
            if CORELOG_IS_ENABLED then
               CORELOG(name_z,nvl(value,'NOVAL'),'AL Cache not null in FP.GC');
            end if;
            if (value <> FND_UNDEFINED_VALUE) then
               val_z := value;
               defined_z := TRUE;
               -- Log value found in appl-level cache
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),'AL Cache VAL in FP.GC');
               end if;
               return;
            end if;
         else
            /* Bug 3637977, see if appl-level context has a value in DB */
            GET_SPECIFIC_DB(name_z,-1,-1,PROFILES_APPL_ID,val_z,defined_z,-1,
               -1,10002,hashValue);
            if defined_z then -- Value found at application-level
               -- Log value found
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),'AL VAL via GSD in FP.GC');
               end if;
               return;
            else
               -- Cache '**FND_UNDEFINED_VALUE**' value for profile at
               -- appl-level
               PUT(name_z,FND_UNDEFINED_VALUE,APPL_NAME_TAB,APPL_VAL_TAB,
                  hashValue);
            end if;
         end if;
      end if;

      if PROFILE_OPTION_EXISTS then
         if PROFILES_ORG_ID is not NULL then
            -- Check Organization-level cache
            GET_SPECIFIC_LEVEL_WNPS(name_z,10006,PROFILES_ORG_ID,0,value,cached,
               NULL,hashValue);
            if (value is not null) then
               -- Log value found in org-level cache
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(value,'NOVAL'),'OL Cache not null in FP.GC');
               end if;
               if (value <> FND_UNDEFINED_VALUE) then
                  val_z := value;
                  defined_z := TRUE;
                  -- Log value found in org-level cache
                  if CORELOG_IS_ENABLED then
                     CORELOG(name_z,nvl(val_z,'NOVAL'),'OL Cache VAL in FP.GC');
                  end if;
                  return;
               end if;
            else
               /* Bug 3637977, see if org-level context has a value in DB */
               GET_SPECIFIC_DB(name_z,-1,-1,-1,val_z,defined_z,PROFILES_ORG_ID,-1,
                  10006,hashValue);
               if defined_z then -- Value found at org-level
                  -- Log value found
                  if CORELOG_IS_ENABLED then
                     CORELOG(name_z,nvl(val_z,'NOVAL'),'OL VAL via GSD in FP.GC');
                  end if;
                  return;
               else
                  -- Cache '**FND_UNDEFINED_VALUE**' value for profile at
                  -- org-level
                  PUT(name_z,FND_UNDEFINED_VALUE,ORG_NAME_TAB,ORG_VAL_TAB,
                     hashValue);
               end if;
            end if;
         end if;
      end if;

      if PROFILE_OPTION_EXISTS then
         -- Check Server-level cache
         GET_SPECIFIC_LEVEL_WNPS(name_z,10005,PROFILES_SERVER_ID,0,value,
            cached,NULL,hashValue);
         if (value is not null) then
            -- Log value found in server-level cache
            if CORELOG_IS_ENABLED then
               CORELOG(name_z,nvl(value,'NOVAL'),
                  'SRVL Cache not null in FP.GC');
            end if;
            if (value <> FND_UNDEFINED_VALUE) then
               val_z := value;
               defined_z := TRUE;
               -- Log value found in server-level cache
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),'SRVL Cache VAL in FP.GC');
               end if;
               return;
            end if;
         else
            /* Bug 3637977, see if server-level context has a value in DB */
            GET_SPECIFIC_DB(name_z,-1,-1,-1,val_z,defined_z,-1,
               PROFILES_SERVER_ID,10005,hashValue);
            if defined_z then -- Value found at server-level
               -- Log value found
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),'SRVL VAL via GSD in FP.GC');
               end if;
               return;
            else
               -- Cache '**FND_UNDEFINED_VALUE**' value for profile at
               -- server-level
               PUT(name_z,FND_UNDEFINED_VALUE,SERVER_NAME_TAB,SERVER_VAL_TAB,
                  hashValue);
            end if;
         end if;
      end if;

      if PROFILE_OPTION_EXISTS then
         -- Check Server/Responsibility-level cache
         GET_SPECIFIC_LEVEL_WNPS(name_z,10007,PROFILES_RESP_ID,
            PROFILES_APPL_ID,value,cached,PROFILES_SERVER_ID,hashValue);
         if (value is not null) then
            -- Log value found in ServResp-level cache
            if CORELOG_IS_ENABLED then
               CORELOG(name_z,nvl(value,'NOVAL'),
                  'ServRespL Cache not null in FP.GC');
            end if;
            if (value <> FND_UNDEFINED_VALUE) then
               val_z := value;
               defined_z := TRUE;
               -- Log value found in ServResp-level cache
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),
                     'ServRespL Cache VAL in FP.GC');
               end if;
               return;
            end if;
         else
            -- See if servresp-level context has a value in DB
            GET_SPECIFIC_DB(name_z,-1,PROFILES_RESP_ID,PROFILES_APPL_ID,val_z,
               defined_z,-1,PROFILES_SERVER_ID, 10007,hashValue);
            if defined_z then -- Value found at ServResp-level
               -- Log value found
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),
                     'ServRespL VAL via GSD in FP.GC');
               end if;
               return;
            else
               -- Cache '**FND_UNDEFINED_VALUE**' value for profile at
               -- resp-level
               PUT(name_z,FND_UNDEFINED_VALUE,SERVRESP_NAME_TAB,
                  SERVRESP_VAL_TAB,hashValue);
            end if;
         end if;
      end if;

      if PROFILE_OPTION_EXISTS then
         -- Check Site-level cache
         GET_SPECIFIC_LEVEL_WNPS(name_z,10001,0,0,value,cached,NULL,hashValue);
         if (value is not null) then
            -- Log value found in site-level cache
            if CORELOG_IS_ENABLED then
               CORELOG(name_z,nvl(value,'NOVAL'),'SL Cache not null in FP.GC');
            end if;
            if (value <> FND_UNDEFINED_VALUE) then
               val_z := value;
               defined_z := TRUE;
               -- Log value found in site-level cache
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),'SL Cache VAL in FP.GC');
               end if;
               return;
            end if;
         else
            /* Bug 3637977, see if site-level context has a value in DB */
            GET_SPECIFIC_DB(name_z,-1,-1,-1,val_z,defined_z,-1,-1, 10001,
               hashValue);
            if defined_z then -- Value found at site-level
               -- Log value found
               if CORELOG_IS_ENABLED then
                  CORELOG(name_z,nvl(val_z,'NOVAL'),'SL VAL via GSD in FP.GC');
               end if;
               return;
            else
               -- Cache '**FND_UNDEFINED_VALUE**' value for profile at
               -- site-level
               PUT(name_z,FND_UNDEFINED_VALUE,SITE_NAME_TAB,SITE_VAL_TAB,
                  hashValue);
            end if;
         end if;
      end if;
      -- End of Cache calls

      -- If it gets here, then there is no value for the profile option and it
      -- is not defined.
      val_z := null;
      defined_z := FALSE;

      -- Log value not found at any level
      if CORELOG_IS_ENABLED then
         CORELOG(name_z,nvl(val_z,'NOVAL'),'Exit FP.GC');
      end if;

   end GET_CACHED;


   /*
   ** DEFINED - test if profile option is defined
   */
   function DEFINED(NAME in varchar2) return boolean is
      VAL varchar2(255);
   begin
      GET(NAME, VAL);
      return (VAL is not NULL);
   end DEFINED;

   /*
   ** GET - get the value of a profile option
   **
   ** NOTES
   **    If the option cannot be found, the out buffer is set to NULL
   **    Since a profile value can never be set to NULL,
   **    if this returns a NULL, then the profile doesn't exist.
   */
   procedure GET(NAME in varchar2, VAL out NOCOPY varchar2) is
      TABLE_INDEX binary_integer;
      DEFINED     boolean;
      OUTVAL      varchar2(255);
      NAME_UPPER  varchar2(80) := UPPER(NAME);
   begin

      -- Log API Entry
      if CORELOG_IS_ENABLED then
         CORELOG(NAME_UPPER,nvl(VAL,'NOVAL'),'Enter FP.G');
      end if;

      -- Search for the profile option
      TABLE_INDEX := FIND(NAME_UPPER);

      if TABLE_INDEX < TABLE_SIZE then
         VAL := VAL_TAB(TABLE_INDEX);
         -- Log value found in Generic Put Cache, API Exit
         if CORELOG_IS_ENABLED then
            CORELOG(NAME_UPPER,nvl(VAL,'NOVAL'),'VAL in GEN PUT, Exit FP.G');
         end if;
      else
         -- Can't find the value in the table; look in the database
         GET_CACHED(NAME_UPPER, OUTVAL, DEFINED);
         VAL := OUTVAL;
         -- Log API Exit
         if CORELOG_IS_ENABLED then
            CORELOG(NAME_UPPER,nvl(VAL,'NOVAL'),'VAL in FP.GC, Exit FP.G');
         end if;
      end if;

   exception
      when others then
         null;
   end GET;


   /*
   ** INVALIDATE_CACHE - Call WF_EVENT.RAISE to invalidate the cache entry
   **                    corresponding to the specified profile.
   */
   procedure INVALIDATE_CACHE(
      x_level_name          in varchar2,
      x_level_value         in varchar2,
      x_level_value_app_id  in varchar2,
      x_name                in varchar2,
      x_level_value2        in varchar2 default null) is

      level_id             number;
      level_value          number;
      level_value_appl_id  number;
      name                 varchar2(80) := upper(x_name);
      event_key            varchar2(255);
      level_value2         number;

   begin
      if (x_level_name = 'SITE') then
         level_id := 10001;
         level_value := 0;
         level_value_appl_id := 0;
      elsif (x_level_name = 'APPL') then
         level_id := 10002;
         level_value := to_number(x_level_value);
         level_value_appl_id := 0;
      elsif (x_level_name = 'RESP') then
         level_id := 10003;
         level_value := to_number(x_level_value);
         level_value_appl_id := to_number(x_level_value_app_id);
      elsif (x_level_name = 'USER') then
         level_id := 10004;
         level_value := to_number(x_level_value);
         level_value_appl_id := 0;
      elsif (x_level_name = 'SERVER') then
         level_id := 10005;
         level_value := to_number(x_level_value);
         level_value_appl_id := 0;
      elsif (x_level_name = 'ORG') then
         level_id := 10006;
         level_value := to_number(x_level_value);
         level_value_appl_id := 0;
      elsif (x_level_name = 'SERVRESP') then -- Added for server/resp hierarchy
         level_id := 10007;
         level_value := to_number(x_level_value);
         level_value_appl_id := to_number(x_level_value_app_id);
         --
         -- level_value2 was added for the Server/Resp Hierarchy.
         -- The subscription that executes the FND_PROFILE.bumpCacheVersion_RF
         -- rule function uses the level_id.  For this subscription, the
         -- level_value2 value is irrelevant.  However, it may become relevant
         -- to other subscriptions subscribing to the
         -- oracle.apps.fnd.profile.value.update event.  At this time, the
         -- level_value2 value will be stored but not passed into the
         -- event_key.
         --
         --Added for server/resp hierarchy
         level_value2 := to_number(x_level_value2);
      else
         return;
      end if;

      if (level_id = 10007) then
         -- Event Key has level_value2
         event_key := level_id||':'||level_value||':'||level_value_appl_id||':'
         ||level_value2||':'||name;
      else
         -- Original event_key format
         event_key := level_id||':'||level_value||':'||level_value_appl_id||':'
         ||name;
      end if;

      --
      -- Modified this direct call to wf_event.raise to use the
      -- fnd_wf_engine.default_event_raise wrapper API
      --
      -- wf_event.raise(p_event_name=>'oracle.apps.fnd.profile.value.update',
      -- p_event_key=>event_key);
      --

      fnd_wf_engine.default_event_raise(
         p_event_name=>'oracle.apps.fnd.profile.value.update',
         p_event_key=>event_key);

   end INVALIDATE_CACHE;

   /*
   ** SAVE_USER - Sets the value of a profile option permanently
   **             to the database, at the user level for the current user.
   **             Also saves in the profile cache for this database session.
   **             Note that this will not save in the profile caches
   **             for any other database sessions that may be up, so those
   **             could potentially be out of sync. This routine will not
   **             actually commit the changes; the caller must commit.
   **
   **  returns: TRUE if successful, FALSE if failure.
   **
   */
   function SAVE_USER(
      X_NAME in varchar2, /* Profile name you are setting */
      X_VALUE in varchar2 /* Profile value you are setting */
      ) return boolean is

      result    BOOLEAN;

   begin
      result := SAVE(X_NAME, X_VALUE, 'USER', PROFILES_USER_ID);
      return result;
   end SAVE_USER;

   /*
   ** SAVE - sets the value of a profile option permanently
   **        to the database, at any level.  This routine can be used
   **        at runtime or during patching.  This routine will not
   **        actually commit the changes; the caller must commit.
   **
   **        ('SITE', 'APPL', 'RESP', 'USER', 'SERVER', 'ORG', or 'SERVRESP').
   **
   **        Examples of use:
   **        FND_PROFILE.SAVE('P_NAME', 'P_VAL', 'SITE');
   **        FND_PROFILE.SAVE('P_NAME', 'P_VAL', 'APPL', 321532);
   **        FND_PROFILE.SAVE('P_NAME', 'P_VAL', 'RESP', 321532, 345234);
   **        FND_PROFILE.SAVE('P_NAME', 'P_VAL', 'USER', 123321);
   **        FND_PROFILE.SAVE('P_NAME', 'SERVER', 25);
   **        FND_PROFILE.SAVE('P_NAME', 'ORG', 204);
   **        FND_PROFILE.SAVE('P_NAME', 'SERVRESP', 321532, 345234, 25);
   **        FND_PROFILE.SAVE('P_NAME', 'SERVRESP', 321532, 345234, -1);
   **        FND_PROFILE.SAVE('P_NAME', 'SERVRESP', -1, -1, 25);
   **
   **  returns: TRUE if successful, FALSE if failure.
   */
   function SAVE(
      X_NAME in varchar2,
         -- Profile name you are setting
      X_VALUE in varchar2,
         -- Profile value you are setting
      X_LEVEL_NAME in varchar2,
         -- Level that you're setting at: 'SITE','APPL','RESP','USER', etc.
      X_LEVEL_VALUE in varchar2 default NULL,
         -- Level value that you are setting at, e.g. user id for 'USER' level.
         -- X_LEVEL_VALUE is not used at site level.
      X_LEVEL_VALUE_APP_ID in varchar2 default NULL,
         -- Used for 'RESP' and 'SERVRESP' level; Resp Application_Id.
      X_LEVEL_VALUE2 in varchar2 default NULL
         -- 2nd Level value that you are setting at.  This is for the
         -- 'SERVRESP' hierarchy.
      ) return boolean is

      x_level_id             NUMBER;
      x_level_value_actual   NUMBER;
      x_last_updated_by      NUMBER;
      x_last_update_login    NUMBER;
      x_last_update_date     DATE;
      x_application_id       NUMBER := NULL;
      x_profile_option_id    NUMBER := NULL;
      x_user_name            VARCHAR2(100);  -- Bug 3203225
      x_level_value2_actual  NUMBER;         -- Added for Server/Resp Hierarchy
      l_profile_option_value VARCHAR2(240);  -- Bug 3958546
      l_defined              BOOLEAN;        -- Bug 3958546

      /* Bug 5603664: APPSPERF:FND:OPTIMIZE FND_PROFILE.VALUE */
      X_NAME_UPPER             VARCHAR2(80) := upper(X_NAME);

      cursor C1 is
      select application_id, profile_option_id
      from fnd_profile_options po
      where po.profile_option_name = X_NAME_UPPER
      /* Bug 5591340: FND_PROFILE.SAVE SHOULD NOT UPDATE VALUES FOR END_DATED
      ** PROFILE OPTIONS
      ** Added these date-sensitive conditions to prevent processing of
      ** end-dated profile options
      */
      and po.start_date_active <= sysdate
      and nvl(po.end_date_active, sysdate) >= sysdate;

      hashValue   binary_integer;

   begin

      if CORELOG_IS_ENABLED then
         FND_CORE_LOG.WRITE_PROFILE_SAVE(
            X_NAME_UPPER,
            nvl(X_VALUE,'NOVAL')||':ENTER',
            X_LEVEL_NAME,
            X_LEVEL_VALUE,
            X_LEVEL_VALUE_APP_ID,
            X_LEVEL_VALUE2);
      end if;

      -- If profile option value being set is > 240 characters, then place the
      -- message FND_PROFILE_OPTION_VAL_TOO_LRG into the error stack and
      -- return FALSE.
      --
      -- The lengthb() function replaced the length() function to handle
      -- multibyte characters appropriately.
      if lengthb(X_VALUE) > 240 then
         fnd_message.set_name('FND', 'FND_PROFILE_OPTION_VAL_TOO_LRG');
         fnd_message.set_token('PROFILE_OPTION_NAME', X_NAME);
         fnd_message.set_token('PROFILE_OPTION_VALUE', X_VALUE);
         return FALSE;
      end if;

      -- Get the profile ID and Appid for this Profile Name
      open C1;
      fetch C1 into x_application_id, x_profile_option_id;
      if (C1%NOTFOUND) then
         return FALSE;
      end if;
      close C1;

      -- The LEVEL_VALUE_APPLICATION_ID applies to the Resp and Server/Resp
      -- levels only.
      if (X_LEVEL_VALUE_APP_ID is not null and
         X_LEVEL_NAME <> 'RESP' and X_LEVEL_NAME <> 'SERVRESP') then
         return FALSE;
      end if;

      -- The LEVEL_VALUE can only be null for SITE level.
      if(X_LEVEL_VALUE is NULL) then
         x_level_value_actual := 0;
         if(X_LEVEL_NAME <> 'SITE') then
            return FALSE; -- Only allow X_LEVEL_VALUE NULL at SITE level
         end if;

      -- The LEVEL_VALUE2 is required for SERVRESP level, -1 should be passed
      -- as a default.
      elsif ((X_LEVEL_NAME = 'SERVRESP') and (X_LEVEL_VALUE2 is NULL)) then
         -- 'SERVRESP' requires a value for X_LEVEL_VALUE2 to save
         -- the profile option value properly.
         return FALSE;
      else
         x_level_value_actual := X_LEVEL_VALUE;
         if (X_LEVEL_NAME = 'SERVRESP') and (X_LEVEL_VALUE2 is not NULL) then
            x_level_value2_actual := X_LEVEL_VALUE2;
         end if;
      end if;


      /* Bug 5603664: APPSPERF:FND:OPTIMIZE FND_PROFILE.VALUE
      ** Generate hashValue and pass it on to FIND and PUT calls.
      */
      hashValue := dbms_utility.get_hash_value(X_NAME_UPPER,1,TABLE_SIZE);

      if (X_LEVEL_NAME = 'SITE') then
         x_level_id := 10001;

         if((x_level_id = 10001) and (x_level_value_actual <> 0)) then
            return FALSE; -- the only site-level allowed is zero.
         end if;

         if CORELOG_IS_ENABLED then
            FND_CORE_LOG.PUT_LINE(X_NAME_UPPER,'GSD call FP.S, SL');
         end if;

         /* Bug 3958546: FND_PROFILE.SAVE SHOULD NOT RAISE INVALIDATION EVENT
         ** IF NO CHANGE IS MADE
         */
         GET_SPECIFIC_DB(
            name_z => X_NAME_UPPER,
            val_z => l_profile_option_value,
            defined_z => l_defined,
            level_id_z => x_level_id,
            PROFILE_HASH_VALUE => hashValue);

      elsif (X_LEVEL_NAME = 'APPL') then

         x_level_id := 10002;

         if CORELOG_IS_ENABLED then
            FND_CORE_LOG.PUT_LINE(X_NAME_UPPER,'GSD call FP.S, AL');
         end if;

         /* Bug 3958546: FND_PROFILE.SAVE SHOULD NOT RAISE INVALIDATION EVENT
         ** IF NO CHANGE IS MADE
         */
         GET_SPECIFIC_DB(
            name_z => X_NAME_UPPER,
            application_id_z => X_LEVEL_VALUE,
            val_z => l_profile_option_value,
            defined_z => l_defined,
            level_id_z => x_level_id,
            PROFILE_HASH_VALUE => hashValue);

      elsif (X_LEVEL_NAME = 'RESP') then

         x_level_id := 10003;

         if CORELOG_IS_ENABLED then
            FND_CORE_LOG.PUT_LINE(X_NAME_UPPER,'GSD call FP.S, RL');
         end if;

         /* Bug 3958546: FND_PROFILE.SAVE SHOULD NOT RAISE INVALIDATION EVENT
         ** IF NO CHANGE IS MADE
         */
         GET_SPECIFIC_DB(
            name_z => X_NAME_UPPER,
            responsibility_id_z => X_LEVEL_VALUE,
            application_id_z => X_LEVEL_VALUE_APP_ID,
            val_z => l_profile_option_value,
            defined_z => l_defined,
            level_id_z => x_level_id,
            PROFILE_HASH_VALUE => hashValue);

      elsif (X_LEVEL_NAME = 'USER') then

         x_level_id := 10004;

         if CORELOG_IS_ENABLED then
            FND_CORE_LOG.PUT_LINE(X_NAME_UPPER,'GSD call FP.S, UL');
         end if;

         /* Bug 3958546: FND_PROFILE.SAVE SHOULD NOT RAISE INVALIDATION EVENT
         ** IF NO CHANGE IS MADE
         */
         GET_SPECIFIC_DB(
            name_z => X_NAME_UPPER,
            user_id_z => X_LEVEL_VALUE,
            val_z => l_profile_option_value,
            defined_z => l_defined,
            level_id_z => x_level_id,
            PROFILE_HASH_VALUE => hashValue);

      elsif (X_LEVEL_NAME = 'SERVER') then

         x_level_id := 10005;

         if CORELOG_IS_ENABLED then
            FND_CORE_LOG.PUT_LINE(X_NAME_UPPER,'GSD call FP.S, SRVL');
         end if;

         /* Bug 3958546: FND_PROFILE.SAVE SHOULD NOT RAISE INVALIDATION EVENT
         ** IF NO CHANGE IS MADE
         */
         GET_SPECIFIC_DB(
            name_z => X_NAME_UPPER,
            val_z => l_profile_option_value,
            defined_z => l_defined,
            server_id_z => X_LEVEL_VALUE,
            level_id_z => x_level_id,
            PROFILE_HASH_VALUE => hashValue);

      elsif (X_LEVEL_NAME = 'ORG') then

         x_level_id := 10006;

         if CORELOG_IS_ENABLED then
            FND_CORE_LOG.PUT_LINE(X_NAME_UPPER,'GSD call FP.S, OL');
         end if;

         /* Bug 3958546: FND_PROFILE.SAVE SHOULD NOT RAISE INVALIDATION EVENT
         ** IF NO CHANGE IS MADE
         */
         GET_SPECIFIC_DB(
            name_z => X_NAME_UPPER,
            val_z => l_profile_option_value,
            defined_z => l_defined,
            org_id_z => X_LEVEL_VALUE,
            level_id_z => x_level_id,
            PROFILE_HASH_VALUE => hashValue);

      elsif (X_LEVEL_NAME = 'SERVRESP') then --Added for Server/Resp Level

         x_level_id := 10007;

         if CORELOG_IS_ENABLED then
            FND_CORE_LOG.PUT_LINE(X_NAME_UPPER,'GSDW call FP.S, ServRespL');
         end if;

         /*
         ** Bug 4025399 :3958546:SERVRESP:FND_PROFILE.SAVE RETURNS TRUE BUT
         ** DOES NOT SAVE VALUE
         **
         ** Due to the unique nature of the SERVRESP hierarchy, GET_SPECIFIC_DB
         ** cannot be used to check the existing value of the profile option
         ** being evaluated since GET_SPECIFIC_DB looks at
         ** (RESP+SERVER) > (RESP+-1) > (-1+SERVER) for a value.  When saving
         ** values, the context passed in should be the only context evaluated.
         ** GET_SPECIFIC_DB_WNPS will be used instead.
         **
         ** GET_SPECIFIC_DB(
         **    name_z => X_NAME,
         **    responsibility_id_z => X_LEVEL_VALUE,
         **    application_id_z => X_LEVEL_VALUE_APP_ID,
         **    val_z => l_profile_option_value,
         **    defined_z => l_defined,
         **    server_id_z => X_LEVEL_VALUE2,
         **    level_id_z => x_level_id);
         */

         /* Bug 3958546: FND_PROFILE.SAVE SHOULD NOT RAISE INVALIDATION EVENT
         ** IF NO CHANGE IS MADE
         */
         GET_SPECIFIC_DB_WNPS(
            name_z => X_NAME_UPPER,
            responsibility_id_z => X_LEVEL_VALUE,
            application_id_z => X_LEVEL_VALUE_APP_ID,
            val_z => l_profile_option_value,
            defined_z => l_defined,
            server_id_z => X_LEVEL_VALUE2,
            level_id_z => x_level_id);

      else
         return FALSE;
      end if;

      -- If the profile option value being saved is the same as the value
      -- obtained from GET_SPECIFIC_DB, then there is no need to go further.
      -- Just return TRUE;
      if ((l_profile_option_value = X_VALUE) or
         (l_profile_option_value is null) and (X_VALUE is null)) then
         if CORELOG_IS_ENABLED then
            FND_CORE_LOG.WRITE_PROFILE_SAVE(
               X_NAME,
               nvl(X_VALUE,'NOVAL')||':EXIT',
               X_LEVEL_NAME,
               X_LEVEL_VALUE,
               X_LEVEL_VALUE_APP_ID,
               X_LEVEL_VALUE2);
         end if;
         return TRUE;
      end if;

      -- If profile option value passed in is NULL, then clear accordingly.
      IF (X_VALUE is null) then
         -- If SERVRESP level, then take LEVEL_VALUE2 into consideration.
         if (x_level_id = 10007) then
            -- D E L E T E --
            FND_PROFILE_OPTION_VALUES_PKG.DELETE_ROW(x_application_id,
               x_profile_option_id, x_level_id, x_level_value_actual,
               X_LEVEL_VALUE_APP_ID, x_level_value2_actual);
         else
            -- D E L E T E --
            FND_PROFILE_OPTION_VALUES_PKG.DELETE_ROW(x_application_id,
               x_profile_option_id, x_level_id, x_level_value_actual,
               X_LEVEL_VALUE_APP_ID);
         end if;

      ELSE

         x_last_update_date := SYSDATE;
         x_last_updated_by := fnd_profile.value('USER_ID');
         if x_last_updated_by is NULL then
            x_last_updated_by := -1;
         end if;
         x_last_update_login := fnd_profile.value('LOGIN_ID');
         if x_last_update_login is NULL then
            x_last_update_login := -1;
         end if;

         -- If profile option value passed in NOT NULL, then update
         -- accordingly. If SERVRESP level, then take LEVEL_VALUE2 into
         -- consideration.
         if (x_level_id = 10007) then
            -- U P D A T E --
            FND_PROFILE_OPTION_VALUES_PKG.UPDATE_ROW(x_application_id,
               x_profile_option_id, x_level_id, x_level_value_actual,
               X_LEVEL_VALUE_APP_ID, x_level_value2_actual, X_VALUE,
               x_last_update_date, x_last_updated_by, x_last_update_login);
         else
            -- U P D A T E --
            FND_PROFILE_OPTION_VALUES_PKG.UPDATE_ROW(x_application_id,
               x_profile_option_id, x_level_id, x_level_value_actual,
               X_LEVEL_VALUE_APP_ID, X_VALUE, x_last_update_date,
               x_last_updated_by, x_last_update_login);
         end if;

      END IF;

      /* Bug 5477866:INCONSISTENT VALUES RETURNED BY FND_PROFILE.VALUE_SPECIFIC
      ** This block of code was separated from the update/insert code block of
      ** SAVE() so that deleted values are properly reflected in level caches
      ** just like non-NULL values are cached when saved.
      ** Previously, only non-NULL values were being cached in level caches
      ** when a new non-NULL value was saved, such that when a value is
      ** deleted, the get apis would still return the previous cached value.
      */
      if (x_level_id = 10007) then
         invalidate_cache(x_level_name,x_level_value,x_level_value_app_id,
            X_NAME_UPPER,x_level_value2);
      else
         invalidate_cache(x_level_name,x_level_value,x_level_value_app_id,
            X_NAME_UPPER);
      end if;

      -- Cache the value in user-level table.
      if (x_level_id = 10004 and
         profiles_user_id = nvl(x_level_value,profiles_user_id)) then
         if CORELOG_IS_ENABLED then
            FND_CORE_LOG.PUT_LINE(X_NAME_UPPER,'UL Val cached in USER_TABS');
         end if;
         PUT(X_NAME_UPPER,nvl(x_value,FND_UNDEFINED_VALUE),USER_NAME_TAB,
            USER_VAL_TAB,hashValue);
      end if;

      -- Cache the value in resp-level table.
      if (x_level_id = 10003 and
         profiles_resp_id = nvl(x_level_value,profiles_resp_id) and
         profiles_appl_id = nvl(x_level_value_app_id,profiles_appl_id)) then
         if CORELOG_IS_ENABLED then
            FND_CORE_LOG.PUT_LINE(X_NAME_UPPER,'RL Val cached in RESP_TABS');
         end if;
         PUT(X_NAME_UPPER,nvl(x_value,FND_UNDEFINED_VALUE),RESP_NAME_TAB,
            RESP_VAL_TAB,hashValue);
      end if;

      -- Cache the value in appl-level table.
      if (x_level_id = 10002 and
         profiles_appl_id = nvl(x_level_value,profiles_appl_id)) then
         if CORELOG_IS_ENABLED then
            FND_CORE_LOG.PUT_LINE(X_NAME_UPPER,'AL Val cached in APPL_TABS');
         end if;
         PUT(X_NAME_UPPER,nvl(x_value,FND_UNDEFINED_VALUE),APPL_NAME_TAB,
            APPL_VAL_TAB,hashValue);
      end if;

      -- Cache the value in server-level table.
      if (x_level_id = 10005 and
         profiles_server_id = nvl(x_level_value,profiles_server_id)) then
         if CORELOG_IS_ENABLED then
            FND_CORE_LOG.PUT_LINE(X_NAME_UPPER,
               'SRVL Val cached in SERVER_TABS');
         end if;
         PUT(X_NAME_UPPER,nvl(x_value,FND_UNDEFINED_VALUE),SERVER_NAME_TAB,
            SERVER_VAL_TAB,hashValue);
      end if;

      -- Cache the value in org-level table.
      if (x_level_id = 10006) then
         if (profiles_org_id = nvl(x_level_value,profiles_org_id)) then
            if CORELOG_IS_ENABLED then
               FND_CORE_LOG.PUT_LINE(X_NAME_UPPER,'OL Val cached in ORG_TABS');
            end if;
            PUT(X_NAME_UPPER,nvl(x_value,FND_UNDEFINED_VALUE),ORG_NAME_TAB,
               ORG_VAL_TAB,hashValue);
         end if;
      end if;

      -- Cache the value in servresp-level table.
      if (x_level_id = 10007 and
         profiles_resp_id = nvl(x_level_value,profiles_resp_id) and
         profiles_server_id = nvl(x_level_value2,profiles_server_id)) then
         if CORELOG_IS_ENABLED then
            FND_CORE_LOG.PUT_LINE(X_NAME_UPPER,
               'ServRespL Val cached in SERVRESP_TABS');
         end if;
         PUT(X_NAME_UPPER,nvl(x_value,FND_UNDEFINED_VALUE),SERVRESP_NAME_TAB,
            SERVRESP_VAL_TAB,hashValue);
      end if;

      -- Cache the value in site-level table.
      if (x_level_id = 10001) then
         if CORELOG_IS_ENABLED then
           FND_CORE_LOG.PUT_LINE(X_NAME_UPPER,'SL Val cached in SITE_TABS');
         end if;
         PUT(X_NAME_UPPER,nvl(x_value,FND_UNDEFINED_VALUE),SITE_NAME_TAB,
            SITE_VAL_TAB,hashValue);
      end if;

      /* Bug 3203225: PREFERENCES NOT UPDATED ON FLY IN WF_ROLES VIEW
      ** needs to call FND_USER_PKG.User_Synch() whenever an update to
      ** ICX_LANGUAGE or ICX_TERRITORY is updated at the user level.
      */
      if ((X_NAME_UPPER = 'ICX_LANGUAGE')
         or (X_NAME_UPPER = 'ICX_TERRITORY')) then
         if ((X_LEVEL_NAME = 'USER') and (X_LEVEL_VALUE is not null)) then
            select user_name
            into   x_user_name
            from   fnd_user
            where  user_id = to_number(X_LEVEL_VALUE);

            FND_USER_PKG.user_synch(x_user_name);
         end if;
      end if;

      -- Log API exit
      if CORELOG_IS_ENABLED then
         FND_CORE_LOG.WRITE_PROFILE_SAVE(
            X_NAME,
            X_VALUE ||':EXIT',
            X_LEVEL_NAME,
            X_LEVEL_VALUE,
            X_LEVEL_VALUE_APP_ID,
            X_LEVEL_VALUE2);
      end if;

      return TRUE;

   end SAVE;

   /*
   ** GET_SPECIFIC - Get a profile value for a specific user/resp/appl combo.
   **                Default for user/resp/appl is the current login.
   */
   procedure GET_SPECIFIC(
      name_z              in varchar2,
      user_id_z           in number  default null,
      responsibility_id_z in number  default null,
      application_id_z    in number  default null,
      val_z               out NOCOPY varchar2,
      defined_z           out NOCOPY boolean,
      org_id_z            in number  default null,
      server_id_z         in number  default null) is

      /* Bug 5603664: APPSPERF:FND:OPTIMIZE FND_PROFILE.VALUE */
      NAME_UPPER  varchar2(80) := UPPER(name_z);

   begin

      -- Log API entry
      if CORELOG_IS_ENABLED then
         CORELOG(
            NAME_UPPER,
            nvl(val_z, 'NOVAL'),
            'Enter FP.GS',
            user_id_z,
            responsibility_id_z,
            application_id_z,
            org_id_z,
            server_id_z);
      end if;

      /* Bug 5477866: INCONSISTENT VALUES RETURNED BY
      ** FND_PROFILE.VALUE_SPECIFIC
      ** Check if fnd_cache_versions was updated. This refreshes level caches
      ** in order for value_specific to return accurate values should a new
      ** profile value be saved in another session. This will introduce a
      ** performance degradation which has been deemed necessary for
      ** value_specific return values.
      */
      CHECK_CACHE_VERSIONS();

      /* Bug 4438015: APPSPERF: TOO MANY EXECUTIONS OF CURSOR PROFILE_INFO
      ** If the context passed in is exactly the same as the current context,
      ** then redirect to GET instead.
      */
      if (user_id_z = PROFILES_USER_ID) and
         (responsibility_id_z = PROFILES_RESP_ID) and
         (application_id_z = PROFILES_APPL_ID) and
         (org_id_z = PROFILES_ORG_ID) and
         (server_id_z = PROFILES_SERVER_ID) then

         if CORELOG_IS_ENABLED then
            CORELOG(NAME_UPPER,nvl(val_z, 'NOVAL'),
               'No context change in FP.GS, Redirect to FP.G');
         end if;

         GET(NAME_UPPER, val_z);

         if (val_z is not null) and
            (val_z <> FND_UNDEFINED_VALUE) then
            defined_z := TRUE;
         end if;
      -- If NULLs were passed for the context levels, default to current
      -- context. This would normally happen when value_specific was called as
      -- such:
      --    fnd_profile.value_specific('PROFILE_OPTION_NAME');
      -- Note that there was no context passed in. Defaulting to current
      -- context effectively satisfies the IF condition above. Hence, redirect
      -- to GET also.
      elsif (user_id_z is NULL) and
         (responsibility_id_z is NULL) and
         (application_id_z is NULL) and
         (org_id_z is NULL) and
         (server_id_z is NULL) then

         if CORELOG_IS_ENABLED then
            CORELOG(NAME_UPPER,nvl(val_z, 'NOVAL'),
               'No context passed in FP.GS, Redirect to FP.G');
         end if;

         GET(NAME_UPPER, val_z);

         if (val_z is not null) and
            (val_z <> FND_UNDEFINED_VALUE) then
            defined_z := TRUE;
         end if;
      else
         -- If a specific level context is passed, then proceed the usual way.
         -- This will likely hit get_specific_db_wnps and make a database
         -- fetch.
         GET_SPECIFIC_WNPS(NAME_UPPER,user_id_z,responsibility_id_z,
            application_id_z,val_z,defined_z,org_id_z,server_id_z);
      end if;

      -- Log API exit
      if CORELOG_IS_ENABLED then
         CORELOG(
            NAME_UPPER,
            nvl(val_z, 'NOVAL'),
            'Exit FP.GS',
            user_id_z,
            responsibility_id_z,
            application_id_z,
            org_id_z,
            server_id_z);
      end if;

   end GET_SPECIFIC;

   /*
   ** VALUE_SPECIFIC - Get profile value for a specific context
   **
   */
   function VALUE_SPECIFIC(
      NAME               in varchar2,
      USER_ID            in number default null,
      RESPONSIBILITY_ID  in number default null,
      APPLICATION_ID     in number default null,
      ORG_ID             in number default null,
      SERVER_ID          in number default null) return varchar2 is

      RETVALUE                 varchar2(255);
      DEFINED                  boolean;

   begin

      -- Log API entry
      if CORELOG_IS_ENABLED then
         CORELOG(
            NAME,
            nvl(RETVALUE, 'NOVAL'),
            'Enter FP.VS',
            USER_ID,
            RESPONSIBILITY_ID,
            APPLICATION_ID,
            ORG_ID,
            SERVER_ID);
      end if;

      -- Use GET_SPECIFIC() to obtain value
      GET_SPECIFIC(NAME,USER_ID,RESPONSIBILITY_ID,APPLICATION_ID,RETVALUE,
         DEFINED,ORG_ID,SERVER_ID);

      -- Log API exit
      if CORELOG_IS_ENABLED then
         CORELOG(
            NAME,
            nvl(RETVALUE, 'NOVAL'),
            'Exit FP.VS',
            USER_ID,
            RESPONSIBILITY_ID,
            APPLICATION_ID,
            ORG_ID,
            SERVER_ID);
      end if;

      if (DEFINED) then
         return (RETVALUE);
      else
         return(NULL);
      end if;

   end VALUE_SPECIFIC;

   /*
   ** VALUE - get profile value, return as function value
   */
   function VALUE(NAME in varchar2) return varchar2 is
      RETVALUE    varchar2(255);
   begin

      -- Log API entry
      if CORELOG_IS_ENABLED then
         CORELOG(NAME,nvl(RETVALUE,'NOVAL'),'Enter FP.V');
      end if;

      -- Use GET() to obtain value
      GET(NAME, RETVALUE);

      -- Log API exit
      if CORELOG_IS_ENABLED then
         CORELOG(NAME,nvl(RETVALUE,'NOVAL'),'Exit FP.V');
      end if;

      return (RETVALUE);
   end VALUE;

   /*
   ** VALUE_WNPS
   **  returns the value of a profile option without caching it.
   **
   **  The main usage for this routine would be in a SELECT statement where
   **  VALUE() is not allowed since it writes package state.
   **
   **  This routine does the same thing as VALUE(); it returns a profile value
   **  from the profile cache, or from the database if it isn't already in the
   **  profile cache already.  The only difference between this and VALUE() is
   **  that this will not put the value into the cache if it is not already
   **  there, so repeated calls to this can be slower because it will have to
   **  hit the database each time for the profile value.
   **
   **  In most cases, however, you can and should use VALUE() instead of
   **  VALUE_WNPS(), because VALUE() will give better performance.
   */
   function VALUE_WNPS(NAME in varchar2) return varchar2 is
      TABLE_INDEX binary_integer;
      DEFINED     boolean;
      OUTVAL      varchar2(255);
      NAME_UPPER  varchar2(80) := UPPER(NAME);
   begin

      -- Search for the profile option
      TABLE_INDEX := FIND(NAME_UPPER);

      if TABLE_INDEX < TABLE_SIZE then
         OUTVAL := VAL_TAB(TABLE_INDEX);
      else
         -- Can't find the value in the table; look in the database
         GET_SPECIFIC_WNPS(NAME_UPPER, PROFILES_USER_ID, PROFILES_RESP_ID,
            PROFILES_APPL_ID,OUTVAL,DEFINED,PROFILES_ORG_ID,
            PROFILES_SERVER_ID);
         if ( not defined) then
            OUTVAL := null;
         end if;
      end if;

      return outval;
   exception
      when others then
         return null;
   end VALUE_WNPS;


   /*
   ** PUTMULTIPLE - puts multiple option pairs in the table
   **
   ** AOL INTERNAL USE ONLY
   **
   ** The name and val VARCHAR2s are of max size 2000, and hold the
   ** concatenations of the strings for each individual pair, with null
   ** terminators (CHR(0)) to seperate the values.  The number of pairs
   ** is passed in numval.  This setup is to avoid the overhead of
   ** calling the put routine multiple times.
   */
   procedure PUTMULTIPLE(
      NAMES in varchar2,
      VALS in varchar2,
      NUM in number) is
      PAIRNUM   number;
      NSTARTLOC number;
      NENDLOC   number;
      VSTARTLOC number;
      VENDLOC   number;
      ONENAME   varchar2(81);
      ONEVAL    varchar2(256);

   begin

      NSTARTLOC:= 1;
      VSTARTLOC:= 1;

      for PAIRNUM in 1.. NUM loop
         NENDLOC := instr(NAMES, chr(0), NSTARTLOC);
         ONENAME := substr(NAMES, NSTARTLOC, NENDLOC - NSTARTLOC);
         NSTARTLOC := NENDLOC + 1;

         VENDLOC := instr(VALS, chr(0), VSTARTLOC);
         ONEVAL  := substr(VALS, VSTARTLOC, VENDLOC - VSTARTLOC);
         VSTARTLOC := VENDLOC + 1;

         PUT(ONENAME, ONEVAL);
      end loop;

   exception
      when others then
         null;
   end PUTMULTIPLE;

/*
** FOR AOL INTERNAL USE ONLY - DO NOT CALL DIRECTLY,
** CALL VIA FND_GLOBAL.INITIALIZE('ORG_ID',org_id)
** FND_PROFILE.INITIALIZE also calls this API to initialize the org context.
**
** initialize_org_context - Initializes the org context used by profiles.
** The org-level cache is cleared of all database (non-put) options first.
** Sets PROFILES_ORG_ID to the current value fnd_global.org_id
*/
procedure INITIALIZE_ORG_CONTEXT
is
begin
     -- Clear org-level cache, if applicable
     if ((PROFILES_ORG_ID is null) or (PROFILES_ORG_ID <> fnd_global.org_id))
          then
          ORG_NAME_TAB.DELETE();
          ORG_VAL_TAB.DELETE();
     end if;

     -- Set profiles org context variable to fnd_global.org_id
     PROFILES_ORG_ID := fnd_global.org_id;

     if release_version < 12 then
        -- For releases less than R12, the ORG_ID profile is the source of the
        -- org context. FND_GLOBAL.ORG_ID = FND_PROFILE.VALUE('ORG_ID')
        PUT('ORG_ID', to_char(PROFILES_ORG_ID));
     else
        -- Bug 7423364: For R12, the profile option ORG_ID is not always an
        -- equivalent of FND_GLOBAL.ORG_ID, which is the org context. The
        -- global variable PROFILES_ORG_ID is the org context used for
        -- evaluating org-level profile option values and should be equal to
        -- FND_GLOBAL.ORG_ID. A value fetch on the profile option ORG_ID
        -- should return the profile option table value, not the org context.
        -- This behavior was confirmed with JMARY and SHNARAYA of the MO Team.
        -- CURRENT_ORG_CONTEXT is being introduced so that profiles code can
        -- provide similar functionality such that FND_GLOBAL.ORG_ID will be
        -- equivalent to FND_PROFILE.VALUE('CURRENT_ORG_CONTEXT').
        -- FND_GLOBAL.VALUE('ORG_ID') will return a value obtained in the
        -- FND_PROFILE_OPTION_VALUES table.
        PUT('CURRENT_ORG_CONTEXT', to_char(PROFILES_ORG_ID));
     end if;

     PUT('ORG_NAME', fnd_global.org_name);

end INITIALIZE_ORG_CONTEXT;

/*
** FOR AOL INTERNAL USE ONLY - DO NOT CALL DIRECTLY,
** CALL VIA FND_GLOBAL.APPS_INITIALIZE
** initialize - Initialize the internal profile information
** The cache is cleared of all database (non-put) options first.
** Initializes the profiles for the level context information.
**
*/
procedure INITIALIZE(
     USER_ID_Z           in number default NULL,
     RESPONSIBILITY_ID_Z in number default NULL,
     APPLICATION_ID_Z    in number default NULL,
     SITE_ID_Z           in number default NULL) is

     NAME              varchar2(256);
     ORG               varchar2(8);
     SESSION_ID        number;
     CACHE_VERSION     number;
     same_version      boolean;
     TEMP_UTL          varchar2(2000);

begin

     -- Clear old db entries
     SESSION_ID := ICX_SEC.G_SESSION_ID;

     -- Check cache versions
     CHECK_CACHE_VERSIONS();

     --
     -- Clear the "put" cache when session_id changes.
     -- NOTE: This needs to stay even when other caches are not
     -- cleared on session change.  Puts are always only good for
     -- the current session.
     --
     if((PROFILES_SESSION_ID is null) or (SESSION_ID is null) or
        (PROFILES_SESSION_ID = -1) or (SESSION_ID = -1) or
        (PROFILES_SESSION_ID <> SESSION_ID)) then
          NAME_TAB.DELETE();
          VAL_TAB.DELETE();
          PROFILE_OPTION_EXISTS := TRUE;
          if CORELOG_IS_ENABLED then
             fnd_core_log.put_line('Generic PUT Cache purged');
         end if;
     end if;

     --
     -- Clear the individual caches whose levels have changed.
     --
     if ((PROFILES_USER_ID is null) or (USER_ID_Z is null) or
         (PROFILES_USER_ID <> USER_ID_Z)) then
          USER_NAME_TAB.DELETE();
          USER_VAL_TAB.DELETE();
     end if;

     if ((PROFILES_RESP_ID is null) or (RESPONSIBILITY_ID_Z is null) or
         (PROFILES_RESP_ID <> RESPONSIBILITY_ID_Z)) then
          RESP_NAME_TAB.DELETE();
          RESP_VAL_TAB.DELETE();
    -- A change in responsibility affects the SERVRESP hierarchy and the cache
    -- should be emptied if the responsibility changes.
          SERVRESP_NAME_TAB.DELETE();
          SERVRESP_VAL_TAB.DELETE();
     end if;

     if ((PROFILES_APPL_ID is null) or (APPLICATION_ID_Z is null) or
         (PROFILES_APPL_ID <> APPLICATION_ID_Z)) then
          APPL_NAME_TAB.DELETE();
          APPL_VAL_TAB.DELETE();
         /* Bug 4738009: RESP SWITCH DOES NOT FLUSH RESP-LEVEL CACHE IF SAME
         ** RESP_ID BUT DIFF APPL_ID
         ** It is possible for responsibility_ids to be the same between
         ** applications.  So, if there is a switch in context between
         ** applications having the same responsibility_id, the resp-level
         ** and servresp-level cache is flushed.
         */
         if (PROFILES_RESP_ID = RESPONSIBILITY_ID_Z) then
            RESP_NAME_TAB.DELETE();
            RESP_VAL_TAB.DELETE();
            SERVRESP_NAME_TAB.DELETE();
            SERVRESP_VAL_TAB.DELETE();
         end if;
     end if;

     if ((PROFILES_SERVER_ID is null) or
         (PROFILES_SERVER_ID <> fnd_global.server_id)) then
          SERVER_NAME_TAB.DELETE();
          SERVER_VAL_TAB.DELETE();
     -- A change in server affects the SERVRESP hierarchy and the cache
     -- should be emptied if the server changes.
          SERVRESP_NAME_TAB.DELETE();
          SERVRESP_VAL_TAB.DELETE();
     end if;

     PROFILES_USER_ID := USER_ID_Z;
     PROFILES_RESP_ID := RESPONSIBILITY_ID_Z;
     PROFILES_APPL_ID := APPLICATION_ID_Z;
     PROFILES_SERVER_ID := fnd_global.server_id;
     PROFILES_SESSION_ID := SESSION_ID;

     -- Set login appl/resp/user specific security profiles
     if (user_id_z is not null) then
          PUT('USER_ID', to_char(user_id_z));

          if (user_id_z = fnd_global.user_id) then
               -- Use global to avoid select if current user
               NAME := fnd_global.user_name;
          elsif (user_id_z = -1) then
               NAME := 'DEFAULT_USER';
          else
               begin
                    SELECT USER_NAME
                    INTO NAME
                    FROM FND_USER
                    WHERE USER_ID = user_id_z;
               exception
                    when others then
                         NAME := '';
               end;
          end if;
          PUT('USERNAME', NAME);
     end if;

     -- For FND_PROFILE.INITIALIZE(), the CORELOG
     -- LOG_PROFNAME argument will be the code phase. LOG_PROFVAL will be
     -- user_name.
      if CORELOG_IS_ENABLED then
         CORELOG(
             'PROFILE_INIT',
             NAME,
             'FP.I',
             USER_ID_Z,
             RESPONSIBILITY_ID_Z,
             APPLICATION_ID_Z,
             fnd_global.org_id,
             fnd_global.server_id);
     end if;

     if ((responsibility_id_z is not null) and (application_id_z is not null))
          then
          PUT('RESP_ID', to_char(responsibility_id_z));
          PUT('RESP_APPL_ID', to_char(application_id_z));
          if ((responsibility_id_z = fnd_global.resp_id) and
          (application_id_z = fnd_global.resp_appl_id)) then
               -- Use global to avoid select if current resp
               NAME := fnd_global.resp_name;
          elsif ((responsibility_id_z = -1) and (application_id_z = -1)) then
               NAME := 'DEFAULT_RESP';
          else
               begin
                    SELECT RESPONSIBILITY_NAME
                    INTO NAME
                    FROM FND_RESPONSIBILITY_VL
                    WHERE RESPONSIBILITY_ID = responsibility_id_z
                    AND APPLICATION_ID = application_id_z;
               exception
                    when others then
                         NAME := '';
               end;
          end if;
          PUT('RESP_NAME', NAME);
     end if;

     -- Set the Server profile
     PUT('SERVER_ID', to_char(PROFILES_SERVER_ID));
     begin
          select node_name
          into NAME
          from fnd_nodes
          where node_id = PROFILES_SERVER_ID;
     exception
     when others then
           NAME := '';
     end;
     PUT('SERVER_NAME', NAME);

     -- Finally, initialize the org context
     initialize_org_context;

end INITIALIZE;

/*
** GET_TABLE_VALUE - get the value of a profile option from the table
*/
function GET_TABLE_VALUE(NAME in varchar2) return varchar2 is
     TABLE_INDEX  binary_integer;
     RETVAL       varchar2(255);
     NAME_UPPER   varchar2(80) := UPPER(NAME);
begin

     TABLE_INDEX := FIND(NAME_UPPER);
     if TABLE_INDEX < TABLE_SIZE then
          RETVAL := VAL_TAB(TABLE_INDEX);
     else
          RETVAL := null;
     end if;
     return RETVAL;

exception
  when others then
          return null;

end GET_TABLE_VALUE;

/*
** GET_ALL_TABLE_VALUES - get all the values from the table
*/
function GET_ALL_TABLE_VALUES(DELIM in varchar2) return varchar2 is
     TABLE_INDEX binary_integer;
     RETVAL      varchar2(32767);
     VAL         varchar2(1000);
begin
     if (not INSERTED) then
          return null;
     end if;

     TABLE_INDEX := 1;
     RETVAL := '';

     while (TABLE_INDEX < TABLE_SIZE) loop

          VAL := NAME_TAB(TABLE_INDEX) || DELIM ||
          VAL_TAB(TABLE_INDEX) || DELIM;

          if length(VAL) + length(RETVAL) > 32767 then
               return RETVAL;
          end if;

          RETVAL := RETVAL || VAL;
          TABLE_INDEX := TABLE_INDEX + 1;

     end loop;

     return RETVAL;

exception
     when others then
          return null;

end GET_ALL_TABLE_VALUES;

/*
* bumpCacheVersion_RF
*      The rule function for FND's subscription on the
*      oracle.apps.fnd.profile.value.update event.  This function calls
*      FND_CACHE_VERSION_PKG.bump_version to increase the version of the
*      appropriate profile level cache.
*/
function bumpCacheVersion_RF (
     p_subscription_guid in raw,
     p_event in out NOCOPY WF_EVENT_T)
return varchar2 is

     l_event_key     varchar2(255);
     l_level_id      number;
     l_cache_name    varchar2(30);

begin
     -- First thing to do is to get the event key.  The event key holds the
     -- information that is required to determine which profile level cache
     -- needs a version bump.  The event key is passed in this format:
     --    level_id||':'||level_value||':'||level_value_appl_id||':'||name
     l_event_key := p_event.getEventKey();

     -- Since all this function does is call
     -- FND_CACHE_VERSION_PKG.bump_version, the only information required from
     -- the event key is the level_id. This will indicate the profile level
     -- cache to be bumped.
     l_level_id:=to_number(SUBSTR(l_event_key,1,INSTR(l_event_key,':')-1));

     -- Using the level_id, determine the profile level cache name.
     if (l_level_id = 10001) then
          l_cache_name := SITE_CACHE;
     elsif (l_level_id = 10002) then
          l_cache_name := APPL_CACHE;
     elsif (l_level_id = 10003) then
          l_cache_name := RESP_CACHE;
     elsif (l_level_id = 10004) then
          l_cache_name := USER_CACHE;
     elsif (l_level_id = 10005) then
          l_cache_name := SERVER_CACHE;
     elsif (l_level_id = 10006) then
          l_cache_name := ORG_CACHE;
     elsif (l_level_id = 10007) then
          l_cache_name := SERVRESP_CACHE;
     else
          -- The level_id obtained is not valid.
          return 'ERROR';
     end if;

     -- Bump cache version using the appropriate cache name
     FND_CACHE_VERSIONS_PKG.bump_version(l_cache_name);
     return 'SUCCESS';

exception
     when others then
          WF_CORE.CONTEXT('FND_PROFILE', 'bumpCacheVersion_RF',
               p_event.getEventName(), p_subscription_guid);
          WF_EVENT.setErrorInfo(p_event, 'ERROR');
          return 'ERROR';
end;


/*
** DELETE - deletes the value of a profile option permanently from the
**          database, at any level.  This routine serves as a wrapper to
**          the SAVE routine which means that this routine can be used at
**          runtime or during patching.  Like the SAVE routine, this
**          routine will not actually commit the changes; the caller must
**          commit.  This API was added for enhancement request 4430579.
**
**        ('SITE', 'APPL', 'RESP', 'USER', 'SERVER', 'ORG', or 'SERVRESP').
**
**        Examples of use:
**        FND_PROFILE.DELETE('P_NAME', 'SITE');
**        FND_PROFILE.DELETE('P_NAME', 'APPL', 321532);
**        FND_PROFILE.DELETE('P_NAME', 'RESP', 321532, 345234);
**        FND_PROFILE.DELETE('P_NAME', 'USER', 123321);
**        FND_PROFILE.DELETE('P_NAME', 'SERVER', 25);
**        FND_PROFILE.DELETE('P_NAME', 'ORG', 204);
**        FND_PROFILE.DELETE('P_NAME', 'SERVRESP', 321532, 345234, 25);
**        FND_PROFILE.DELETE('P_NAME', 'SERVRESP', 321532, 345234, -1);
**        FND_PROFILE.DELETE('P_NAME', 'SERVRESP', -1, -1, 25);
**
**  returns: TRUE if successful, FALSE if failure.
**
*/
function DELETE(
   X_NAME in varchar2,
      -- Profile name you are setting
   X_LEVEL_NAME in varchar2,
      -- Level that you're setting at: 'SITE','APPL','RESP','USER', etc.
   X_LEVEL_VALUE in varchar2 default NULL,
      -- Level value that you are setting at, e.g. user id for 'USER' level.
      -- X_LEVEL_VALUE is not used at site level.
   X_LEVEL_VALUE_APP_ID in varchar2 default NULL,
      -- Used for 'RESP' and 'SERVRESP' level; Resp Application_Id.
   X_LEVEL_VALUE2 in varchar2 default NULL
      -- 2nd Level value that you are setting at.  This is for the 'SERVRESP'
      -- hierarchy only.
) return boolean is

   l_deleted   boolean;

begin

   -- Call SAVE routine and pass NULL for the profile option value.  This
   -- physically deletes the row from fnd_profile_option_values.
   l_deleted := SAVE(X_NAME,
                     NULL,
                     X_LEVEL_NAME,
                     X_LEVEL_VALUE,
                     X_LEVEL_VALUE_APP_ID,
                     X_LEVEL_VALUE2);

   return l_deleted;

end;

begin
     -- Initialization section
     TABLE_SIZE   := 8192;

end FND_PROFILE;
