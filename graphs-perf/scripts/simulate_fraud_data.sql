SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON
SET DEFINE OFF
WHENEVER SQLERROR CONTINUE

SPOOL scripts/simulate_fraud_data_out.txt

-- Assumes you are already connected as GRAPHUSER. If needed, CONNECT manually before running.

PROMPT === Ensure prerequisite device and merchants exist (idempotent) ===
INSERT INTO fraud_devices_t (device_id, device_fingerprint, device_type, risk_score, is_flagged)
SELECT 99999901, 'DFP' || TO_CHAR(99999901), 'MOBILE', 90, 1
FROM dual
WHERE NOT EXISTS (SELECT 1 FROM fraud_devices_t WHERE device_id = 99999901);

INSERT INTO fraud_merchants_t (merchant_id, merchant_name, category, risk_score, is_flagged)
SELECT x.merchant_id, 'MERCH_' || TO_CHAR(x.merchant_id), 'RISK', 90, 0
FROM (SELECT 88888801 AS merchant_id FROM dual
      UNION ALL
      SELECT 88888802 FROM dual) x
WHERE NOT EXISTS (SELECT 1 FROM fraud_merchants_t m WHERE m.merchant_id = x.merchant_id);

COMMIT;

PROMPT === Inject flagged transactions for shared-device and many-to-one patterns (set-based) ===
-- Pick three existing accounts deterministically
INSERT INTO fraud_transactions_t (transaction_id, amount, transaction_date, risk_score, is_flagged, account_id, device_id, merchant_id)
SELECT
  900000000 + LEVEL AS transaction_id,
  100 + LEVEL       AS amount,
  TRUNC(SYSDATE) - TRUNC(DBMS_RANDOM.VALUE(0, 6)) AS transaction_date,
  95                AS risk_score,
  1                 AS is_flagged,
  (SELECT account_id FROM (SELECT account_id, ROW_NUMBER() OVER (ORDER BY account_id) rn FROM fraud_accounts_t) WHERE rn = 1) AS account_id,
  99999901          AS device_id,
  88888801          AS merchant_id
FROM dual CONNECT BY LEVEL <= 10
UNION ALL
SELECT
  900000100 + LEVEL,
  120 + LEVEL,
  TRUNC(SYSDATE) - TRUNC(DBMS_RANDOM.VALUE(0, 6)),
  93,
  1,
  (SELECT account_id FROM (SELECT account_id, ROW_NUMBER() OVER (ORDER BY account_id) rn FROM fraud_accounts_t) WHERE rn = 2),
  99999901,
  88888801
FROM dual CONNECT BY LEVEL <= 10
UNION ALL
SELECT
  900000200 + LEVEL,
  80 + LEVEL,
  TRUNC(SYSDATE) - TRUNC(DBMS_RANDOM.VALUE(0, 6)),
  92,
  1,
  CASE MOD(LEVEL,3)
    WHEN 1 THEN (SELECT account_id FROM (SELECT account_id, ROW_NUMBER() OVER (ORDER BY account_id) rn FROM fraud_accounts_t) WHERE rn = 1)
    WHEN 2 THEN (SELECT account_id FROM (SELECT account_id, ROW_NUMBER() OVER (ORDER BY account_id) rn FROM fraud_accounts_t) WHERE rn = 2)
    ELSE         (SELECT account_id FROM (SELECT account_id, ROW_NUMBER() OVER (ORDER BY account_id) rn FROM fraud_accounts_t) WHERE rn = 3)
  END,
  99999901 + LEVEL,
  88888802
FROM dual CONNECT BY LEVEL <= 6;

PROMPT === Set locations (tx_location) for injected rows (NORTH for shared; SOUTH for many-to-one) ===
-- NORTH hemisphere for shared-device set (transaction_id 900000000–900000199)
UPDATE fraud_transactions_t
SET tx_location = SDO_GEOMETRY(
  2001, 4326,
  SDO_POINT_TYPE(
    -100 + MOD(transaction_id, 200),  -- LONG
    10 + MOD(transaction_id, 50),     -- LAT
    NULL
  ),
  NULL, NULL
)
WHERE transaction_id BETWEEN 900000000 AND 900000199;

-- SOUTH hemisphere for many-to-one set (transaction_id 900000200–900000299)
UPDATE fraud_transactions_t
SET tx_location = SDO_GEOMETRY(
  2001, 4326,
  SDO_POINT_TYPE(
    -60 + MOD(transaction_id, 120),   -- LONG
    -10 - MOD(transaction_id, 50),    -- LAT
    NULL
  ),
  NULL, NULL
)
WHERE transaction_id BETWEEN 900000200 AND 900000299;

PROMPT === Ensure Customer->Device mapping for the shared device (idempotent) ===
INSERT INTO fraud_customer_devices_t (customer_id, device_id)
WITH acc AS (
  SELECT account_id, rn
  FROM (
    SELECT account_id, ROW_NUMBER() OVER (ORDER BY account_id) rn
    FROM fraud_accounts_t
  )
  WHERE rn <= 2
)
SELECT a.customer_id, 99999901
FROM fraud_accounts_t a
JOIN acc b ON a.account_id = b.account_id
WHERE NOT EXISTS (
  SELECT 1 FROM fraud_customer_devices_t f
  WHERE f.customer_id = a.customer_id AND f.device_id = 99999901
);

COMMIT;

PROMPT === Verify injected row counts ===
SET SQLFORMAT CSV
SELECT COUNT(*) AS injected_tx_rows
FROM fraud_transactions_t
WHERE transaction_id BETWEEN 900000000 AND 900000299;

SELECT COUNT(*) AS injected_uses_device_rows
FROM fraud_customer_devices_t
WHERE device_id = 99999901;

SPOOL OFF
EXIT
