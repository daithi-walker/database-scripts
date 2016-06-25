create or replace PACKAGE CEP_STANDARD AUTHID CURRENT_USER AS
/* $Header: ceseutls.pls 115.19 2003/12/18 20:50:31 bhchung ship $ */
/*----------------------------------------------------------------------------*
 | PUBLIC PROCEDURE                                                           |
 |    debug             - Display text message if in debug mode               |
 |    enable_debug      - Enable run time debugging                           |
 |    disable_debug     - Disable run time debugging                          |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    Generate standard debug information sending it to dbms_output so that   |
 |    the client tool can log it for the user.                                |
 |                                                                            |
 | REQUIRES                                                                   |
 |    line_of_text           The line of text that will be displayed.         |
 |                                                                            |
 | EXCEPTIONS RAISED                                                          |
 |                                                                            |
 | KNOWN BUGS                                                                 |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | HISTORY                                                                    |
 |    26 Mar 93  Nigel Smith      Created                                     |
 |    28 Jul 99  K Adams          Added option to either send it to a file or |
 |				  dbms_output. 				      |
 |                                If debug path and file name are passed,     |
 |                                it writes to the path/file_name instead     |
 |                                of dbms_output.                             |
 |                                                                            |
 *----------------------------------------------------------------------------*/
--
G_patch_level 	VARCHAR2(30) := '11.5.CE.J';

FUNCTION return_patch_level RETURN VARCHAR2;

procedure debug( line in varchar2 ) ;
procedure enable_debug( path_name in varchar2 default NULL,
			file_name in varchar2 default NULL);
procedure disable_debug( display_debug in varchar2 );
--
FUNCTION Get_Window_Session_Title RETURN VARCHAR2;
--
function get_effective_date(p_bank_account_id NUMBER,
			p_trx_code VARCHAR2,
			p_receipt_date DATE)  RETURN DATE;
PRAGMA RESTRICT_REFERENCES(get_effective_date, WNDS, WNPS );

END CEP_STANDARD;
/

create or replace PACKAGE CEP_STANDARD AUTHID CURRENT_USER AS
/* $Header: ceseutls.pls 115.19 2003/12/18 20:50:31 bhchung ship $ */
/*----------------------------------------------------------------------------*
 | PUBLIC PROCEDURE                                                           |
 |    debug             - Display text message if in debug mode               |
 |    enable_debug      - Enable run time debugging                           |
 |    disable_debug     - Disable run time debugging                          |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    Generate standard debug information sending it to dbms_output so that   |
 |    the client tool can log it for the user.                                |
 |                                                                            |
 | REQUIRES                                                                   |
 |    line_of_text           The line of text that will be displayed.         |
 |                                                                            |
 | EXCEPTIONS RAISED                                                          |
 |                                                                            |
 | KNOWN BUGS                                                                 |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | HISTORY                                                                    |
 |    26 Mar 93  Nigel Smith      Created                                     |
 |    28 Jul 99  K Adams          Added option to either send it to a file or |
 |				  dbms_output. 				      |
 |                                If debug path and file name are passed,     |
 |                                it writes to the path/file_name instead     |
 |                                of dbms_output.                             |
 |                                                                            |
 *----------------------------------------------------------------------------*/
--
G_patch_level 	VARCHAR2(30) := '11.5.CE.J';

FUNCTION return_patch_level RETURN VARCHAR2;

procedure debug( line in varchar2 ) ;
procedure enable_debug( path_name in varchar2 default NULL,
			file_name in varchar2 default NULL);
procedure disable_debug( display_debug in varchar2 );
--
FUNCTION Get_Window_Session_Title RETURN VARCHAR2;
--
function get_effective_date(p_bank_account_id NUMBER,
			p_trx_code VARCHAR2,
			p_receipt_date DATE)  RETURN DATE;
PRAGMA RESTRICT_REFERENCES(get_effective_date, WNDS, WNPS );

END CEP_STANDARD;
/

create or replace package body CEP_STANDARD AS
/* $Header: ceseutlb.pls 115.13 2003/11/03 23:17:01 bhchung ship $             */
/*-------------------------------------------------------------------------+
 |                                                                         |
 | PRIVATE VARIABLES                                                       |
 |                                                                         |
 +-------------------------------------------------------------------------*/

debug_flag varchar2(1) := null; -- 'F' for file debug and 'S' for screen debug

FUNCTION return_patch_level RETURN VARCHAR2 IS
BEGIN
  RETURN (G_patch_level);
END return_patch_level;


/*----------------------------------------------------------------------------*
 | PUBLIC PROCEDURE                                                           |
 |    debug      - Print a debug message                                      |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    Generate standard debug information sending it to dbms_output so that   |
 |    the client tool can log it for the user.                                |
 |                                                                            |
 | REQUIRES                                                                   |
 |    line_of_text           The line of text that will be displayed.         |
 |                                                                            |
 | EXCEPTIONS RAISED                                                          |
 |                                                                            |
 | KNOWN BUGS                                                                 |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | HISTORY                                                                    |
 |    12 Jun 95  Ganesh Vaidee    Created                                     |
 |    28 Jul 99  K Adams          Added option to either send it to a file or |
 |				  dbms_output.                                |
 |                                                                            |
 *----------------------------------------------------------------------------*/
procedure debug( line in varchar2 ) is
begin
  /* Bug 3234187 */
  if( FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
    FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
        'ce', line);
  end if;
/*
   if debug_flag = 'F' then
      ce_debug_pkg.debug( line );
   else
      null;
    --dbms_output.put_line( line );
   end if;
*/
end;
--
/*----------------------------------------------------------------------------*
 | PUBLIC PROCEDURE                                                           |
 |    enable_debug      - Enable run time debugging                           |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    Generate standard debug information sending it to dbms_output so that   |
 |    the client tool can log it for the user.                                |
 |                                                                            |
 | REQUIRES                                                                   |
 |                                                                            |
 | EXCEPTIONS RAISED                                                          |
 |                                                                            |
 | KNOWN BUGS                                                                 |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | HISTORY                                                                    |
 |    12 Jun 95  Ganesh Vaidee    Created                                     |
 |    28 Jul 99  K Adams          Added option to either send it to a file or |
 |				  dbms_output. 				      |
 |                                If debug path and file name are passed,     |
 |                                it writes to the path/file_name instead     |
 |                                of dbms_output.                             |
 |                                If AR is installed, it includes ar debug    |
 |                                messages, too.                              |
 |                                                                            |
 *----------------------------------------------------------------------------*/
procedure enable_debug( path_name in varchar2 default NULL,
			file_name in varchar2 default NULL) is

install		BOOLEAN;
status   	VARCHAR2(1);
industry 	VARCHAR2(1);

begin
    install := fnd_installation.get(222,222,status,industry);

    if (path_name is not null and file_name is not null) then
       debug_flag := 'F';
       ce_debug_pkg.enable_file_debug(path_name, file_name);
       if (status = 'I') then
	 arp_standard.enable_file_debug(path_name,file_name);
       end if;
    else
       debug_flag := 'S';
       if (status = 'I') then
	 arp_standard.enable_debug;
       end if;
    end if;
exception
  when others then
    raise;
end;
--
/*----------------------------------------------------------------------------*
 | PUBLIC PROCEDURE                                                           |
 |    disable_debug     - Disable run time debugging                          |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    Generate standard debug information sending it to dbms_output so that   |
 |    the client tool can log it for the user.                                |
 |                                                                            |
 | REQUIRES                                                                   |
 |                                                                            |
 | EXCEPTIONS RAISED                                                          |
 |                                                                            |
 | KNOWN BUGS                                                                 |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | HISTORY                                                                    |
 |    12 Jun 95  Ganesh Vaidee    Created                                     |
 |    28 Jul 99  K Adams          Added option to either send it to a file or |
 |				  dbms_output. 				      |
 |                                                                            |
 *----------------------------------------------------------------------------*/
procedure disable_debug (display_debug in varchar2) is

install		BOOLEAN;
status   	VARCHAR2(1);
industry 	VARCHAR2(1);

begin
  if display_debug = 'Y' then
    debug_flag := null;
    ce_debug_pkg.disable_file_debug;

    install := fnd_installation.get(222,222,status,industry);
    if (status ='I') then
	arp_standard.disable_debug;
        arp_standard.disable_file_debug;
    end if;
  end if;
exception
  when others then
    raise;
end;
--

FUNCTION Get_Window_Session_Title RETURN VARCHAR2 IS

  l_multi_org 		VARCHAR2(1);
  l_multi_cur		VARCHAR2(1);
  l_wnd_context 	VARCHAR2(80);
  l_id			VARCHAR2(15);

BEGIN

  /*
  ***
  *** Get multi-org and MRC information on the current
  *** prodcut installation.
  ***
   */
  SELECT 	nvl(multi_org_flag, 'N')
  ,		nvl(multi_currency_flag, 'N')
  INTO 		l_multi_org
  ,		l_multi_cur
  FROM		fnd_product_groups;


  /*
  ***
  *** Case #1 : Non-Multi-Org or Multi-SOB
  ***
  ***  A. MRC not installed, OR
  ***     MRC installed, Non-Primary/Reporting Books
  ***       Form Name (SPB Short Name) - context Info
  ***       e.g. Maintain Forecasts (US OPS) - Forecast Context Info
  ***
  ***  B. MRC installed, Primary Books
  ***       Form Name (SOB Short Name: Primary Currency) - Context Info
  ***       e.g. Maintain Forecasts (US OPS: USD) - Forecast Context Info
  ***  C. MRC installed, Report Books
  ***       Form Name (SOB Short Name: Reporting Currency) - Context Info
  ***       e.g. Maintain Forecasts (US OPS: EUR) - Forecast Context Info
  ***
  ***
   */
  IF (l_multi_org = 'N') THEN

    BEGIN
      select 	g.short_name ||
		  decode(g.mrc_sob_type_code, 'N', NULL,
                    decode(l_multi_cur, 'N', NULL,
		      ': ' || substr(g.currency_code, 1, 5)))
      into 	l_wnd_context
      from 	gl_sets_of_books g
      ,	 	ce_system_parameters c
      where	c.set_of_books_id = g.set_of_books_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        return (NULL);
    END;

  /*
  ***
  *** Case #2 : Multi-Org
  ***
  ***  A. MRC not installed, OR
  ***     MRC installed, Non-Primary/Reporting Books
  ***       Form Name (OU Name) - Context Info
  ***       e.g. Maintain Forecasts (US West) - Forecast Context Info
  **
  ***  B. MRC installed, Primary Books
  ***       Form Name (OU Name: Primary Currency) - Context Info
  ***       e.g. Maintain Forecast (US West: USD) - Forecast Context Info
  ***
  ***  C. MRC installed, Reporting Books
  ***       Form Name (OU Name: Reporting Currency) - Context Info
  ***       e.g. Maintain Forecast (US West: EUR) - Forecast Context Info
  ***
  ***
   */
  ELSE

    FND_PROFILE.GET ('ORG_ID', l_id);

    BEGIN
      select 	substr(h.name, 1, 53) ||
                  decode(g.mrc_sob_type_code, 'N', substr(h.name, 54, 7),
		    decode(l_multi_cur, 'N', substr(h.name, 54, 7),
                      ': ' || substr(g.currency_code, 1, 5)))
      into 	l_wnd_context
      from 	gl_sets_of_books g,
		ce_system_parameters c,
		hr_operating_units h
      where     h.organization_id = to_number(l_id)
      and       c.set_of_books_id = g.set_of_books_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN null;
    END;

  END IF;

  return l_wnd_context;

END Get_Window_Session_Title;

/*----------------------------------------------------------------------------*
 | PUBLIC PROCEDURE                                                           |
 |    get_effective_date						      |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    This is primarily for AR autolockbox interface. Calculates the          |
 |	effective date for receipts.                                          |
 |                                                                            |
 | REQUIRES                                                                   |
 |                                                                            |
 | EXCEPTIONS RAISED                                                          |
 |                                                                            |
 | KNOWN BUGS                                                                 |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | HISTORY                                                                    |
 |    29 Oct 1996	Bidemi Carrol		Created			      |
 |                                                                            |
 *----------------------------------------------------------------------------*/
function get_effective_date(p_bank_account_id NUMBER,
			p_trx_code VARCHAR2,
			p_receipt_date DATE) RETURN DATE IS
fd	ce_transaction_codes.float_days%TYPE;
begin
  select nvl(float_days,0)
  into fd
  from ce_transaction_codes ctc
  where ctc.trx_code = p_trx_code
  and   ctc.bank_account_id = p_bank_account_id;

 return (p_receipt_date + fd);
exception
  when others then
    return p_receipt_date;
end get_effective_date;

end CEP_STANDARD;
/