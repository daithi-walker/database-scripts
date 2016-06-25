create or replace
package FND_STATS AUTHID CURRENT_USER as
/* $Header: AFSTATSS.pls 115.56 2008/11/24 10:52:22 appldev ship $ */


AUTO_SAMPLE_SIZE NUMBER :=0;         --


-- table having fewer blocks than this thold will be serialized
SMALL_TAB_FOR_PAR_THOLD  NUMBER := 500;

-- table having fewer blocks than this thold will be gathered at 100%
SMALL_TAB_FOR_EST_THOLD  NUMBER := 500;

-- index having fewer blocks than this thold will be serialized
SMALL_IND_FOR_PAR_THOLD  NUMBER := 500;

-- index having fewer blocks than this thold will be gathered at 100%
SMALL_IND_FOR_EST_THOLD  NUMBER := 500;

TYPE Error_Out IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;

procedure CREATE_STAT_TABLE ;

procedure ENABLE_SCHEMA_MONITORING(schemaname in varchar2 default 'ALL');

procedure DISABLE_SCHEMA_MONITORING(schemaname in varchar2 default 'ALL');

/* Undocumented and for INTERNAL use only */
procedure CREATE_STAT_TABLE( schemaname in varchar2,
                              tabname    in varchar2,
                              tblspcname in varchar2 default null);

procedure TRANSFER_STATS(   errbuf OUT NOCOPY  varchar2,
                            retcode OUT NOCOPY  varchar2,
                            action  in varchar2,
                            schemaname in varchar2,
                            tabname in varchar2,
                            stattab in varchar2 default 'FND_STATTAB',
                            statid   in varchar2
                           ) ;

procedure BACKUP_SCHEMA_STATS( schemaname in varchar2,
                               statid  in varchar2 default null);

procedure BACKUP_TABLE_STATS( schemaname in varchar2,
                              tabname in varchar2,
                              statid   in varchar2 default 'BACKUP',
                              partname in varchar2 default null,
                              cascade  in boolean default true
                              )  ;

procedure BACKUP_TABLE_STATS(   errbuf OUT NOCOPY  varchar2,
                                retcode OUT NOCOPY  varchar2,
                                schemaname in varchar2,
                                tabname in varchar2,
                                statid   in varchar2 default 'BACKUP',
                                partname in varchar2 default null,
                                cascade  in boolean default true
                             ) ;

procedure RESTORE_SCHEMA_STATS( schemaname in varchar2,
                                statid     in varchar2 default null);

procedure RESTORE_TABLE_STATS(ownname in varchar2,
                              tabname  in varchar2,
                              statid   in varchar2 default null,
                              partname in varchar2 default null,
                              cascade  in boolean default true
                              );

procedure RESTORE_TABLE_STATS(  errbuf OUT NOCOPY  varchar2,
                                retcode OUT NOCOPY  varchar2,
                                ownname in varchar2,
                                tabname  in varchar2,
                                statid   in varchar2 default null,
                                partname in varchar2 default null,
                                cascade  in boolean default true
                                );

/* Undocumented and for INTERNAL use only */
procedure RESTORE_INDEX_STATS(ownname in varchar2,
                              indname  in varchar2,
                              statid   in varchar2 default null,
                              partname in varchar2 default null);

procedure RESTORE_COLUMN_STATS(ownname in varchar2,
                              tabname  in varchar2,
                              colname  in varchar2,
                              partname in varchar2 default null,
                              statid   in varchar2 default null);

/* This restores the column stats for all cols specified in FND_HISTOGRAM_COLS */
procedure RESTORE_COLUMN_STATS(statid in varchar2 default null) ;

/* This procedure is created so that it can be called from SQL prompt
   This is exactly same except it doesn't have the output parameter */
procedure GATHER_SCHEMA_STATISTICS(schemaname in varchar2,
                              estimate_percent in number default 10,
                              degree in number default null,
                              internal_flag in varchar2 default 'NOBACKUP',
                              request_id in number default null,
                              hmode in varchar2 default 'LASTRUN',
                              options in varchar2 default 'GATHER',
                              modpercent in number default 10,
                              invalidate    in varchar2 default 'Y'
                              );

procedure GATHER_SCHEMA_STATS(schemaname in varchar2,
                              estimate_percent in number default 10,
                              degree in number default null,
                              internal_flag in varchar2 default 'NOBACKUP',
                              --Errors        OUT NOCOPY  Error_Out, -- commented to handle the error collection
                              request_id in number default null,
                              hmode in varchar2 default 'LASTRUN',
                              options in varchar2 default 'GATHER',
                              modpercent in number default 10,
                              invalidate    in varchar2 default 'Y'
                              );





procedure GATHER_SCHEMA_STATS_SQLPLUS(schemaname in varchar2,
                              estimate_percent in number default 10,
                              degree in number default null,
                              internal_flag in varchar2 default 'NOBACKUP',
                              Errors        OUT NOCOPY  Error_Out, -- commented to handle the error collection
                              request_id in number default null,
                              hmode in varchar2 default 'LASTRUN',
                              options in varchar2 default 'GATHER',
                              modpercent in number default 10,
                              invalidate    in varchar2 default 'Y'
                              );

procedure GATHER_SCHEMA_STATS(errbuf OUT NOCOPY  varchar2,
                              retcode OUT NOCOPY  varchar2,
                              schemaname in varchar2,
                              estimate_percent in number default 10,
                              degree in number default null,
                              internal_flag in varchar2 default 'NOBACKUP',
                              request_id in number default null,
                              hmode in varchar2 default 'LASTRUN',
                              options in varchar2 default 'GATHER',
                              modpercent in number default 10,
                              invalidate    in varchar2 default 'Y'
                              );

procedure GATHER_INDEX_STATS(ownname in varchar2,
                             indname  in varchar2,
                             percent  in number default null,
			     degree in number default null,
                             partname in varchar2 default null,
                             backup_flag  in varchar2 default 'NOBACKUP',
                              hmode in varchar2 default 'LASTRUN',
                              invalidate    in varchar2 default 'Y'
                             );

procedure GATHER_TABLE_STATS(ownname in varchar2,
                             tabname  in varchar2,
                             percent  in number default null,
                             degree in number default null,
                             partname in varchar2 default null,
                             backup_flag in varchar2 default 'NOBACKUP',
                             cascade  in boolean default true,
                             granularity  in varchar2 default 'DEFAULT',
                              hmode in varchar2 default 'LASTRUN',
                              invalidate    in varchar2 default 'Y'
                            );

procedure GATHER_TABLE_STATS(errbuf OUT NOCOPY  varchar2,
                             retcode OUT NOCOPY  varchar2,
                             ownname in varchar2,
                             tabname  in varchar2,
                             percent  in number default null,
                             degree in number default null,
                             partname in varchar2 default null,
                             backup_flag in varchar2 default 'NOBACKUP',
                             granularity  in varchar2 default 'DEFAULT',
                              hmode in varchar2 default 'LASTRUN',
                              invalidate    in varchar2 default 'Y'
                             );

procedure GATHER_COLUMN_STATS(appl_id in number default null,
                              percent in number default null,
                              degree in number default null,
                              backup_flag in varchar2 default 'NOBACKUP',
                              --Errors OUT NOCOPY  Error_Out,--commented to handle the error collection
                              hmode in varchar2 default 'LASTRUN',
                              invalidate    in varchar2 default 'Y'
                             );

procedure GATHER_ALL_COLUMN_STATS(ownname in varchar2,
                              percent in number default null,
                              degree in number default null,
                              hmode in varchar2 default 'LASTRUN',
                              invalidate    in varchar2 default 'Y'
                              );

procedure GATHER_ALL_COLUMN_STATS(errbuf OUT NOCOPY  varchar2,
                              retcode OUT NOCOPY  varchar2,
                              ownname in varchar2,
                              percent in number default null,
                              degree in number default null,
                              hmode in varchar2 default 'LASTRUN',
                              invalidate    in varchar2 default 'Y'
                              );

procedure GATHER_COLUMN_STATS(ownname in varchar2,
                              tabname  in varchar2,
                              colname  in varchar2,
                              percent in number default null,
                              degree in number default null,
                              hsize   in number default 254,
                              backup_flag in varchar2 default 'NOBACKUP',
                              partname in varchar2 default null,
                              hmode in varchar2 default 'LASTRUN',
                              invalidate    in varchar2 default 'Y'
                             );

procedure GATHER_COLUMN_STATS(errbuf OUT NOCOPY  varchar2,
                              retcode OUT NOCOPY  varchar2,
                              ownname in varchar2,
                              tabname  in varchar2,
                              colname  in varchar2,
                              percent  in number  default null,
                              degree in number default null,
                              hsize   in number default 254,
                              backup_flag in varchar2 default 'NOBACKUP',
                              partname in varchar2 default null,
                              hmode in varchar2 default 'LASTRUN',
                              invalidate    in varchar2 default 'Y'
                             );

/* Purges all records of the FND_STATS_HIST that fall between from_req_id and to_req_id */
procedure  PURGE_STAT_HISTORY(from_req_id in number,
                      to_req_id  in number
                                ) ;

/* Purges all records of the FND_STATS_HIST that fall between from_req_id and to_req_id */
procedure  PURGE_STAT_HISTORY(purge_from_date in varchar2 ,
                      purge_to_date  in varchar2
                                ) ;
procedure PURGE_STAT_HISTORY(errbuf OUT NOCOPY  varchar2,
                             retcode OUT NOCOPY  varchar2,
                             purge_mode in varchar2 ,
                             from_value in varchar2 ,
                             to_value in varchar2 );


/* Undocumented and for INTERNAL use only */
procedure SET_TABLE_STATS(ownname in varchar2,
                          tabname in varchar2,
                          numrows  in number,
                          numblks  in number,
                          avgrlen  in number,
                          partname in varchar2 default null);


/* Undocumented and for INTERNAL use only */
procedure SET_INDEX_STATS(ownname in varchar2,
                          indname in varchar2,
                          numrows  in number,
                          numlblks  in number,
                          numdist  in number,
                          avglblk  in number,
                          avgdblk  in number,
                          clstfct  in number,
                          indlevel in number,
                          partname in varchar2 default null);

procedure  LOAD_XCLUD_STATS(schemaname in varchar2);

/* This one is for a particular INTERFACE TABLE  */
procedure  LOAD_XCLUD_STATS(schemaname in varchar2,
                            tablename  in varchar2);

/* This is for loading exclusion list into fnd_exclude_table_stats */
procedure LOAD_XCLUD_TAB(action in varchar2,
                          appl_id in number,
                          tabname in varchar2);

/* This is for internal/support purpose only. For loading/deleting SEED database */
/* procedure DELETE_XCLUD_IND( appl_id in number,
                          tabname in varchar2,
                          indname in varchar2,
                          partname  in varchar2 default null);
*/
/* This is for internal purpose only. For loading into SEED database */
procedure LOAD_HISTOGRAM_COLS(action in varchar2,
                          appl_id in number,
                          tabname in varchar2,
                          colname in varchar2,
                          partname in varchar2 default null,
                          hsize  in number default 254,
                          commit_flag in varchar2 default 'Y' );

/* This is for internal purpose only. This is for seeding Materialized View columns For loading into SEED database */
procedure LOAD_HISTOGRAM_COLS_MV(action in varchar2,
                          ownername in varchar2,
                          tabname in varchar2,
                          colname in varchar2,
                          partname in varchar2 default null,
                          hsize  in number default 254,
                          commit_flag in varchar2 default 'Y');
/* This is to check if the leading cols of non-unique indexes of
   a list of input table_names needs histograms */
procedure CHECK_HISTOGRAM_COLS(tablelist        in varchar2,
                               factor           in integer default 75,
                               percent          in number default 10,
                               degree           in number default null);

/* This is to create histograms on all leading cols of non-unique indexes of all the
   tables in a given schema */
procedure ANALYZE_ALL_COLUMNS(ownname       in varchar2,
                              percent       in number default null,
                              hsize         in number default 254,
                              hmode in varchar2 default 'LASTRUN');
/* conc. job version of ANALYZE_ALL_COLUMNS */
procedure ANALYZE_ALL_COLUMNS(errbuf OUT NOCOPY  varchar2,
                              retcode OUT NOCOPY  varchar2,
                              ownname       in varchar2,
                              percent  in number default null,
                              hsize              in number default 254,
                              hmode in varchar2 default 'LASTRUN');

/* Used for updating the FND_STATS_HIST with autonomous_transaction */
procedure  UPDATE_HIST(schemaname varchar2,
                                 objectname in varchar2,
                                 objecttype in varchar2,
                                 partname   in varchar2,
                                 columntablename   in varchar2,
                                 degree  in number,
                                 upd_ins_flag in varchar2,
                                 percent in number default null
                                ) ;
/* This procedure checks tables, indexes and histograms to see if statistics exist or are stale */
procedure verify_stats(schemaname  varchar2 default null,
		       tableList   varchar2 default null,
		       days_old    number   default null,
                       column_stat boolean default false);
end FND_STATS;

create or replace
package body FND_STATS as
/* $Header: AFSTATSB.pls 115.97 2008/11/24 10:53:40 appldev ship $ */

db_versn number :=81;
request_from varchar2(7) default 'U';
MAX_ERRORS_PRINTED NUMBER := 20 ;    -- The max nof. allowable errors.
STD_GRANULARITY        VARCHAR2(15) := 'DEFAULT' ;  -- Global/partion
PART_GRANULARITY       VARCHAR2(15) := 'PARTITION' ;-- Granularity is partition level.
ALL_GRANULARITY        VARCHAR2(15) := 'ALL' ;-- Granularity is ALL.
INDEX_LEVEL            NUMBER := 1 ; /* default ind_level for fudged ind. stats,
                                        came to this value so that optimizer
                                        prefers index access */


fnd_stattab varchar2(30) := 'FND_STATTAB'; -- Name of the backup table
fnd_statown varchar2(30) := 'APPLSYS'; -- Owner of the backup table


stat_tab_exist boolean := false;
dummy1      varchar2(30);
dummy2      varchar2(30);
dummybool   boolean  ;
cur_request_id number(15) default null;
call_from_sqlplus boolean :=false;

fm_first_flag  boolean :=true; -- Flush_monitoring first time call flag

stathist varchar2(8);


def_degree number; -- default degree for parallel
g_Errors Error_Out;

-- New cursort to support MVs
cursor schema_cur is
 select upper(oracle_username) sname
       from   fnd_oracle_userid
       where oracle_id between 900 and 999
       and    read_only_flag = 'U'
 union all
  select distinct upper(oracle_username) sname
    from fnd_oracle_userid a,
        fnd_product_installations b
    where a.oracle_id = b.oracle_id
    order by sname;


/************************************************************************/
/* Function : GET_BLOCKS                                                */
/* Desciption: Gets the size in blocks of the given table.              */
/************************************************************************/
Function GET_BLOCKS(schemaname in varchar2,object_name in varchar2,
                    object_type in varchar2) return number
is
total_blocks number;
total_bytes number;
unused_blocks number;
unused_bytes number;
last_extf number;
last_extb number;
last_usedblock number;
begin
  DBMS_SPACE.UNUSED_SPACE(upper(schemaname),upper(object_name),upper(object_type),total_blocks,
         total_bytes,unused_blocks,unused_bytes,last_extf,last_extb,
         last_usedblock);
   return total_blocks-unused_blocks;
exception
  when others then
   -- For partitioned tables, we will get an exception as it unused space
   -- expects a partition spec. If table is partitioned, we definitely
   -- do not want to do serial, so will return thold+1000.
   return fnd_stats.SMALL_TAB_FOR_PAR_THOLD+1000;
end;


/************************************************************************/
/* Procedure:  SCHEMA_MONITORING                                        */
/* Desciption: Non Public procedure that is called by                   */
/* ENABLE_SCHEMA_MONITORING or DISABLE_SCHEMA_MONITORING                */
/************************************************************************/
procedure SCHEMA_MONITORING(mmode in varchar2,schemaname in varchar2)
 is
TYPE name_tab is TABLE OF dba_tables.table_name%TYPE;
tmp_str varchar2(200);
   names name_tab;
   num_tables number := 0;
   modeval varchar2(5);
   modbool varchar2(6);
begin

if mmode='ENABLE' then
   modeval:='YES';
   modbool:='TRUE';
else
   modeval:='NO';
   modbool:='FALSE';
end if;

  if (( db_versn > 80) and (db_versn < 90)) then
    -- 8i does not have the ALTER_SCHEMA_TAB_MONITORING function,
    -- therefore this has to be taken care of manually.

    if schemaname='ALL' then  -- call itself with the schema name
           for c_schema in schema_cur loop
             FND_STATS.SCHEMA_MONITORING(mmode,c_schema.sname);
           end loop;  /* schema_cur */

        else     -- schemaname<>'ALL'

               select table_name
                BULK COLLECT INTO
                names
                from dba_tables
                where owner = upper(schemaname)
		and (iot_type <> 'IOT_OVERFLOW' or iot_type is null)

                and temporary <> 'Y'
                and monitoring <> modeval;    -- skip table that already have the selected mode

                num_tables := SQL%ROWCOUNT;

                for i in 1..num_tables LOOP
                      if mmode='ENABLE' then
                         tmp_str:='ALTER TABLE '||upper(schemaname)||'.'||names(i)||' MONITORING';
                      elsif mmode='DISABLE' then
                         tmp_str:='ALTER TABLE '||upper(schemaname)||'.'||names(i)||' NOMONITORING';
                      end if;
                      EXECUTE IMMEDIATE tmp_str;
                      dbms_output.put_line(tmp_str);
                 end loop;

       end if;   -- if schemaname ='ALL'

  elsif ((db_versn > 90 ) and (db_versn < 100)) then
    -- 8i does not have the ALTER_SCHEMA_TAB_MONITORING function,
    -- therefore 9i specific function calls have to be dynamic sql.
    if schemaname='ALL' then
      tmp_str:='BEGIN dbms_stats.ALTER_DATABASE_TAB_MONITORING(monitoring=>'||modbool||',sysobjs=>FALSE); END;';
      EXECUTE IMMEDIATE tmp_str;
    else
      tmp_str:='BEGIN dbms_stats.ALTER_SCHEMA_TAB_MONITORING(ownname=>:SCHEMANAME,monitoring=>'||modbool||'); END;';
      EXECUTE IMMEDIATE tmp_str USING schemaname;
    end if;

  else -- db version is 10, do nothing as it is taken care of by default.
   -- db_versn is a 2 char code, which is 10 for 10g.
   null;
  end if;
end;


/************************************************************************/
/* Procedure: ENABLE_SCHEMA_MONITORING                                  */
/* Desciption: Enables MONITORING option for all tables in the          */
/* given schema. If schemaname is not specified, defaults to 'ALL'.     */
/************************************************************************/
procedure ENABLE_SCHEMA_MONITORING(schemaname in varchar2)
is
begin
  SCHEMA_MONITORING('ENABLE',schemaname);
end;

/************************************************************************/
/* Procedure: ENABLE_SCHEMA_MONITORING                                  */
/* Desciption: Enables MONITORING option for all tables in the          */
/* given schema. If schemaname is not specified, defaults to 'ALL'.     */
/************************************************************************/
procedure DISABLE_SCHEMA_MONITORING(schemaname in varchar2)
is
begin
  SCHEMA_MONITORING('DISABLE',schemaname);
end;

/************************************************************************/
/* Procedure: GET_PARALLEL                                              */
/* Desciption: Gets the min between number of parallel max servers      */
/* and the cpu_count. This number is used as a default degree of        */
/* parallelism is none is specified.                                    */
/************************************************************************/
procedure GET_PARALLEL(parallel IN OUT NOCOPY  number)
 is
begin
     select min(to_number(value))
     into parallel
     from v$parameter
     where name='parallel_max_servers'
     or name ='cpu_count';
end;

/************************************************************************/
/* Function: GET_REQUEST_ID                                             */
/* Desciption: Gets the current request_id                              */
/* If the call is thru a concurrent program, the conc request id is     */
/* returned, which can be later over-ridden if restart case.            */
/* If is is not thru a concurrent program, a user request id is         */
/* generated.                                                           */
/************************************************************************/
function GET_REQUEST_ID return number
 is
  str_request_id varchar2(30);
  request_id_l number(15);
  l_message varchar2(1000);
begin
--      FND_PROFILE.GET('CONC_REQUEST_ID', str_request_id);
--        if str_request_id is not null then  -- call is via a conc program
       if FND_GLOBAL.CONC_REQUEST_ID > 0 then  -- call is via a conc program
         request_from:='C';             -- set request type C for CONC
           request_id_l := FND_GLOBAL.CONC_REQUEST_ID;  -- set request id to conc request id
       elsif ( FND_GLOBAL.USER_ID > 0) then  -- check if call from apps program
          request_from:='P';                  -- P for PROG , cal by program
           -- generate it from sequence
          select fnd_stats_hist_s.nextval into request_id_l from dual;
       else                                -- call not from within apps context, maybe sqlplus
         request_from:='U';                -- U for USER, called from sqlplus etc
          -- generate it from sequence
         select fnd_stats_hist_s.nextval into request_id_l from dual;
       end if;
  -- dbms_output.put_line('Request_id is '||request_id);
  -- dbms_output.put_line('Effective Request_id is '||request_id_l);
  -- l_message := 'Request_id is '||cur_request_id|| 'Effective Request_id is '||request_id_l;

  -- FND_FILE.put_line(FND_FILE.log,l_message);
  return request_id_l;
end;


/************************************************************************/
/* Procedure: CREATE_STAT_TABLE                                         */
/* Desciption: Create stats table to hold statistics. Default parameters*/
/* are used for tablename and owner.                                    */
/************************************************************************/
procedure CREATE_STAT_TABLE
 is
     PRAGMA AUTONOMOUS_TRANSACTION;
begin
     -- if stat_tab has already been created, do not recreate
    begin
     dummy1:='N';
      execute immediate 'select ''Y'' from all_tables '||
      ' where owner='''||fnd_statown|| ''' and table_name='''||fnd_stattab||'''' into dummy1;
    exception
      when others then
       stat_tab_exist:=false;
    end;
      if dummy1='Y' then
         stat_tab_exist := true;
      end if;

     if stat_tab_exist = false then
        DBMS_STATS.CREATE_STAT_TABLE(fnd_statown,fnd_stattab);
        stat_tab_exist := true;
     end if;

     exception
         when others then raise;
end ;  /* CREATE_STAT_TABLE */

/************************************************************************/
/* Procedure: CREATE_STAT_TABLE                                         */
/* Desciption: Create stats table to hold statistics. Caller can specify*/
/* cusotm values for schema, tablename or tablespace name               */
/************************************************************************/
procedure CREATE_STAT_TABLE( schemaname in varchar2,
                              tabname    in varchar2,
                              tblspcname in varchar2 default null) is
     PRAGMA AUTONOMOUS_TRANSACTION;
begin
     DBMS_STATS.CREATE_STAT_TABLE(schemaname,tabname,tblspcname);
     exception
         when others then raise;
end;  /* CREATE_STAT_TABLE(,,) */

/**
*  procedure TRANSFER_STATS : Wrapper around backup/restore stats procedures,
*                             required for the new "Backup/Restore Statistics"
*                             conc program.
*/
procedure TRANSFER_STATS(   errbuf OUT NOCOPY  varchar2,
                            retcode OUT NOCOPY  varchar2,
                            action in varchar2,
                            schemaname in varchar2,
                            tabname in varchar2,
                            stattab in varchar2 default 'FND_STATTAB',
                            statid   in varchar2
                           ) is
  exist_insufficient exception;
  pragma exception_init(exist_insufficient,-20000);
  l_message varchar2(1000);
begin
     begin
      create_stat_table(schemaname,stattab);

    exception
      when others then
       null;
    end;

      if(upper(action) = 'BACKUP') then
         if(tabname is null) then
            BACKUP_SCHEMA_STATS( schemaname ,
                                 statid  );
         else
            BACKUP_TABLE_STATS( schemaname ,
                                tabname    ,
                                statid  )  ;
         end if;

      elsif(upper(action) = 'RESTORE') then

         if(tabname is null) then
            RESTORE_SCHEMA_STATS( schemaname ,
                                  statid  );
         else
            RESTORE_TABLE_STATS(schemaname ,
                                tabname ,
                                statid
                                );
         end if;
      end if;

   exception
     when exist_insufficient then
        errbuf := sqlerrm ;
        retcode := '2';
        l_message := errbuf;
        FND_FILE.put_line(FND_FILE.log,l_message);
        raise;
     when others then
        errbuf := sqlerrm ;
        retcode := '2';
        l_message := errbuf;
        FND_FILE.put_line(FND_FILE.log,l_message);
        raise;
end;






/************************************************************************/
/* Procedure: BACKUP_SCHEMA_STATS                                       */
/* Desciption: Copies schema statistics to fnd_stattab table. If schema */
/* name is 'ALL', copies all schema stats. Statistics stored with       */
/* a particular stat id.                                                */
/************************************************************************/
procedure BACKUP_SCHEMA_STATS( schemaname in varchar2,
                               statid     in varchar2)
is
     exist_insufficient exception;
     pragma exception_init(exist_insufficient,-20002);
begin
    -- First create the FND_STATTAB if it doesn't exist.
    BEGIN
       FND_STATS.CREATE_STAT_TABLE();
       exception
           when exist_insufficient then null;
    END;
    if (upper(schemaname) <> 'ALL')  then
        DBMS_STATS.EXPORT_SCHEMA_STATS(schemaname, fnd_stattab, statid,
            fnd_statown);
    else
      for c_schema in schema_cur loop
        DBMS_STATS.EXPORT_SCHEMA_STATS(c_schema.sname, fnd_stattab, statid,
            fnd_statown);
      end loop;  /* schema_cur */
    end if;
end;  /* BACKUP_SCHEMA_STATS() */

/************************************************************************/
/* Procedure: BACKUP_TABLE_STATS                                        */
/* Desciption: Copies table statistics along with index and column      */
/* stats if cascade is true. Procedure is called from concurrent program*/
/* manager.                                                             */
/************************************************************************/
procedure BACKUP_TABLE_STATS( errbuf OUT NOCOPY  varchar2,
                              retcode  OUT NOCOPY  varchar2,
                              schemaname in varchar2,
                              tabname in varchar2,
                              statid   in varchar2 default 'BACKUP',
                              partname in varchar2 default null,
                              cascade  in boolean default true
                              )
is
  exist_insufficient exception;
  pragma exception_init(exist_insufficient,-20000);
  l_message varchar2(1000);
begin

   FND_STATS.BACKUP_TABLE_STATS(schemaname, tabname, statid, partname,
        cascade);
   exception
     when exist_insufficient then
        errbuf := sqlerrm ;
        retcode := '2';
        l_message := errbuf;
        FND_FILE.put_line(FND_FILE.log,l_message);
        raise;
     when others then
        errbuf := sqlerrm ;
        retcode := '2';
        l_message := errbuf;
        FND_FILE.put_line(FND_FILE.log,l_message);
        raise;
end;  /*   BACKUP_TABLE_STATS */

/************************************************************************/
/* Procedure: BACKUP_TABLE_STATS                                        */
/* Desciption: Copies table statistics along with index and column      */
/* stats if cascade is true. Procedure is called by the concurrent      */
/* program manager version of BACKUP_TABLE_STATS. Procedure can also be */
/* called from sqlplus                                                  */
/************************************************************************/
procedure BACKUP_TABLE_STATS( schemaname in varchar2,
                              tabname in varchar2,
                              statid   in varchar2 default 'BACKUP',
                              partname in varchar2 default null,
                              cascade  in boolean default true
                              )
is
     exist_insufficient exception;
     pragma exception_init(exist_insufficient,-20002);
begin
    -- First create the FND_STATTAB if it doesn't exist.
    BEGIN
       FND_STATS.CREATE_STAT_TABLE();
       exception
           when exist_insufficient then null;
    END;
    DBMS_STATS.EXPORT_TABLE_STATS(schemaname,
                                  tabname,
                                  partname,
                                  fnd_stattab,
                                  statid,
                                  cascade,
                                  fnd_statown) ;
end;  /* BACKUP_TABLE_STATS() */

/************************************************************************/
/* Procedure: RESTORE_SCHEMA_STATS                                      */
/* Desciption: Retores schema statistics from fnd_stattab table. If     */
/* schema name is 'ALL', copies all schema stats. Statistics restored   */
/* with a particular stat id.                                           */
/************************************************************************/
procedure RESTORE_SCHEMA_STATS(schemaname in varchar2,
                               statid     in varchar2 default null)
is
begin
    if (upper(schemaname) <> 'ALL')  then
        DBMS_STATS.IMPORT_SCHEMA_STATS(schemaname, fnd_stattab, statid,
            fnd_statown);
    else
      for c_schema in schema_cur loop
        DBMS_STATS.IMPORT_SCHEMA_STATS(c_schema.sname, fnd_stattab, statid,
            fnd_statown);
      end loop;  /* schema_cur */
    end if;
end;  /* RESTORE_SCHEMA_STATS() */

/************************************************************************/
/* Procedure: RESTORE_TABLE_STATS                                       */
/* Desciption: Retores table statistics from fnd_stattab table. If      */
/* cascase is true, restores column as well as index stats too. This    */
/* procedure is called from concurrent program manager.                 */
/************************************************************************/
procedure RESTORE_TABLE_STATS(errbuf OUT NOCOPY  varchar2,
                              retcode OUT NOCOPY  varchar2,
                              ownname in varchar2,
                              tabname  in varchar2,
                              statid   in varchar2 default null,
                              partname in varchar2 default null,
                              cascade  in boolean default true
                              )
is
  exist_insufficient exception;
  exist_invalid      exception;
  pragma exception_init(exist_insufficient,-20000);
  pragma exception_init(exist_invalid,-20001);
  l_message varchar2(1000);
begin
     FND_STATS.RESTORE_TABLE_STATS(ownname,tabname,statid,partname,cascade);
       exception
           when exist_insufficient then
              errbuf := sqlerrm;
              retcode := '2';
              l_message := errbuf;
              FND_FILE.put_line(FND_FILE.log,l_message);
              raise;
           when exist_invalid then
              errbuf := 'ORA-20001: Invalid or inconsistent values in the user stattab ='||fnd_stattab ||' statid='||statid ;
              retcode := '2';
              l_message := errbuf;
              FND_FILE.put_line(FND_FILE.log,l_message);
              raise;
           when others then
              errbuf := sqlerrm ;
              retcode := '2';
              l_message := errbuf;
              FND_FILE.put_line(FND_FILE.log,l_message);
              raise;
end;  /* RESTORE_TABLE_STATS */

/************************************************************************/
/* Procedure: RESTORE_TABLE_STATS                                       */
/* Desciption: Retores table statistics from fnd_stattab table. If      */
/* cascase is true, restores column as well as index stats too. This    */
/* procedure is called from the concurrent program manager version of   */
/* RESTORE_TABLE_STATS as well as from sqlplus                          */
/************************************************************************/
procedure RESTORE_TABLE_STATS(ownname in varchar2,
                              tabname  in varchar2,
                              statid   in varchar2 default null,
                              partname in varchar2 default null,
                              cascade  in boolean default true
                             )
is
begin
     DBMS_STATS.IMPORT_TABLE_STATS(ownname,tabname,partname,
                                  fnd_stattab,statid,cascade,fnd_statown);
end;  /* RESTORE_TABLE_STATS */

/************************************************************************/
/* Procedure: RESTORE_INDEX_STATS                                       */
/* Desciption: Retores index statistics from fnd_stattab table for a    */
/* particular table.                                                    */
/************************************************************************/
procedure RESTORE_INDEX_STATS(ownname in varchar2,
                              indname  in varchar2,
                              statid   in varchar2 default null,
                              partname in varchar2 default null)
is
begin
     DBMS_STATS.IMPORT_INDEX_STATS(ownname,indname,partname,fnd_stattab,
                                   statid,fnd_statown) ;
end; /* RESTORE_INDEX_STATS */

/************************************************************************/
/* Procedure: RESTORE_COLUMN_STATS                                      */
/* Desciption: Retores column statistics from fnd_stattab table for a   */
/* particular column.                                                   */
/************************************************************************/
procedure RESTORE_COLUMN_STATS(ownname in varchar2,
                              tabname  in varchar2,
                              colname  in varchar2,
                              partname in varchar2 default null,
                              statid   in varchar2 default null)
is
begin
     DBMS_STATS.IMPORT_COLUMN_STATS(ownname, tabname, colname, partname,
        fnd_stattab, statid, fnd_statown) ;
end; /* RESTORE_COLUMN_STATS() */

/************************************************************************/
/* Procedure: RESTORE_COLUMN_STATS                                      */
/* Desciption: Retores column statistics from fnd_stattab table for all */
/* columns seeded in the fnd_histogram_cols table.                      */
/************************************************************************/
procedure RESTORE_COLUMN_STATS(statid in varchar2 default null)
is
  /* cursor col_cursor is
    select upper(b.oracle_username) ownname ,
           a.table_name tabname,
           a.column_name colname,
           a.partition partname
    from   FND_HISTOGRAM_COLS a,
           FND_ORACLE_USERID b,
           FND_PRODUCT_INSTALLATIONS c
    where  a.application_id = c.application_id
    and    c.oracle_id  = b.oracle_id
    order by ownname, tabname, column_name;
*/

  -- New cursor to support MVs
 cursor col_cursor is
 select nvl(upper(b.oracle_username), a.owner) ownname ,
           a.table_name tabname,
           a.column_name colname,
           a.partition partname
    from   FND_HISTOGRAM_COLS a,
           FND_ORACLE_USERID b,
           FND_PRODUCT_INSTALLATIONS c
    where  a.application_id = c.application_id (+)
    and    c.oracle_id  = b.oracle_id (+)
    order by ownname, tabname, colname;

begin
    for c_rec in col_cursor loop
        DBMS_STATS.IMPORT_COLUMN_STATS(c_rec.ownname,c_rec.tabname,
                                       c_rec.colname,c_rec.partname,
                                       fnd_stattab,statid,fnd_statown);
    end loop;
end; /* RESTORE_COLUMN_STATS */



/************************************************************************/
/* Procedure: DLOG                                                      */
/* Desciption: Writes out log messages to the conc program log.         */
/************************************************************************/

procedure dlog(p_str IN varchar2) is
begin
   dbms_output.put_line(substr(p_str,1,250));
        FND_FILE.put_line(FND_FILE.log,p_str);
end dlog;


/************************************************************************/
/* Procedure: GATHER_TABLE_STATS_PVT                                    */
/* Desciption: Private package that now calls dbms_stats dynamically    */
/*             depending upon the version of the database. For 8i,      */
/*             dbms_stats is called as before, for higher versions, it  */
/*             is called with the no_invalidate flag.                   */
/************************************************************************/

procedure GATHER_TABLE_STATS_PVT(ownname in varchar2,
                                 tabname  in varchar2,
                                 estimate_percent  in number default null,
                                 degree in number default null,
                                 method_opt VARCHAR2 DEFAULT 'FOR ALL COLUMNS SIZE 1',
                                 partname in varchar2 default null,
                                 cascade  in boolean default true,
                                 granularity  in varchar2 default 'DEFAULT',
                                 stattab  VARCHAR2 DEFAULT NULL,
                                 statown VARCHAR2 DEFAULT NULL,
                                 invalidate    in varchar2 default 'Y'
                                ) is
l_tmp_str varchar2(600);
no_invalidate varchar2(1);
begin
  if ((upper(invalidate) ='Y') OR (upper(invalidate) ='YES')) then
   no_invalidate:='N';
  else
   no_invalidate:='Y';
  end if;

  -- If db version is < 9iR2, OR it is 92 and no_inv is false OR it is > 92
  -- and no_inv is true,   calls dbms_stats statically, else ...
  if ( (db_versn <= 92) OR (db_versn=92 AND no_invalidate='N') OR
      (db_versn>=100 AND no_invalidate='Y')) then
   DBMS_STATS.GATHER_TABLE_STATS( ownname => ownname ,
                                  tabname => tabname ,
                                  estimate_percent => estimate_percent ,
                                  degree => degree ,
                                  method_opt => method_opt ,
                                  block_sample => FALSE ,
                                  partname => partname ,
                                  cascade => cascade ,
                                  granularity => granularity ,
                                  stattab => stattab ,
                                  statown => statown
                                 );

  else

      l_tmp_str:= 'BEGIN DBMS_STATS.GATHER_TABLE_STATS( ownname => :ownname ,'||
                    ' tabname => :tabname ,'||
                    ' estimate_percent => :estimate_percent ,'||
                    ' degree => :degree ,'||
                    ' method_opt => :method_opt ,'||
                    ' block_sample => FALSE ,'||
                    ' partname => :partname ,'||
                    ' granularity => :granularity ,'||
                    ' stattab => :stattab ,'||
                    ' statown => :statown, ';
      if (no_invalidate='Y') then
        l_tmp_str:=l_tmp_str|| '               no_invalidate => TRUE ,';
      else
        l_tmp_str:=l_tmp_str|| '               no_invalidate => FALSE ,';
      end if;
      if (cascade) then
        l_tmp_str:=l_tmp_str|| '               cascade => TRUE ';
      else
        l_tmp_str:=l_tmp_str|| '               cascade => FALSE ';
      end if;
      l_tmp_str:=l_tmp_str|| '              ); end;';
   EXECUTE IMMEDIATE l_tmp_str USING ownname , tabname , estimate_percent ,
                     degree , method_opt , partname ,
                     granularity , stattab , statown;
  end if;
exception
  when others then
    raise;

end;  /* GATHER_TABLE_STATS_PVT */


/************************************************************************/
/* Procedure: GATHER_INDEX_STATS_PVT                                    */
/* Desciption: Private package that now calls dbms_stats dynamically    */
/*             depending upon the version of the database. For 8i,      */
/*             dbms_stats is called as before, for higher versions, it  */
/*             is called with the invalidate flag.                   */
/************************************************************************/
procedure GATHER_INDEX_STATS_PVT(ownname in varchar2,
                                 indname  in varchar2,
                                 estimate_percent  in number default null,
                                 degree in number default null,
                                 partname in varchar2 default null,
                                 invalidate    in varchar2 default 'Y'
                                ) is
l_tmp_str varchar2(600);
no_invalidate varchar2(1);
begin
  if ((upper(invalidate) ='Y') OR (upper(invalidate) ='YES')) then
   no_invalidate:='N';
  else
   no_invalidate:='Y';
  end if;

  -- If db version is < 9iR2,  calls dbms_stats statically, else ...
  if  (db_versn <= 92)  then
   DBMS_STATS.GATHER_INDEX_STATS( ownname => ownname ,
                                  indname => indname ,
                                  estimate_percent => estimate_percent ,
                                  partname => partname
                                 );
  else
      l_tmp_str:= 'BEGIN DBMS_STATS.GATHER_INDEX_STATS( ownname => :ownname ,'||
                  '               indname => :indname ,'||
                  '               estimate_percent => :estimate_percent ,'||
                  '               degree => :degree ,'||
                  '               partname => :partname ,';
      if (no_invalidate='Y') then
        l_tmp_str:=l_tmp_str|| '               no_invalidate => TRUE ';
      else
        l_tmp_str:=l_tmp_str|| '               no_invalidate => FALSE ';
      end if;
      l_tmp_str:=l_tmp_str||'              ); END;';
   EXECUTE IMMEDIATE l_tmp_str USING ownname , indname , estimate_percent ,
                     degree , partname ;
  end if;

end;  /* GATHER_INDEX_STATS_PVT */



/************************************************************************/
/* Procedure: GATHER_SCHEMA_STATS                                       */
/* Desciption: Gather schema statistics. This is the concurrent program */
/* manager version.                                                     */
/************************************************************************/
procedure GATHER_SCHEMA_STATS(errbuf OUT NOCOPY  varchar2,
                              retcode OUT NOCOPY  varchar2,
                              schemaname in varchar2,
                              estimate_percent in number,
                              degree in number ,
                              internal_flag in varchar2,
                              request_id in number,
                              hmode in varchar2 default 'LASTRUN',
                              options in varchar2 default 'GATHER',
                              modpercent in number default 10,
                              invalidate    in varchar2 default 'Y'
                              )
is
  exist_insufficient exception;
  bad_input exception;
  pragma exception_init(exist_insufficient,-20000);
  pragma exception_init(bad_input,-20001);
  l_message varchar2(1000);
  Error_counter number := 0;
  --Errors Error_Out; -- commented for bug error handling
  -- num_request_id number(15);
  conc_request_id number(15);
  degree_parallel number(4);
begin
-- Set the package body variable.
stathist := hmode;

  -- check first if degree is null
  if degree is null then
     degree_parallel:=def_degree;
  else
     degree_parallel := degree;
  end if;

  l_message := 'In GATHER_SCHEMA_STATS , schema_name= '|| schemaname
    || ' percent= '|| to_char(estimate_percent) || ' degree = '
    || to_char(degree_parallel) || ' internal_flag= '|| internal_flag ;
  FND_FILE.put_line(FND_FILE.log,l_message);
  BEGIN

       FND_STATS.GATHER_SCHEMA_STATS(schemaname, estimate_percent,
          degree_parallel, internal_flag , request_id,stathist,
          options,modpercent,invalidate); -- removed errors parameter for error handling


       exception
                when exist_insufficient then
                   errbuf := sqlerrm ;
                   retcode := '2';
                   l_message := errbuf;
                   FND_FILE.put_line(FND_FILE.log,l_message);
                   raise;
                when bad_input then
                   errbuf := sqlerrm ;
                   retcode := '2';
                   l_message := errbuf;
                   FND_FILE.put_line(FND_FILE.log,l_message);
                   raise;
                when others then
                   errbuf := sqlerrm ;
                   retcode := '2';
                   l_message := errbuf;
                   FND_FILE.put_line(FND_FILE.log,l_message);
                   raise;
  END;
     FOR i in 0..MAX_ERRORS_PRINTED LOOP
         exit when g_Errors(i) is null;
         Error_counter:=i+1;
         FND_FILE.put_line(FND_FILE.log,'Error #'||Error_counter||
            ': '||g_Errors(i));
         -- added to send back status to concurrent program manager bug 2625022
         errbuf := sqlerrm ;
         retcode := '2';
     END LOOP;
end; /* GATHER_SCHEMA_STATS */

/************************************************************************/
/* Procedure: GATHER_SCHEMA_STATISTICS                                  */
/* Desciption: Gather schema statistics. This is the sqlplus version. It*/
/* does not have any o/p parameters                                     */
/************************************************************************/
procedure GATHER_SCHEMA_STATISTICS(schemaname in varchar2,
                              estimate_percent in number ,
                              degree in number ,
                              internal_flag in varchar2,
                              request_id in number,
                              hmode in varchar2 default 'LASTRUN',
                              options in varchar2 default 'GATHER',
                              modpercent in number default 10,
                              invalidate    in varchar2 default 'Y'
                              )
is
   Errors  Error_Out;
begin
call_from_sqlplus:=true;
   FND_STATS.GATHER_SCHEMA_STATS_SQLPLUS(schemaname, estimate_percent,
        degree,internal_flag, Errors, request_id,hmode,options
        ,modpercent,invalidate);
end; /* end of GATHER_SCHEMA_STATISTICS */


/************************************************************************/
/* Procedure: GATHER_SCHEMA_STATS_SQLPLUS                                       */
/* Desciption: Gather schema statistics. This is called by concurrent   */
/* manager version of GATHER_SCHEMA_STATS.                              */
/* Notes: internal_flag='INTERNAL' will call dbms_utility.analyze_schema*/
/* insead of dbms_stats.gather_schema_stats                             */
/* internal_flag='NOBACKUP'  will bypass dbms_stats.export_schema_stats */
/************************************************************************/
procedure GATHER_SCHEMA_STATS_SQLPLUS(schemaname in varchar2,
                              estimate_percent in number ,
                              degree in number ,
                              internal_flag in varchar2 ,
                              Errors        out  NOCOPY  Error_Out,
                              request_id in number default null,
                              hmode in varchar2 default 'LASTRUN',
                              options in varchar2 default 'GATHER',
                              modpercent in number default 10,
                              invalidate    in varchar2 default 'Y'
                             )
is
   TYPE name_tab is TABLE OF dba_tables.table_name%TYPE;
   TYPE partition_tab is TABLE OF sys.dba_tab_modifications.partition_name%TYPE;
   TYPE partition_type_tab is TABLE OF dba_tables.partitioned%TYPE;

   part_flag partition_type_tab;
   names name_tab;
   pnames partition_tab;

   num_tables number := 0;
   l_message varchar2(1000) ;
   granularity    varchar2(12);
   exist_insufficient exception;
   pragma exception_init(exist_insufficient,-20002);
   err_cnt BINARY_INTEGER := 0;
   degree_parallel number(4);
   str_request_id varchar(30);

-- Cursor to get list of tables and indexes with no stats
cursor empty_cur(schemaname varchar2) is
select type,owner,name from (
   select 'TABLE' type,owner,table_name name from dba_tables
   where owner=upper(schemaname)
     and (iot_type <> 'IOT_OVERFLOW' or iot_type is null)
     and temporary <> 'Y'
     and last_analyzed is null
   UNION ALL
   select 'INDEX' type,owner,index_name name from dba_indexes
   where ( table_owner=upper(schemaname) or owner=upper(schemaname) )
     and index_type <> 'LOB' and index_type<>'DOMAIN'
     and temporary <> 'Y'
     and last_analyzed is null
  )
order by type,owner,name
;

cursor nomon_tab(schemaname varchar2) is
select owner,table_name from dba_tables dt
  where  owner=upper(schemaname)
     and (iot_type <> 'IOT_OVERFLOW' or iot_type is null)
     and temporary <> 'Y'
     and monitoring='NO' and not exists
                                     (select null
                                        from dba_external_tables de
                                         where de.table_name=dt.table_name and
                                               de.owner=dt.owner);-- added this to avoid externale tables being selected
begin
  -- Set the package body variable.
  stathist := hmode;

    -- if request id (restart case) is provided, then this is the cur_request_id
    -- valid for both conc program and sql plus case.
     if request_id is not null then
        cur_request_id := request_id;
     end if;

    -- get degree of parallelism
    if degree is null then
       degree_parallel:=def_degree;
    else
       degree_parallel := degree;
    end if;
    -- Initialize the TABLE Errors
    Errors(0) := NULL;
    granularity := FND_STATS.ALL_GRANULARITY;  -- granularity will be ALL for all tables
    err_cnt := 0;


    -- If a specific schema is given
    if (upper(schemaname) <> 'SYS')  then
     if (upper(schemaname) <> 'ALL')  then
        -- Insert/update the fnd_stats_hist table
        if(upper(stathist)<> 'NONE') then
          begin
--            if(cur_request_id is null) then
--             cur_request_id := GET_REQUEST_ID(request_id);
--            end if;
            FND_STATS.UPDATE_HIST(schemaname=>schemaname,
                                 objectname=>schemaname,
                                 objecttype=>'SCHEMA',
                                 partname=>null,
                                 columntablename=>null,
                                 degree=>degree_parallel,
                                 upd_ins_flag=>'S',
                                 percent=>nvl(estimate_percent,10));
         end;
      end if;  --if(upper(stathist)<> 'NONE')

       -- backup the existing schema stats
        if ( (upper(internal_flag) =  'BACKUP')  ) then
            FND_STATS.BACKUP_SCHEMA_STATS( schemaname );
        end if;

        if(upper(options)='GATHER') then
             select  table_name ,partitioned
             BULK COLLECT INTO
             names, part_flag
             from dba_tables dt
             where owner = upper(schemaname)
             and (iot_type <> 'IOT_OVERFLOW' or iot_type is null)
             and temporary <> 'Y'                -- Bypass if temporary tables for bug#1108002
             and not exists
                  (select null from fnd_stats_hist fsh
                   where dt.owner=fsh.schema_name
                   and   fsh.REQUEST_ID  = cur_request_id
                   and   fsh.object_type='CASCADE'
                   and   fsh.history_mode=stathist
                   and   dt.table_name = fsh.object_name
                   and   LAST_GATHER_END_TIME is not null)
		   and not exists
                 (select null
                    from fnd_exclude_table_stats fets,
                         fnd_oracle_userid fou,
                         fnd_product_installations fpi
                    where fou.oracle_username=upper(schemaname)
		          and fou.oracle_id=fpi.oracle_id
		          and fpi.application_id = fets.application_id
                          and dt.table_name = fets.table_name) -- added by saleem for bug 7479909
              order by table_name;
            num_tables := SQL%ROWCOUNT;

             for i in 1..num_tables LOOP
               if ( part_flag(i) = 'YES' ) then
                  granularity := FND_STATS.ALL_GRANULARITY ;
               else
                  granularity := FND_STATS.STD_GRANULARITY;
               end if;

              begin
                FND_STATS.GATHER_TABLE_STATS(ownname => schemaname,
                                             tabname => names(i),
                                             percent => nvl(estimate_percent,10),
                                             degree  => degree_parallel,
                                             partname=>null,
                                             cascade => TRUE,
                                             granularity => granularity,
                                             hmode => stathist,
                                             invalidate=> invalidate
                                             );
              exception
                      when others then
                      Errors(err_cnt) := 'ERROR: While GATHER_TABLE_STATS:
                        object_name='||schemaname||'.'
                        ||names(i)||'***'||SQLERRM||'***' ;
                      Errors(err_cnt+1) := NULL;
                      err_cnt := err_cnt+1;
              end;
            END LOOP;      /* end of individual tables */

         elsif ( (upper(options)='GATHER AUTO') OR
                 (upper(options)='LIST AUTO') ) then
            -- if db_versn > 81 then call flush, else use whatever
            -- data is available in dtm
            if db_versn > 81 then
             if(fm_first_flag) then
              EXECUTE IMMEDIATE 'BEGIN DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO; END;' ;
              fm_first_flag := false;
             end if;
            end if;

            -- gather stats for stale tables/partitions. Potentially, there
            -- could be some redundent stats gathering, if for eg the table
            -- and one of its partitions, both are statle. gather_table_stats
            -- would get called twice, once for the table ( which would gather
            -- stats for the partitions too, and the partition by itself. The
            -- probability of this happening is small, and even if that happens
            -- on a rare occasion, the overhead should not be that high, so
            -- leaving it as it is for the moment. This can be revisited if
            -- tests and experience show that that is not the case.

            select iv.table_name,iv.partition_name       -- ,subpartition_name
            BULK COLLECT INTO
            names,pnames             -- ,spnames
            from (
                   select dtm.table_name,dtm.partition_name
                   from sys.dba_tab_modifications dtm
                   where dtm.table_owner = upper(schemaname)
                   and dtm.partition_name is null
                   and exists ( select null from dba_tables dt
                                where dt.owner=dtm.table_owner
                                and dt.table_name=dtm.table_name
                                and (nvl(dtm.inserts,0)+nvl(dtm.updates,0)+nvl(dtm.deletes,0))
                                         > (modpercent*nvl(dt.num_rows,0))/100
                              )
                   union all
                   select dtm.table_name,dtm.partition_name
                   from sys.dba_tab_modifications dtm
                   where dtm.table_owner = upper(schemaname)
                   and dtm.partition_name is not null
                   and exists ( select null from dba_tab_partitions dtp
                                where dtp.table_owner=dtm.table_owner
                                and dtp.table_name=dtm.table_name
                                and dtp.partition_name=dtm.partition_name
                                and (nvl(dtm.inserts,0)+nvl(dtm.updates,0)+nvl(dtm.deletes,0))
                                         > (modpercent*nvl(dtp.num_rows,0))/100
                              )
                ) iv
            order by table_name;

            num_tables := SQL%ROWCOUNT;
            for i in 1..num_tables LOOP
              begin
              if (upper(options)='GATHER AUTO') then
                 FND_STATS.GATHER_TABLE_STATS(ownname => schemaname,
                                           tabname => names(i),
                                           percent => nvl(estimate_percent,10),
                                           degree  => degree_parallel,
                                           partname=>pnames(i),
                                           cascade => TRUE,
                                           granularity => granularity,
                                           hmode => stathist,
                                           invalidate=> invalidate
                                           );
              else
                dlog('Statistics on '||schemaname||'.'||names(i)||'Partition '||nvl(pnames(i),'n/a')||' are Stale');
              end if;
                exception
                      when others then
                      Errors(err_cnt) := 'ERROR: While GATHER_TABLE_STATS:
                        object_name='||schemaname||'.'
                        ||names(i)||'***'||SQLERRM||'***' ;
                      Errors(err_cnt+1) := NULL;
                      err_cnt := err_cnt+1;
                end;
            END LOOP;      /* end of individual tables */

      -- GATHER AUTO includes GATHER EMPTY, so gather stats
      -- on any unalalyzed tables and/or indexes.
          FOR c_rec in empty_cur(upper(schemaname))
            LOOP
             if c_rec.type = 'TABLE' then
              if (upper(options)='GATHER AUTO') then
               FND_STATS.GATHER_TABLE_STATS(ownname => c_rec.owner,
                                         tabname => c_rec.name,
                                         percent => nvl(estimate_percent,10),
                                         degree  => degree_parallel,
                                         partname=>null,
                                         cascade => TRUE,
                                         granularity => granularity,
                                         hmode => stathist,
                                         invalidate=> invalidate
                                        );
              else
                dlog('Table '||c_rec.owner||'.'||c_rec.name ||' is missing statistics.');
              end if;
             elsif c_rec.type='INDEX' then
              if (upper(options)='GATHER AUTO') then
               fnd_stats.gather_index_stats(ownname=>c_rec.owner,
                                            indname=>c_rec.name,
                                            percent=>nvl(estimate_percent,10),
                                            invalidate=>invalidate);
              else
                dlog('Index '||c_rec.owner||'.'||c_rec.name ||' is missing statistics! ');
              end if;
             end if;
          end loop;

         -- Check if there are any tables in the schema which does not have
         -- monitoring enabled. If yes, gather stats for them using 10% and
         -- enable monitoring for such tables so that we have data for them
         -- in dba_tab_modifications for next time.

        FOR c_rec in nomon_tab(upper(schemaname))
         LOOP
              if (upper(options)='GATHER AUTO') then
               FND_STATS.GATHER_TABLE_STATS(ownname => c_rec.owner,
                                         tabname => c_rec.table_name,
                                         percent => nvl(estimate_percent,10),
                                         degree  => degree_parallel,
                                         partname=>null,
                                         cascade => TRUE,
                                         granularity => granularity,
                                         hmode => stathist,
                                         invalidate=> invalidate
                                        );
               EXECUTE IMMEDIATE 'alter table '||c_rec.owner||'.'||c_rec.table_name||' monitoring';
                dlog('Monitoring has now been enabled for Table '||c_rec.owner||'.'||c_rec.table_name||'. Stats were gathered.' );
              else
                dlog('Monitoring is not enabled for Table '||c_rec.owner||'.'||c_rec.table_name );
              end if;


         END LOOP;    -- nomon_tab

         elsif ( (upper(options)='GATHER EMPTY') OR
                  (upper(options)='LIST EMPTY')) then

          FOR c_rec in empty_cur(upper(schemaname))
            LOOP
             if c_rec.type = 'TABLE' then
              if (upper(options)='GATHER EMPTY') then
               FND_STATS.GATHER_TABLE_STATS(ownname => c_rec.owner,
                                         tabname => c_rec.name,
                                         percent => nvl(estimate_percent,10),
                                         degree  => degree_parallel,
                                         partname=>null,
                                         cascade => TRUE,
                                         granularity => granularity,
                                         hmode => stathist,
                                         invalidate=> invalidate
                                        );
              else
                dlog('Table '||c_rec.owner||'.'||c_rec.name ||' is missing statistics! ');
              end if;
             elsif c_rec.type='INDEX' then
              if (upper(options)='GATHER EMPTY') then
               fnd_stats.gather_index_stats(ownname=>c_rec.owner,
                                            indname=>c_rec.name,
                                            percent=>nvl(estimate_percent,10),
                                            invalidate=>invalidate);
              else
                dlog('Statistics for Index '||c_rec.owner||'.'||c_rec.name ||' are Empty');
              end if;
             end if;
          end loop;
         end if;        /* end of if upper(options)=  */

         -- End timestamp
      if(upper(stathist) <> 'NONE') then
         begin
            FND_STATS.UPDATE_HIST(schemaname=>schemaname,
                                 objectname=>schemaname,
                                 objecttype=>'SCHEMA',
                                 partname=>null,
                                 columntablename=>null,
                                 degree=>degree_parallel,
                                 upd_ins_flag=>'E'
                                );
          end;
      end if;

    else   /* This is for ALL schema */
        for c_schema in schema_cur loop
        --dbms_output.put_line('start of schema = '|| c_schema.sname);
        -- make a recursive call to gather_schema_stats
          GATHER_SCHEMA_STATS_SQLPLUS(schemaname=>c_schema.sname ,
                              estimate_percent=>estimate_percent ,
                              degree=>degree  ,
                              internal_flag=>internal_flag ,
                              Errors=> Errors   ,
                              request_id=>request_id ,
                              hmode=>stathist ,
                              options=>options ,
                              modpercent=>modpercent ,
                              invalidate=> invalidate
                             );

         end loop;  /* schema_cur */
    end if;
   else   -- schema is SYS, print message in log.
     dlog('Gathering statistics on the SYS schema using FND_STATS is not allowed.');
     dlog('Please use DBMS_STATS package to gather stats on SYS objects.');
   end if;   -- end of schema<> SYS
end; /* GATHER_SCHEMA_STATS_SQLPLUS */


/************************************************************************/
/* Procedure: GATHER_SCHEMA_STATS                                       */
/* Desciption: Gather schema statistics. This is called by concurrent   */
/* manager version of GATHER_SCHEMA_STATS.                              */
/* Notes: internal_flag='INTERNAL' will call dbms_utility.analyze_schema*/
/* insead of dbms_stats.gather_schema_stats                             */
/* internal_flag='NOBACKUP'  will bypass dbms_stats.export_schema_stats */
/************************************************************************/
procedure GATHER_SCHEMA_STATS(schemaname in varchar2,
                              estimate_percent in number ,
                              degree in number ,
                              internal_flag in varchar2 ,
                              --Errors        OUT NOCOPY  Error_Out,-- commented for handling errors
                              request_id in number default null,
                              hmode in varchar2 default 'LASTRUN',
                              options in varchar2 default 'GATHER',
                              modpercent in number default 10,
                              invalidate    in varchar2 default 'Y'
                             )
is
   TYPE name_tab is TABLE OF dba_tables.table_name%TYPE;
   TYPE partition_tab is TABLE OF sys.dba_tab_modifications.partition_name%TYPE;
   TYPE partition_type_tab is TABLE OF dba_tables.partitioned%TYPE;

   part_flag partition_type_tab;
   names name_tab;
   pnames partition_tab;

   num_tables number := 0;
   l_message varchar2(1000) ;
   granularity    varchar2(12);
   exist_insufficient exception;
   pragma exception_init(exist_insufficient,-20002);
   err_cnt BINARY_INTEGER := 0;
   degree_parallel number(4);
   str_request_id varchar(30);

-- Cursor to get list of tables and indexes with no stats
cursor empty_cur(schemaname varchar2) is
select type,owner,name from (
   select 'TABLE' type,owner,table_name name from dba_tables dt
   where owner=upper(schemaname)
     and (iot_type <> 'IOT_OVERFLOW' or iot_type is null)
     and temporary <> 'Y'
     and last_analyzed is null
     -- leave alone if excluded table
     and not exists
         (select null
            from fnd_exclude_table_stats fets,
                 fnd_oracle_userid fou,
                 fnd_product_installations fpi
            where fou.oracle_username=upper(schemaname)
		  and fou.oracle_id=fpi.oracle_id
		  and fpi.application_id = fets.application_id
                  and dt.table_name = fets.table_name)
   UNION
   select DISTINCT 'TABLE' type,table_owner owner,table_name name from dba_indexes  di
   where ( di.table_owner=upper(schemaname) or di.owner=upper(schemaname) )
     and di.index_type <> 'LOB'
     and di.temporary <> 'Y'
     and di.last_analyzed is null
     and not exists
	        (select null
		  from fnd_exclude_table_stats fets,
		       fnd_oracle_userid fou,
		       fnd_product_installations fpi
		  where fou.oracle_username=upper(schemaname)
		  and   fou.oracle_id=fpi.oracle_id
		  and   fpi.application_id=fets.application_id
		  and   di.table_name=fets.table_name
		  )
)
order by type,owner,name
;

cursor nomon_tab(schemaname varchar2) is
select owner,table_name from dba_tables dt
  where  owner=upper(schemaname)
     and (iot_type <> 'IOT_OVERFLOW' or iot_type is null)
     and temporary <> 'Y'
     and monitoring='NO' and not exists
                                     (select null
                                        from dba_external_tables de
                                         where de.table_name=dt.table_name and
                                               de.owner=dt.owner);-- added this to avoid externale tables being selected
begin
  -- Set the package body variable.
  stathist := hmode;

    -- if request id (restart case) is provided, then this is the cur_request_id
    -- valid for both conc program and sql plus case.
     if request_id is not null then
        cur_request_id := request_id;
     end if;

    -- get degree of parallelism
    if degree is null then
       degree_parallel:=def_degree;
    else
       degree_parallel := degree;
    end if;
    -- Initialize the TABLE Errors
    --Errors(0) := NULL; -- commented the initialization so that the errors will not be cleared
    granularity := FND_STATS.ALL_GRANULARITY;  -- granularity will be ALL for all tables
    err_cnt := 0;


    -- If a specific schema is given
    if (upper(schemaname) <> 'SYS')  then
     if (upper(schemaname) <> 'ALL')  then


        -- Insert/update the fnd_stats_hist table
        if(upper(stathist)<> 'NONE') then
          begin
--            if(cur_request_id is null) then
--             cur_request_id := GET_REQUEST_ID(request_id);
--            end if;
            FND_STATS.UPDATE_HIST(schemaname=>schemaname,
                                 objectname=>schemaname,
                                 objecttype=>'SCHEMA',
                                 partname=>null,
                                 columntablename=>null,
                                 degree=>degree_parallel,
                                 upd_ins_flag=>'S',
                                 percent=>nvl(estimate_percent,10));
         end;
      end if;  --if(upper(stathist)<> 'NONE')

       -- backup the existing schema stats
        if ( (upper(internal_flag) =  'BACKUP')  ) then
            FND_STATS.BACKUP_SCHEMA_STATS( schemaname );
        end if;

        if(upper(options)='GATHER') then
             select  table_name ,partitioned
             BULK COLLECT INTO
             names, part_flag
             from dba_tables dt
             where owner = upper(schemaname)
             and (iot_type <> 'IOT_OVERFLOW' or iot_type is null)
             and temporary <> 'Y'                -- Bypass if temporary tables for bug#1108002
             and not exists
                  (select null from fnd_stats_hist fsh
                   where dt.owner=fsh.schema_name
                   and fsh.REQUEST_ID  = cur_request_id
                   and fsh.object_type='CASCADE'
                   and fsh.history_mode=stathist
                   and dt.table_name = fsh.object_name
                   and LAST_GATHER_END_TIME is not null)
             -- leave alone if excluded table
             and not exists
                 (select null
                    from fnd_exclude_table_stats fets,
                         fnd_oracle_userid fou,
                         fnd_product_installations fpi
                    where fou.oracle_username=upper(schemaname)
		          and fou.oracle_id=fpi.oracle_id
		          and fpi.application_id = fets.application_id
                          and dt.table_name = fets.table_name)
             order by table_name;


            num_tables := SQL%ROWCOUNT;

             for i in 1..num_tables LOOP
               if ( part_flag(i) = 'YES' ) then
                  granularity := FND_STATS.ALL_GRANULARITY ;
               else
                  granularity := FND_STATS.STD_GRANULARITY;
               end if;

              begin
                FND_STATS.GATHER_TABLE_STATS(ownname => schemaname,
                                             tabname => names(i),
                                             percent => nvl(estimate_percent,10),
                                             degree  => degree_parallel,
                                             partname=>null,
                                             cascade => TRUE,
                                             granularity => granularity,
                                             hmode => stathist,
                                             invalidate=> invalidate
                                             );
              exception
                      when others then
                      g_Errors(err_cnt) := 'ERROR: While GATHER_TABLE_STATS:
                        object_name='||schemaname||'.'
                        ||names(i)||'***'||SQLERRM||'***' ;
                      g_Errors(err_cnt+1) := NULL;
                      err_cnt := err_cnt+1;
              end;
            END LOOP;      /* end of individual tables */

         elsif ( (upper(options)='GATHER AUTO') OR
                 (upper(options)='LIST AUTO') ) then
            -- if db_versn > 81 then call flush, else use whatever
            -- data is available in dtm
            if db_versn > 81 then
             if(fm_first_flag) then
              EXECUTE IMMEDIATE 'BEGIN DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO; END;' ;
              fm_first_flag := false;
             end if;
            end if;

            -- gather stats for stale tables/partitions. Potentially, there
            -- could be some redundent stats gathering, if for eg the table
            -- and one of its partitions, both are statle. gather_table_stats
            -- would get called twice, once for the table ( which would gather
            -- stats for the partitions too, and the partition by itself. The
            -- probability of this happening is small, and even if that happens
            -- on a rare occasion, the overhead should not be that high, so
            -- leaving it as it is for the moment. This can be revisited if
            -- tests and experience show that that is not the case.

            select iv.table_name,iv.partition_name       -- ,subpartition_name
            BULK COLLECT INTO
            names,pnames             -- ,spnames
            from (
                   select dtm.table_name,dtm.partition_name
                   from sys.dba_tab_modifications dtm
                   where dtm.table_owner = upper(schemaname)
                   and dtm.partition_name is null
                   and exists ( select null from dba_tables dt
                                where dt.owner=dtm.table_owner
                                and dt.table_name=dtm.table_name
				and dt.partitioned='NO'
                                and (nvl(dtm.inserts,0)+nvl(dtm.updates,0)+nvl(dtm.deletes,0))
                                         > (modpercent*nvl(dt.num_rows,0))/100
                              )
                   union all
                   select dtm.table_name,dtm.partition_name
                   from sys.dba_tab_modifications dtm
                   where dtm.table_owner = upper(schemaname)
                   and dtm.partition_name is not null
                   and exists ( select null from dba_tab_partitions dtp
                                where dtp.table_owner=dtm.table_owner
                                and dtp.table_name=dtm.table_name
                                and dtp.partition_name=dtm.partition_name
                                and (nvl(dtm.inserts,0)+nvl(dtm.updates,0)+nvl(dtm.deletes,0))
                                         > (modpercent*nvl(dtp.num_rows,0))/100
                              )
                ) iv
            order by table_name;

            num_tables := SQL%ROWCOUNT;
            for i in 1..num_tables LOOP
              begin
              if (upper(options)='GATHER AUTO') then
                 FND_STATS.GATHER_TABLE_STATS(ownname => schemaname,
                                           tabname => names(i),
                                           percent => nvl(estimate_percent,10),
                                           degree  => degree_parallel,
                                           partname=>pnames(i),
                                           cascade => TRUE,
                                           granularity => granularity,
                                           hmode => stathist,
                                           invalidate=> invalidate
                                           );
              else
                dlog('Statistics on '||schemaname||'.'||names(i)||'Partition '||nvl(pnames(i),'n/a')||' are Stale');
              end if;
                exception
                      when others then
                      g_Errors(err_cnt) := 'ERROR: While GATHER_TABLE_STATS:
                        object_name='||schemaname||'.'
                        ||names(i)||'***'||SQLERRM||'***' ;
                      g_Errors(err_cnt+1) := NULL;
                      err_cnt := err_cnt+1;
                end;
            END LOOP;      /* end of individual tables */

      -- GATHER AUTO includes GATHER EMPTY, so gather stats
      -- on any unalalyzed tables and/or indexes.
          FOR c_rec in empty_cur(upper(schemaname))
            LOOP
             if c_rec.type = 'TABLE' then
              if (upper(options)='GATHER AUTO') then
               FND_STATS.GATHER_TABLE_STATS(ownname => c_rec.owner,
                                         tabname => c_rec.name,
                                         percent => nvl(estimate_percent,10),
                                         degree  => degree_parallel,
                                         partname=>null,
                                         cascade => TRUE,
                                         granularity => granularity,
                                         hmode => stathist,
                                         invalidate=> invalidate
                                        );
              else
                dlog('Table '||c_rec.owner||'.'||c_rec.name ||' is missing statistics.');
              end if;
             end if;
          end loop;

         -- Check if there are any tables in the schema which does not have
         -- monitoring enabled. If yes, gather stats for them using 10% and
         -- enable monitoring for such tables so that we have data for them
         -- in dba_tab_modifications for next time.

        FOR c_rec in nomon_tab(upper(schemaname))
         LOOP
              if (upper(options)='GATHER AUTO') then
               FND_STATS.GATHER_TABLE_STATS(ownname => c_rec.owner,
                                         tabname => c_rec.table_name,
                                         percent => nvl(estimate_percent,10),
                                         degree  => degree_parallel,
                                         partname=>null,
                                         cascade => TRUE,
                                         granularity => granularity,
                                         hmode => stathist,
                                         invalidate=> invalidate
                                        );
               EXECUTE IMMEDIATE 'alter table '||c_rec.owner||'.'||c_rec.table_name||' monitoring';
                dlog('Monitoring has now been enabled for Table '||c_rec.owner||'.'||c_rec.table_name||'. Stats were gathered.' );
              else
                dlog('Monitoring is not enabled for Table '||c_rec.owner||'.'||c_rec.table_name );
              end if;


         END LOOP;    -- nomon_tab

         elsif ( (upper(options)='GATHER EMPTY') OR
                  (upper(options)='LIST EMPTY')) then

          FOR c_rec in empty_cur(upper(schemaname))
            LOOP
             if c_rec.type = 'TABLE' then
              if (upper(options)='GATHER EMPTY') then
               FND_STATS.GATHER_TABLE_STATS(ownname => c_rec.owner,
                                         tabname => c_rec.name,
                                         percent => nvl(estimate_percent,10),
                                         degree  => degree_parallel,
                                         partname=>null,
                                         cascade => TRUE,
                                         granularity => granularity,
                                         hmode => stathist,
                                         invalidate=> invalidate
                                        );
              else
                dlog('Table '||c_rec.owner||'.'||c_rec.name ||' is missing statistics! ');
              end if;
             end if;
          end loop;
         end if;        /* end of if upper(options)=  */

         -- End timestamp
      if(upper(stathist) <> 'NONE') then
         begin
            FND_STATS.UPDATE_HIST(schemaname=>schemaname,
                                 objectname=>schemaname,
                                 objecttype=>'SCHEMA',
                                 partname=>null,
                                 columntablename=>null,
                                 degree=>degree_parallel,
                                 upd_ins_flag=>'E'
                                );
          end;
      end if;

    else   /* This is for ALL schema */
        for c_schema in schema_cur loop
        --dbms_output.put_line('start of schema = '|| c_schema.sname);
        -- make a recursive call to 7
          GATHER_SCHEMA_STATS(schemaname=>c_schema.sname ,
                              estimate_percent=>estimate_percent ,
                              degree=>degree  ,
                              internal_flag=>internal_flag ,
                              --Errors=> Errors   ,-- commented for error handling
                              request_id=>request_id ,
                              hmode=>stathist ,
                              options=>options ,
                              modpercent=>modpercent ,
                              invalidate=> invalidate
                             );

         end loop;  /* schema_cur */
    end if;
   else   -- schema is SYS, print message in log.
     dlog('Gathering statistics on the SYS schema using FND_STATS is not allowed.');
     dlog('Please use DBMS_STATS package to gather stats on SYS objects.');
   end if;   -- end of schema<> SYS
end; /* GATHER_SCHEMA_STATS */

/************************************************************************/
/* Procedure: GATHER_INDEX_STATS                                        */
/* Desciption: Gathers stats for a particular index.                    */
/************************************************************************/
procedure GATHER_INDEX_STATS(ownname in varchar2,
                             indname  in varchar2,
                             percent  in number default null,
                             degree in number default null,
                             partname in varchar2 default null,
                             backup_flag  in varchar2 ,
                             hmode in varchar2  default 'LASTRUN',
                             invalidate    in varchar2 default 'Y'
                            )
is
     num_blks number;
     adj_percent number ; -- adjusted percent based on table blocks.
     exist_insufficient exception;
     pragma exception_init(exist_insufficient,-20002);
     degree_parallel number(4) ;
begin
   -- Set the package body variable.
   stathist := hmode;

   num_blks := fnd_stats.get_blocks(ownname,indname,'INDEX');

   -- In 8i, you cannot provide a degree for an index, in 9iR2 we can.
    if num_blks <= SMALL_IND_FOR_PAR_THOLD then
      degree_parallel:=1;
    else
      if degree is null then
      degree_parallel:=def_degree;
    else
       degree_parallel :=degree;
       end if;
    end if;

    -- For better stats, indexes smaller than small_ind_for_est_thold
    -- should be gathered at 100%.
    if num_blks <= SMALL_IND_FOR_EST_THOLD then
     if ((db_versn>80) AND ( db_versn < 90)) then   -- w/a for bug 1998176
        adj_percent:=99.99;
      else
        adj_percent:=100;
      end if;
    else
      adj_percent:=percent;
    end if;

    -- Insert/update the fnd_stat_hist table
  if(upper(stathist) <> 'NONE') then
    begin
       FND_STATS.UPDATE_HIST(schemaname=>upper(ownname),
           objectname=>upper(indname),
           objecttype=>'INDEX',
           partname=>upper(partname),
           columntablename=>null,
           degree=>degree_parallel,
           upd_ins_flag=>'S',
           percent=>nvl(adj_percent,10));
    end;
   end if;
     -- backup the existing index stats
     if ( upper(nvl(backup_flag,'NOBACKUP')) = 'BACKUP' ) then
       -- First create the FND_STATTAB if it doesn't exist.
          BEGIN
             FND_STATS.CREATE_STAT_TABLE();
             exception
              when exist_insufficient then null;
          END;
         DBMS_STATS.EXPORT_INDEX_STATS( ownname, indname, null,
                                     fnd_stattab, null, fnd_statown );
     end if;

     FND_STATS.GATHER_INDEX_STATS_PVT(ownname => ownname,
                                      indname => indname,
                                      partname => partname,
                                      estimate_percent => nvl(adj_percent,10),
                                      degree=>degree_parallel,
                                      invalidate => invalidate
                                     ) ;
     -- End timestamp
   if(upper(stathist) <> 'NONE') then
     begin
        -- update fnd_stats_hist for completed stats
        FND_STATS.UPDATE_HIST(schemaname=>upper(ownname),
           objectname=>upper(indname),
           objecttype=>'INDEX',
           partname=>upper(partname),
           columntablename=>null,
           degree=>degree_parallel,
           upd_ins_flag=>'E'
          );
     end;
   end if;
end ;  /* GATHER_INDEX_STATS */

/************************************************************************/
/* Procedure: GATHER_TABLE_STATS                                        */
/* Desciption: Gathers stats for a particular table. Concurrent program */
/* version.                                                             */
/************************************************************************/
procedure GATHER_TABLE_STATS(errbuf OUT NOCOPY  varchar2,
                             retcode OUT NOCOPY  varchar2,
                             ownname in varchar2,
                             tabname  in varchar2,
                             percent  in number,
                             degree in number,
                             partname in varchar2,
                             backup_flag in varchar2,
                             granularity in varchar2,
                             hmode in varchar2  default 'LASTRUN',
                             invalidate    in varchar2 default 'Y'
                             )
is
  exist_insufficient exception;
  pragma exception_init(exist_insufficient,-20000);
  l_message varchar2(1000);
begin
 FND_STATS.GATHER_TABLE_STATS(ownname, tabname, percent, degree, partname,
    backup_flag, true, granularity,hmode,invalidate);
  exception
           when exist_insufficient then
              errbuf := sqlerrm ;
              retcode := '2';
              l_message := errbuf;
              FND_FILE.put_line(FND_FILE.log,l_message);
              raise;
           when others then
              errbuf := sqlerrm ;
              retcode := '2';
              l_message := errbuf;
              FND_FILE.put_line(FND_FILE.log,l_message);
              raise;
end; /* GATHER_TABLE_STATS */

/************************************************************************/
/* Procedure: GATHER_TABLE_STATS                                        */
/* Desciption: Gathers stats for a particular table. Called by          */
/* Concurrent program version.                                          */
/************************************************************************/
procedure GATHER_TABLE_STATS(ownname in varchar2,
                             tabname  in varchar2,
                             percent  in number,
                             degree in number,
                             partname in varchar2,
                             backup_flag  in varchar2,
                             cascade  in boolean,
                             granularity in varchar2,
                             hmode in varchar2  default 'LASTRUN',
                             invalidate    in varchar2 default 'Y'
                             )
is
   cascade_true boolean := TRUE;
   approx_num_rows number ;
   num_blks number;
   adj_percent number ; -- adjusted percent based on table blocks.
   num_ind_rows number;
   obj_type varchar2(7);
   method       varchar2(2000) ;
   exist_insufficient exception;
   pragma exception_init(exist_insufficient,-20002);

   -- New cursor to support MVs
   cursor col_cursor (ownname varchar2, tabname varchar2, partname varchar2) is
    select  a.column_name,
           nvl(a.hsize,254) hsize
    from   FND_HISTOGRAM_COLS a
    where  a.table_name = upper(tabname)
    and    (a.partition = upper(partname) or partname is null )
    order by a.column_name;


   cursor ind_cursor(ownname varchar2,tabname varchar2) is
     select a.index_name indname,
            a.owner indowner,
            a.uniqueness uniq
     from dba_indexes a
     where table_name = upper(tabname)
     and   table_owner= upper(ownname)
     order by index_name;

     degree_parallel number(4);
begin
    -- Set the package body variable.
     stathist := hmode;
      num_blks:=fnd_stats.get_blocks(ownname,tabname,'TABLE');

    -- For better performance, tables smaller than small_tab_for_par_thold should be gathered in serial.
    if num_blks <= SMALL_TAB_FOR_PAR_THOLD then
      degree_parallel:=1;
    elsif degree is null then  -- degree will not be null when called from gather_schema_stats
         degree_parallel:=def_degree;
    else
	degree_parallel := degree;
    end if;

    -- For better stats, tables smaller than small_tab_for_est_thold
    -- should be gathered at 100%.
    if num_blks <= SMALL_TAB_FOR_EST_THOLD then
     if ((db_versn>80) AND (db_versn < 90)) then   -- w/a for bug 1998176
        adj_percent:=99.99;
      else
        adj_percent:=100;
      end if;
    else
      adj_percent:=percent;
    end if;

    -- Insert/update the fnd_stat_hist table
    -- change to call update_hist for autonomous_transaction
    if (cascade) then
        obj_type:='CASCADE';
    else
        obj_type := 'TABLE';
    end if;
    if(upper(stathist) <> 'NONE') then
      begin
--        if(cur_request_id is null) then
--         cur_request_id := GET_REQUEST_ID(null); -- for gather table stats, we will not have a request_id
--        end if;
        FND_STATS.UPDATE_HIST(schemaname=>ownname,
                              objectname=>tabname,
                              objecttype=>obj_type,
                              partname=>partname,
                              columntablename=>null,
                              degree=>degree_parallel,
                              upd_ins_flag=>'S',
                              percent=>nvl(adj_percent,10));
        exception
          when others then raise;
       end;
     end if;
     -- backup the existing table stats
    if ( upper(nvl(backup_flag,'NOBACKUP')) = 'BACKUP' ) then
         begin
          -- First create the FND_STATTAB if it doesn't exist.
          BEGIN
              FND_STATS.CREATE_STAT_TABLE();
              exception
                  when exist_insufficient then null;
          END;
         DBMS_STATS.EXPORT_TABLE_STATS(ownname, tabname, partname,
                                       fnd_stattab,null,cascade,fnd_statown );
         exception
            when others then raise;
         end;
     end if;
     if (db_versn >= 92)  then
         --Build up the method_opt if histogram cols are present
         method := ' FOR COLUMNS ' ;
         FOR c_rec in col_cursor(ownname,tabname,partname)
         LOOP
             method := method ||' '|| c_rec.column_name ||'  SIZE '
                || c_rec.hsize ;
         END LOOP;
         -- If no histogram cols then  nullify method ;
         if method = ' FOR COLUMNS ' then
                method := 'FOR ALL COLUMNS SIZE 1' ;
         end if;

           if (method = 'FOR ALL COLUMNS SIZE 1') then
             BEGIN
             --dbms_output.put_line('SINGLE:'||method||'granularity='||granularity);
              FND_STATS.GATHER_TABLE_STATS_PVT(ownname => ownname,
                                           tabname => tabname,
                                           partname => partname,
                                           method_opt => method,
                                           estimate_percent => nvl(adj_percent,10),
                                           degree  => degree_parallel,
                                           cascade => cascade,
                                           granularity => granularity,
                                           invalidate=> invalidate
                                           );
              exception
                    when others then
		      -- dbms_output.put_line('about to raise'||sqlcode||' --- '||sqlerrm);
                      -- Error code for external table error is ora-20000 which is the same as the code
		      -- for exist_insufficient error. Because of that, we have to resort to the following
		      -- if check on the error message.
		     if(substr(sqlerrm,instr(sqlerrm,',')+2)= 'sampling on external table is not supported') then
                        null;  -- Ignore this error because apps does not use External tables.
		      else
                         raise;
		    end if;
              END;
          else  -- call it with histogram cols.
             BEGIN
             -- dbms_output.put_line('FOR ALL COLUMNS SIZE 1 '||method);
             FND_STATS.GATHER_TABLE_STATS_PVT(ownname => ownname,
                                           tabname => tabname,
                                           partname => partname,
                                           method_opt => 'FOR ALL COLUMNS SIZE 1 '||method,
                                           estimate_percent => nvl(adj_percent,10),
                                           degree  => degree_parallel,
                                           cascade => cascade,
                                           granularity => granularity,
                                           invalidate=> invalidate
                                           );
             exception
                   when others then
                   raise;
             END;
          end if;

      else -- version is pre 9.2, use the old method of calling twice.

         --Build up the method_opt if histogram cols are present
         method := ' FOR COLUMNS ' ;
         FOR c_rec in col_cursor(ownname,tabname,partname)
         LOOP
             if method <> ' FOR COLUMNS ' then
                method := method || ',' ;
             end if;
             method := method ||' '|| c_rec.column_name ||'  SIZE '
                || c_rec.hsize ;
         END LOOP;
         -- If no histogram cols then  nullify method ;
         if method = ' FOR COLUMNS ' then
                method := 'FOR ALL COLUMNS SIZE 1' ;
         end if;
         -- Due to the limitations of in DBMS_STATS in 8i we need to call
         -- FND_STATS.GATHER_TABLE_STATS twice, once for histogram
         -- and once for just the table stats.
           if (method = 'FOR ALL COLUMNS SIZE 1') then
             BEGIN
             --dbms_output.put_line('SINGLE:'||method||'granularity='||granularity);
              FND_STATS.GATHER_TABLE_STATS_PVT(ownname => ownname,
                                           tabname => tabname,
                                           partname => partname,
                                           method_opt => method,
                                           estimate_percent => nvl(adj_percent,10),
                                           degree  => degree_parallel,
                                           cascade => cascade,
                                           granularity => granularity,
                                           invalidate=> invalidate
                                           );
              exception
                    when others then
                    raise;
              END;
          else  -- call it twice
             BEGIN
             --dbms_output.put_line('DOUBLE 1:'||method||'granularity='||granularity);
             FND_STATS.GATHER_TABLE_STATS_PVT(ownname => ownname,
                                           tabname => tabname,
                                           partname => partname,
                                           method_opt => 'FOR ALL COLUMNS SIZE 1',
                                           estimate_percent => nvl(adj_percent,10),
                                           degree  => degree_parallel,
                                           cascade => cascade,
                                           granularity => granularity,
                                           invalidate=> invalidate
                                           );
             exception
                   when others then
                   raise;
             END;
             BEGIN
             --dbms_output.put_line('DOUBLE 2:'||method||'granularity='||granularity);
             FND_STATS.GATHER_TABLE_STATS_PVT(ownname => ownname,
                                           tabname => tabname,
                                           partname => partname,
                                           method_opt => method,
                                           estimate_percent => nvl(adj_percent,10),
                                           degree  => degree_parallel,
                                           cascade => FALSE,
                                           granularity => granularity,
                                           invalidate=> invalidate
                                           );
             exception
                    when others then
                    raise;
             END;
          end if;

     end if;     -- db_versn  is 8i
    -- End timestamp
    -- change to call update_hist for autonomous_transaction
     if(upper(stathist) <> 'NONE') then
       begin
           FND_STATS.UPDATE_HIST(schemaname=>ownname,
                                 objectname=>tabname,
                                 objecttype=>obj_type,
                                 partname=>partname,
                                 columntablename=>null,
                                 degree=>degree_parallel,
                                 upd_ins_flag=>'E'
                                );
           exception
             when others then raise;
        end;
       end if;

end ;  /* GATHER_TABLE_STATS */

/************************************************************************/
/* Procedure: GATHER_COLUMN_STATS                                       */
/* Desciption: Gathers stats for all columns in FND_HISTOGRAM_COLS table*/
/************************************************************************/
procedure GATHER_COLUMN_STATS(appl_id in number default null,
                              percent in number default null,
                              degree in number default null,
                              backup_flag in varchar2 ,
                              --Errors OUT NOCOPY  Error_Out, -- commented for errorhandling
                              hmode in varchar2  default 'LASTRUN',
                               invalidate    in varchar2 default 'Y'
                             )
is

  -- New cursor to support MVs
  cursor tab_cursor (appl_id number) is
    select distinct a.application_id, a.table_name , a.partition
    from   FND_HISTOGRAM_COLS a
    where (a.application_id = appl_id or appl_id is null)
    order by a.application_id, a.table_name;

 -- New cursor to support MVs
 cursor col_cursor (appl_id number, tabname varchar2, partname varchar2) is
 select    a.column_name,
	   nvl(a.hsize,254) hsize,
           nvl(a.owner, upper(b.oracle_username)) ownname
    from   FND_HISTOGRAM_COLS a,
           FND_ORACLE_USERID b,
           FND_PRODUCT_INSTALLATIONS c
    where  a.application_id = appl_id
    and    a.application_id = c.application_id (+)
    and    c.oracle_id  = b.oracle_id (+)
    and    a.table_name = upper(tabname)
    and    ( a.partition = upper(partname) or partname is null )
    order by a.column_name;

    exist_insufficient exception;
    pragma exception_init(exist_insufficient,-20002);
    owner varchar2(30);
    i BINARY_INTEGER := 0;
    method varchar2(2000);
    degree_parallel number(4);
    /* defind variables for the bulk fetch */
    TYPE num_list IS TABLE OF number(15) INDEX BY BINARY_INTEGER;
    TYPE char_list IS TABLE OF varchar2(64) INDEX BY BINARY_INTEGER;
    list_column_name char_list;
    list_hsize num_list;
    list_ownname char_list;

begin
   -- Set the package body variable.
   stathist := hmode;

   if degree is null then
       degree_parallel:=def_degree;
   else
      degree_parallel := degree;
   end if;
   -- Initialize the TABLE Errors
   --Errors(0) := NULL; -- commented for stopping the initialization
   for t_rec in tab_cursor(appl_id) loop
       method := ' FOR COLUMNS ';   /* initialize method_opt variable */
       /* Bulk fetch data from col_cursor and loop through it */
       OPEN col_cursor (t_rec.application_id,t_rec.table_name, t_rec.partition);
       FETCH col_cursor BULK COLLECT into list_column_name, list_hsize, list_ownname;
       CLOSE col_cursor;
       for i in 1..list_column_name.last LOOP
        if(upper(stathist) <> 'NONE') then
         begin
           FND_STATS.UPDATE_HIST(schemaname=>list_ownname(i),
                                 objectname=>list_column_name(i),
                                 objecttype=>'COLUMN',
                                 partname=>t_rec.partition,
                                 columntablename=>t_rec.table_name,
                                 degree=>degree_parallel,
                                 upd_ins_flag=>'S'
                                );
          end;
        end if;
        -- First export the col stats depending on backup-flag
        if ( upper(nvl(backup_flag,'NOBACKUP')) =  'BACKUP') then
          begin
           -- First create the FND_STATTAB if it doesn't exist.
           BEGIN
              FND_STATS.CREATE_STAT_TABLE();
              exception
                   when exist_insufficient then null;
           END;
           DBMS_STATS.EXPORT_COLUMN_STATS(list_ownname(i),
                                           t_rec.table_name,
                                           list_column_name(i),
                                           t_rec.partition,
                                           fnd_stattab,
                                           null,
                                           fnd_statown);
          end;
        end if;
        -- Build up the method_opt variable
        if (method <> ' FOR COLUMNS ') then
            method := method || ',';
        end if;
        method := method||  list_column_name(i) ||' SIZE ' || list_hsize(i);
        owner := list_ownname(i);
       end loop;   /* end of c_rec */
       begin
       FND_STATS.GATHER_TABLE_STATS_PVT(ownname => owner,
                                     tabname => t_rec.table_name,
                                     partname => t_rec.partition,
                                     estimate_percent => nvl(percent,10),
                                     method_opt => method,
                                     degree   => degree_parallel,
                                     cascade => FALSE,
                                     invalidate=> invalidate,
                                     stattab => fnd_stattab,
                                     statown => fnd_statown);
        -- now that histograms are collected update fnd_stats_hist
       if(upper(stathist) <> 'NONE') then
        for i in 1..list_column_name.last LOOP
           FND_STATS.UPDATE_HIST(schemaname=>list_ownname(i),
                                 objectname=>list_column_name(i),
                                 objecttype=>'COLUMN',
                                 partname=>t_rec.partition,
                                 columntablename=>t_rec.table_name,
                                 degree=>degree_parallel,
                                 upd_ins_flag=>'E'
                                );
        end loop;
       end if;
       exception
                  when others then
                  g_Errors(i) := 'ERROR: In GATHER_COLUMN_STATS: '||SQLERRM ;
                  g_Errors(i+1) := NULL;
                  i := i+1;
       end;  /* end of FND_STATS.GATHER_TABLE_STATS_PVT call */
    end loop;  /* end of t_rec */
end;  /* end of procedure GATHER_COLUMN_STATS */

/************************************************************************/
/* Procedure: GATHER_ALL_COLUMN_STATS                                   */
/* Desciption: Gathers cols stats for a given schema                    */
/* or if ownname = 'ALL' then for ALL apps schema                       */
/************************************************************************/
procedure GATHER_ALL_COLUMN_STATS(ownname in varchar2,
                              percent in number default null,
                              degree in number default null,
                              hmode in varchar2  default 'LASTRUN',
                              invalidate    in varchar2 default 'Y'
                              )
is

-- New cursor for MVs
  cursor tab_cursor (ownname varchar2)   is
  select  distinct a.table_name, a.application_id
    from   FND_HISTOGRAM_COLS a,
           FND_ORACLE_USERID b,
           FND_PRODUCT_INSTALLATIONS c
    where  (b.oracle_username= upper(ownname) or a.owner =upper(ownname))
    and    a.application_id = c.application_id (+)
    and    c.oracle_id  = b.oracle_id (+)
    order by 2 , 1;


  cursor col_cursor (appl_id number, tabname varchar2) is
     select  column_name,
             nvl(hsize,254) hsize
     from   FND_HISTOGRAM_COLS a
     where  a.application_id = appl_id
     and    a.table_name     = upper(tabname)
     order by 1 ;

   method varchar2(2000) ;
   degree_parallel number(4);
begin
    -- Set the package body variable.
    stathist := hmode;

     if degree is null then
         degree_parallel:=def_degree;
     else
        degree_parallel := degree;
     end if;

     -- If a specific schema is given
     if (upper(ownname) <> 'ALL')  then
        -- get the tables for the given schema
        for t_rec in  tab_cursor(ownname) loop
           -- Insert/update the fnd_stats_hist table
           --dbms_output.put_line('appl_id = '||t_rec.application_id||',table='||t_rec.table_name);
          if(upper(stathist) <> 'NONE') then
            begin
                FND_STATS.UPDATE_HIST(schemaname=>ownname,
                                 objectname=>ownname,
                                 objecttype=>'HIST',
                                 partname=>null,
                                 columntablename=>null,
                                 degree=>degree_parallel,
                                 upd_ins_flag=>'S'
                                );
             end;
           end if;
           -- get the column list and build up the METHOD_OPT
           method := ' FOR COLUMNS ';
           for c_rec in col_cursor(t_rec.application_id, t_rec.table_name) loop

               -- Build up the method_opt variable
               if (method <> ' FOR COLUMNS ') then
                  method := method || ',';
               end if;
               method := method||  c_rec.column_name ||' SIZE ' || c_rec.hsize;
           end loop ; /* c_rec */
           --dbms_output.put_line('     method =  '|| method);
           begin
           FND_STATS.GATHER_TABLE_STATS_PVT ( ownname => ownname,
                                       tabname => t_rec.table_name,
                                       estimate_percent => nvl(percent,10),
                                       method_opt => method,
                                       degree   => degree_parallel,
                                       cascade => FALSE,
                                       invalidate => invalidate
                                       );
            exception
                  when others then raise;
            end;  /* end of FND_STATS.GATHER_TABLE_STATS_PVT call */
            -- End timestamp
          if(upper(stathist) <> 'NONE') then
            begin
                FND_STATS.UPDATE_HIST(schemaname=>ownname,
                                 objectname=>ownname,
                                 objecttype=>'HIST',
                                 partname=>null,
                                 columntablename=>null,
                                 degree=>degree_parallel,
                                 upd_ins_flag=>'E'
                                );
            end;
           end if;
        end loop ; /* t_rec */
    else    /* ownname = 'ALL' */
        for s_rec in schema_cur loop
            --dbms_output.put_line('start of schema = '|| s_rec.sname);
            -- get the tables for the given schema
            for t_rec in  tab_cursor(s_rec.sname) loop
                -- Insert/update the fnd_stat_hist table
                --dbms_output.put_line('appl_id = '||t_rec.application_id||',table='||t_rec.table_name);
           if(upper(stathist) <> 'NONE') then
                begin
                    FND_STATS.UPDATE_HIST(schemaname=>s_rec.sname,
                                 objectname=>s_rec.sname,
                                 objecttype=>'HIST',
                                 partname=>null,
                                 columntablename=>null,
                                 degree=>degree_parallel,
                                 upd_ins_flag=>'S'
                                );
                end;
           end if;
                -- get the column list and build up the METHOD_OPT
                method := ' FOR COLUMNS ';
                for c_rec in col_cursor(t_rec.application_id, t_rec.table_name) loop

                    -- Build up the method_opt variable
                    if (method <> ' FOR COLUMNS ') then
                       method := method || ',';
                    end if;
                    method := method||  c_rec.column_name ||' SIZE ' || c_rec.hsize;
                end loop ; /* c_rec */
                --dbms_output.put_line('     method =  '|| method);
                begin
                FND_STATS.GATHER_TABLE_STATS_PVT ( ownname => s_rec.sname,
                                            tabname => t_rec.table_name,
                                            estimate_percent => nvl(percent,10),
                                            method_opt => method,
                                            degree   => degree_parallel,
                                            cascade => FALSE,
                                       invalidate => invalidate
                                            );
                 exception
                       when others then raise;
                 end;  /* end of FND_STATS.GATHER_TABLE_STATS_PVT call */
                 -- End timestamp
             if(upper(stathist) <> 'NONE') then
                 begin
                    FND_STATS.UPDATE_HIST(schemaname=>s_rec.sname,
                                 objectname=>s_rec.sname,
                                 objecttype=>'HIST',
                                 partname=>null,
                                 columntablename=>null,
                                 degree=>degree_parallel,
                                 upd_ins_flag=>'S'
                                );
                 end;
            end if;
           end loop ; /* t_rec */
        end loop ; /* s_rec */
    end if ; /* end of ownname='ALL' */
end;  /* end of GATHER_ALL_COLUMN_STATS */

/************************************************************************/
/* Procedure: GATHER_ALL_COLUMN_STATS                                   */
/* Desciption: Gathers cols stats for a given schema                    */
/* or if ownname = 'ALL' then for ALL apps schema. This the concurrent  */
/* program manager version                                              */
/************************************************************************/
procedure GATHER_ALL_COLUMN_STATS(errbuf OUT NOCOPY  varchar2,
                              retcode OUT NOCOPY  varchar2,
                              ownname in varchar2,
                              percent in number default null,
                              degree in number default null,
                              hmode in varchar2  default 'LASTRUN',
                              invalidate    in varchar2 default 'Y'
                              )
is
   l_message varchar2(2000);
begin
   -- Set the package body variable.
   stathist := hmode;
    FND_STATS.GATHER_ALL_COLUMN_STATS(ownname=>ownname,percent=>percent,degree=>degree,hmode=>stathist,invalidate=>invalidate);
    exception
     when others then
              errbuf := sqlerrm ;
              retcode := '2';
              l_message := errbuf;
              FND_FILE.put_line(FND_FILE.log,l_message);
              raise;


end; /* end of conc mgr GATHER_ALL_COLUMN_STATS */

/************************************************************************/
/* Procedure: GATHER_COLUMN_STATS                                       */
/* Desciption: Gathers cols stats This the concurrent program manager   */
/* version                                                              */
/************************************************************************/
procedure GATHER_COLUMN_STATS(errbuf OUT NOCOPY  varchar2,
                              retcode OUT NOCOPY  varchar2,
                              ownname in varchar2,
                              tabname  in varchar2,
                              colname  in varchar2,
                              percent  in number  default null,
                              degree in number default null,
                              hsize   in number default 254,
                              backup_flag in varchar2 ,
                              partname in varchar2 default null,
                              hmode in varchar2  default 'LASTRUN',
                              invalidate    in varchar2 default 'Y'
                             )
is
  exist_insufficient exception;
  pragma exception_init(exist_insufficient,-20000);
  l_message varchar2(1000);
begin
  -- Set the package body variable.
  stathist := hmode;

  l_message := 'In GATHER_COLUMN_STATS , column is '|| ownname||'.'||tabname||'.'||colname||' backup_flag= '|| backup_flag ;
  FND_FILE.put_line(FND_FILE.log,l_message);
dlog(l_message);
  BEGIN
dlog('about to g c s');
       FND_STATS.GATHER_COLUMN_STATS(ownname,tabname,colname,percent,degree
                ,hsize,backup_flag,partname,hmode,invalidate);
       exception
                when exist_insufficient then
                   errbuf := sqlerrm ;
                   retcode := '2';
                   l_message := errbuf;
                   FND_FILE.put_line(FND_FILE.log,l_message);
                   raise;
                when others then
                   errbuf := sqlerrm ;
                   retcode := '2';
                   l_message := errbuf;
                   FND_FILE.put_line(FND_FILE.log,l_message);
                   raise;
  END;
end;  /* end of GATHER_COLUMN_STATS for conc. job */

/************************************************************************/
/* Procedure: GATHER_COLUMN_STATS                                       */
/* Desciption: Gathers cols stats.                                      */
/************************************************************************/
procedure GATHER_COLUMN_STATS(ownname in varchar2,
                              tabname  in varchar2,
                              colname  in varchar2,
                              percent  in number  default null,
                              degree in number default null,
                              hsize   in number default 254,
                              backup_flag in varchar2 ,
                              partname in varchar2 default null,
                              hmode in varchar2  default 'LASTRUN',
                              invalidate    in varchar2 default 'Y'
                             )
is
  method varchar2(200);
  exist_insufficient exception;
  pragma exception_init(exist_insufficient,-20002);
  degree_parallel number(4);
begin
dlog('about to g c s no cm version');
  -- Set the package body variable.
  stathist := hmode;

   if degree is null then
       degree_parallel:=def_degree;
   else
      degree_parallel := degree;
   end if;
   -- Insert/update the fnd_stat_hist table
      if(upper(stathist) <> 'NONE') then
        begin
          FND_STATS.UPDATE_HIST(schemaname=>ownname,
                                 objectname=>colname,
                                 objecttype=>'COLUMN',
                                 partname=>partname,
                                 columntablename=>tabname,
                                 degree=>degree_parallel,
                                 upd_ins_flag=>'S'
                                );
        end;
       end if;
       -- First export the col stats depending on the backup_flag
       if ( upper(nvl(backup_flag,'NOBACKUP')) = 'BACKUP' ) then
       begin
        -- First create the FND_STATTAB if it doesn't exist.
        BEGIN
           FND_STATS.CREATE_STAT_TABLE();
           exception
                when exist_insufficient then null;
        END;
            DBMS_STATS.EXPORT_COLUMN_STATS ( ownname,
                                             tabname,
                                             colname,
                                             partname,
                                             fnd_stattab,
                                             null,
                                             fnd_statown );
       end;
       end if;

       -- Now gather statistics
       method := 'FOR COLUMNS SIZE ' || hsize || ' '|| colname;
       FND_STATS.GATHER_TABLE_STATS_PVT ( ownname => ownname,
                                       tabname => tabname,
                                       partname =>partname,
                                       estimate_percent => nvl(percent,10),
                                       method_opt => method,
                                       degree   => degree_parallel,
                                       cascade => FALSE,
                                       stattab => fnd_stattab,
                                       statown => fnd_statown,
                                       invalidate => invalidate);

        -- End timestamp
      if(upper(stathist) <> 'NONE') then
         begin
           FND_STATS.UPDATE_HIST(schemaname=>ownname,
                                 objectname=>colname,
                                 objecttype=>'COLUMN',
                                 partname=>null,
                                 columntablename=>tabname,
                                 degree=>degree_parallel,
                                 upd_ins_flag=>'E'
                                );
         end;
      end if;
end; /* GATHER_COLUMN_STATS */

/************************************************************************/
/* Procedure: SET_TABLE_STATS                                           */
/* Desciption: Sets table stats to certain values.                      */
/************************************************************************/
procedure SET_TABLE_STATS(ownname in varchar2,
                          tabname in varchar2,
                          numrows  in number,
                          numblks  in number,
                          avgrlen  in number,
                          partname in varchar2 default null )
is
--  PRAGMA AUTONOMOUS_TRANSACTION ;
begin
     DBMS_STATS.SET_TABLE_STATS(ownname,
                                tabname,
                                partname,
                                null,
                                null,
                                numrows,
                                numblks,
                                avgrlen,
                                null,
                                null);
end; /* SET_TABLE_STATS */

/************************************************************************/
/* Procedure: SET_INDEX_STATS                                           */
/* Desciption: Sets index stats to certain values.                      */
/************************************************************************/
procedure SET_INDEX_STATS(ownname in varchar2,
                          indname in varchar2,
                          numrows  in number,
                          numlblks in number,
                          numdist  in number,
                          avglblk  in number,
                          avgdblk  in number,
                          clstfct  in number,
                          indlevel in number,
                          partname in varchar2 default null)
is
   l_iot varchar2(5):='FALSE';
   l_clstfct number:=clstfct;
begin
   /* add this to fix bug # .....
      when the index is of type IOT, set clustering factor to zero
   */
   /* added to fix bug 2239903 */
   select decode(index_type,'IOT - TOP', 'TRUE', 'FALSE')
   into  l_iot
   from  dba_indexes
   where owner = ownname
   and   index_name = indname;

   if (l_iot = 'TRUE') then
      l_clstfct := 0;
   end if;

   DBMS_STATS.SET_INDEX_STATS(ownname,
                             indname,
                             partname,
                             null,
                             null,
                             numrows,
                             numlblks,
                             numdist,
                             avglblk,
                             avgdblk,
                             l_clstfct,
                             indlevel,
                             null,
                             null);
exception
   when others then null;
end; /* SET_INDEX_STATS */

/******************************************************************************/
/* Procedure: LOAD_XCLUD_TAB                                                  */
/* Desciption: This procedure was deprecated, but 11.5.2CU2 onwards           */
/*             we are reuseing it for a different purpose. This procedure     */
/*             will be used to populate fnd_exclude_table_stats table , which */
/*             which contains the list of tables which should be skipped      */
/*             by the gather schema stats program.                            */
/******************************************************************************/
procedure LOAD_XCLUD_TAB(action in varchar2,
                          appl_id in number,
                          tabname in varchar2) is
exist_flag varchar2(6) := null;
begin
       if ((Upper(action) = 'INSERT') OR (Upper(action) = 'INS') OR (Upper(action) = 'I')) then
           -- Check for existence of the table first in FND Dictionary
           -- then in data dictionary
           -- break out if it doesn't exist
           begin
               select 'EXIST'
               into  exist_flag
               from  fnd_tables a
               where a.table_name = upper(tabname)
               and   a.application_id = appl_id ;
               exception
                    when no_data_found then
                    begin
                       select 'EXIST'
                       into exist_flag
                       from dba_tables
                       where table_name = upper(tabname)
                       and owner = ( select b.oracle_username
                               from fnd_product_installations a,
                                    fnd_oracle_userid b
                               where a.application_id = appl_id
                               and   b.oracle_id = a.oracle_id);
                        exception
                        when no_data_found then
                           raise_application_error(-20000, 'Table ' || tabname || ' does not exist in fnd_tables/dba_tables for the
given application ');
                      end;
            end;
            -- Now insert
            insert into FND_EXCLUDE_TABLE_STATS(APPLICATION_ID,TABLE_NAME,CREATION_DATE,CREATED_BY,
                                                LAST_UPDATE_DATE,LAST_UPDATED_BY,LAST_UPDATE_LOGIN)
            values (  appl_id,
                      upper(tabname),
                      sysdate,
                      1,
                      sysdate,
                      1,
                      null) ;
         elsif ((Upper(action) = 'DELETE') OR (Upper(action) = 'DEL') OR (Upper(action) = 'D')) then
            delete from FND_EXCLUDE_TABLE_STATS
            where  table_name = upper(tabname)
            and    application_id = appl_id;
         end if;
        commit;


end; /* LOAD_XCLUD_TAB */

/************************************************************************/
/* Procedure: LOAD_HISTOGRAM_COLS                                       */
/* Desciption: This is for internal purpose only. For loading into      */
/* SEED database                                                        */
/************************************************************************/
procedure LOAD_HISTOGRAM_COLS(action in varchar2,
                          appl_id in number,
                          tabname in varchar2,
                          colname in varchar2,
                          partname in varchar2 default null,
                          hsize  in number default 254,
                          commit_flag in varchar2 default 'Y')
is
exist_flag varchar2(5) := null;
begin
       if upper(action) = 'INSERT' then
       begin
           -- Check for existence of the table first
           -- break out if it doesn't exist
           begin
                 select distinct('EXIST')
                 into  exist_flag
                 from  dba_tab_columns a,
                       fnd_oracle_userid b,
                       fnd_product_installations c
                 where a.table_name = upper(tabname)
                 and   a.column_name = upper(colname)
                 and   c.application_id = appl_id
                 and   c.oracle_id  = b.oracle_id
                 and   a.owner = b.oracle_username;
                 exception
                    when no_data_found then
                         raise_application_error(-20000, 'Column ' || tabname ||'.' || colname || ' does not exist in dba_tab_columns for the given application ');
                    when others then
                         raise_application_error(-20001, 'Error in reading dictionary info. for column  ' || tabname ||'.' || colname );
           end;
 	   begin
           	insert into FND_HISTOGRAM_COLS(APPLICATION_ID,
               TABLE_NAME,
               COLUMN_NAME,
               PARTITION,
               HSIZE,
               CREATION_DATE,
               CREATED_BY,
               LAST_UPDATE_DATE,
               LAST_UPDATED_BY,
               LAST_UPDATE_LOGIN)
           	values(appl_id,
               upper(tabname),
               upper(colname),
               upper(partname),
               hsize,
               sysdate,
               1,
               sysdate,
               1,
               null
               ) ;
	   exception
		when DUP_VAL_ON_INDEX then
		     null;
	   end;
       end;
       elsif upper(action) = 'DELETE' then
       begin
           delete from FND_HISTOGRAM_COLS
           where  application_id = appl_id
           and    table_name   = upper(tabname)
           and    column_name   = upper(colname)
           and    (partition  = upper(partname) or partition is null);
       end;
       end if;
       if ( commit_flag = 'Y') then /* for remote db operation */
         commit;
       end if;
end; /* LOAD_HISTOGRAM_COLS */

/************************************************************************/
/* Procedure: LOAD_HISTOGRAM_COLS                                       */
/* Desciption: This is for internal purpose only. For loading into      */
/* SEED database                                                        */
/************************************************************************/
procedure LOAD_HISTOGRAM_COLS_MV(action in varchar2,
                          ownername in varchar2,
                          tabname in varchar2,
                          colname in varchar2,
                          partname in varchar2 default null,
                          hsize  in number default 254,
                          commit_flag in varchar2 default 'Y')
is
exist_flag varchar2(5) := null;
begin
       if upper(action) = 'INSERT' then
       begin
           -- Check for existence of the table first
           -- break out if it doesn't exist
           begin
                 select distinct('EXIST')
                 into  exist_flag
                 from  dba_tab_columns a
                 where a.table_name = upper(tabname)
                 and   a.column_name = upper(colname)
                 and   a.owner = upper(ownername);
                 exception
                    when no_data_found then
                         raise_application_error(-20000, 'Column ' || tabname ||'.' || colname || ' does not exist in dba_tab_columns for the given owner ');
                    when others then
                         raise_application_error(-20001, 'Error in reading dictionary info. for column  ' || tabname ||'.' || colname );
           end;
           begin
               insert into FND_HISTOGRAM_COLS(
               application_id,
	       OWNER,
               TABLE_NAME,
               COLUMN_NAME,
               PARTITION,
               HSIZE,
               CREATION_DATE,
               CREATED_BY,
               LAST_UPDATE_DATE,
               LAST_UPDATED_BY,
               LAST_UPDATE_LOGIN)
               values(
               -1,
               upper(ownername),
               upper(tabname),
               upper(colname),
               upper(partname),
               hsize,
               sysdate,
               1,
               sysdate,
               1,
               null
               ) ;
           exception
                when DUP_VAL_ON_INDEX then
                     null;
           end;
       end;
       elsif upper(action) = 'DELETE' then
       begin
           delete from FND_HISTOGRAM_COLS
           where  owner = upper(ownername)
           and    table_name   = upper(tabname)
           and    column_name   = upper(colname)
           and    (partition  = upper(partname) or partition is null);
       end;
       end if;
       if ( commit_flag = 'Y') then /* for remote db operation */
         commit;
       end if;
end; /* LOAD_HISTOGRAM_COLS_MV */



/************************************************************************/
/* Procedure: LOAD_XCLUD_STATS                                          */
/* Desciption: This will artificially pump the                          */
/*  stats with some value so that the CBO                               */
/* goes for index scans instead of full table scans.  The idea behind   */
/* this is that during a gather_schema_stats the interface tables may   */
/* not have data and hence the stats for such tables will be of no use  */
/* and hence we need to pump some artificial stats for such tables.     */
/* Ideally a customer has to run gather_table_stats on the interface    */
/* tables after populating with data. This will give them accurate data.*/
/* A good methodology would be gather_table_stats once for the interface*/
/* table populated with good ammount of data and for all the consecutive*/
/* runs use restore_table_data procedure to restore the stats.          */
/* The simplified algorith for calculations are:                        */
/* BLOCKS = num_rows*1/20,                                              */
/* AVG_ROW_LENGTH = 50% of Total max row_length                         */
/* Clustering factor = num. of blocks                                   */
/* num. of leaf blks =                                                  */
/*      (cardinality)/((db_block_size -overhead 200)/key_size)          */
/*     revised to the following as per Amozes to alway prefer index scan*/
/* num. of leaf blks = 100/num of table blks                            */
/* index_level = 1                                                      */
/* Distinct keys = num of rows                                          */
/************************************************************************/
procedure  LOAD_XCLUD_STATS(schemaname in varchar2)
is
begin
  -- This procedure has been deprecated. Stub is being retained for now
  -- so that it does not break compilation in case it is still being called.
  null;
end ;    /* LOAD_XCLUD_STATS  */

/************************************************************************/
/* Procedure: LOAD_XCLUD_STATS                                          */
/* Desciption: This one is for a particular INTERFACE TABLE             */
/************************************************************************/
procedure  LOAD_XCLUD_STATS(schemaname in varchar2,
                            tablename  in varchar2)
is
begin
  -- This procedure has been deprecated. Stub is being retained for now
  -- so that it does not break compilation in case it is still being called.
  null;
end ;    /* LOAD_XCLUD_STATS  */

/************************************************************************/
/* Procedure: CHECK_HISTOGRAM_COLS                                      */
/* Desciption: For a given list of comma seperated tables,              */
/*  this procedure checks the                                           */
/*   data in all the leading columns of all the non-unique indexes of   */
/*   those tables and figures out if histogram needs to be created for  */
/*   those columns. The algorithm is as follows :                       */
/*   select decode(floor(sum(tot)/(max(cnt)*75)),0,'YES','NO') HIST     */
/*   from (select count(col) cnt , count(*) tot                         */
/*         from tab sample (S)                                          */
/*         where col is not null                                        */
/*         group by col);                                               */
/*   The decode says whether or not a single value occupies 1/75th or   */
/*   more of the sample.                                                */
/*   If sum(cnt) is very small (a small non-null sample), the results   */
/*   may be inaccurate. A count(*) of atleast 3000 is recommended .     */
/************************************************************************/
procedure CHECK_HISTOGRAM_COLS(tablelist        in varchar2,
                               factor           in integer,
                               percent          in number,
                               degree           in number default null)
is
begin
declare
  cursor column_cur(tname  varchar2)  is
    select distinct column_name  col,
           b.table_name tab,
           b.table_owner own
           from dba_ind_columns a,
                dba_indexes   b
           where b.table_owner = upper(substr(tname,1,instr(tname,'.')-1))
           and  (b.table_name  = upper(substr(tname,instr(tname,'.')+1))
                 or
                 b.table_name like upper(substr(tname,instr(tname,'.')+1)) )
           and  b.uniqueness  = 'NONUNIQUE'
           and  b.index_type  = 'NORMAL'
           and  a.index_owner = b.owner
           and  a.index_name  = b.index_name
           and  a.column_position = 1
     order by 3 , 2 ,1 ;
   TYPE List IS TABLE OF VARCHAR2(62) INDEX BY BINARY_INTEGER;
   Table_List List;
   MAX_NOF_TABLES number := 32768;
   table_counter integer := 0 ;
   sql_string varchar2(2000);
   mytablelist varchar2(4000);
   hist varchar2(3);
   abs_tablename varchar2(61);
   total_cnt   integer;
   max_cnt   integer;
begin
     -- initialize Table_list
     Table_List(0) := NULL;
     mytablelist := replace(tablelist,' ','');
     if (percent < 0 or percent > 100) then
     raise_application_error(-20001,'percent must be between 0 and 100');
     end if;
     dbms_output.put_line('Table-Name                                   Column-Name                   Histogram Tot-Count  Max-Count');
     dbms_output.put_line('==========================================================================================================');
     WHILE (instr(mytablelist,',') > 0) LOOP
        Table_List(table_counter):= substr(mytablelist,1,instr(mytablelist,',') - 1) ;
        Table_List(table_counter+1) := NULL;
        table_counter := table_counter + 1;
        mytablelist := substr(mytablelist,instr(mytablelist,',')+1) ;
        exit when table_counter = MAX_NOF_TABLES;
     END LOOP;
     -- This gets the last table_name in a comma separated list
     Table_List(table_counter) := mytablelist ;
     Table_List(table_counter+1) := NULL;
     FOR i in 0..MAX_NOF_TABLES LOOP
         exit when Table_List(i) is null;
         for c_rec in column_cur(Table_List(i)) loop
             --Build up the dynamic sql
             sql_string := 'select ';
             sql_string := sql_string || '/*+ PARALLEL (tab,';
             sql_string := sql_string || degree || ') */';
             sql_string := sql_string || ' decode(floor(sum(tot)/(max(cnt)*'||factor||')),0,''YES'',''NO'') , nvl(sum(tot),0), nvl(max(cnt),0) ';
             sql_string := sql_string || ' from (select count('||c_rec.col||') cnt, count(*) tot from ';
             sql_string := sql_string|| c_rec.own||'.'||c_rec.tab || ' sample (';
             sql_string := sql_string || percent||') tab ';
             sql_string := sql_string || ' group by '||c_rec.col||' )' ;
             begin
             EXECUTE IMMEDIATE sql_string into hist,total_cnt,max_cnt;
             exception
               when zero_divide then
                  hist := 'NO';
             end;
             abs_tablename := c_rec.own||'.'||c_rec.tab;
             dbms_output.put_line(rpad(upper(abs_tablename),40,' ')||rpad(c_rec.col,30,' ')||  rpad(hist,10,' ')||lpad(to_char(total_cnt),9,' ')||lpad(to_char(max_cnt),9,' '));
         end loop;
     END LOOP;
end;
end ;  /* end of CHECK_HISTOGRAM_COLS */

/************************************************************************/
/* Procedure: ANALYZE_ALL_COLUMNS                                       */
/* Desciption: This is to create histograms on all leading cols of      */
/* non-unique indexes of all the tables in a given schema               */
/************************************************************************/
procedure ANALYZE_ALL_COLUMNS(ownname           in varchar2,
                              percent           in number,
                              hsize             in number,
                              hmode in varchar2 default 'LASTRUN'
                              )
is
begin
  -- This procedure has been deprecated. Stub is being retained for now
  -- so that it does not break compilation in case it is still being called.
  null;
end;  /*end of ANALYZE_ALL_COLUMNS*/

/************************************************************************/
/* Procedure: ANALYZE_ALL_COLUMNS                                       */
/* Desciption: conc. job version of ANALYZE_ALL_COLUMNS                 */
/************************************************************************/
procedure ANALYZE_ALL_COLUMNS(errbuf           OUT NOCOPY  varchar2,
                              retcode          OUT NOCOPY  varchar2,
                              ownname          in varchar2,
                              percent in number ,
                              hsize            in number ,
                              hmode in varchar2 default 'LASTRUN'
                             )
is
begin
  -- This procedure has been deprecated. Stub is being retained for now
  -- so that it does not break compilation in case it is still being called.
  null;
end; /* end of ANALYZE_ALL_COLUMNS */

/************************************************************************/
/* Procedure: UPDATE_HIST                                               */
/* Desciption: Internal procedure to insert or update entries in table  */
/* fnd_stats_hist. These values are used later if restartability is     */
/* needed.                                                              */
/************************************************************************/
procedure UPDATE_HIST(schemaname varchar2, objectname in varchar2,
    objecttype in varchar2, partname in varchar2, columntablename in varchar2,
    degree  in number, upd_ins_flag in varchar2,percent in number) is
PRAGMA AUTONOMOUS_TRANSACTION ;
   cascade_true varchar2(1);
begin
       -- if request_id is null then we cannot do it in FULL mode, defaults to LASTRUN
       --- if(stathist='FULL') then
         --- stathist:='LASTRUN';
       --- end if;
   if(stathist = 'LASTRUN') then -- retaining the old behavior as default
      -- S (Start) is when the entry is already in fnd_stats_hist and statistics
      -- were gathering is going to start for that particular object
       if (upd_ins_flag = 'S') then
               update FND_STATS_HIST set
                  parallel = degree,
                  request_id = cur_request_id,
                  request_type = request_from,
                  last_gather_start_time = sysdate,
                  last_gather_date = '',
                  last_gather_end_time = '',
                  est_percent=percent
             where
                  schema_name = upper(schemaname)
                  and object_name = upper(objectname)
                  and (partition = upper(partname) or partname is null)
                  and ( column_table_name = upper(columntablename)
                        or columntablename is null)
                  and object_type = upper(objecttype)
              --    and request_id=cur_request_id -- commented this line for the bug 5648754
                  and history_mode='L';
          /* Added by mo, this segment checks if an entry was updated or not.
             If not, a new entry will be added. */
          if SQL%ROWCOUNT = 0 then
              insert into FND_STATS_HIST(
                SCHEMA_NAME,
                OBJECT_NAME,
                OBJECT_TYPE,
                PARTITION,
                COLUMN_TABLE_NAME,
                LAST_GATHER_DATE,
                LAST_GATHER_START_TIME,
                LAST_GATHER_END_TIME,
                PARALLEL,
                REQUEST_ID,
                REQUEST_type,
                HISTORY_MODE,
                EST_PERCENT)
              values (
                   upper(schemaname),
                   upper(objectname),
                   upper(objecttype),
                   upper(partname),
                   columntablename,
                   '',
                   sysdate,
                   '',
                   degree,
                   cur_request_id,
                   request_from,
                   'L',
                   percent);
          end if;
       end if;
       -- E (End) is when the entry is already in fnd_stats_hist and statistics
       -- gathering finished successfully for that particular object
       if (upd_ins_flag = 'E') then
               update FND_STATS_HIST set
                  last_gather_date = sysdate,
                  last_gather_end_time = sysdate
             where
                  schema_name = upper(schemaname)
                  and object_name = upper(objectname)
                  and (partition = upper(partname) or partname is null)
                  and ( column_table_name = upper(columntablename)
                        or columntablename is null)
                  and object_type = upper(objecttype)
                  and request_id=cur_request_id
                  and history_mode='L';
         end if;
   elsif (stathist = 'FULL') then  -- new option, old hist will not be updated

       if (upd_ins_flag = 'S') then
               update FND_STATS_HIST set
                  parallel = degree,
                  request_id = cur_request_id,
                  request_type = request_from,
                  last_gather_start_time = sysdate,
                  last_gather_date = '',
                  last_gather_end_time = '',
                  est_percent=percent
             where
                  schema_name = upper(schemaname)
                  and object_name = upper(objectname)
                  and (partition = upper(partname) or partname is null)
                  and ( column_table_name = upper(columntablename)
                        or columntablename is null)
                  and object_type = upper(objecttype)
                  and history_mode='F'   -- F for FULL mode
                  and request_id=cur_request_id;
                  -- commenting out because it is not part of unique cons criteria
                  -- and request_type=request_from;

            /* This segment checks if an entry was updated or not. This is still required even for
             FULL mode, because multiple calls for the same object from the same session will have
             the same cur_request_id. If not, a new entry will be added. */
          if SQL%ROWCOUNT = 0 then
              insert into FND_STATS_HIST(
                SCHEMA_NAME,
                OBJECT_NAME,
                OBJECT_TYPE,
                PARTITION,
                COLUMN_TABLE_NAME,
                LAST_GATHER_DATE,
                LAST_GATHER_START_TIME,
                LAST_GATHER_END_TIME,
                PARALLEL,
                REQUEST_ID,
                REQUEST_type,
                HISTORY_MODE,
                EST_PERCENT)
              values (
                   upper(schemaname),
                   upper(objectname),
                   upper(objecttype),
                   upper(partname),
                   columntablename,
                   '',
                   sysdate,
                   '',
                   degree,
                   cur_request_id,
                   request_from,
                   'F',
                   percent);
           end if;
       end if;
       -- E (End) is when the entry is already in fnd_stats_hist and statistics
       -- gathering finished successfully for that particular object
       if (upd_ins_flag = 'E') then
             update FND_STATS_HIST set
                  last_gather_date = sysdate,
                  last_gather_end_time = sysdate
             where
                  schema_name = upper(schemaname)
                  and object_name = upper(objectname)
                  and (partition = upper(partname) or partname is null)
                  and ( column_table_name = upper(columntablename)
                        or columntablename is null)
                  and object_type = upper(objecttype)
                  and history_mode='F'
                  and request_id=cur_request_id;
                  -- commenting out because it is not part of unique cons criteria
                  -- and request_type=request_from;
       end if;
   end if;
       commit;
exception
  when others then
    fnd_file.put_line(FND_FILE.LOG,'Unable to correctly update the history table - fnd_stats_hist.');
    fnd_file.put_line(FND_FILE.LOG,sqlcode||' - '|| sqlerrm);
    rollback;

end;   /* end of UPDATE_HIST */

/************************************************************************/
/* Procedure: PURGE_STAT_HISTORY                                        */
/* Desciption: Purges the fnd_stat_hist table based on the FROM_REQ_ID  */
/* and TO_REQ_ID provided.                                              */
/************************************************************************/
procedure PURGE_STAT_HISTORY(from_req_id in number,to_req_id in number)
 is
     PRAGMA AUTONOMOUS_TRANSACTION;
begin
     delete from fnd_stats_hist
     where request_id between from_req_id and to_req_id;
     commit;
end;

/************************************************************************/
/* Procedure: PURGE_STAT_HISTORY                                        */
/* Desciption: Purges the fnd_stat_hist table based on the FROM_DATE    */
/* and TO_DATE provided. Date should be provided in DD-MM-YY format    */
/************************************************************************/
procedure PURGE_STAT_HISTORY(purge_from_date in varchar2,purge_to_date in varchar2)
 is
     PRAGMA AUTONOMOUS_TRANSACTION;
purge_from_date_l varchar2(15);
purge_to_date_l varchar2(15);

begin
    -- If from_date is null then from_date is sysdate-One year
     if (purge_from_date is null ) then
         purge_from_date_l:=to_char(sysdate-365,'DD-MM-YY');
     else
         purge_from_date_l:=purge_from_date;
     end if;

    -- If to_date is null then to_date is sysdate-One week
     if (purge_to_date is null ) then
         purge_to_date_l:=to_char(sysdate-7,'DD-MM-YY');
     else
         purge_to_date_l:=purge_to_date;
     end if;
     delete from fnd_stats_hist
     where last_gather_date between to_date(purge_from_date_l,'DD-MM-YY') and to_date(purge_to_date_l,'DD-MM-YY');
     commit;
end;


/**************************************************************************/
/* Procedure: PURGE_STAT_HISTORY Conc Program version                     */
/* Desciption: Purges the fnd_stat_hist table based on the Mode parameter.*/
/**************************************************************************/
procedure PURGE_STAT_HISTORY(errbuf OUT NOCOPY  varchar2,
                             retcode OUT NOCOPY  varchar2,
                             purge_mode in varchar2,
                             from_value in varchar2,
                             to_value in varchar2
                             )
 is
begin

  If upper(purge_mode) = 'DATE' then
    PURGE_STAT_HISTORY(from_value,to_value);
   elsif upper(purge_mode)='REQUEST' then
    PURGE_STAT_HISTORY(to_number(from_value),to_number(to_value));
  end if;

exception
     when others then
        errbuf := sqlerrm ;
        retcode := '2';
        FND_FILE.put_line(FND_FILE.log,errbuf);
        raise;
end;

/************************************************************************/
/* Procedure: table_stats                                               */
/* Desciption: Internal procedures used by verify_stats. Gets info about*/
/* table stats.                                                         */
/************************************************************************/
procedure table_stats(schema varchar2, tableName varchar2) is
       last_analyzed     dba_tables.last_analyzed%type;
       sample_size       dba_tables.sample_size%type;
       num_rows          dba_tables.num_rows%type;
       blocks            dba_tables.blocks%type;
     begin
       select last_analyzed, sample_size, trunc(num_rows), blocks
       into   last_analyzed, sample_size, num_rows, blocks
       from   dba_tables
       where  table_name = tableName
       and    owner      = schema;
       dbms_output.put_line('===================================================================================================');
       dbms_output.put_line('            Table   ' || tableName);
       dbms_output.put_line('===================================================================================================');
       dbms_output.put_line(rpad('last analyzed', 18, ' ')|| rpad('sample_size', 12, ' ')||rpad('num_rows', 20, ' ') ||rpad('blocks', 10, ' '));
       dbms_output.put_line(rpad(to_char(last_analyzed, 'MM-DD-YYYY hh24:mi'), 18, ' ') || rpad(sample_size, 12, ' ') || rpad(num_rows, 20, ' ') ||blocks);
       dbms_output.put_line('	');
Exception
       when no_data_found then
          dbms_output.put_line('=================================================================================================');
          dbms_output.put_line('Table not found; Owner: '|| schema ||', name: '|| tableName);
          dbms_output.put_line('=================================================================================================');
     end table_stats;

/************************************************************************/
/* Procedure: index_stats                                               */
/* Desciption: Internal procedures used by verify_stats. Gets info about*/
/* index stats.                                                         */
/************************************************************************/
procedure index_stats(lowner varchar2, indexName varchar2) is
       last_analyzed     	dba_indexes.last_analyzed%type;
       num_rows          	dba_indexes.num_rows%type;
       leaf_blocks       	dba_indexes.leaf_blocks%type;
       distinct_keys     	dba_indexes.distinct_keys%type;
       avg_leaf_blocks_per_key 	dba_indexes.avg_leaf_blocks_per_key%type;
       avg_data_blocks_per_key 	dba_indexes.avg_data_blocks_per_key%type;
       clustering_factor 	dba_indexes.clustering_factor%type;
       uniqueness		dba_indexes.uniqueness%type;
       val1                     varchar2(255);
       val2                     varchar2(255);
       val3                     varchar2(255);
       val4                     varchar2(255);
     begin
       select last_analyzed, trunc(num_rows), leaf_blocks, distinct_keys, avg_leaf_blocks_per_key,avg_data_blocks_per_key, clustering_factor, uniqueness
       into last_analyzed, num_rows, leaf_blocks, distinct_keys, avg_leaf_blocks_per_key,                                   avg_data_blocks_per_key, clustering_factor, uniqueness
       from dba_indexes
       where owner = lowner
       and   index_name = indexName;
       val1:= rpad(indexname, 30, ' ') || rpad(to_char(last_analyzed, 'MM-DD-YYYY hh24:mi'), 18,' ');
       val2:= rpad(num_rows, 10, ' ') ||rpad(leaf_blocks, 8, ' ');
       val3:= rpad(distinct_keys, 9, ' ') || rpad(avg_leaf_blocks_per_key, 8, ' ');
       val4:= rpad(avg_data_blocks_per_key, 8, ' ') || rpad(clustering_factor, 9, ' ');
       dbms_output.put_line(val1 || val2 || val3 || val4);

     end index_stats;

/************************************************************************/
/* Procedure: histo_header                                              */
/* Desciption: Internal procedures used by verify_stats. Prints header  */
/* for histograms in the o/p file                                       */
/************************************************************************/
procedure histo_header is
     begin
       dbms_output.put_line('----------------------------------------------------------------------------------------------------');
       dbms_output.put_line('       Histogram  Stats');
       dbms_output.put_line(rpad('Schema', 15, ' ')||rpad('Table Name', 31, ' ')||rpad('Status', 12, ' ')||rpad('last analyzed', 18, ' ') || 'Column Name');
       dbms_output.put_line('----------------------------------------------------------------------------------------------------');
     end;

/************************************************************************/
/* Procedure: index_header                                              */
/* Desciption: Internal procedures used by verify_stats. Prints header  */
/* for indexes in the o/p file                                          */
/************************************************************************/
procedure index_header is
     val1 varchar2(255);
     val2 varchar2(255);
     val3 varchar2(255);
     val4 varchar2(255);
     begin
       val1 := rpad('Index name', 30, ' ') || rpad('last analyzed', 18, ' ');
       val2 := rpad('num_rows', 10, ' ')|| rpad('LB', 8, ' ');
       val3 := rpad('DK', 9, ' ')|| rpad('LB/key', 8, ' ');
       val4 := rpad('DB/key', 8, ' ')||rpad('CF', 9, ' ');
       dbms_output.put_line(val1 || val2 || val3 || val4);
       dbms_output.put_line('----------------------------------------------------------------------------------------------------');
     end;

/************************************************************************/
/* Procedure: histo_stats                                               */
/* Desciption: Internal procedures used by verify_stats. Gets info about*/
/* about histogram stats.                                               */
/************************************************************************/
procedure histo_stats(schema varchar2, tableName varchar2, columnName varchar2) is
       found0 boolean := false;
       found1 boolean := false;
       status varchar2(64) := 'not present';
       last_analyzed  dba_tab_columns.last_analyzed%type;

       cursor histo_details(schema varchar2, tableName varchar2, columnName varchar2) is
         select endpoint_number, last_analyzed
         from   dba_histograms a, dba_tab_columns b
         where  a.owner = schema
         and    a.table_name = tableName
         and    a.column_name = columnName
	 and    a.owner = b.owner
	 and    a.table_name = b.table_name
	 and    a.column_name = b.column_name
         and    endpoint_number not in (0, 1);
     begin
       for each_histo in histo_details(schema, tableName, columnName) LOOP
	 last_analyzed := each_histo.last_analyzed;
	 status := 'present';
	 exit;
       END LOOP;
       dbms_output.put_line(rpad(schema, 15, ' ')|| rpad(tableName, 31, ' ') || rpad(status, 12, ' ')|| rpad(to_char(last_analyzed, 'DD-MM-YYYY hh24:mi'), 18, ' ') || columnName);
Exception
       when no_data_found then
         dbms_output.put_line('=================================================================================================');
         dbms_output.put_line('Histogram not found; Owner: '|| schema ||', name: '|| tableName || ', column name: ' || columnName);
         dbms_output.put_line('=================================================================================================');
     end histo_stats;

/************************************************************************/
/* Procedure: file_tail                                                 */
/* Desciption: Internal procedures used by verify_stats. Prints legend  */
/* in the o/p file                                                      */
/************************************************************************/
procedure file_tail is
begin
  dbms_output.put_line('	');
  dbms_output.put_line('	');
  dbms_output.put_line('Legend:');
  dbms_output.put_line('LB : Leaf Blocks');
  dbms_output.put_line('DK : Distinct Keys');
  dbms_output.put_line('DB : Data Blocks');
  dbms_output.put_line('CF : Clustering Factor');


end;

/************************************************************************/
/* Procedure: column_stats                                              */
/* Desciption: Internal procedures used by verify_stats. Gets info about*/
/* about column stats.                                                  */
/************************************************************************/
procedure column_stats(column_name dba_tab_columns.column_name%type,
   num_distinct dba_tab_columns.num_distinct%type,
   num_nulls dba_tab_columns.num_nulls%type,
   density dba_tab_columns.density%type,
   sample_size dba_tab_columns.sample_size%type,
   last_analyzed dba_tab_columns.last_analyzed%type,
   first_col boolean) is
       val1                     varchar2(255);
       val2                     varchar2(255);
       val3                     varchar2(255);
     begin
       if (first_col = true) then
          dbms_output.put_line('----------------------------------------------------------------------------------------------------');
          dbms_output.put_line('       Column  Stats');
	  val1 := rpad('Column name', 31, ' ') ||  rpad('sample_size', 12, ' ');
          val2 := rpad('num_distinct', 14, ' ')|| rpad('num_nulls', 14, ' ');
	  val3 := rpad('density', 12, ' ') || rpad('last analyzed', 18, ' ');
	  dbms_output.put_line(val1||val2||val3);
          dbms_output.put_line('----------------------------------------------------------------------------------------------------');
       end if;
       val1 := rpad(column_name, 31, ' ') || rpad(sample_size, 12, ' ');
       val2 := rpad(num_distinct, 14, ' ')|| rpad(trunc(num_nulls), 14, ' ');
       val3 := rpad(trunc(density, 9), 12, ' ') || rpad(to_char(last_analyzed, 'MM-DD-YYYY hh24:mi'), 18, ' ');
       dbms_output.put_line(val1 || val2 || val3);
end;

/************************************************************************/
/* Procedure: verify_stats                                              */
/* Desciption: Checks stats for database objects depending on input.    */
/* Sends its output to the screen. Should be called from SQL prompt, and*/
/* o/p should be spooled to a file. Can be used to check all tables in  */
/* schema, or particular tables. Column stats can also be checked.      */
/************************************************************************/
procedure verify_stats(schemaName varchar2 default null, tableList varchar2 default null,
    days_old number default null, column_stat boolean default false) is
  cursor  all_tables(schema varchar2) is
    select table_name, owner
    from dba_tables dt
    where owner = schema
    and (iot_type <> 'IOT_OVERFLOW' or iot_type is null)
    and ((sysdate - nvl(last_analyzed, to_date('01-01-1900', 'MM-DD-YYYY')))>days_old or days_old is null)
    order by table_name;

  cursor all_indexes(schema varchar2, tableName varchar2) is
    select index_name, owner
    from dba_indexes
    where table_owner = schema
    and table_name = tableName
    order by index_name;

  /*cursor all_histograms(schema varchar2, tableName varchar2) is
    select a.column_name
    from fnd_histogram_cols a,
         fnd_oracle_userid b,
         fnd_product_installations c
    where a.application_id = c.application_id
    and   c.oracle_id = b.oracle_id
    and   b.oracle_username = schema
    and   a.table_name = tableName
    order by a.column_name;*/

  cursor all_histograms(schema varchar2, tableName varchar2) is
    select a.column_name
    from fnd_histogram_cols a
    where a.table_name = tableName
    order by a.column_name;


  cursor all_columns(schema varchar2, tableName varchar2) is
    select COLUMN_NAME, NUM_DISTINCT, NUM_NULLS, DENSITY, SAMPLE_SIZE, LAST_ANALYZED
    from   dba_tab_columns
    where  owner = schema
    and    table_name = tableName
    order by column_name;

   MyTableList varchar2(4000);
   MySchema varchar2(255);
   TYPE List IS TABLE OF varchar2(64) INDEX BY BINARY_INTEGER;
   Table_Name List;
   Table_Owner List;
   table_counter integer := 1;
   MAX_NOF_TABLES number := 32768;
   operation varchar2(64):= '';
   ownerIndex number(1);
   first_histo boolean;
   first_index boolean;
   first_col boolean;
   verify_stats_exception EXCEPTION;
begin
     dbms_output.enable(1000000);
     -- read all input params into plsql vars
     MySchema := upper(schemaName);
     MyTableList := replace(upper(TableList), ' ', '');
     -- clean up input data
     -- start with the tables list
     if MyTableList is NULL then
	-- user wants to inspect all tables in schema
        if MySchema is NOT NULL then
	        operation := 'schema';
        end if;
     else
	    operation := 'table';
    end if;
    Table_Name(1) := NULL;
    Table_Owner(1) := NULL;
    -- check operation flag and process accordingly
    if operation = 'table' then
        -- initialize Table_list
        WHILE (instr(MyTableList,',') > 0) LOOP
	        dbms_output.put_line('MyTableList ' || mytableList);
            Table_Name(table_counter):= substr(mytablelist,1,instr(mytablelist,',') - 1) ;
            ownerIndex := instr(Table_Name(table_counter), '.');
            if ownerIndex <> 0 then
                Table_Owner(table_counter):= substr(Table_Name(table_counter), 1, ownerIndex-1);
                Table_Name(table_counter):= substr(Table_Name(table_counter), ownerIndex+1);
  	        else
	            Table_Owner(table_counter):= MySchema;
	        end if;
            table_counter := table_counter + 1;
            Table_Name(table_counter) := NULL;
            Table_Owner(table_counter) := NULL;
            MyTableList := substr(MyTableList,instr(MyTableList,',')+1) ;
            exit when table_counter = MAX_NOF_TABLES;
        END LOOP;
        -- This gets the last table_name in a comma separated list
        Table_Name(table_counter) := MyTableList ;
	    -- check if owner is specified on command line or not
	    OwnerIndex := instr(Table_Name(table_counter), '.');
        if ownerIndex <> 0 then
            Table_Owner(table_counter):= substr(Table_Name(table_counter), 1, ownerIndex-1);
            Table_Name(table_counter):= substr(Table_Name(table_counter), ownerIndex+1);
        else
            Table_Owner(table_counter):= MySchema;
        end if;
        Table_Name(table_counter+1) := NULL;
        Table_Owner(table_counter+1) := NULL;
    elsif operation = 'schema' then
	    -- retrieve all tables for schema and continue with processing
	    OPEN all_tables(MySchema);
	    FETCH all_tables BULK COLLECT into Table_Name, Table_Owner LIMIT MAX_NOF_TABLES;
        CLOSE all_tables;
    else  -- error occurred
        raise verify_stats_exception;
    end if;
    -- loop all the tables and check their stats and indexes
    FOR i in 1..Table_Name.last LOOP
        exit when Table_Name(i) is null;
	    first_histo := true;
	    first_index := true;
        first_col := true;
	    -- get table stats first
        table_stats(Table_Owner(i), Table_Name(i));
        -- do the stats for all table columns if flag is yes
        if (column_stat = true) then
            for col_rec in all_columns(Table_Owner(i), Table_Name(i)) loop
                column_stats(col_rec.column_name, col_rec.num_distinct,
                col_rec.num_nulls, col_rec.density,
                col_rec.sample_size, col_rec.last_analyzed, first_col);
                first_col:= false;
            end loop;
        end if;
	    -- do the stats for all table indexes
        for index_rec in all_indexes(Table_Owner(i), Table_Name(i)) loop
		    if first_index = true then
			    index_header();
			    first_index := false;
		    end if;
	 	    index_stats(index_rec.owner, index_rec.index_Name);
        end loop;
        -- do the stats for all table histograms
        for histo_rec in all_histograms(Table_Owner(i), Table_Name(i)) loop
            if first_histo = true then
			    histo_header();
			    first_histo:= false;
		    end if;
            histo_stats(Table_Owner(i), Table_Name(i), histo_rec.column_name);
        end loop;
     END LOOP;
     file_tail();
EXCEPTION
    when verify_stats_exception then
	    dbms_output.put_line('verify_stats(schema_name varchar2 default null,
            table_list varchar2 default null, days_old number default null,
            column_stats boolean defualt false)');
end ;  /* end of verify_stats*/

begin
    -- Get the default DOP that will be used if none is provided.
    GET_PARALLEL(def_degree);
    dummybool := fnd_installation.get_app_info('FND',dummy1,dummy2,fnd_statown);

    --     select substr(version,1,instr(version,'.')-1)
    select replace(substr(version,1,instr(version,'.',1,2)-1),'.')
    into db_versn from v$instance;
    -- Initialize cur_request_id
    cur_request_id:=GET_REQUEST_ID;
--    dbms_output.put_line('Database version is '||db_versn);
EXCEPTION
  WHEN OTHERS THEN
   db_versn:=81;  -- Just in case, default it to 8i
end FND_STATS;
