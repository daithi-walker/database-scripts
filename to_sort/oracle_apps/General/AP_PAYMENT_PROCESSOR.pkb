create or replace PACKAGE BODY AP_PAYMENT_PROCESSOR AS
/*$Header: appprocb.pls 115.40 2010/01/15 10:48:07 anarun noship $*/

STRING_START_DELIM	      CONSTANT	VARCHAR2(30) := 'Payment_batch:' ;
STRING_END_DELIM   	      CONSTANT	VARCHAR2(30) := 'End_of_List' ;
PROGRAM_START_DELIM           CONSTANT	VARCHAR2(30) := '<<##Program_Name:' ;
PROGRAM_END_DELIM	      CONSTANT	VARCHAR2(30) := '##>>' ;
PARAM_STRING_START_DELIM      CONSTANT	VARCHAR2(30) := '##Parameters::' ;
PARAM_NAME_END_DELIM	      CONSTANT	VARCHAR2(30) := ':' ;
PARAM_VALUE_END_DELIM	      CONSTANT	VARCHAR2(30) := '#*' ;

STRING_START_DELIM_LEN	      CONSTANT	NUMBER	     := length(STRING_START_DELIM);
STRING_END_DELIM_LEN	      CONSTANT  NUMBER	     := length(STRING_END_DELIM);
PROGRAM_START_DELIM_LEN	      CONSTANT  NUMBER	     := length(PROGRAM_START_DELIM);
PROGRAM_END_DELIM_LEN	      CONSTANT  NUMBER	     := length(PROGRAM_END_DELIM);
PARAM_STRING_START_DELIM_LEN  CONSTANT  NUMBER	     := length(PARAM_STRING_START_DELIM);
PARAM_NAME_END_DELIM_LEN      CONSTANT  NUMBER	     := length(PARAM_NAME_END_DELIM);
PARAM_VALUE_END_DELIM_LEN     CONSTANT	NUMBER	     := length(PARAM_VALUE_END_DELIM);

P_Param_Name_List             Param_Name_List;
P_Param_Value_List	      Param_Value_List;
Progs_Params_List	      VARCHAR2(2000);

PROCEDURE submit_sub_program(
     P_p_request_id               OUT NOCOPY    NUMBER,
     P_program                    IN     VARCHAR2,
     P_payment_batch              IN     VARCHAR2,
     P_param_name_list            IN OUT NOCOPY Param_Name_list,
     P_param_value_list           IN OUT NOCOPY Param_Value_list,
     No_of_Parameters		  IN     NUMBER,
     P_org_id			  IN     NUMBER,
     P_event                      IN     VARCHAR2) ;


FUNCTION get_program_short_name
    (P_program                    IN     VARCHAR2,
     P_payment_batch              IN     VARCHAR2) RETURN VARCHAR2;

FUNCTION get_execution_method
    (P_program_short_name         IN     VARCHAR2) RETURN VARCHAR2;

FUNCTION get_parameter_value
    (P_Parameter_Name             IN     VARCHAR2) RETURN VARCHAR2;

PROCEDURE delete_parameter_and_value
    (P_Parameter_Name             IN     VARCHAR2);

PROCEDURE insert_conc_req
    (P_payment_batch              IN     VARCHAR2,
     P_request_id                 IN     NUMBER,
     P_program                    IN     VARCHAR2);

PROCEDURE set_printer
    (P_printer_name               IN     VARCHAR2,
     P_save_output_flag	          IN     VARCHAR2,
     P_program                    IN     VARCHAR2); -- Bug 4200601 parameter
                                                    -- added

FUNCTION is_program_srs
    (P_program_short_name         IN     VARCHAR2) RETURN VARCHAR2;


FUNCTION fnd_request_api
    (P_program_name	          IN      VARCHAR2,
     P_program_short_name         IN      VARCHAR2,
     P_param_name_list            IN      Param_Name_List,
     P_param_value_list           IN      Param_Value_List,
     P_Parameter_Passing_Style	  IN      VARCHAR2,
     No_of_parameters		  IN      NUMBER) RETURN NUMBER;


PROCEDURE set_batch_status
    (p_payment_batch              IN      VARCHAR2,
     program_name                 IN      VARCHAR2,
     p_status                     IN      VARCHAR2 );


request_submission_failure        EXCEPTION;
request_failed			  EXCEPTION;
cannot_set_printer                EXCEPTION;
No_Program_Exists	          EXCEPTION;


PROCEDURE initialize(P_Payment_Batch VARCHAR2) IS
BEGIN

  Progs_Params_List := NULL;
  Progs_Params_List := String_Start_Delim ||P_Payment_Batch ;

END initialize;



PROCEDURE append_program(P_program_name VARCHAR2) IS

l_length NUMBER;
BEGIN

 --Check if this is the first program being appended,
 --if so remove the String end delimiter
 IF(INSTR(Progs_Params_List,program_start_delim) <> 0 ) THEN

   l_length := length(Progs_Params_List) - String_End_Delim_Len ;

   Progs_Params_List := SUBSTR(Progs_Params_List,1,l_length);

   Progs_Params_List := Progs_Params_List || Program_Start_Delim
			 || P_program_name ||Param_String_Start_Delim
			 ||Program_End_Delim || String_End_Delim ;
 ELSE

   Progs_Params_List := Progs_Params_List || Program_Start_Delim
			 || P_program_name ||Param_String_Start_Delim
			 ||Program_End_Delim || String_End_Delim ;

 END IF;

END append_program;


PROCEDURE append_parameter(P_Parameter_Name VARCHAR2,
			   P_Parameter_Value VARCHAR2) IS

l_length   NUMBER;
BEGIN


 --Check if any programs exist, for the parameters to be appended.
 IF(INSTR(Progs_Params_List,PROGRAM_START_DELIM) <> 0) THEN

      --Delete the PROGRAM_END_DELIM and STRING_END_DELIM,before appending the
      --parameter and parameter_value to the list.

      l_length := length(Progs_Params_List) -
			(String_End_Delim_Len + Program_End_Delim_Len) ;

      Progs_Params_List := SUBSTR(Progs_Params_List,1,l_length);

      --Append the parameter and  parameter_value to the list
      Progs_Params_List := Progs_Params_List || P_Parameter_Name
			     || Param_Name_End_Delim ||P_Parameter_Value
		 	     || Param_Value_End_Delim ||Program_End_Delim
			     || String_End_Delim;


 ELSE

      RAISE No_Program_Exists;

 END IF;

END append_parameter;


PROCEDURE delete_program(P_program_name VARCHAR2) IS

 Start_of_program NUMBER;
 End_of_program NUMBER;

BEGIN

  Start_of_program := INSTR(Progs_Params_List,P_program_name) -
			        Program_Start_Delim_Len ;

  End_of_program := INSTR(Progs_Params_List,Program_End_Delim ,Start_of_program) +
				Program_End_Delim_Len ;

  Progs_Params_List := SUBSTR(Progs_Params_List,1, Start_of_program - 1) ||
				SUBSTR(Progs_Params_List,End_of_program);

END delete_program;



FUNCTION get_program_name(P_occurrence IN NUMBER ) RETURN VARCHAR2 IS
 l_program_name VARCHAR2(80);
 l_start        NUMBER;
 l_length       NUMBER;

BEGIN

  l_start := INSTR(Progs_Params_list ,Program_Start_Delim,1,P_occurrence) +
							Program_Start_Delim_Len ;

  l_length := INSTR(Progs_Params_list,Param_String_Start_Delim,l_start)- l_start ;

  l_program_name := SUBSTR(Progs_Params_list,l_start,l_length);

  return(l_program_name);

END get_program_name;


PROCEDURE get_parameters(P_program_name      IN  VARCHAR2,
			 P_progs_params_list IN VARCHAR2,
			 P_param_name_list   OUT NOCOPY Param_Name_List,
			 P_param_value_list  OUT NOCOPY Param_Value_List,
			 No_of_Parameters    OUT NOCOPY NUMBER) IS
  parameter_length NUMBER := 0 ;
  p_index_name_and_value VARCHAR2(200);
  l_index NUMBER := 0;
  l_start NUMBER;
  l_length NUMBER;
  l_sqlerrm VARCHAR2(200);
  is_first_occurence_program VARCHAR2(1) := 'Y';
  -- Bug 5220404  added below variables
  temp_p_program_name VARCHAR2(80) := NULL;
  l_prog_occurance  NUMBER := 0;

BEGIN

     --Bug fix:1883279 Need to intialize the parameter list so that
     --value from the previous sub program are not passed to the
     --next program.

     FOR i in 0..20 LOOP
	 P_param_name_list(i) := NULL;
	 P_param_value_list(i) := NULL;
     END LOOP;

    -- Bug 5220404 has changed the code below so that the position
    --of program name can be tracked correctly
    -- The payment process manager should not end up in error
    --in case  the program name occurs anywhere else in the parameter list
     temp_P_program_name:=PROGRAM_START_DELIM||P_program_name;

     Select DECODE(INSTR(P_Progs_Params_List,temp_P_program_name),0,0,
            INSTR(P_Progs_Params_List,temp_P_program_name)+PROGRAM_START_DELIM_LEN)
     into  l_prog_Occurance
     from dual;


     l_start := l_prog_Occurance + length(p_program_name)
                             + Param_String_Start_Delim_Len + parameter_length;


     LOOP
       --Exit the loop when you encounter the Program_End_Delim.

       EXIT WHEN(SUBSTR(P_Progs_Params_List,l_start,Program_End_Delim_Len)
					                   = Program_End_Delim);
      l_start := l_prog_occurance + length(p_program_name)
                             + Param_String_Start_Delim_Len + parameter_length ;

       l_length := INSTR(P_Progs_Params_List,Param_Value_End_Delim,l_start)-
								l_start ;

       p_index_name_and_value := SUBSTR(P_Progs_Params_List,l_start,l_length);

       p_param_name_list(l_index) := SUBSTR(p_index_name_and_value,1,
			   INSTR(p_index_name_and_value,Param_Name_End_Delim) - 1);

       p_param_value_list(l_index) := SUBSTR(p_index_name_and_value,
				       length(p_param_name_list(l_index)) +
						  Param_Name_End_Delim_Len + 1);

       parameter_length := parameter_length + length(p_index_name_and_value) +
							Param_Value_End_Delim_Len ;

       l_index := l_index + 1 ;


   END LOOP;

       No_of_parameters := l_index - 1 ;

  EXCEPTION
   WHEN OTHERS THEN
     IF (SQLCODE <> -20001 ) THEN
      FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      l_sqlerrm := SQLERRM;
    END IF;
   APP_EXCEPTION.RAISE_EXCEPTION;

END get_parameters;


--Function to get the value of a parameter from the Global List
--Progs_Params_List,when Parameter name is passed to it.
FUNCTION get_parameter_value(P_Parameter_Name   IN  VARCHAR2) RETURN VARCHAR2 IS

l_current_calling_sequence VARCHAR2(200);
i NUMBER := 0;

BEGIN

 l_current_calling_sequence := 'AP_PAYMENT_PROCESSOR.get_parameter_value';

 i:= P_param_name_list.FIRST;

 LOOP


  IF(P_param_name_list(i) = P_Parameter_Name) THEN

     return(P_param_value_list(i));

  END IF;

  EXIT WHEN( i = P_param_name_list.LAST);
  i := P_param_name_list.NEXT(i);

 END LOOP;
 return(NULL);

 EXCEPTION
  WHEN OTHERS THEN
   IF (SQLCODE <> -20001 ) THEN
    FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
    FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
    FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_current_calling_sequence);
    FND_MESSAGE.SET_TOKEN('PARAMETERS','P_Parameter_Name ='||P_parameter_name);
   END IF;

  APP_EXCEPTION.RAISE_EXCEPTION;

END get_parameter_value;



PROCEDURE delete_parameter_and_value(P_Parameter_Name IN VARCHAR2) IS

 Parameter_found   BOOLEAN := FALSE;
 l_current_calling_sequence   VARCHAR2(200);
 i NUMBER :=0;
BEGIN

  l_current_calling_sequence := 'AP_PAYMENT_PROCESSOR.delete_parameter_and_value';

  LOOP

    IF(P_param_name_list(i) = P_Parameter_Name) THEN
      Parameter_found := TRUE;
    END IF;

    EXIT WHEN (i = P_param_name_list.LAST OR parameter_found);
    i := i + 1;

  END LOOP;

  IF(parameter_found) THEN
    P_param_name_list.delete(i);
    P_param_value_list.delete(i);

  END IF;

  EXCEPTION
   WHEN OTHERS THEN
    IF (SQLCODE <> -20001 ) THEN

      FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_current_calling_sequence);
      FND_MESSAGE.SET_TOKEN('PARAMETERS','P_Parameter_Name ='||P_parameter_name);

    END IF;

  APP_EXCEPTION.RAISE_EXCEPTION;

END delete_parameter_and_value;


--Procedure to submit the parent concurrent program.
--This procedure is called from the client(APXPAWKB ,apbsetlb.pls..)
PROCEDURE submit(
      ERRBUF                         OUT NOCOPY    VARCHAR2,
      RETCODE                        OUT NOCOPY    NUMBER,
      P_org_id                       IN     NUMBER     DEFAULT NULL,
      P_event                        IN     VARCHAR2   DEFAULT NULL,
      P_calling_sequence	     IN     VARCHAR2   DEFAULT NULL) IS
l_current_calling_sequence	VARCHAR2(2000);
l_debug_info			VARCHAR2(100);
l_programs_list			VARCHAR2(2000);
l_payment_batch			VARCHAR2(100);
next_occurrence			NUMBER :=1;
l_count				NUMBER :=1;
l_errbuf			VARCHAR2(200);
l_request_id			NUMBER := 0;
TYPE PROGS_PARAMS_LIST_TABLE IS TABLE OF VARCHAR2(240)
 INDEX BY BINARY_INTEGER;
l_progs_params_list             PROGS_PARAMS_LIST_TABLE;
no_of_args 			NUMBER;
l_start				NUMBER := 1;
l_start_c			NUMBER := 1;
l_i				NUMBER := 0;
l_len_c				NUMBER;
l_param_len			NUMBER;
l_msg				VARCHAR2(2000);
l_icx_numeric_characters   VARCHAR2(30); -- 5854067
l_return_status   boolean;  -- 5854067
BEGIN

	-- Update the calling sequence
        --
	l_current_calling_sequence := P_calling_sequence||'->'||
					'AP_PAYMENT_PROCESSOR.submit';

        l_debug_info := 'Get the count of programs submitted .';

	LOOP

	   EXIT WHEN(INSTR(Progs_Params_List,PROGRAM_START_DELIM,1,l_count) = 0);
           l_count :=l_count+1;

        END LOOP;

	l_debug_info := 'Get the Payment_Batch name .';

        l_payment_batch := SUBSTR(Progs_Params_List,string_start_delim_len+1,
                            INSTR(Progs_Params_List,PROGRAM_START_DELIM,1,1)-
					     (string_start_delim_len+1));

	-----------------------------------------------------------
	-- To get all the programs that have to be submitted
	-- and build a string of just the programs.
	-----------------------------------------------------------
	LOOP

  	   BEGIN


	     EXIT WHEN(next_occurrence > l_count - 1);

	     l_programs_list := l_programs_list||get_program_name(next_occurrence);
	     next_occurrence := next_occurrence + 1;

 	   END;

	END LOOP;

	--------------------------------------------------------------
	--Split up the global string into multiple strings of
	--length 240,since Fnd_Request.Submit_Request API
	--does not allow variable values of more than 240 characters.
	--------------------------------------------------------------

	l_debug_info := 'Break up the global list into strings of length 240 .';

	FOR i in 0..8 LOOP

	  l_progs_params_list(i) := NULL;

        END LOOP;

	l_param_len := LENGTHB(progs_params_list);

	l_i := 0;

        LOOP

	  EXIT WHEN l_start > l_param_len OR l_i >= 9;

	  -- Bug 2054815: Check if the 240th byte of the string is
	  -- the first byte of a multi-byte character.
	  l_len_c := LENGTH(SUBSTRB(progs_params_list,l_start,240));
	  --bug 3778135
	  --We reduce the length here so that length is less than 240 bytes.
	  --But this reduction can't be done by 1.Instead a loop is written till
	  -- the length is less than 240.

	/*  IF LENGTHB(SUBSTR(progs_params_list,l_start_c,l_len_c)) > 240 THEN
	    -- Yes, it is the first byte of a multi-byte character.
	    -- The string should not be broken up here.
	    l_len_c := l_len_c - 1;
	  END IF;*/

	  while (LENGTHB(SUBSTR(progs_params_list,l_start_c,l_len_c)) > 240)
	  loop
	    -- Yes, it is the first byte of a multi-byte character.
	    -- The string should not be broken up here.
	    l_len_c := l_len_c -1;
 	  END loop;

	  -- Bug 2108392: If the last character is space, it is trimmed by
	  -- submit_request and doesn't work.  Trim the trailing spaces and
	  -- bring it to the beginning of the next line.
	  l_progs_params_list(l_i) := RTRIM(SUBSTR(progs_params_list,l_start_c,l_len_c));

	  -- Bug 2054815 and 2108392: Count the length of the parameter
	  -- both in bytes and character so that substr and substrb work.
	  l_start_c := l_start_c + LENGTH(l_progs_params_list(l_i));
	  l_start := l_start + LENGTHB(l_progs_params_list(l_i));
	  l_i := l_i + 1;

        END LOOP;
        --below code added for 5854067 as we need to set the current nls character setting
        --before submitting a child requests.
        fnd_profile.get('ICX_NUMERIC_CHARACTERS',l_icx_numeric_characters);
        l_return_status:= FND_REQUEST.SET_OPTIONS( numeric_characters => l_icx_numeric_characters);

	l_debug_info := 'Submit the parent concurrent process .';

        l_request_id := fnd_request.submit_request(
			           'SQLAP',
 			           'APPPRSPR',
			           NULL,NULL,FALSE,
				   l_progs_params_list(0),
				   l_progs_params_list(1),
				   l_progs_params_list(2),
				   l_progs_params_list(3),
				   l_progs_params_list(4),
				   l_progs_params_list(5),
				   l_progs_params_list(6),
				   l_progs_params_list(7),
				   l_progs_params_list(8),
			           l_payment_batch,
				   l_programs_list,
			           P_org_id,
			           P_event,
				   l_current_calling_sequence,
			           chr(0), '', '', '', '', '', '', '', '',
		                   '', '', '', '', '', '', '', '', '', '',
		                   '', '', '', '', '', '', '', '', '', '',
		                   '', '', '', '', '', '', '', '', '', '',
	                           '', '', '', '', '', '', '', '', '', '',
		                   '', '', '', '', '', '', '', '', '', '',
		                   '', '', '', '', '', '', '', '', '', '',
		                   '', '', '', '', '', '', '', '', '', '',
				   '', '', '', '', '', '');

 --bug 3617640
 IF(l_request_id <> 0) THEN
   --Store the request_id in the appropriate table
   IF p_event = 'BATCH_PROCESS' THEN
	 UPDATE ap_invoice_selection_criteria
         SET  request_id = l_request_id
         WHERE checkrun_name = l_payment_batch
 	 AND org_id = p_org_id;
   ELSIF p_event = 'PAY_PROCESS' THEN
	 UPDATE ap_checks
         SET  request_id = l_request_id
         WHERE checkrun_name = l_payment_batch
   	 AND org_id = p_org_id;
   END IF;

   commit;

   retcode := l_request_id;
   errbuf := 'Successful completion';
   return;

 ELSE
  RAISE Request_Submission_Failure;
 END IF;

 EXCEPTION
 WHEN request_submission_failure THEN
   l_msg := FND_MESSAGE.GET;
   FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
   FND_MESSAGE.SET_TOKEN('ERROR',l_msg);
   FND_MESSAGE.SET_TOKEN('PARAMETERS',
			 ',P_org_id='||to_char(p_org_id)
			 ||',P_event='||p_event);
   FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_current_calling_sequence);
   retcode := 2;
   FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);

   errbuf := 'Request Submission Failed';
   RETURN;

 WHEN OTHERS then
  IF (SQLCODE <> -20001 ) THEN
    FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
    FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
    FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_current_calling_sequence);
    FND_MESSAGE.SET_TOKEN('PARAMETERS','Request ID = '||TO_CHAR(l_request_id));
    FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
 END IF;

 APP_EXCEPTION.RAISE_EXCEPTION;

END submit;


--This procedure is the Concurrent Parent Program
--which in turn submits other payment programs as
--child requests.
--Called from the procedure Submit of AP_PAYMENT_PROCESSOR package.

PROCEDURE submit_program(
     ERRBUF           	            OUT NOCOPY    VARCHAR2,
     RETCODE           		    OUT NOCOPY    NUMBER,
     P_progs_params_list1	    IN     VARCHAR2,
     P_progs_params_list2           IN     VARCHAR2,
     P_progs_params_list3           IN     VARCHAR2,
     P_progs_params_list4           IN     VARCHAR2,
     P_progs_params_list5           IN     VARCHAR2,
     P_progs_params_list6           IN     VARCHAR2,
     P_progs_params_list7           IN     VARCHAR2,
     P_progs_params_list8           IN     VARCHAR2,
     P_progs_params_list9           IN     VARCHAR2,
     P_payment_batch                IN     VARCHAR2,
     P_programs_list                IN     VARCHAR2,
     P_org_id			    IN     NUMBER  ,
     P_event                        IN     VARCHAR2,
     P_calling_sequence		    IN     VARCHAR2) IS

l_current_calling_sequence  	  VARCHAR2(2000);
l_debug_info   		  	  VARCHAR2(100);
l_req_data                        VARCHAR2(240); -- Bug2828863 Changing length to 240.
l_program_index                   NUMBER;
l_request_id                      NUMBER;
l_sqlerrm 			  VARCHAR2(200);
l_error_mesg			  VARCHAR2(2000);
no_of_parameters                  NUMBER;
p_progs_params_list               VARCHAR2(2000);
TYPE PROGRAMS_TABLE  IS TABLE OF VARCHAR2(30)
		  INDEX BY BINARY_INTEGER;
l_programs_list                   PROGRAMS_TABLE;
l_prev_program_index		  NUMBER;
l_prev_request_id		  NUMBER;
dstatus				  VARCHAR2(30) := 'SUCCESS' ;
dphase				  VARCHAR2(30);
rstatus				  VARCHAR2(80);
rphase				  VARCHAR2(80);
message				  VARCHAR2(240);
l_call_status			  BOOLEAN;
l_complete			  BOOLEAN;
l_debug_index			  NUMBER := 1;
l_length			  NUMBER := 0;
l_start				  NUMBER := 0;
l_program_name			  VARCHAR2(80):= NULL;
BEGIN

    -- Update the calling sequence
    --
    l_current_calling_sequence := P_calling_sequence||'->'||
			 	   'AP_PAYMENT_PROCESSOR.submit_program';

    l_debug_info := 'Building back the global list .';

    ------------------------------------------------------------------------
    --Concatenate back the split progs_params_list into a single list again.
    ------------------------------------------------------------------------
    p_progs_params_list := p_progs_params_list1||p_progs_params_list2||
		           p_progs_params_list3||p_progs_params_list4||
                           p_progs_params_list5||p_progs_params_list6||
		           p_progs_params_list7||p_progs_params_list8||
		           p_progs_params_list9 ;

   ------------------------------------------------------------
   -- Programs defined in the order they should run
   ------------------------------------------------------------

   l_programs_list(1) := 'AUTOSELECT';
   l_programs_list(2) := 'BUILD';
   --Bug 2353651 Added for Calling Federal's Report
   l_programs_list(3) := 'CASH_POSITION';
   l_programs_list(4) := 'PRELIM_REGISTER';
   --Bug:2637430  Added for Federal Financials
   l_programs_list(5) := 'THIRD_PARTY_PAYMENT';
   --Bug:2025932 Added for AP-AR Netting
   l_programs_list(6) := 'NETTING';
   l_programs_list(7) := 'FORMAT';
   l_programs_list(8) := 'CONFIRM';
   l_programs_list(9) := 'ACCOUNT' ;
   l_programs_list(10) := 'POPAY';
   l_programs_list(11) := 'FINAL_REGISTER';
   l_programs_list(12) := 'REMITTANCE';
   l_programs_list(13) := 'CANCEL';

  ------------------------------------------------------------
  --Print to Log file all the programs that will be submitted
  ------------------------------------------------------------
  l_req_data := fnd_conc_global.request_data;

  IF(p_programs_list IS NOT NULL AND l_req_data IS NULL) THEN

    l_debug_info := 'Payment Process Manager will submit ';
    FND_FILE.PUT_LINE(FND_FILE.LOG,l_debug_info);

    LOOP
      EXIT WHEN (l_debug_index > 13) ;

      l_start := INSTR(p_programs_list,l_programs_list(l_debug_index));
      l_length := length(l_programs_list(l_debug_index));

      IF(l_start <> 0) THEN
        l_program_name := '........'||SUBSTR(p_programs_list,l_start,l_length);
      ELSE
        l_program_name := NULL;
        fnd_file.put_line(FND_FILE.LOG,l_program_name);
      END IF;

      IF(l_program_name IS NOT NULL) THEN
      END IF;
      l_debug_index := l_debug_index + 1;

    END LOOP;

  END IF;

 ------------------------------------------------------------
 -- Read the value from REQUEST_DATA.  If this is the
 -- first run of the program, then this value will be null.
 -- Otherwise, this will be the value that we passed to
 -- SET_REQ_GLOBALS on the previous run.
 ------------------------------------------------------------

 l_req_data := fnd_conc_global.request_data;
 IF(l_req_data IS NOT NULL) THEN

      l_prev_program_index := SUBSTR(l_req_data,1,INSTR(l_req_data,':')-1);
      l_prev_request_id := SUBSTR(l_req_data,INSTR(l_req_data,':')+1);

      IF(l_prev_request_id IS NOT NULL) THEN
        l_call_status := FND_CONCURRENT.GET_REQUEST_STATUS(l_prev_request_id,
					 	           '','',
					                   rphase,rstatus,
						           dphase,dstatus,message);
      END IF;

 END IF;

 IF(dstatus <> 'ERROR') THEN



   ------------------------------------------------------------
   -- If this is the first run, we'll set l_program_index 1.
   -- Otherwise, we'll set l_program_index request_data + 1.
   ------------------------------------------------------------
   IF (l_req_data IS NOT NULL) THEN

     l_program_index := TO_NUMBER(l_prev_program_index) + 1;

     l_debug_info := l_programs_list(l_prev_program_index)||' completed successfully.';
     fnd_file.put_line(FND_FILE.LOG,l_debug_info);

     IF (l_program_index > 13) THEN
       errbuf := 'Successful Completion...';
       retcode := 0;
       return;
     END IF;

   ELSE

     l_program_index := 1;

   END IF;

 <<next_program>>
   --------------------------------------------------------------
   -- If the Programs List passed to the parent process includes
   -- this program, then submit a request for it.
   --------------------------------------------------------------
  IF(l_program_index <= 13) THEN

   IF INSTR(p_programs_list,l_programs_list(l_program_index)) <> 0 THEN

                l_debug_info := 'Get the parameters for the subprogram . ';
                get_parameters(l_programs_list(l_program_index),
			       p_progs_params_list,
		               P_param_name_list ,
                               P_param_Value_List ,
		               No_of_parameters);


                l_debug_info := 'Submitting '||l_programs_list(l_program_index)||'...';

 	        fnd_file.put_line(FND_FILE.LOG,l_debug_info);

                submit_sub_program(l_request_id,
			           l_programs_list(l_program_index),
                                   P_payment_batch,
			           P_param_name_list,
			           P_param_value_list,
			           No_of_Parameters,
			           P_org_id,
			           P_event);

      IF l_request_id = 0 THEN

        RAISE request_submission_failure;

      ELSE

        -- Here we set the globals to put the program into the
        -- PAUSED status on exit, and to save the state in
        -- request_data.

        fnd_conc_global.set_req_globals(conc_status => 'PAUSED',
                                        request_data => to_char(l_program_index)||':'
							||to_char(l_request_id)) ;
        l_debug_info := l_programs_list(l_program_index)||' Submitted...Request id : '||
			             to_char(l_request_id);
	fnd_file.put_line(FND_FILE.LOG,l_debug_info);

	l_debug_info := 'Wait for '||l_programs_list(l_program_index)||' to complete...'
			||' enter Paused mode.';
        fnd_file.put_line(FND_FILE.LOG,l_debug_info);

      END IF;

      RETURN;

   ELSE

      l_program_index := l_program_index + 1;
      GOTO next_program;

   END IF; --INSTR

 END IF; --l_program_index

 l_debug_info := 'Payment Process Manager Completed Successfully .';
 fnd_file.put_line(FND_FILE.LOG,l_debug_info);

ELSE
   RAISE request_failed;
END IF; --dstatus

 EXCEPTION

   WHEN request_submission_failure THEN

      errbuf := 'Request Submission Failed';
      retcode := 2;
      l_error_mesg := FND_MESSAGE.GET||
		   ' occurred when trying to submit the payment batch '||
		   p_payment_batch||' with the parameters '
		   ||P_Param_Value_List(0)||' ,'||P_Param_Value_List(1)||'...' ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,l_error_mesg);

     RETURN;

   WHEN request_failed THEN
      l_error_mesg :=l_programs_list(l_prev_program_index)||' Failed.'||

                     ' Refer to the log file of request '||to_char(l_prev_request_id)
		     ||' for error information.';
      FND_FILE.PUT_LINE(FND_FILE.LOG,l_error_mesg);
      l_error_mesg := 'Payment Process Manager Aborted with error.';
      FND_FILE.PUT_LINE(FND_FILE.LOG,l_error_mesg);

      l_complete := FND_CONCURRENT.SET_COMPLETION_STATUS
		    ('ERROR','One of the child requests for this program'||
							' has errored .');
      RETURN;


   WHEN cannot_set_printer THEN
      errbuf := 'Cannot Set Printer';
      retcode := 3;
      RETURN;

   WHEN NO_DATA_FOUND THEN
    NULL;

   WHEN OTHERS then
     IF (SQLCODE <> -20001 ) THEN

      FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_current_calling_sequence);
      FND_MESSAGE.SET_TOKEN('PARAMETERS','Program index = '
					||TO_CHAR(l_program_index));
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_current_calling_sequence);
      FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);

      l_sqlerrm := SQLERRM;
      l_error_mesg := 'The following error has occurred : '||
			l_sqlerrm ||'while performing the '||l_debug_info;

      FND_FILE.PUT_LINE(FND_FILE.LOG,l_error_mesg);
      RETURN;


     END IF;
   APP_EXCEPTION.RAISE_EXCEPTION;

END submit_program;


--Procedure which submits the child requests based on a predefined
--sequence of programs list.
--Called from the Concurrent Program AP_PAYMENT_PROCESSOR.Submit_Program.

PROCEDURE submit_sub_program(
     P_p_request_id                 OUT NOCOPY    NUMBER,
     P_program                      IN     VARCHAR2,
     P_payment_batch                IN     VARCHAR2,
     P_param_name_list		    IN OUT NOCOPY Param_Name_List,
     P_param_value_list		    IN OUT NOCOPY Param_Value_List,
     No_of_Parameters		    IN     NUMBER,
     P_org_id			    IN     NUMBER,
     P_event			    IN     VARCHAR2) IS

 l_current_calling_sequence	 VARCHAR2(2000);
 l_debug_info 			 VARCHAR2(300);
 l_checks_printer	  	 VARCHAR2(80);
 l_format_payments_program_name  VARCHAR2(80);
 l_sra_printer		         VARCHAR2(80);
 l_remittance_program_name	 VARCHAR2(80);
 l_prelim_register_printer	 VARCHAR2(80);
 l_final_register_printer	 VARCHAR2(80);
 l_program_short_name   	 VARCHAR2(80);
 l_execution_method    	         VARCHAR2(1);
 l_request_id                    NUMBER;
 l_first_request                 NUMBER;
 l_last_Request                  NUMBER;
 l_message_name                  VARCHAR2(100);
 l_is_program_srs		 VARCHAR2(10);
 l_save_output_flag		 VARCHAR2(1) := 'Y'; --Bug fix:1636159
 l_parameter_index		 NUMBER := 0; --Bug fix:1687296

BEGIN

   l_current_calling_sequence := 'AP_PAYMENT_PROCESSOR.submit_sub_program' ;
   l_debug_info := 'Get short_name and execution_method for the program .';

   ------------------------------------------------------------
   -- Get the short name and execution methods for the program
   -- to be submitted.
   -- Execution method will be used for some of the programs.
   ------------------------------------------------------------
   l_program_short_name := get_program_short_name(p_program, p_payment_batch);
   l_execution_method := get_execution_method(l_program_short_name);

   ------------------------------------------------------------
   -- Handle Payment Programs in the following if-elsif tree.
   -- Different programs require different handling.
   ------------------------------------------------------------

   ------------------------------------------------------------
   -- AutoSelect Program
   ------------------------------------------------------------
   IF p_program = 'AUTOSELECT' THEN

      l_debug_info := 'Submitting AUTOSELECT .';

      set_batch_status(p_payment_batch,p_program,'SELECTING');

      IF l_execution_method = 'P' THEN
         -- Oracle Reports program
         P_p_request_id := fnd_request_api(p_program,
                            l_program_short_name,
                            P_param_name_list,
                            P_param_value_list,
			    'BYNAME',
			    No_of_parameters);

      ELSE
         -- RPT Program

	 delete_parameter_and_value('P_DEBUG_SWITCH');

	 delete_parameter_and_value('P_TRACE_SWITCH');

         P_p_request_id := fnd_request_api(p_program,
                            l_program_short_name,
			    P_param_name_list,
			    P_param_value_list,
			    'POSITIONAL',
                            No_of_parameters);
      END IF;

      IF P_p_request_id = 0 THEN
         -- Failure
	 null;
      ELSE
         -- Success
         insert_conc_req(p_payment_batch,
      END IF;
			 P_p_request_id,
			 'AUTOSELECT');



   ------------------------------------------------------------
   -- Build Program
   ------------------------------------------------------------
   ELSIF p_program = 'BUILD' THEN
       --Bug fix:1703184
       -- set_batch_status(p_payment_batch,p_program,'REBUILDING');
       l_debug_info := 'Submitting BUILD ..';

      IF l_execution_method = 'P' THEN
         -- Oracle Reports program

         P_p_request_id := fnd_request_api(p_program,
                            l_program_short_name,
			    P_param_name_list,
			    P_param_value_list,
			    'BYNAME',
			    No_of_parameters);
      ELSE
         -- RPT Program

	 delete_parameter_and_value('P_DEBUG_SWITCH');

         delete_parameter_and_value('P_TRACE_SWITCH');

         P_p_request_id := fnd_request_api(p_program,
                            'APPBLD',
                            P_param_name_list,
			    P_param_value_list,
			    'POSITIONAL',
			    No_of_parameters);
      END IF;

      IF P_p_request_id = 0 THEN
         -- Failure
	 null;
      ELSE
         -- Success
        insert_conc_req(p_payment_batch,
			P_p_request_id,
			'BUILD');

      END IF;

    ------------------------------------------------------------
   -- Check Federal Financials CASH_POSITION Program
   ------------------------------------------------------------

    --Bug :2353651 Added for Cash Position

    ELSIF p_program = 'CASH_POSITION' THEN

      l_debug_info := 'Submitting CASH_POSITION Program. ';

      P_p_request_id := fnd_request_api(p_program,
                                        l_program_short_name,
                                        p_param_name_list,
                                        p_param_value_list,
                                        'POSITIONAL',
                                        No_of_parameters);


      IF P_p_request_id = 0 THEN
      -- Failure
       null;
      ELSE
      -- Success
      insert_conc_req(p_payment_batch,
                      P_p_request_id,
                      'FVAPCPDP');

      END IF;

   ------------------------------------------------------------
   -- Preliminary Register Report
   ------------------------------------------------------------
   ELSIF p_program = 'PRELIM_REGISTER' THEN
      l_parameter_index := 0;

      l_debug_info := 'Submitting Preliminary Payment Register. ';

      l_prelim_register_printer := get_parameter_value('P_PRELIM_REGISTER_PRINTER');

      delete_parameter_and_value('P_PRELIM_REGISTER_PRINTER');
      --Bug fix:1796453
      IF( l_prelim_register_printer IS NOT NULL) THEN
	 l_parameter_index := l_parameter_index + 1;
      END IF;
      -- Bug 4200601: third parameter added in call below
      set_printer(l_prelim_register_printer,l_save_output_flag,'PRELIM_REGISTER');

      P_p_request_id := fnd_request_api(p_program,
                         l_program_short_name,
                         P_param_name_list,
			 P_param_value_list,
			 'POSITIONAL',
			 No_of_parameters - l_parameter_index);

      IF P_p_request_id = 0 THEN
         -- Failure
	 null;
      END IF;


   ------------------------------------------------------------
   -- Check AP/AR Netting Programs
   ------------------------------------------------------------
    --Bug :2025932 Added for AP-AR Netting
    ELSIF p_program = 'NETTING' THEN

      l_debug_info := 'Submitting AP/AR Netting Program. ';

      P_p_request_id := fnd_request_api(p_program,
				        l_program_short_name,
					p_param_name_list,
				        p_param_value_list,
				        'POSITIONAL',
				        No_of_parameters);


      IF P_p_request_id = 0 THEN
      -- Failure
       null;
      ELSE
      -- Success
      insert_conc_req(p_payment_batch,
		      P_p_request_id,
         	      'FVAANMIR');

      END IF;

   -- Bug : 2637430 Added for federal financials.
   --------------------------------------------------------------
   -- Third Party Payment Process
   ------------------------------------------------------------
   ELSIF p_program = 'THIRD_PARTY_PAYMENT' THEN

      l_debug_info := 'Submitting Third Party Payment Program. ';

      P_p_request_id := fnd_request_api(p_program,
 			                l_program_short_name,
				        p_param_name_list,
				        p_param_value_list,
				        'POSITIONAL',
				        No_of_parameters);

      IF P_p_request_id = 0 THEN
         -- Failure
         insert_conc_req(p_payment_batch,
         null;
      ELSE
         -- Success
		         P_p_request_id,
		         'FVAPTPPR');

      END IF;


   ------------------------------------------------------------
   -- Check Formatting Programs
   ------------------------------------------------------------

   ELSIF p_program = 'FORMAT' THEN

      l_parameter_index := 0;

      l_debug_info := 'Submitting FORMAT .';

      --Bug fix: 1796476
      IF (P_event <> 'PAY_PROCESS') THEN
         set_batch_status(p_payment_batch,p_program,'FORMATTING');
      END IF;

      l_checks_printer := get_parameter_value('P_CHECKS_PRINTER');

      --Bug fix:1687296
      if(l_checks_printer is not null) then
        l_parameter_index := l_parameter_index + 1;
      end if;

      Delete_Parameter_and_value('P_CHECKS_PRINTER');

      l_format_payments_program_name := get_parameter_value('P_FORMAT_PAYMENTS_PROGRAM_NAME');

      SELECT save_output_flag
      INTO l_save_output_flag
      FROM fnd_concurrent_programs_vl
      WHERE concurrent_program_name = l_format_payments_program_name
      AND application_id = 200; --Bug fix:1921901
      -- Bug 4200601 : third paramter added to call below
      set_printer(l_checks_printer,l_save_output_flag,'FORMAT');

      l_execution_method := get_execution_method(l_format_payments_program_name);

      delete_parameter_and_value('P_FORMAT_PAYMENTS_PROGRAM_NAME');

      --Bug fix:1687296
      IF (l_format_payments_program_name IS NOT NULL) THEN
        l_parameter_index := l_parameter_index + 1;
      END IF;

      l_is_program_srs := is_program_srs(l_format_payments_program_name);

      IF l_execution_method = 'P' THEN
         -- Oracle Reports program

         IF (is_program_srs(l_format_payments_program_name) in ('Q','Y')) THEN
            P_p_request_id := fnd_request_api(p_program,
			       l_format_payments_program_name,
                               P_param_name_list,
			       P_param_value_list,
			       'POSITIONAL',
			       No_of_parameters-l_parameter_index ); /*bug1687296*/

         ELSE
            P_p_request_id := fnd_request_api(p_program,
			       l_format_payments_program_name,
                               P_param_name_list,
			       P_param_value_list,
			       'BYNAME',
			       No_of_parameters-l_parameter_index); --Bug fix:1687296

         END IF;
      ELSE
         -- RPT Program

         P_p_request_id := fnd_request_api(p_program,
			    l_format_payments_program_name,
                            P_param_name_list,
			    P_param_value_list,
			    'POSITIONAL',
			    No_of_parameters-l_parameter_index ); --Bug fix:1687296
      END IF;


      IF P_p_request_id = 0 THEN
         -- Failure
	 null;
      ELSE
         -- Success
         insert_conc_req(p_payment_batch,
			 P_p_request_id,
			 'FORMAT');

      END IF;


   ------------------------------------------------------------
   -- Confirm Program
   ------------------------------------------------------------
   ELSIF p_program = 'CONFIRM' THEN

      l_debug_info := 'Submitting CONFIRM . ';

      -- Code Added For Bug 2266098 Starts

      set_batch_status(p_payment_batch,p_program,'CONFIRMING');

      -- Code Added For Bug 2266098 Ends

      P_p_request_id := fnd_request_api(p_program,
                         l_program_short_name,
			 P_param_name_list,
                         P_param_value_list,
			 'POSITIONAL',
			 No_of_parameters);

      IF P_p_request_id = 0 THEN
         -- Failure
         NULL;
      ELSE
         -- Success
         insert_conc_req(p_payment_batch,
			 P_p_request_id,
			 'CONFIRM');

      -- XXAP / DJEI / DETE / Start
       XXAP_REMIT_ADVICE_PKG.REMITTANCE_EMAIL_WRAPPER_PROC(P_payment_batch);
       -- XXAP / DJEI / DETE / End

      END IF;

   ------------------------------------------------------------
   -- Create Accounting
   ------------------------------------------------------------

   ELSIF p_program = 'ACCOUNT' THEN

     l_debug_info := 'Submitting ACCOUNT .';

     P_p_request_id := fnd_request_api(p_program,
	                l_program_short_name,
	                p_param_name_list,
		        p_param_value_list,
			'POSITIONAL',
		        No_of_parameters);

         IF P_p_request_id = 0 THEN
          -- Failure
          NULL;
         END IF;

   ELSIF p_program = 'POPAY' THEN
   ------------------------------------------------------------
   -- Positive Pay Report
   ------------------------------------------------------------
      l_debug_info := 'Submitting Positive Pay File .';

      P_p_request_id := fnd_request_api(p_program,
                         l_program_short_name,
                         P_param_name_list,
			 P_param_value_list,
			 'POSITIONAL',
			 No_of_parameters );


      IF P_p_request_id = 0 THEN
         -- Failure
         NULL;
      END IF;


   ------------------------------------------------------------
   -- Final Register Report
   ------------------------------------------------------------

   ELSIF p_program = 'FINAL_REGISTER' THEN
      l_parameter_index := 0;
      l_debug_info := 'Submitting Final Register. ';

      l_final_register_printer := get_parameter_value('P_FINAL_REGISTER_PRINTER');
      delete_parameter_and_value('P_FINAL_REGISTER_PRINTER');

       --Bug fix:1696463
       IF (l_final_register_printer IS NOT NULL) THEN
	  l_parameter_index := l_parameter_index + 1;
       END IF;
      -- Bug 4200601: third parameter added to call below
      set_printer(l_final_register_printer,l_save_output_flag,'FINAL_REGISTER');

      P_p_request_id := fnd_request_api(p_program,
                         l_program_short_name,
                         P_param_name_list,
			 P_param_value_list,
			 'POSITIONAL',
			 No_of_parameters-l_parameter_index ); --Bug fix:1796453

      IF P_p_request_id = 0 THEN
         -- Failure
         NULL;
      END IF;


   ------------------------------------------------------------
   -- Separate Remittance Advice
   ------------------------------------------------------------
   ELSIF p_program = 'REMITTANCE' THEN

      l_parameter_index := 0;

      l_debug_info := 'Submitting Separate Remittance Advice. ';

      l_sra_printer := get_parameter_value('P_SRA_PRINTER');

      delete_parameter_and_value('P_SRA_PRINTER');

      --Bug fix:1796453
      IF(l_sra_printer is NOT NULL) THEN
	l_parameter_index := l_parameter_index + 1;
      END IF;
      -- Bug 4200601: third parameter added to call below
      set_printer(l_sra_printer,l_save_output_flag,'REMITTANCE');

      l_remittance_program_name := get_parameter_value('P_REMITTANCE_PROGRAM_NAME');

      delete_parameter_and_value('P_REMITTANCE_PROGRAM_NAME');

      --Bug fix:1796453
      IF(l_remittance_program_name is NOT NULL) THEN
        l_parameter_index := l_parameter_index + 1;
      END IF;


      IF (is_program_srs(l_remittance_program_name) IN ('Q','Y')) THEN

         P_p_request_id := fnd_request_api(p_program,
			    l_remittance_program_name,
                            P_param_name_list,
			    P_param_value_list,
			    'POSITIONAL',
			    No_of_parameters-l_parameter_index ); --Bug fix:1796453
      ELSE

         P_p_request_id := fnd_request_api(p_program,
			    l_remittance_program_name,
                            P_param_name_list,
			    P_param_value_list,
			    'BYNAME',
			    No_of_parameters-l_parameter_index); --Bug fix:1796453
      END IF;

      IF P_p_request_id = 0 THEN
         -- Failure
         NULL;
      END IF;


   ------------------------------------------------------------
   -- Cancel Program
   ------------------------------------------------------------
   ELSIF p_program = 'CANCEL' THEN

      l_debug_info := 'Submitting CANCEL. ';

      set_batch_status(p_payment_batch,p_program,'CANCELING');
      P_p_request_id := fnd_request_api(p_program,
                         l_program_short_name,
			 P_param_name_list,
			 P_param_value_list,
			 'POSITIONAL',
			 No_of_parameters);


      IF P_p_request_id = 0 THEN
         -- Failure
         NULL;
      ELSE
         -- Success
         insert_conc_req(p_payment_batch,
			 P_p_request_id,
			 'CONFIRM');

      END IF;


   END IF;

 EXCEPTION
   WHEN OTHERS THEN
    IF (SQLCODE <> -20001 ) THEN
      FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_current_calling_sequence);
      FND_MESSAGE.SET_TOKEN('PARAMETERS','P_Program='||P_program
		            ||',P_payment_batch='||P_payment_batch
		            ||',P_param_name_list = '||P_param_name_list(0)||','
                            ||P_param_name_list(1)||'...'
		            ||',P_Param_Value_List ='||P_Param_Value_List(0)||','
		            ||P_Param_Value_List(1)||'...' );
      FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
    END IF;



END submit_sub_program;


--added the function to set the formatted status for a SEPA format
FUNCTION set_formatted_status(p_payment_batch   IN VARCHAR2,
                           program_name      IN VARCHAR2,
                           p_status          IN VARCHAR2
                           ) RETURN BOOLEAN IS
   l_is_quick_pay   AP_INVOICE_SELECTION_CRITERIA.Status%TYPE ; -- Bug 8703994
BEGIN

   IF(program_name IN ('AUTOSELECT',
                          'BUILD',
                          'MODIFY',
                          'FORMAT',
                          'CONFIRM',
                          'POPAY',
                          'PRELIM-REGISTER',
                          'FINAL-REGISTER',
                          'REMITTANCE',
                          'CANCEL')) then
	-- Bug 8703994 : Added below select and if-end if
        SELECT status
	INTO   l_is_quick_pay
	FROM   AP_INVOICE_SELECTION_CRITERIA
	WHERE  checkrun_name=p_payment_batch ;

	IF l_is_quick_pay <> 'QUICKCHECK' THEN
            UPDATE ap_invoice_selection_criteria
            SET status = p_status
            WHERE checkrun_name=p_payment_batch ;
            COMMIT;
	END IF ;

return TRUE;

ELSE

return FALSE;

END IF;

EXCEPTION WHEN OTHERS THEN

return FALSE;

END;



--Procedure to set the status of the batch to appropriate status
--just before the sub_programs such as AUTOSELECT,BUILD ...are submitted.
--Called from procedure Submit_Sub_Program.

PROCEDURE set_batch_status(p_payment_batch   IN VARCHAR2,
			   program_name      IN VARCHAR2,
			   p_status          IN VARCHAR2 ) IS

Parameter_Value_Null EXCEPTION;

BEGIN

 IF( P_Payment_batch IS NOT NULL AND program_name IS NOT NULL
     AND p_status IS NOT NULL ) THEN

   IF(program_name IN ('AUTOSELECT',
			  'BUILD',
			  'MODIFY',
			  'FORMAT',
			  'CONFIRM',
			  'POPAY',
			  'PRELIM-REGISTER',
			  'FINAL-REGISTER',
			  'REMITTANCE',
			  'CANCEL')) then

       UPDATE ap_invoice_selection_criteria
       SET status = p_status
       WHERE checkrun_name=p_payment_batch ;

       COMMIT;

   END IF;

ELSE

  raise PARAMETER_VALUE_NULL;

END IF;


 EXCEPTION

   WHEN PARAMETER_VALUE_NULL THEN
    IF(SQLCODE <> -20001 ) THEN

     FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
     FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
     FND_MESSAGE.SET_TOKEN('PARAMETERS','P_Payment_batch='||P_Payment_batch
				   	||',program_name='||program_name
				   	||',status='||p_status );
    END IF;

   WHEN OTHERS THEN
    IF(SQLCODE <> -20001 ) THEN

     FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
     FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
     FND_MESSAGE.SET_TOKEN('PARAMETERS','P_Payment_batch='||P_Payment_batch
					||',program_name='||program_name
					||',status='||p_status );
    END IF;

 APP_EXCEPTION.RAISE_EXCEPTION;

END ;


--Function to determine whether any of the concurrent requests submitted
--for a payment batch are pending

FUNCTION PAY_BATCH_REQUESTS_FINISHED(P_payment_batch IN VARCHAR2) RETURN BOOLEAN IS
 l_result BOOLEAN := FALSE;
 BEGIN

    AP_CONC_PROG_PKG.PAY_BATCH_REQUESTS_FINISHED(
			    X_Batch_Name       => P_payment_batch,
			    X_Calling_Sequence => 'APXPAWKB',
			    X_Finished_Flag    => l_result);
      return(l_result);

END PAY_BATCH_REQUESTS_FINISHED;


FUNCTION get_program_short_name
     (P_program                    IN     VARCHAR2,
      P_payment_batch              IN     VARCHAR2)
RETURN VARCHAR2  IS

   l_build_program VARCHAR2(80);
   l_dummy_program VARCHAR2(80) := NULL;

BEGIN

   IF p_program = 'AUTOSELECT' THEN
      RETURN('APXPBASL');

   ELSIF p_program = 'BUILD' THEN

      SELECT PP1.program_name
       INTO l_build_program
       FROM AP_PAYMENT_PROGRAMS PP1,
            AP_CHECK_FORMATS CF,
            AP_CHECK_STOCKS CS,
            AP_INVOICE_SELECTION_CRITERIA aisc
      WHERE CS.check_stock_id = aisc.check_stock_id
        AND CS.check_format_id = CF.check_format_id
        AND CF.build_payments_program_id = PP1.program_id
        AND aisc.checkrun_name = p_payment_batch;

      RETURN(l_build_program);

   -- Bug 2353651 Added for Federal Financials Report
   ELSIF p_program = 'CASH_POSITION' THEN
      RETURN('FVAPCPDP');

   --Bug :2025932 Added for AP-AR Netting
   ELSIF p_program = 'PRELIM_REGISTER' THEN
      RETURN('APXPBPPR');

   ELSIF p_program = 'NETTING' THEN
      RETURN('FVAANMIR');

   --Bug :2637430 Added for federal financials, for third party payment process.
   ELSIF p_program = 'THIRD_PARTY_PAYMENT' THEN
      RETURN('FVAPTPPR');

   ELSIF p_program = 'FORMAT' THEN
      RETURN(l_dummy_program);

   ELSIF p_program = 'CONFIRM' THEN
      RETURN('APPBCF');

   ELSIF p_program = 'ACCOUNT' THEN
      RETURN('APACCENG');

   ELSIF p_program = 'POPAY' THEN
      RETURN('APXPOPAY');

   ELSIF p_program = 'FINAL_REGISTER' THEN
      RETURN('APXPBFPR');

   ELSIF p_program = 'REMITTANCE' THEN
      RETURN(l_dummy_program);

   -- Payment Process Enhancements. Created a new concurrent program
   -- for Cancel Process.
   ELSIF p_program = 'CANCEL' THEN
      RETURN('APPBCN');

   END IF;
 EXCEPTION
   WHEN OTHERS THEN
    IF (SQLCODE <> -20001 ) THEN
       FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
       FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
       FND_MESSAGE.SET_TOKEN('PARAMETERS','P_Payment_Batch '||P_payment_batch
		              ||',P_program '||P_program);

    END IF;
 APP_EXCEPTION.RAISE_EXCEPTION;

END get_program_short_name;


FUNCTION get_execution_method
     (P_program_short_name     IN    VARCHAR2) RETURN VARCHAR2  IS
  l_result VARCHAR2(1) := '';
BEGIN

  ap_conc_prog_pkg.execution_method(
                                x_program_name     => p_program_short_name,
                                x_calling_sequence => 'AP_PAYMENT_PROCESSOR',
                                x_execution_method => l_result);
  return(l_result);

END get_execution_method;


PROCEDURE insert_conc_req
     (P_payment_batch        IN     VARCHAR2,
      P_request_id           IN     NUMBER,
      P_program              IN     VARCHAR2 ) IS
BEGIN

  AP_INV_SELECTION_CRITERIA_PKG.INSERT_CONC_REQ(p_payment_batch,
  					        p_request_id,
				                p_program,
					        'APXPAWKB');

  EXCEPTION
   WHEN OTHERS THEN
     IF (SQLCODE <> -20001 ) THEN
      FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      FND_MESSAGE.SET_TOKEN('PARAMETERS','P_Payment_Batch '||P_payment_batch
			||',P_request_id '||to_char(P_request_id)
			||',P_program '||P_program );

     END IF;

  APP_EXCEPTION.RAISE_EXCEPTION;

END insert_conc_req;


PROCEDURE set_printer
     (P_printer_name           IN VARCHAR2,
      P_save_output_flag       IN VARCHAR2,
      P_program                IN VARCHAR2 ) IS -- Bug 4200601, parameter added
BEGIN

IF (p_printer_name IS NOT NULL) THEN

   --Bug fix:1636159
   --Added the following IF condition
 IF(P_save_output_flag = 'Y' ) THEN
-- Bug 3249796 default copies set to null in call below
-- Bug 4200601 : if condition below added such that default
-- copies are set to NULL for all programs except 'FORMAT'
  IF P_program = 'FORMAT'   THEN
    IF NOT fnd_request.set_print_options(p_printer_name, '',1 , TRUE, 'N') THEN
        -- Failure
        RAISE cannot_set_printer;
    END IF;
  ELSE
    IF NOT  fnd_request.set_print_options(p_printer_name, '','', TRUE, 'N') THEN
        -- Failure
        RAISE cannot_set_printer;
      END IF;
  END IF;

 ELSIF(p_save_output_flag = 'N') THEN

  IF P_program = 'FORMAT'  THEN
    IF NOT fnd_request.set_print_options(p_printer_name, '',1 , FALSE, 'N') THEN
        -- Failure
        RAISE cannot_set_printer;
    END IF;
  ELSE
    IF NOT fnd_request.set_print_options(p_printer_name, '','', FALSE, 'N') THEN
        -- Failure
        RAISE cannot_set_printer;
    END IF;
  END IF;

 END IF;

--Bug 4638721 added the below else part
ELSIF (p_printer_name IS NULL) THEN

 IF(p_save_output_flag = 'Y' ) THEN

  IF P_program = 'FORMAT'   THEN
    --Bug 5858363 - changed the 'noprint' to NULL in fnd_request.set_print_options
    IF NOT fnd_request.set_print_options(NULL, '',0 , TRUE, 'N') THEN
        -- Failure
        RAISE cannot_set_printer;
    END IF;
  END IF;

 ELSIF(p_save_output_flag = 'N') THEN

  IF P_program = 'FORMAT'  THEN
    --Bug 5858363 - changed the 'noprint' to NULL in fnd_request.set_print_options
    IF NOT fnd_request.set_print_options(NULL, '',0 , FALSE, 'N') THEN
        -- Failure
        RAISE cannot_set_printer;
    END IF;
  END IF;

END IF;
 END IF;
--Bug 4638721 ends


END set_printer;


FUNCTION is_program_srs
  (P_program_short_name     IN    VARCHAR2) RETURN VARCHAR2  IS
  l_result VARCHAR2(1) := '';
BEGIN

  ap_conc_prog_pkg.is_program_srs(
                                x_program_name     => p_program_short_name,
                                x_calling_sequence => 'AP_PAYMENT_PROCESSOR',
                                x_srs_flag => l_result);

  return(l_result);

END is_program_srs;


--Function to actually submit the sub_programs such as AUTOSELECT,BUILD..
--This function is called from the procedure Submit_Sub_Program.

FUNCTION fnd_request_api
  (P_program_name              IN   VARCHAR2,
   P_program_short_name        IN   VARCHAR2,
   P_param_name_list	       IN   Param_Name_List,
   P_param_value_list	       IN   Param_Value_List,
   P_Parameter_Passing_Style   IN   VARCHAR2,
   No_of_Parameters	       IN   NUMBER
   ) RETURN NUMBER  IS

   l_current_calling_sequence  VARCHAR2(200);
   TYPE parameter_and_value_list IS TABLE OF VARCHAR2(100)
	INDEX BY BINARY_INTEGER;
   l_parameter_list  parameter_and_value_list;
   l_request_id NUMBER := 0;
   l_application_short_name VARCHAR2(50);
   /* Variables for 4303528 */
   l_output_file_type   xdo_templates_b.default_output_type%type; --Bug7596724
   l_session_language   nls_session_parameters.value%type;
   l_iso_language     fnd_languages.iso_language%type;
   l_iso_territory    fnd_languages.iso_territory%type;
   l_data_source_code   varchar2(1);
   l_template_code    xdo_templates_b.template_code%type;
   lb_set_add_layout   boolean;
   l_debug_info   varchar2(200);
  /* end for 4303528 */
   l_icx_numeric_characters   VARCHAR2(30); -- 5854067
   l_return_status   boolean;  -- 5854067
BEGIN

  l_current_calling_sequence := 'AP_PAYMENT_PROCESSOR.fnd_request_api';

  l_debug_info := 'AP_PAYMENT_PROCESSOR.fnd_request_api';
    FND_FILE.PUT_LINE(FND_FILE.LOG,l_debug_info);

  --Bug fix:1883279 Initialize the l_parameter_list to chr(0) instead of NULL,
  --since it is causing problems for PL/SQL concurrent programs.
  FOR j in 0..19 LOOP
     l_parameter_list(j) := chr(0);
  END LOOP;


  FOR i in 0..(No_of_parameters-1) LOOP
    IF (P_Parameter_Passing_Style = 'BYNAME') THEN

       IF ((P_param_name_list(i) IS NOT NULL) AND
	   (P_param_value_list(i) IS NOT NULL)) THEN

	   l_parameter_list(i) := P_param_name_list(i)||'='
				    || ''''||P_param_value_list(i)||'''';


       END IF;

    ELSE

       IF (P_param_name_list(i) IS NOT NULL) THEN

	   l_parameter_list(i) := P_param_value_list(i);

       END IF;

    END IF;

  END LOOP;

  --Bug :2025932 Added for AP-AR Netting
  --Bug :2353651 Added for Cash Report
  --Bug :2637430 Added for Third Party Payment Program
  IF(p_program_short_name in ('FVAANMIR','FVAPCPDP','FVAPTPPR')) THEN
    l_application_short_name := 'FV';
  ELSE
    l_application_short_name := 'SQLAP' ;
  END IF;

 l_debug_info := 'l_application_short_name-'||l_application_short_name;
    FND_FILE.PUT_LINE(FND_FILE.LOG,l_debug_info);

 l_debug_info := 'P_program_name-'||P_program_name;
    FND_FILE.PUT_LINE(FND_FILE.LOG,l_debug_info);

 l_debug_info := 'P_program_short_name-'||P_program_short_name;
    FND_FILE.PUT_LINE(FND_FILE.LOG,l_debug_info);

/* Start changes for bug 4303528 */
  IF P_program_name = 'FORMAT' THEN

 l_debug_info := 'Program name - FORMAT';
    FND_FILE.PUT_LINE(FND_FILE.LOG,l_debug_info);
               BEGIN
             /* Commented out below query for bug8820765 */
             /*    SELECT '1'
                 INTO   l_output_file_type
                 FROM   fnd_concurrent_programs
                 WHERE  concurrent_program_name =P_program_short_name
                 AND    output_file_type= 'XML'
                 AND    application_id =200;

   l_debug_info := 'l_output_file_type-'||l_output_file_type;
    FND_FILE.PUT_LINE(FND_FILE.LOG,l_debug_info); */

                 SELECT  value
                 INTO    l_session_language
                 FROM    nls_session_parameters
                 WHERE   parameter = 'NLS_LANGUAGE';
   l_debug_info := 'l_session_language-'||l_session_language;
    FND_FILE.PUT_LINE(FND_FILE.LOG,l_debug_info);

                 SELECT lower(iso_language),iso_territory
                 INTO   l_iso_language,l_iso_territory
                 FROM   fnd_languages
                 where  nls_language = l_session_language;

   l_debug_info := 'l_iso_language-'||l_iso_language;
    FND_FILE.PUT_LINE(FND_FILE.LOG,l_debug_info);
   l_debug_info := 'l_iso_territory-'||l_iso_territory;
                    because data in xdo tables is like that. */
    FND_FILE.PUT_LINE(FND_FILE.LOG,l_debug_info);

                 /* intentionally language is compared to territory
                 --bug 6807219
                 /*SELECT '1'
                 INTO   l_data_source_code
                 FROM   xdo_ds_definitions_tl
                 WHERE  data_source_code =P_program_short_name
                 AND    language = l_iso_territory
                 AND    application_short_name ='SQLAP';*/

               --Bug6741280 added following if condition for Sepa11i project
                 IF (P_program_short_name IN ('APXSEPAS','APXSEPAU')) THEN
                    l_iso_language:='en';
                    l_iso_territory:='US';
                 END IF;


              /* We will pick the first active  template of that
                 language randomly. */
              /* bug8820765 added exception handler */
	      --Bug7596724: Fetching the default_output_type
              begin
                 SELECT template_code,nvl(default_output_type,'PDF')
                 INTO   l_template_code,l_output_file_type
                 FROM   xdo_templates_b
                 WHERE  data_source_code = P_program_short_name
                 AND    lower( default_language) = l_iso_language
                 AND    default_territory = l_iso_territory
                 AND    end_date is null
                 AND    application_id = 200
                 AND    rownum=1;
              exception
                 when NO_DATA_FOUND then
                  null;
              end;

	      --Bug7596724: Setting the output_format to l_output_file_type
                 lb_set_add_layout := fnd_request.add_layout
                                 ( template_appl_name   => l_application_short_name
                                 , template_code        => l_template_code
                                 , template_language    => l_iso_language
                                 , template_territory   => l_iso_territory
                                 , output_format        => l_output_file_type
                                 );



                 IF lb_set_add_layout THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Template added successfully');
                 END IF;
               EXCEPTION
                WHEN OTHERS THEN
                    l_debug_info := 'Could not attach the template due to
                    following error in
                    AP_PAYMENT_PROCESSOR.submit_sub_program '||sqlcode||' - '
                    ||sqlerrm;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,l_debug_info);
               END;
  END IF;
 /* End changes for bug 4303528 */
-- Submit the child request.  The sub_request parameter
  -- must be set to 'Y'.
--below code added for 5854067 as we need to set the current nls character setting
--before submitting a child requests.
fnd_profile.get('ICX_NUMERIC_CHARACTERS',l_icx_numeric_characters);
l_return_status:= FND_REQUEST.SET_OPTIONS( numeric_characters => l_icx_numeric_characters);
      l_request_id := FND_REQUEST.SUBMIT_REQUEST (
                      l_application_short_name, p_program_short_name,
                       '', '', TRUE,
		       l_parameter_list(0),l_parameter_list(1) ,
		       l_parameter_list(2), l_parameter_list(3),
		       l_parameter_list(4), l_parameter_list(5),
		       l_parameter_list(6), l_parameter_list(7),
		       l_parameter_list(8), l_parameter_list(9),
		       l_parameter_list(10), l_parameter_list(11),
		       l_parameter_list(12), l_parameter_list(13),
		       l_parameter_list(14), l_parameter_list(15),
		       l_parameter_list(16), l_parameter_list(17),
		       l_parameter_list(18), l_parameter_list(19),
		       chr(0), '', '','', '', '', '', '', '', '',
                       '', '', '', '', '', '', '', '', '', '',
                       '', '', '', '', '', '', '', '', '', '',
                       '', '', '', '', '', '', '', '', '', '',
                       '', '', '', '', '', '', '', '', '', '',
                       '', '', '', '', '', '', '', '', '', '',
                       '', '', '', '', '', '', '', '', '', '',
                       '', '', '', '', '', '', '', '', '','');

  RETURN l_request_id;

 EXCEPTION
  WHEN OTHERS THEN
   IF (SQLCODE <> -20001 ) THEN
     FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
     FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
     FND_MESSAGE.SET_TOKEN('PARAMETERS','P_program_name ='||P_program_name||
			   ',P_program_short_name ='||P_program_short_name||
			   ',No_of_Parameters ='||to_char(No_of_Parameters));
   END IF;

  APP_EXCEPTION.RAISE_EXCEPTION;

END fnd_request_api;


END AP_PAYMENT_PROCESSOR;
