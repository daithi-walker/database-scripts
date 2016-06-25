PATCH related scripts
/* Query to find out if any patch except localisation patch is applied or not, if applied, that what all drivers it contain and time of it’s application*/ 

select A.APPLIED_PATCH_ID, A.PATCH_NAME, A.PATCH_TYPE, B.PATCH_DRVIER_ID, B.DRIVER_FILE_NAME, B.ORIG_PATCH_NAME, B.CREATION_DATE, B.PLATFORM, B.SOURCE_CODE, B.CREATIONG_DATE, B.FILE_SIZE, B.MERGED_DRIVER_FLAG, B.MERGE_DATE from AD_APPLIED_PATCHES A, AD_PATCH_DRIVERS B where A.APPLIED_PATCH_ID = B.APPLIED_PATCH_ID and A.PATCH_NAME = ‘’

/* To know that if the patch is applied successfully, applied on both node or not, start time of patch application and end time of patch application, patch top location , session id … patch run id */

select D.PATCH_NAME, B.APPLICATIONS_SYSTEM_NAME, B.NAME, C.DRIVER_FILE_NAME, A.PATCH_DRIVER_ID, A.PATCH_RUN_ID, A.SESSION_ID, A.PATCH_TOP, A.START_DATE, A.END_DATE, A.SUCCESS_FLAG, A.FAILURE_COMMENTS from AD_PATCH_RUNS A, AD_APPL_TOPS B, AD_PATCH_DRIVERS C, AD_APPLIED_PATCHES D where A.APPL_TOP_ID = B.APPL_TOP_ID AND A.PATCH_DRIVER_ID = C.PATCH_DRIVER_ID and C.APPLIED_PATCH_ID = D.APPLIED_PATCH_ID and A.PATCH_DRIVER_ID in (select PATCH_DRIVER_ID from AD_PATCH_DRIVERS where APPLIED_PATCH_ID in (select APPLIED_PATCH_ID from AD_APPLIED_PATCHES where PATCH_NAME = ‘’)) ORDER BY 3;


* To get file version of any application file which is changed through patch application */ 

select A.FILE_ID, A.APP_SHORT_NAME, A.SUBDIR, A.FILENAME, max(B.VERSION) from AD_FILES A, AD_FILE_VERSIONS B where A.FILE_ID = B.FILE_ID and B.FILE_ID = 86291 group by A.FILE_ID, A.APP_SHORT_NAME, A.SUBDIR, A.FILENAM

/* To get information related to how many time driver file is applied for bugs */ 

select * from AD_PATCH_RUN_BUGS where BUG_ID in (select BUG_ID from AD_BUGS where BUG_NUMBER = ‘’

/* To find latest patchset level for module installed */ 

select APP_SHORT_NAME, max(PATCH_LEVEL) from AD_PATCH_DRIVER_MINIPKS GROUP BY APP_SHORT_NAME

/* To find what is being done by the patch */ 

select A.BUG_NUMBER “Patch Number”, B. PATCh_RUN_BUG_ID “Run Id”,D.APP_SHORT_NAME appl_top, D.SUBDIR, D.FILENAME, max(F.VERSION) latest, E.ACTION_CODE action from AD_BUGS A, AD_PATCH_RUN_BUGS B, AD_PATCH_RUN_BUG_ACTIONS C, AD_FILES D, AD_PATCH_COMMON_ACTIONS E, AD_FILE_VERSIONS F where A.BUG_ID = B.BUG_ID and B.PATCH_RUN_BUG_ID = C.PATCH_RUN_BUG_ID and C.FILE_ID = D.FILE_ID and E.COMMON_ACTION_ID = C.COMMON_ACTION_ID and D.FILE_ID = F.FILE_ID and A.BUG_NUMBER = ‘’ and B.PATCH_RUN_BUG_ID = ‘ < > ‘ and C.EXECUTED_FLAG = ‘Y’ GROUP BY A.BUG_NUMBER, B.PATCH_RUN_BUG_ID, D. APP_SHORT_NAME, D>SUBDIR, D.FILENAME, E.ACTION_CODE

/* Second Query to know, what all has been done during application of PATCH */ 
Select J.PATCh_NAME, H.APPLICATIONS_SYSTEM_NAME Instance_Name, H.NAME, I.DRIVER_FILE_NAME, D.APP_SHORT_NAME appl_top, D.SUBDIR, D.FILENAME, max(F.VERSION) latest, E.ACTION_CODE action from AD_BUGS A, AD_PATCH_RUN_BUGS B, AD_PATCH_RUN_BUG_ACTIONS C, AD_FILES D, AD_PATCH_COMMON_ACTIONS E, AD_FILE_VERSIONS F, AD_PATCH_RUNS G, AD_APPL_TOPS H, AD_PATCH_DRIVERS I, AD_APPLIED_PATCHES J where A.BUG_ID = B.BUG_ID and B.PATCH_RUN_BUG_ID = C.PATCH_RUN_BUG_ID and C.FILE_ID = D.FILE_ID and E.COMMON_ACION_ID = C.COMMON_ACTION_ID and D.FILE_ID = F.FILE_ID and G.APPL_TOP_ID = H.APPL_TOP_ID and G.PATCH_DRIVER_ID = I.PATCH_DRIVER_ID and I.APPLIED_PATCH_ID = J.APPLIED_PATCH_ID and B.PATCH_RUN_ID = G.PATCH_RUN_ID and C.EXECUTED_FLAG = ‘Y’ and G.PATCH_DRIVER_ID in (select PATCH_DRIVER_ID from AD_PATCH_DRIVERS where APPLIED_PATCH_ID in (select APPLIED_PATCH_ID from AD_APPLIED_PATCHES where PATCH_NAME = ‘’)) GROUP BY J.PATCH_NAME, H.APPLICATINS_SYSTEM_NAME, H.NAME, I.DRIVER_FILE_BNAME, D.APP_SHORT_NAME, D.SUBDIR, D.FILENAME, E.ACTION_CODE


/* To find Merged patch Information from database in Oracle Applications */ 
select bug_number from ad_bugs where bug_id in ( select bug_id from ad_comprising_patches where patch_driver_id =(select patch_driver_id from ad_patch_drivers where applied_patch_id =&n) );

/* Script to find out Patch level of mini Pack */ 
Select product_version,patch_level from FND_PROUDCT_INSTALLATIONS where patch_level like ‘%&shortname%’;
Replace short name by name of Oracle Apps Minipack for which you want to find out Patch level . ex.
AD – for Applications DBA
GL – for General Ledger
PO – Purchase Order

Query to check .Autoconfig patch Level 

11i

SET head off Lines 120 pages 100
col p_num format A65
col bug_number format A10
col patch_name format A10
select bug_number, decode(bug_number,
'2488995' ,'11i.ADX.A'
,'2682177' ,'11i.ADX.B'
,'2682863' ,'11i.TXK-C'
,'2757379' ,'11i.TXK-D'
,'2902755' ,'11i.TXK-E'
,'3002409' ,'11i.ADX.C'
,'3104607' ,'11i.TXK-F'
,'3219567' ,'11i.TXK-B'
,'3239694' ,'11i.TXK-G'
,'3271975' ,'11i.ADX.E'
,'3416234' ,'11i.TXK-H'
,'3453499' ,'11i.ADX.F'
,'3594604' ,'11i.TXK-I'
,'3817226' ,'11i.ADX.E.1'
,'3950067' ,'11i.TXK-J'
,'4104924' ,'11i.TXK-K'
,'4367673' ,'11i.TXK-J.1'
,'4717668' ,'11i.TXK-M'
,'5035661' ,'11i.One_off'
,'5107107' ,'11i.TXK-N ROLLUP PATCH (AUG 2'
,'5414396 ' ,'11i RAPIDCLONE CONSOLIDATED FIXES JAN/2008 '
,'5456078' ,'11i.One_off_a'
,'5473858' ,'11i.ATG_PF.H RUP5'
,'5478710' ,'11i.TXK-O'
,'5759055' ,'11i.TXK-P'
,'5903765' ,'11i.ATG_PF.H RUP6'
,'5985992' ,'11i.TXK-Q'
) p_num, last_update_date
FROM ad_bugs
WHERE bug_number IN ( '2488995' ,'2682177' ,'2682863' ,'2757379' ,'2902755' ,'3002409' ,'3104607' ,'3219567' ,'3239694' ,'3271975' ,'3416234' ,'3453499' ,'3594604' ,'3817226' ,'3950067' ,'4104924' ,'4367673' ,'4717668' ,'5035661' ,'5107107' ,'5414396 ' ,'5456078' ,'5473858' ,'5478710' ,'5759055' ,'5903765' ,'5985992' ); 


R12

===


SET head off Lines 120 pages 100
col p_num format A65
col bug_number format A10
col patch_name format A10
spool LACF_ptch_level.txt
select ' LACF ' FROM dual;
/
select bug_number, decode(bug_number,
'4494373' ,'R12.TXK.A'
,'5872965' ,'R12.OAM.A'
,'5909746' ,'R12.TXK.A.1'
,'5917601' ,'R12.TXK.A.2'
,'6077487' ,'R12.TXK.A.DELTA.3'

,'6329757' ,'R12.TXK.A.DELTA.4'
,'6145693 ' ,'R12 RAPIDCLONE CONSOLIDATED FIXES JAN/2008'
) p_num, last_update_date
FROM ad_bugs
WHERE bug_number IN ( '4494373' ,'5872965' ,'5909746' ,'5917601' ,'6077487' ,'6145693 ','6329757' ); 


Query to check AD Patch level 

11i

==

SET head off Lines 120 pages 100
col p_num format A65
col bug_number format A10
col patch_name format A10


select bug_number, decode(bug_number,
'1351004' '11i.AD.A'
,'1460640' ,'11i.AD.B'
,'1475426' ,'11i.AD.C'
,'1627493' ,'11i.AD.D'
,'1945611' ,'11i.AD.E'
,'2141471' ,'11i.AD.F'
,'2344175' ,'11i.AD.G'
,'2673262' ,'11i.AD.H'
,'4038964' ,'11i.AD.I.1'
,'4229931' ,'11i.AD.I.2'
,'4337683' ,'11i.AD.I.2'
,'4502904' ,'11i.AD.I.3'
,'4605654' ,'11i.AD.I.4 Delta.4'
,'4712847' ,'11i.AD.I.3'
,'4712852' ,'11i.AD.I.4'
,'5161676' ,'11i.AD.I.5'
,'5161680' ,'11i.AD.I.5' 

,'6502079' ,'11i.AD.I.Delta.6' 

,'6502082' ,'11i.AD.I.6' 

) p_num, last_update_date
FROM ad_bugs
WHERE bug_number IN ( '1351004' '1460640' '1475426' '1627493' '1945611' '2141471' '2344175' '2673262' '4038964' '4229931' '4337683' '4502904' '4605654' '4712847' '4712852' '5161676' '5161680','6502079','6502082' ); 



R12

==



SET head off Lines 120 pages 100
col p_num format A65
col bug_number format A10
col patch_name format A10

select bug_number, decode(bug_number,
'4502962' 'R12.AD.A'
,'5905728' ,'R12.AD.A.1'
,'6014659' ,'R12.AD.A.2' 

,'6272715' ,'R12.AD.A.3' 

,'6510214' ,'R12.AD.A.4'
) p_num, last_update_date
FROM ad_bugs
WHERE bug_number IN ( '4502962' '5905728' '6014659','6272715','6510214' );


Query to Check ATG (Techstack) Patch level 

11i

===

SET head off Lines 120 pages 100
col p_num format A65
col bug_number format A10
col patch_name format A10
select bug_number, decode(bug_number,
'3438354', '11i.ATG_PF.H'
,'4017300' ,'11i.ATG_PF.H.RUP1'
,'4125550' ,'11i.ATG_PF.H.RUP2'
,'4334965' ,'11i.ATG_PF.H RUP3'
,'4676589' ,'11i.ATG_PF.H RUP4'
,'5382500' ,'11i.ATG_PF.H RUP5 HELP'
,'5473858' ,'11i.ATG_PF.H.5'
,'5674941' ,'11i.ATG_PF.H RUP5 SSO Integrat'
,'5903765' ,'11i.ATG_PF.H RUP6'
,'6117031' ,'11i.ATG_PF.H RUP6 SSO 10g Integration'
,'6330890' ,'11i.ATG_PF.H RUP6 HELP'
) p_num, last_update_date
FROM ad_bugs
WHERE bug_number
IN ( '3438354', '4017300', '4125550', '4334965', '4676589', '5382500', '5473858', '5674941', '5903765', '6117031', '6330890' );


R12
===
SET head off Lines 120 pages 100
col p_num format A65
col bug_number format A10
col patch_name format A10

select bug_number, decode(bug_number,
'5917344', 'R12.ATG_PF.A.DELTA.2',
'6077669', 'R12.ATG_PF.A.DELTA.3',
'6272680', 'R12.ATG_PF.A.DELTA.4 '
) p_num, last_update_date
FROM ad_bugs
WHERE bug_number
IN ('5917344', '6077669', '6272680');


Query to check Product patch levels 

set linesize 1000
column APPS format a10
select decode(nvl(a.APPLICATION_short_name,'Not Found'),
'SQLAP','AP','SQLGL','GL','OFA','FA',
'Not Found','id '||to_char(fpi.application_id),
a.APPLICATION_short_name) apps,
decode(fpi.status,'I','Installed','S','Shared',
'N','Inactive',fpi.status) status,
fpi.product_version,
nvl(fpi.patch_level,'-- Not Available --') Patchset,
to_char(fpi.last_update_date,'dd-Mon-RRRR') "Update Date"
from fnd_oracle_userid o, fnd_application a, fnd_product_installations fpi
where fpi.application_id = a.application_id(+)
and fpi.oracle_id = o.oracle_id(+)
order by 1,2
/

Running the following query will tell you which family pack of HRMS you are on in 11i.

SELECT ‘HR_PF.’ ||
DECODE (BUG_NUMBER,’2115771' ,’A(2115771)’,
‘2268451' ,’B(2268451)’,
‘2502761' ,’C(2502761)’,
‘2632500' ,’D(2632500)’,
‘2803988' ,’E(2803988)’,
‘2968701' ,’F(2968701)’,
‘3116666' ,’G(3116666)’,
‘3233333' ,’H(3233333)’,
‘3127777' ,’I(3127777)’,
‘3333633' ,’J(3333633)’,
‘3500000' ,’K(3500000)’,
‘5055050' ,’K RUP1(5055050)’,
‘5337777' ,’K RUP2(5337777)’,
‘6699770' ,’K RUP3(6699770)’,
‘7666111' ,’K RUP4(7666111)’) ||
‘ patchset is installed ‘ “HR Family Pack”,
to_char(last_update_date,’DD-MON-YYYY HH24:MI:SS’) “DATE APPLIED”
FROM AD_BUGS
WHERE BUG_NUMBER in (‘2115771',’2268451',’2502761',’2632500',’2803988',
‘2968701',’3116666',’3233333',’3127777',’3333633',’3500000', ‘5055050',
‘5337777',’6699770',’7666111')
ORDER BY BUG_NUMBER DESC
/


To find localization patches are applied.select * from jai_applied_patches where patch_number = 7361928;

How to check whether the product is install,shared and Not installed in Apps.
select t.application_name
, t.application_id
, i.patch_level
, decode(i.status,’I',’Fully Installed’,
‘N’,'Not Installed’,'S’,'Shared’,'Undetermined’) status
from fnd_product_installations i
, fnd_application_vl t
where i.application_id = t.application_id
order by t.application_id;


/* To find the latest application version */ 

select ARU_RELEASE_NAME||'.'||MINOR_VERSION||'.'||TAPE_VERSION version, START_DATE_ACTIVE updated,ROW_SOURCE_COMMENTS "how it is done", BASE_RELEASE_FLAG "Base version" FROM AD_RELEASES where END_DATE_ACTIVE IS NULL 


/* to find the base application version */ 

select ARU_RELEASE_NAME||'.'||MINOR_VERSION||'.'||TAPE_VERSION version, START_DATE_ACTIVE when updated, ROW_SOURCE_COMMENTS "how it is done" from AD_RELEASES where BASE_RELEASE_FLAG = 'Y' 


/* To find all available application version */ 

select ARU_RELEASE_NAME||'.'||MINOR_VERSION||'.'||TAPE_VERSION version, START_DATE_ACTIVE when updated, END_DATE_ACTIVE "when lasted", CASE WHEN BASE_RELEASE_FLAG = 'Y' Then 'BASE VERSION' ELSE 'Upgrade' END "BASE/UPGRADE", ROW_SOURCE_COMMENTS "how it is done" from AD_RELEASES

It shows patches applied to multiple application tiers - this sql shows if the 11.5.10.2 maintenance pack has been applied (patch number 3480000)

DECLARE
TYPE p_patch_array_type is varray(30) of varchar2(10);
p_patchlist p_patch_array_type;
p_appltop_name varchar2(50);
p_patch_status varchar2(15);
p_appl_top_id number;
p_result varchar2(15);
p_instance varchar2(15);
gvAbstract varchar2(240) := NULL;
CURSOR alist IS
select appl_top_id, name from ad_appl_tops;
procedure println(msg in varchar2)
is
begin
dbms_output.enable(1000000);
dbms_output.put_line(msg);
end;
BEGIN
select instance_name into p_instance from v$instance;
open alist;
p_patchlist:= p_patch_array_type('3480000');
LOOP
FETCH alist INTO p_appl_top_id,p_appltop_name;
EXIT WHEN alist%NOTFOUND;
IF p_appltop_name NOT IN ('GLOBAL','*PRESEEDED*')
THEN
println(p_appltop_name || ' - - - ' || p_instance );
println('=============================');
for i in 1..p_patchlist.count
loop
begin
select ABSTRACT into gvAbstract
from FND_UMS_BUGFIXES
where BUG_NUMBER = p_patchlist(i);
exception 
when NO_DATA_FOUND then
gvAbstract := NULL;
end;
p_patch_status := ad_patch.is_patch_applied('11i',p_appl_top_id,p_patchlist(i));
case p_patch_status 
when 'EXPLICIT' then 
p_result := 'APPLIED';
else 
p_result := p_patch_status;
end case;
println('Patch ' || p_patchlist(i)|| ' - ' || substr(gvAbstract,1,25) || ' - was ' || p_result);
end loop;
END if;
println('.');
END LOOP;
close alist;
END;
/

To check if specific bug fix is applied, you need to query the AD_BUGS table only. This table contains all patches and all superseded patches ever applied:

select ab.bug_number, ab.creation_date
from ad_bugs ab
where ab.bug_number = '&BugNumber';

Retrieve basic information regarding patch applied, useful when you need to know when and where (node) you applied specific patch:
select aap.patch_name, aat.name, apr.end_date
from ad_applied_patches aap,
ad_patch_drivers apd,
ad_patch_runs apr,
ad_appl_tops aat
where aap.applied_patch_id = apd.applied_patch_id
and apd.patch_driver_id = apr.patch_driver_id
and aat.appl_top_id = apr.appl_top_id
and aap.patch_name = '&PatchName';

Run the following query, it will show you all modules affected by specific patch in one click…
select distinct aprb.application_short_name as "Affected Modules"
from ad_applied_patches aap,
ad_patch_drivers apd,
ad_patch_runs apr,
ad_patch_run_bugs aprb
where aap.applied_patch_id = apd.applied_patch_id
and apd.patch_driver_id = apr.patch_driver_id
and apr.patch_run_id = aprb.patch_run_id
and aprb.applied_flag = 'Y'
and aap.patch_name = '&PatchName';

One of the ways to find out the exact patchset that was applied to your database successfully, is you can query from props$ table. This table is owner by sys. Logon as system or sys and select from props$ table. This table has fields like name, values and comments. The name columne NLS_RDBMS_VERSION has the value equilent to the patchset applied to that database.

SQL> select name, value$ from props$;
NAME VALUE$
NLS_RDBMS_VERSION 7.3.4.3.1

Query to find languages installed or not:

Select distinct NLS_LANGUAGE, LANGUAGE_CODE,NLS_TERRITORY,INSTALLED_FLAG
from fnd_languages
where INSTALLED_FLAG = 'I' or INSTALLED_FLAG = 'B'
ORDER BY NLS_LANGUAGE

Select distinct NLS_LANGUAGE, LANGUAGE_CODE,NLS_TERRITORY,INSTALLED_FLAG
from fnd_languages
ORDER BY NLS_LANGUAGE

Tech stack validation:
Ensure that your current working directory is 
patch unzipped location]/fnd/patch/115/bin 

on Unix or Linux:
Ensure "APPLRGF" variable is set in environment. If not, set it to the same value as "APPLTMP". 
./txkprepatchcheck.pl -script=ValidateRollup
-outfile=$APPLTMP/txkValidateRollup.html
-appspass=
or
./txkprepatchcheck.pl -script=ValidateRollup -outfile=$APPLTMP/txkValidateRollup.txt -reporttype=text -appspass=crepti12

Query to check customizations are affected by a patch
This script will read cr_customization.txt file
xx_custom=/local/dba/scripts_vis/cr_customization.txt
patch_loc=/patch11i/vis_patches/6329356
echo "checking for customizations under ${patch_loc}"
cd ${patch_loc}
cat ${xx_custom} | while read line
do
if [ "$line" != "" ];
then
grep -i "$line" /vis/applmgr/11510/admin/VIS/log/u5014514.drv.log

fi
done

To knowd all the patdhes applied from 01-Sep-2005 to 28-Jan-2006. i.e b/w 2 dates use
$AD_TOP/patch/115/sql/adpchlst.sql

To check to make sure the correct data was installed run the following script this script can also be used to check if datainstaller was run successfully: 
select application_short_name, Legislation_code, status, action, last_update_date 
from hr_legislation_installations 
where application_short_name in ('PER','PAY'); 

To check if DB version is 32 or 64 bit:
a.) conn to sqlplus if it is 64 ,then will show
b.)select address from v$sql where rownum<2;
c.)go to ORACLE_HOME/bin
do a file oracle.

Commands usefull during Patch analysis
select bug_number from ad_bugs where bug_number='&t';
select to_char(CREATION_DATE,'dd-mon-yyyy hh24:mi:ss') from ad_bugs where bug_number=’&t’; 
select to_char(LAST_UPDATE_DATE,'dd-mon-yyyy hh24:mi:ss')from ad_bugs where bug_number='&t’;
select patch_level from fnd_product_installations where patch_level like '&p';
select release_name from fnd_product_groups;
select DRIVER_FILE_NAME from ad_patch_drivers where DRIVER_FILE_NAME like '%3117672%';


For querrying the MERGED PATCHES you can use the following script which will show which merged patches are applied for which language 
select a.PATCH_DRIVER_ID,DRIVER_FILE_NAME,c.bug_id,d.language
from ad_patch_drivers a,AD_COMPRISING_PATCHES b, ad_bugs 
c,AD_PATCH_DRIVER_LANGS d
where c.bug_number = '&no'
and c.bug_id = b.bug_id
and a.PATCH_DRIVER_ID = b.patch_driver_id
and a.patch_driver_id = d.patch_driver_id; 

we can querry the ad_bugs for the US language version patches


To know which services are running on what nodes
select SUPPORT_CP,SUPPORT_FORMS,SUPPORT_WEB,SUPPORT_ADMIN from fnd_nodes;


To Know All the Drivers (NLS) language applied to Instance? 

col PATCH_NAME format a10
col PATCH_TYPE format a10
col DRIVER_FILE_NAME format a15
col PLATFORM format a10
select AP.PATCH_NAME, AP.PATCH_TYPE, AD.DRIVER_FILE_NAME, AD.CREATION_DATE, AD.PLATFORM,AL.LANGUAGE
from AD_APPLIED_PATCHES AP, AD_PATCH_DRIVERS AD, AD_PATCH_DRIVER_LANGS AL
where AP.APPLIED_PATCH_ID = AD.APPLIED_PATCH_ID
and AD.PATCH_DRIVER_ID = AL.PATCH_DRIVER_ID
and AP.PATCH_NAME = '&No';"

select aap.patch_name,count(*) from AD_patch_driver_langs apdl, ad_applied_patches aap, AD_PATCH_DRIVERS apd 
where apdl.patch_driver_id=apd.patch_driver_id and 
aap.applied_patch_id=apd.applied_patch_id and 
apdl.language <>'US' 
group by aap.patch_name 
having count(*) > 0 and count(*)<10 -- Changed from 9 to 10 
order by patch_name"

To see NLS patches applied:
select language,driver_file_name from AD_PATCH_DRIVERS adp,AD_PATCH_DRIVER_LANGS adpl where adp.patch_driver_id = adpl.patch_driver_id 
and driver_file_name like '%&a%' order by 1;

Script for Patch Log Analysis :
@$AD_TOP/patch/115/sql/adphrept.sql 1 ALL ALL 03/01/2004 07/05/2004 ALL ALL ALL ALL ALL N N N N N sample.txt 


To know patches applied
select distinct(patch_name) from ad_applied_patches 

AD Patches Tables
AD_APPLIED_PATCHES
AD_PATCH_DRIVERS
AD_PATCH_RUNS
AD_APPL_TOPS
AD_RELEASES 
AD_FILES
AD_FILE_VERSIONS
AD_PATCH_RUN_BUGS
AD_BUGS
AD_PATCH_COMMON_ACTIONS 
AD_PATCH_RUN_BUG_ACTIONS
ad_comprising_patches 

FND Tables
FND_APPL_TOPS 
FND_LOGINS 
FND_USER 
FND_DM_NODES 
FND_TNS_ALIASES 
FND_NODES 
FND_RESPONSIBILITY 
FND_DATABASES 
FND_UNSUCCESSFUL_LOGINS 
FND_LANGUAGES 
FND_APPLICATION 
FND_PROFILE_OPTION_VALUES


To know which driver patch has been applied:
select DRIVER_FILE_NAME from AD_PATCH_DRIVERS;
select DRIVER_FILE_NAME from AD_PATCH_DRIVERS where DRIVER_FILE_NAME like '%2408149%';


To check if multicurrency is present
select MULTI_CURRENCY_FLAG from fnd_product_groups;
M
-
Y

Purging timing information for prior sessions.
sqlplus -s APPS/***** @$AD_TOP/admin/sql/adtpurge.sql 10 1000

Snapshot sql
sqlplus -s &un_apps/***** @$AD_TOP/patch/115/sql/adbkflsn.sql 111

Maintenance mode
$AD_TOP/patch/115/sql/adsetmmd.sql ENABLE
$AD_TOP/patch/115/sql/adsetmmd.sql DISABLE
select fnd_profile.value('APPS_MAINTENANCE_MODE') from dual;
FND_PROFILE.VALUE('APPS_MAINTENANCE_MODE')
--------------------------------------------------------------------------------
MAINT


to check the product is registered
select * from applsys.fnd_application where application_short_name='BNE';


adutconf.sql --- script used to generate Oracle Applications Database Configuration Report
Location : $AD_TOP/sql/adutconf.sql
Output : $AD_TOP/sql/adutconf.lst

PRODUCT VERSIONS (AD,PO,....)
select patch_level from fnd_product_installations where patch_level like '%&PRODUCT_NAME%'; 
select PATCH_LEVEL from fnd_product_installations where PATCH_LEVEL like '%AD%';
select PATCH_LEVEL,status from fnd_product_installations where PATCH_LEVEL like '%ICX%';

applying opatch without inventory
opatch apply -no_inventory
$ORACLE_HOME/cfgtoollogs/opatch/opatch-2009_Oct_29_22-33-37-CST_Thu.log --> opatch log location


To find opatch version:
/OPatch/ 
./opatch version


opatch options:
$ opatch prereq CheckConflictAgainstOHWithDetail -phBaseDir ./9352164
opatch apply -local: apply patch only on local node in clusterdatabase environment
opatch apply -jdktop : if opatch could not find the path of jdk
opatch apply -no_inventory : Apply patch without updating inventory

to find the opatch that are installed
cd /OPatch/.patch_storage

OR cd /unioac/oracle/product/920/OPatch/ 
./opatch lsinventory
If it fails please check the path is correct in /etc/oraInst.loc or /var/opt/oracle/oraInst.loc

From CPUJan2006 onwards, for the OPatch installed CPU’s it is possible to do the following 
select * from registry$history;

ACTION_TIME ACTION NAMESPACE VERSION ID COMMENTS
—————————- —— ——— ———- ——— ———-
09-MAY-07 07.17.43.371379 AM CPU SERVER 10.2.0.2.0 5689957 CPUJan2007"

CPU will create directories and files like %ORACLE_HOME%\cpu\CPUOct2005\patch.log or $ORACLE_HOME/cpu/CPUOct2005/install.log

Syntax to merge set of patches
admrgpch -s temp -d 3171663_NLS
admrgpch -s merge_nov11 -d merge_cnv1_nov11 -logfile merge_cnv1_nov11.log


To know products and patches present in system
/SQL/adutconf.lst



adpatch options
Adpatch no longer checks for prerequisite patches as part of the patch
to force this check:
adpatch options=prereqs

To see what the patch does without applying it (a good idea when
patching in a production environment)
adpatch apply=no"

To bypass the irritating maintenance mode requirement run:
adpatch options=hotpatch"

How do you hide apps password during adpatching?
Ans:
adpatch flags=hidepw"
adpatch options=noprereq
adpatch options=nocopyportion,nogenerateportion i.e to apply only database portion of u driver on db/admin node
options=nocompilejsp
on admin1 opations=nocompiledb, on admin 2 options=nocompiledb,nodatabaseportion, on web1 options=nocompiledb,nodatabaseportion, on web2 options=nocompiledb,nodatabaseportion
opatch options=nofilecheck (for not checking version of patch in database from ad_patch_version table
adpatch options=nodatabaseportion ( this is required while applying patches on external nodes )
adpatch options=nodatabaseportion,nocompiledb,nocompilejsp,norevcache

adpatch options :

adpatch options=nocompilejsp
adpatch options=forcecopy
adpatch options=noprereq,hotpatch,nocompilejsp

adpatch options = ""hotpatch,noautoconfig,nocompilejsp"".
adpatch options = ""hotpatch,nodatabaseportion,nocompilejsp,noautoconfig"".

adpatch options=nocheckfile,hotpatch,nocopyportion,nogenerateportion
adpatch options = ""novalidate""

On external Webnode:
adpatch options=nogenerateportion,nodatabaseportion"

Verify that you do not want to restart the previous failed session.
Start AutoPatch with the abandon=yes option:
UNIX:
$ adpatch defaultsfile=$APPL_TOP/admin/testdb1/def.txt logfile=7654321.log \
patchtop=$APPL_TOP/patches/7654321 driver=c7654321.drv workers=3 \
interactive=no abandon=yes



Create the defaults file 
adpatch defaultsfile=$APPL_TOP/admin/testdb1/adpatchdef.txt

Create Defaultsfile.txt

adpatch defaultsfile=$APPL_TOP/admin/$TWO_TASK/defaults.txt

( You can keep this txt file in any location of your choice)
Now abort autopatch section at point where it asks for patch directory by ctrl +c or ctrl+d
Now check if this file exists
You have to do above steps only once in an environment to create defaults file.
====================================
Apply as per below-

time adpatch \
defaultsfile=$APPL_TOP/admin/$TWO_TASK/defaults.txt \
logfile=u5394384.log \
patchtop=/d31/app/upgrade_115102/BASE_PATCHES/5394384 \
driver=u5394384.drv \
workers=8 \
interactive=yes \
abandon=yes


R12
PAA helps users to track and perform manual steps during patching Executed by invoking
$AD_TOP/bin/admsi.pl…
When patches are merged using admrgpch, PAA merges readme files and this avoids redundant tasks. Also it simplifies patch application by combining all manual steps


To find some products patch level

ATG rollup patch level by pointing your browser to this URL -> http://hostname:port/OA_HTML/OAInfo.jsp

How to Find iReceviables Patchset Level on 11i Instance [ID 263942.1]
[ID 307564.1] 

How to Find iReceviables Patchset Level on 11i Instance [ID 263942.1]

How To Determine Which HZ-Trading Community Architecture (TCA), Oracle Customers Online (IMC), Oracle Credit Management (OCM), TAX (AR), CUs And Framework 

(FWK) Patchset Has Been Applied? [ID 262680.1]



Change the Patch Wizard directory patch
Login to OAM

Navigate to Patch Wizard and then click Go Button
Under Patch Wizard Tasks you will find the below along with 3 more task names
Task Name 
Patch Wizard Preferences 

Click the Icon under Tasks 

then change the value of Staging directory from /d01/applmgr/prodappl/pwizard to the /d01/apreprod/preprodappl/pwizard

you trace 10.1.0.6 OUI by running the following command
/usr/bin/truss -aefo /tmp/oui.trc ./runInstaller 

// This will bypass the OS check //

runInstaller eg
$ JAVA_HOME=/u01/app/oracle/product/jdk1.6.0_16; export JAVA_HOME 

$ ./runInstaller -jreLoc $JAVA_HOME

runInstaller -ignoreSysPrereqs

Query used to view the patch level status of all modules 
SELECT a.application_name, 
DECODE (b.status, 'I', 'Installed', 'S', 'Shared', 'N/A') status, 
patch_level 
FROM apps.fnd_application_vl a, apps.fnd_product_installations b 
WHERE a.application_id = b.application_id; 

Check Current Applied Patch 
SELECT patch_name, patch_type, maint_pack_level, creation_date 
FROM applsys.ad_applied_patches 
ORDER BY creation_date DESC

To know if OTA is running or not:
@$ECX_TOP/patch/115/sql/ecxver.sql

patchsets.sh
ftp://oracle-ftp.oracle.com/apps/patchsets/PATCHSET_COMPARE_TOOL/patchsets.sh
ftp ftp.oracle.com 
login as an anonymous user, and then: 
cd support/outgoing/PATCHSET_COMPARE_TOOL
mget patchsets.sh