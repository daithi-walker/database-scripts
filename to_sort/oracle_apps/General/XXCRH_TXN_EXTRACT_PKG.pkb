create or replace PACKAGE BODY XX_TXN_EXTRACT_PKG IS


PROCEDURE WriteLog (p_comments IN VARCHAR2
				   ,p_procedure_name IN VARCHAR2
				   ,p_progress IN VARCHAR2) IS

PRAGMA autonomous_transaction;

BEGIN
  INSERT INTO xx_debug (create_date, comments, procedure_name, progress) VALUES
  		 	  			  (SYSDATE, p_comments, p_procedure_name, p_progress);
  COMMIT;
END WriteLog;

PROCEDURE Create_File (ErrBuf 					OUT VARCHAR2
				      ,RetCode 					OUT NUMBER
					  ,p_gl_date_from 			IN DATE
					  ,p_gl_date_to   			IN DATE) IS


  CURSOR C_Get_Data ( p_gl_date_from DATE, p_gl_date_to DATE) IS
  SELECT     XCOM.COMPANY_CODE				COMP_CODE_ORDR
		 	,XCOM.COMPANY_CODE				COMP_CODE_INVC
		 	,XCOM.COMPANY_NAME				COMP_NAME
			,rct.customer_trx_id
		 	,RCT.TRX_NUMBER					INVC_CODE
		 	,RCT.TRX_DATE		 			INVC_DATE
		 	,RCT.ROWID						TRX_ROW_ID  -- USED FOR UPDATING THE PROCESSED RECORDS
			,RCT.PRIMARY_SALESREP_ID				  -- TO FETCH TR3
			,RCT.BILL_TO_SITE_USE_ID				  -- TO FETCH TR3
			,RCT.SHIP_TO_SITE_USE_ID				  -- TO FETCH TR11
		 	,TO_CHAR(RCT.TRX_DATE,'MM')		MONTH
		 	,TO_CHAR(RCT.TRX_DATE,'RRRR')	YEAR
			,RCTL.INTERFACE_LINE_ATTRIBUTE1		PROJ_NAME -- cc 241
		 	,TRIM(RCT.PURCHASE_ORDER)		PO
		 	,SUBSTR(RCTL.DESCRIPTION,1,40)	DESCR
		 	,RCTL.QUANTITY_INVOICED			DELV_QTY
--		 ,RCTL.QUANTITY_INVOICED			PRICE_QTY -- use DEVL_QTY
 		    ,RCTL.UOM_CODE					DELV_QTY_UOM
		 	,RCTL.UNIT_SELLING_PRICE		UNIT_PRICE
			,RCTL.INVENTORY_ITEM_ID
			,RCTL.INTERFACE_LINE_ATTRIBUTE1
		 	,RCTLGD.ACCTD_AMOUNT			EXT_PRICE_AMT
		 	,DECODE(GCC.SEGMENT2
		 	  	   ,'0000'
				   ,RCTT.ATTRIBUTE3
				   ,GCC.SEGMENT2)			SHIP_PLANT_CODE
		    ,RC.CUSTOMER_NUMBER				CUST_CODE
		    ,substr(RC.CUSTOMER_NAME,1,40)	CUST_NAME
		    ,RCTT.ATTRIBUTE2				RCTT_ATTRIBUTE2
			,RCTT.NAME						TRX_TYPE
		    ,RBS.NAME 			            BATCH_SOURCE
			,''								TKT_DATE
			,'1'							ORDER_TYPE
			,''								TRUCK_CODE
			,''								HLER_CODE
			,''								REMOVE_RSN_CODE
			,''								SALES_ANL_CODE
			,''								ORDER_DATE
			,''								ORDER_CODE
			,''								TKT_CODE
			,''								ORDER_INTRNL_LINE_NUM
			,'D'							DELV_METH_CODE
			,''								EQUIV_ABBR
			,''								EQUIV_QTY
			,''								TYPE_PRICE
			,''								TKT_CHRG_CODE
			,''								HAUL_CHRG_TO_CUST
			,''								PD
			,''								EXT_AMT
			,''								PSC
			,''								ZONE_CODE
			,'1'							EXTRA_ORD_TYP
			,''								HAUL_CHRG_TO_CUST_HIRE
			,''								HAUL_CHRG_TO_CUST_OWN
			,''								TOT_AMT
			,''								COST_HIRE_HAUL
			,''								COST_OWN_HAUL
			,''								CHRG_INVC_HAUL_AMT
			,''								COST_HIRE_HAUL_AT_SALES_INVC
			,''								COST_OWN_HAUL_AT_SALES_INVC
			,''								S_INVC
			,''								SALES_CODE
			,''								SPREADER_CODE
			,''								CAT_DESCR
			,''								REGION_CODE
			,''								REGION
			,'Regular Sales'				EXTRA_ORD_TYP_DESCR
			,''		  						ADDR_STATE
			,''								SUB_CAT_CODE
			,''								SUB_CAT_NAME
FROM 	  RA_CUSTOMER_TRX  					RCT,
		  RA_CUSTOMER_TRX_LINES				RCTL,
		  RA_CUST_TRX_LINE_GL_DIST			RCTLGD,
		  XX_COMMAND_ORACLE_MAP			XCOM,
		  GL_CODE_COMBINATIONS_KFV			GCC,
		  RA_CUST_TRX_TYPES					RCTT,
		  RA_BATCH_SOURCES					RBS,
		  RA_CUSTOMERS						RC
WHERE	  RCT.CUSTOMER_TRX_ID				= RCTL.CUSTOMER_TRX_ID
AND		  RCTL.CUSTOMER_TRX_LINE_ID 		= RCTLGD.CUSTOMER_TRX_LINE_ID
AND       RCT.ORG_ID						= XCOM.ORACLE_ORG_ID
AND       RCTLGD.CODE_COMBINATION_ID        = GCC.CODE_COMBINATION_ID
AND		  RCT.CUST_TRX_TYPE_ID				= RCTT.CUST_TRX_TYPE_ID
AND		  RBS.BATCH_SOURCE_ID 				= RCT.BATCH_SOURCE_ID
AND       NVL(RCT.ATTRIBUTE1,'N')			<> to_char(rct.customer_trx_id)
AND       RCTL.LINE_TYPE					='LINE'
AND		  nvl(RCTL.INVENTORY_ITEM_ID,0)		NOT IN(6,4829)
AND       RCTLGD.ACCOUNT_CLASS				='REV'
AND	      NVL(RBS.ATTRIBUTE1,'N')			='Y'
AND		  NVL(RCTT.ATTRIBUTE1,'N')			='Y'
AND		  RCT.BILL_TO_CUSTOMER_ID			=RC.CUSTOMER_ID
AND 	  EXISTS (SELECT 1
		  		  FROM	 AR_PAYMENT_SCHEDULES APS
				  WHERE  APS.CUSTOMER_TRX_ID =  RCT.CUSTOMER_TRX_ID
				  AND	 TRUNC(GL_DATE) BETWEEN P_GL_DATE_FROM AND P_GL_DATE_TO
				 );

  CURSOR C_Get_Plant (b_segment2 VARCHAR2) IS
  SELECT ffvl.description PLANT_NAME
  FROM   FND_FLEX_VALUES_TL ffvl
  ,	   	 FND_FLEX_VALUES ffv
  ,	   	 FND_ID_FLEX_SEGMENTS_VL ffs
  WHERE  ffs.application_column_name = 'SEGMENT2'
  AND	 ffs.flex_value_set_id = ffv.flex_value_set_id
  AND	 ffvl.flex_value_id = ffv.flex_value_id
  AND    ffv.flex_value = b_segment2
  AND	 ffs.id_flex_code = 'GL#';

  cursor c_get_sub_cat (v_seg1 varchar2) is
	SELECT c.segment2
	FROM mtl_categories c,
		 mtl_item_categories ic,
		 mtl_system_items_b b
	WHERE c.category_id = ic.category_id
	and   ic.organization_id = 86
	and   b.inventory_item_id = ic.inventory_item_id
	and   b.segment1 = v_seg1;

  v_org_id						 NUMBER DEFAULT FND_PROFILE.VALUE('ORG_ID');
  v_company						 VARCHAR2(10);
  v_count						 NUMBER;
  r_Get_Data	 				 C_Get_Data%ROWTYPE;
  r_Get_Plant				 	 C_Get_Plant%ROWTYPE;
  v_progress					 VARCHAR2(10);
  v_error						 VARCHAR2(2000);
  v_output_file					 UTL_FILE.FILE_TYPE;
  v_filename					 VARCHAR2(100);
  v_fileloc						 VARCHAR2(100);
  v_existing					 VARCHAR2(1);
  v_SUB_ITEM_CAT				  VARCHAR2(100);


  -- VARIABLES TO PUT IN FILE
  L_SLSMN_EMPL_CODE	  VARCHAR2(100)	DEFAULT NULL;
  L_PROD_CODE		  VARCHAR2(100) DEFAULT NULL;
  L_PROJ_CODE		  VARCHAR2(100) DEFAULT NULL;
  L_CAT_CODE		  VARCHAR2(100) DEFAULT NULL;
  L_PROJ_NAME		  VARCHAR2(100) DEFAULT NULL;
  L_ADDR_LINE_1	  	  VARCHAR2(100) DEFAULT NULL;
  L_ADDR_LINE_2	  	  VARCHAR2(100) DEFAULT NULL;
  L_SUB_ITEM_CAT  	  VARCHAR2(100) DEFAULT NULL;
  L_PLANT_NAME		  VARCHAR2(100) DEFAULT NULL;


BEGIN
  WriteLog('START. ', 'XX_TXN_EXTRACT_PKG.Create_File', v_progress);


  SELECT 'CTSALE'||TO_CHAR(SYSDATE,'DDMMYY')||decode(v_org_id,85,'RDL',84,'RPL',83,'JAW')||'.TXT'
  INTO 	  v_filename
  FROM    DUAL;

  v_fileloc := XX_SYSTEM_PKG.GET_XX_VALUE('XX','XX_BASE_DIR') ||'/out/CA';

  v_output_file := UTL_FILE.FOPEN(v_fileloc, v_filename,'W',32767);

  v_count := 0;

  FOR i IN C_Get_Data (p_gl_date_from , p_gl_date_to) LOOP



-- FETCH SALES PERSON NUMBER
    BEGIN

	  SELECT JRS.SALESREP_NUMBER
	  INTO	 L_SLSMN_EMPL_CODE
	  FROM   JTF_RS_SALESREPS JRS
	  WHERE  JRS.SALESREP_ID = NVL(I.PRIMARY_SALESREP_ID,-9999)
	  AND    ORG_ID 		 = V_ORG_ID;

	EXCEPTION

	 WHEN  NO_DATA_FOUND THEN
	  BEGIN
	    SELECT JRS.SALESREP_NUMBER
	    INTO   L_SLSMN_EMPL_CODE
	    FROM   JTF_RS_SALESREPS JRS,
	    	   HZ_CUST_SITE_USES HCSU
	    WHERE  JRS.SALESREP_ID          = HCSU.PRIMARY_SALESREP_ID
	    AND	   HCSU.SITE_USE_CODE       ='BILL_TO'
	    AND	   HCSU.SITE_USE_ID = I.BILL_TO_SITE_USE_ID
	    AND    JRS.ORG_ID               = V_ORG_ID;
	  EXCEPTION
	   WHEN OTHERS THEN
	    fnd_file.put_line(fnd_file.log,'Customer Number '||i.CUST_CODE||' does not have sales representative attached to all sites');
         --		fnd_file.put_line(fnd_file.log,'Error:'||substr(Sqlerrm,1,100));

		RETCODE:=2;
	   END ;

	WHEN OTHERS THEN
	  fnd_file.put_line(fnd_file.log,'Customer Number '||i.CUST_CODE||' does not have sales representative attached to all sites');
      --        fnd_file.put_line(fnd_file.Log,'Unable to get SALES REP NUMBER for Transaction/Customer: '||I.INVC_CODE||'/'||i.CUST_CODE );
	  fnd_file.put_line(fnd_file.log,'Error:'||substr(Sqlerrm,1,100));

	  RETCODE := 2;

	END ;

	-- fetch item number
	BEGIN
 	  SELECT MSIB.SEGMENT1,
        	 MC.SEGMENT2
	  INTO   L_PROD_CODE,
	  		 L_SUB_ITEM_CAT
	  FROM   MTL_SYSTEM_ITEMS_B  MSIB,
 	   		 MTL_ITEM_CATEGORIES MIC,
	   		 MTL_CATEGORIES      MC
	  WHERE  MSIB.INVENTORY_ITEM_ID = NVL(I.INVENTORY_ITEM_ID,-9999)
	  AND	 MSIB.INVENTORY_ITEM_ID = MIC.INVENTORY_ITEM_ID
	  AND	 MSIB.ORGANIZATION_ID	= MIC.ORGANIZATION_ID
	  AND    MIC.CATEGORY_ID 		= MC.CATEGORY_ID
	  AND	 MSIB.ORGANIZATION_ID = 86
	  AND    MSIB.SEGMENT1 NOT LIKE 'EU%';



	EXCEPTION
	WHEN NO_DATA_FOUND THEN
	  IF I.RCTT_ATTRIBUTE2 IS NOT NULL THEN
	   L_PROD_CODE := i.RCTT_ATTRIBUTE2;
	   L_SUB_ITEM_CAT:= substr(i.RCTT_ATTRIBUTE2,1,4);
	  ELSE
	   fnd_file.put_line(fnd_file.log,'Transaction Type '||I.trx_type ||'does not have default product attached');
	   RETCODE:=2;
	  END IF;

	WHEN OTHERS THEN
	   fnd_file.put_line(fnd_file.log,'Transaction Type '||I.trx_type ||'does not have default product attached');
	   RETCODE:=2;

	END;



	-- fETCH PROJ_CODE

	BEGIN
	  IF i.BATCH_SOURCE = 'PROJECTS INVOICES' THEN  -- cc 241
	     L_PROJ_CODE := I.INTERFACE_LINE_ATTRIBUTE1;
	  ELSE
		 SELECT    NVL(SUBSTR(HPS.PARTY_SITE_NUMBER,1,INSTR(HPS.PARTY_SITE_NUMBER,'-')-1),SUBSTR(HPS.PARTY_SITE_NUMBER,1,12))
	 	 INTO      L_PROJ_CODE
		 FROM      HZ_CUST_SITE_USES  SU_BILL,
		 	   	   HZ_CUST_ACCT_SITES RAA_BILL,
		 		   HZ_PARTY_SITES 		  HPS
		 WHERE 	   SU_BILL.SITE_USE_ID 		  =  I.BILL_TO_SITE_USE_ID
		 AND       SU_BILL.CUST_ACCT_SITE_ID  =  RAA_BILL.CUST_ACCT_SITE_ID
		 AND       RAA_BILL.PARTY_SITE_ID     =  HPS.PARTY_SITE_ID;
	  END IF;

	EXCEPTION
	  WHEN OTHERS THEN

	   fnd_file.put_line(fnd_file.log,'Unable to fetch the Proj_code.');
   	   fnd_file.put_line(fnd_file.log,I.BILL_TO_SITE_USE_ID||'-'||SQLERRM );
	   RETCODE:=2;

	END;

-- FETCH PLANT NAME


	BEGIN
	  SELECT  SUBSTR(ffvl.description,1,100)
	  INTO 	  L_PLANT_NAME
	  FROM    FND_FLEX_VALUES_TL ffvl
	    	 ,FND_FLEX_VALUES ffv
			 ,FND_ID_FLEX_SEGMENTS_VL ffs
	  WHERE   FFS.APPLICATION_COLUMN_NAME = 'SEGMENT2'
  	  AND	  FFS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
	  AND	  FFVL.FLEX_VALUE_ID = FFV.FLEX_VALUE_ID
	  AND     FFV.FLEX_VALUE = I.SHIP_PLANT_CODE
	  AND	  FFS.ID_FLEX_CODE = 'GL#';
	EXCEPTION
	  WHEN OTHERS THEN
	     L_PLANT_NAME := NULL;

	END;

 -- PROJ_NAME

	BEGIN
	  IF i.BATCH_SOURCE = 'PROJECTS INVOICES' THEN -- cc 241

		SELECT PP.NAME
		INTO   L_PROJ_NAME
		FROM   PA_PROJECTS PP
		WHERE  PP.SEGMENT1 = I.PROJ_NAME;

	  END IF;

	   BEGIN

		   SELECT HL.ADDRESS1,
		   		  HL.ADDRESS2
		   INTO	  L_ADDR_LINE_1,
		   		  L_ADDR_LINE_2
		   FROM   HZ_CUST_SITE_USES  HSU ,
		   		  HZ_CUST_ACCT_SITES HCS,
		   		  HZ_PARTY_SITES HPS,
		   		  HZ_LOCATIONS HL
		   WHERE  HSU.CUST_ACCT_SITE_ID = HCS.CUST_ACCT_SITE_ID
		   AND    HCS.PARTY_SITE_ID     = HPS.PARTY_SITE_ID
		   AND    HPS.LOCATION_ID		= HL.LOCATION_ID
		   AND    HSU.SITE_USE_CODE     = 'SHIP_TO'
		   AND    HSU.SITE_USE_ID	    = I.SHIP_TO_SITE_USE_ID;

	 EXCEPTION

	   WHEN NO_DATA_FOUND THEN

		 BEGIN

           SELECT HL.ADDRESS1,
		   		  HL.ADDRESS2
		   INTO	  L_ADDR_LINE_1,
		   		  L_ADDR_LINE_2
		   FROM   HZ_CUST_SITE_USES  HSU ,
		   		  HZ_CUST_ACCT_SITES HCS,
		   		  HZ_PARTY_SITES HPS,
		   		  HZ_LOCATIONS HL
		   WHERE  HSU.CUST_ACCT_SITE_ID = HCS.CUST_ACCT_SITE_ID
		   AND    HCS.PARTY_SITE_ID     = HPS.PARTY_SITE_ID
		   AND    HPS.LOCATION_ID		= HL.LOCATION_ID
		   AND    HSU.SITE_USE_CODE     = 'BILL_TO'
		   AND    HSU.SITE_USE_ID	    = I.BILL_TO_SITE_USE_ID;
		EXCEPTION
		  WHEN OTHERS THEN
		    FND_FILE.PUT_LINE(FND_FILE.LOG,'unable to Fetch Proj Name, Addres Line1, Address Line2 for the trx:'||I.INVC_CODE);

			RETCODE:=2;
		END;

	 WHEN OTHERS THEN
	      FND_FILE.PUT_LINE(FND_FILE.LOG,'unable to Fetch Proj Name, Addres Line1, Address Line2 for the trx:'||I.INVC_CODE);
		  RETCODE:=2;

	 END;
	EXCEPTION
	 WHEN OTHERS THEN
	      FND_FILE.PUT_LINE(FND_FILE.LOG,'unable to Fetch Proj Name for the Project Invoice with trx:'||I.INVC_CODE);
		  RETCODE:=2;


	END;



	UTL_FILE.PUT_LINE (v_output_file, i.COMP_CODE_ORDR ||'|'|| i.COMP_CODE_INVC
					  ||'|'|| i.INVC_CODE  ||'|'||	i.INVC_DATE
					  ||'|'|| i.SHIP_PLANT_CODE	  ||'|'||	i.TKT_DATE
					  ||'|'|| i.ORDER_TYPE	  ||'|'||i.TRUCK_CODE
					  ||'|'|| i.HLER_CODE	  ||'|'||	i.REMOVE_RSN_CODE
					  ||'|'|| i.MONTH	  ||'|'||	i.YEAR
					  ||'|'|| L_SLSMN_EMPL_CODE	  ||'|'||	i.SALES_ANL_CODE
					  ||'|'|| i.PO	  ||'|'||	i.ORDER_DATE
					  ||'|'|| i.ORDER_CODE	  ||'|'||	i.TKT_CODE
					  ||'|'|| L_PROD_CODE	  ||'|'||	i.DESCR
					  ||'|'|| i.DELV_QTY	  ||'|'||	i.DELV_QTY
					  ||'|'|| i.DELV_QTY_UOM	  ||'|'||	i.EXT_PRICE_AMT
					  ||'|'|| i.ORDER_INTRNL_LINE_NUM	  ||'|'||	i.DELV_METH_CODE
					  ||'|'|| i.EQUIV_ABBR	  ||'|'||	i.EQUIV_QTY
					  ||'|'|| i.TYPE_PRICE	  ||'|'||	i.TKT_CHRG_CODE
					  ||'|'|| i.UNIT_PRICE	  ||'|'||	i.HAUL_CHRG_TO_CUST
					  ||'|'|| L_PROD_CODE	  ||'|'||	i.PD  ||'|'||	i.EXT_AMT
					  ||'|'|| i.PSC	  ||'|'||	i.CUST_CODE  ||'|'||	i.CUST_NAME
					  ||'|'|| L_PROJ_CODE	  ||'|'||	i.ZONE_CODE
					  ||'|'|| i.EXTRA_ORD_TYP ||'|'||	i.HAUL_CHRG_TO_CUST_HIRE
					  ||'|'|| i.HAUL_CHRG_TO_CUST_OWN	  ||'|'||	i.TOT_AMT
					  ||'|'|| i.COST_HIRE_HAUL  ||'|'||	i.COST_OWN_HAUL
					  ||'|'|| i.CHRG_INVC_HAUL_AMT  ||'|'||	i.COST_HIRE_HAUL_AT_SALES_INVC
					  ||'|'|| i.COST_OWN_HAUL_AT_SALES_INVC  ||'|'||	i.SALES_CODE
					  ||'|'|| i.SPREADER_CODE	  ||'|'||	substr(nvl(L_PROD_CODE,'00'),1,2)
					  ||'|'|| i.CAT_DESCR	  ||'|'||	L_SUB_ITEM_CAT
					  ||'|'|| i.COMP_NAME	  ||'|'||	L_PLANT_NAME
					  ||'|'|| i.REGION_CODE	  ||'|'||	I.REGION
					  ||'|'|| i.EXTRA_ORD_TYP_DESCR  ||'|'||	nvl(L_PROJ_NAME,L_ADDR_LINE_2)
					  ||'|'|| L_ADDR_LINE_1  ||'|'||	L_ADDR_LINE_2
					  ||'|'|| i.ADDR_STATE  ||'|'||	i.SUB_CAT_CODE
					  ||'|'|| i.SUB_CAT_NAME
					  ||'|'			);

	v_count := v_count + 1;

--	 Update DFF so the transaction does not get extracted again.
	UPDATE ra_customer_trx_all X
	SET   attribute1 = i.customer_Trx_id
	WHERE X.ROWID = i.TRX_ROW_ID;

  END LOOP;

  UTL_FILE.FCLOSE(v_output_file);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'File '||v_filename||' created successfully with '||v_count||' lines.');

  WriteLog('END. ', 'XX_PROJECT_INVOICES_PKG.Insert_Project_Invoices_Data', v_progress);

  IF RETCODE=2 THEN
    Rollback;

	UTL_FILE.Fremove(v_fileloc, v_filename);
	FND_FILE.PUT_LINE(FND_FILE.LOG,'File not generated as there are errors. Please refer the log file, correct the errors and rerun the program');

  END IF;

EXCEPTION WHEN OTHERS THEN
  v_error := SQLERRM;
  DBMS_OUTPUT.PUT_LINE(V_ERROR);
  WriteLog(v_error, 'XX_PROJECT_INVOICES_PKG.Insert_Project_Invoices_Data', v_progress);
  fnd_file.put_line(FND_FILE.LOG, 'Load Failed: '||v_error);
  RAISE;

END create_file;

END XX_TXN_EXTRACT_PKG;
