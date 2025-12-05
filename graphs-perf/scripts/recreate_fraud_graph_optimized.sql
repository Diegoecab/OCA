SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON
WHENEVER SQLERROR CONTINUE

SPOOL scripts\recreate_fraud_graph_optimized_out.txt

CONNECT graphuser/Admin123@//localhost:1521/FREEPDB1

PROMPT === Add supporting indexes for edges ===
BEGIN
  EXECUTE IMMEDIATE 'CREATE INDEX idx_fcd_dev_cust ON fraud_customer_devices_t(device_id, customer_id)';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -955 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'CREATE INDEX idx_fa_cust_acct ON fraud_accounts_t(customer_id, account_id)';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

PROMPT === Gather stats on base tables used by edges ===
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(USER,'FRAUD_CUSTOMERS_T',cascade=>TRUE);
  DBMS_STATS.GATHER_TABLE_STATS(USER,'FRAUD_ACCOUNTS_T',cascade=>TRUE);
  DBMS_STATS.GATHER_TABLE_STATS(USER,'FRAUD_TRANSACTIONS_T',cascade=>TRUE);
  DBMS_STATS.GATHER_TABLE_STATS(USER,'FRAUD_DEVICES_T',cascade=>TRUE);
  DBMS_STATS.GATHER_TABLE_STATS(USER,'FRAUD_MERCHANTS_T',cascade=>TRUE);
  DBMS_STATS.GATHER_TABLE_STATS(USER,'FRAUD_CUSTOMER_DEVICES_T',cascade=>TRUE);
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

PROMPT === Drop and recreate FRAUD_GRAPH with optimized edges (owns_account, uses_device) ===
DROP PROPERTY GRAPH fraud_graph;

CREATE PROPERTY GRAPH fraud_graph
  VERTEX TABLES (
    fraud_customers_t   KEY (customer_id) LABEL customer,
    fraud_accounts_t    KEY (account_id)  LABEL account,
    fraud_transactions_t KEY (transaction_id) LABEL transaction,
    fraud_devices_t     KEY (device_id)   LABEL device,
    fraud_merchants_t   KEY (merchant_id) LABEL merchant
  )
  EDGE TABLES (
    fraud_accounts_t AS owns_account
      KEY (customer_id, account_id)
      SOURCE KEY (customer_id) REFERENCES fraud_customers_t (customer_id)
      DESTINATION KEY (account_id) REFERENCES fraud_accounts_t (account_id),

    fraud_transactions_t AS performed_transaction
      KEY (transaction_id)
      SOURCE KEY (account_id) REFERENCES fraud_accounts_t (account_id)
      DESTINATION KEY (transaction_id) REFERENCES fraud_transactions_t (transaction_id),

    fraud_transactions_t AS has_device
      KEY (transaction_id, device_id)
      SOURCE KEY (transaction_id) REFERENCES fraud_transactions_t (transaction_id)
      DESTINATION KEY (device_id) REFERENCES fraud_devices_t (device_id),

    fraud_transactions_t AS paid_to
      KEY (transaction_id, merchant_id)
      SOURCE KEY (transaction_id) REFERENCES fraud_transactions_t (transaction_id)
      DESTINATION KEY (merchant_id) REFERENCES fraud_merchants_t (merchant_id),

    fraud_customer_devices_t AS uses_device
      KEY (customer_id, device_id)
      SOURCE KEY (customer_id) REFERENCES fraud_customers_t (customer_id)
      DESTINATION KEY (device_id) REFERENCES fraud_devices_t (device_id)
  );

PROMPT === Verify graph exists ===
SET SQLFORMAT CSV
SELECT graph_name FROM user_property_graphs WHERE UPPER(graph_name)='FRAUD_GRAPH';

SPOOL OFF
EXIT
