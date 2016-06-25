/* For Supplier Bank Account Number Use This One */
SELECT   bank_account_name
,        bank_account_num
,        branch_id
FROM     iby_ext_bank_accounts
WHERE    ext_bank_account_id IN
         (
         SELECT   ext_bank_account_id
         FROM     iby_account_owners
         WHERE    account_owner_party_id IN
                  (
                  SELECT   party_id
                  FROM     hz_party_sites
                  WHERE    party_site_name LIKE '%UPC%'
                  )
         )

/* USE THIS QUERY TO GET BANK NAME AND BANK BRANCH NAME OF SUPPLIER BANK*/
SELECT   BANKORGPROFILE.HOME_COUNTRY BANK_HOME_COUNTRY,
BANKORGPROFILE.PARTY_ID BANK_PARTY_ID,
BANKORGPROFILE.ORGANIZATION_NAME BANK_NAME,
BANKORGPROFILE.BANK_OR_BRANCH_NUMBER BANK_NUMBER,
BRANCHPARTY.PARTY_ID BRANCH_PARTY_ID,
BRANCHPARTY.PARTY_NAME BANK_BRANCH_NAME,
BRANCHPARTY.PARTY_ID
FROM HZ_ORGANIZATION_PROFILES BANKORGPROFILE,
HZ_CODE_ASSIGNMENTS BANKCA,
HZ_PARTIES BRANCHPARTY,
HZ_ORGANIZATION_PROFILES BRANCHORGPROFILE,
HZ_CODE_ASSIGNMENTS BRANCHCA,
HZ_RELATIONSHIPS BRREL,
HZ_CODE_ASSIGNMENTS BRANCHTYPECA,
HZ_CONTACT_POINTS BRANCHCP,
HZ_CONTACT_POINTS EDICP
WHERE SYSDATE BETWEEN TRUNC (BANKORGPROFILE.EFFECTIVE_START_DATE)
AND NVL (TRUNC (BANKORGPROFILE.EFFECTIVE_END_DATE),SYSDATE + 1)
AND BANKCA.CLASS_CATEGORY = 'BANK_INSTITUTION_TYPE'
AND BANKCA.CLASS_CODE IN ('BANK', 'CLEARINGHOUSE')
AND BANKCA.OWNER_TABLE_NAME = 'HZ_PARTIES'
AND (BANKCA.STATUS = 'A' OR BANKCA.STATUS IS NULL)
AND BANKCA.OWNER_TABLE_ID = BANKORGPROFILE.PARTY_ID
AND BRANCHPARTY.PARTY_TYPE = 'ORGANIZATION'
AND BRANCHPARTY.STATUS = 'A'
AND BRANCHORGPROFILE.PARTY_ID = BRANCHPARTY.PARTY_ID
AND SYSDATE BETWEEN TRUNC (BRANCHORGPROFILE.EFFECTIVE_START_DATE)
AND NVL (TRUNC (BRANCHORGPROFILE.EFFECTIVE_END_DATE),SYSDATE + 1)
AND BRANCHCA.CLASS_CATEGORY = 'BANK_INSTITUTION_TYPE'
AND BRANCHCA.CLASS_CODE IN ('BANK_BRANCH', 'CLEARINGHOUSE_BRANCH')
AND BRANCHCA.OWNER_TABLE_NAME = 'HZ_PARTIES'
AND (BRANCHCA.STATUS = 'A' OR BRANCHCA.STATUS IS NULL)
AND BRANCHCA.OWNER_TABLE_ID = BRANCHPARTY.PARTY_ID
AND BANKORGPROFILE.PARTY_ID = BRREL.OBJECT_ID
AND BRREL.RELATIONSHIP_TYPE = 'BANK_AND_BRANCH'
AND BRREL.RELATIONSHIP_CODE = 'BRANCH_OF'
AND BRREL.STATUS = 'A'
AND BRREL.SUBJECT_TABLE_NAME = 'HZ_PARTIES'
AND BRREL.SUBJECT_TYPE = 'ORGANIZATION'
AND BRREL.OBJECT_TABLE_NAME = 'HZ_PARTIES'
AND BRREL.OBJECT_TYPE = 'ORGANIZATION'
AND BRREL.SUBJECT_ID = BRANCHPARTY.PARTY_ID
AND BRANCHTYPECA.CLASS_CATEGORY(+) = 'BANK_BRANCH_TYPE'
AND BRANCHTYPECA.PRIMARY_FLAG(+) = 'Y'
AND BRANCHTYPECA.OWNER_TABLE_NAME(+) = 'HZ_PARTIES'
AND BRANCHTYPECA.OWNER_TABLE_ID(+) = BRANCHPARTY.PARTY_ID
AND BRANCHTYPECA.STATUS(+) = 'A'
AND BRANCHCP.OWNER_TABLE_NAME(+) = 'HZ_PARTIES'
AND BRANCHCP.OWNER_TABLE_ID(+) = BRANCHPARTY.PARTY_ID
AND BRANCHCP.CONTACT_POINT_TYPE(+) = 'EFT'
AND BRANCHCP.STATUS(+) = 'A'
AND EDICP.OWNER_TABLE_NAME(+) = 'HZ_PARTIES'
AND EDICP.OWNER_TABLE_ID(+) = BRANCHPARTY.PARTY_ID
AND EDICP.CONTACT_POINT_TYPE(+) = 'EDI'
AND EDICP.STATUS(+) = 'A'
AND BRANCHCA.OWNER_TABLE_ID = :IBY_BRANCH_ID /*USER BRANCH ID FROM ABOVE QUERY*/