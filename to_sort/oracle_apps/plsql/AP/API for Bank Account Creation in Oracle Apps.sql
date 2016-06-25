/*
API for Bank Account Creation in Oracle Apps

CE_BANK_PUB.CREATE_BANK_ACCT API is used to create a bank account for the branch party id passed as an input parameter. The API uses the BANKACCT_REC_TYPE record to pass the input values. On successful creation of bank account, the API returns the bank account id along with the information /error messages. The API returns a null bank account id if the bank branch is not created.
*/

DECLARE

   p_init_msg_list   VARCHAR2 (200);
   p_acct_rec        apps.ce_bank_pub.bankacct_rec_type;
   x_acct_id         NUMBER;
   x_return_status   VARCHAR2 (200);
   x_msg_count       NUMBER;
   x_msg_data        VARCHAR2 (200);
   p_count           NUMBER;

BEGIN
   p_init_msg_list := NULL;
   -- HZ_PARTIES.PARTY_ID BANK BRANCH
   p_acct_rec.branch_id := 8056;
   -- HZ_PARTIES.PARTY_ID BANK
   p_acct_rec.bank_id := 8042;
   -- HZ_PARTIES.PARTY_ID ORGANIZATION
   p_acct_rec.account_owner_org_id := 23273;
   -- HZ_PARTIES.PARTY_ID Person related to ABOVE ORGANIZATION 
   p_acct_rec.account_owner_party_id := 2041;

   p_acct_rec.account_classification := 'INTERNAL';
   p_acct_rec.bank_account_name := 'Test Bank Accunt';
   p_acct_rec.bank_account_num := 14256789;
   p_acct_rec.currency := 'INR';
   p_acct_rec.start_date := SYSDATE;
   p_acct_rec.end_date := NULL;

   CE_BANK_PUB.CREATE_BANK_ACCT
                  (p_init_msg_list      => p_init_msg_list,
                   p_acct_rec           => p_acct_rec,
                   x_acct_id            => x_acct_id,
                   x_return_status      => x_return_status,
                   x_msg_count          => x_msg_count,
                   x_msg_data           => x_msg_data
                  );
                        
   DBMS_OUTPUT.put_line ('X_ACCT_ID = ' || x_acct_id);
   DBMS_OUTPUT.put_line ('X_RETURN_STATUS = ' || x_return_status);
   DBMS_OUTPUT.put_line ('X_MSG_COUNT = ' || x_msg_count);
   DBMS_OUTPUT.put_line ('X_MSG_DATA = ' || x_msg_data);

   IF x_msg_count = 1
   THEN
      DBMS_OUTPUT.put_line ('x_msg_data ' || x_msg_data);
   ELSIF x_msg_count > 1
   THEN
      LOOP
         p_count := p_count + 1;
         x_msg_data := fnd_msg_pub.get (fnd_msg_pub.g_next, fnd_api.g_false);

         IF x_msg_data IS NULL
         THEN
            EXIT;
         END IF;

         DBMS_OUTPUT.put_line ('Message' || p_count || ' ---' || x_msg_data);
      END LOOP;
   END IF;
END;