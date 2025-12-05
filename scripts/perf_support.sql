SET ECHO ON
SET FEEDBACK ON
WHENEVER SQLERROR CONTINUE

SPOOL scripts\perf_support_out.txt

CONNECT graphuser/Admin123@//localhost:1521/FREEPDB1

PROMPT === Create canonical account view per customer (to avoid account-pair blowup) ===
CREATE OR REPLACE VIEW v_customer_main_account AS
SELECT
  customer_id,
  MIN(account_id) AS main_account_id
FROM fraud_accounts_t
GROUP BY customer_id;

PROMPT === Verify view ===
SET SQLFORMAT CSV
SELECT COUNT(*) AS rows_in_view FROM v_customer_main_account;

SPOOL OFF
EXIT
