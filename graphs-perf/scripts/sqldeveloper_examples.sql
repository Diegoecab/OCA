-- Simple SQL Developer queries to visualize FRAUD_GRAPH patterns
-- Notes:
-- - Use SQL/PGQ label syntax: (n IS label)
-- - GRAPH_TABLE header: GRAPH_TABLE(fraud_graph MATCH ... COLUMNS (...))
-- - Include COLUMNS with vertex_id and/or edge_id for visualization
-- - Run any SELECT and click the Visualize icon in SQL Developer

PROMPT === Q1 Vertices: Accounts (first 100) ===
SELECT
  VERTEX_ID,
  label,
  account_id
FROM GRAPH_TABLE(fraud_graph MATCH
  (a IS account)
  COLUMNS (
    VERTEX_ID(a) AS VERTEX_ID,
    'account'   AS label,
    a.account_id AS account_id
  )
) GT
FETCH FIRST 100 ROWS ONLY;

PROMPT === Q1 Vertices: Transactions (first 100) ===
SELECT
  VERTEX_ID,
  label,
  transaction_id,
  risk_score
FROM GRAPH_TABLE(fraud_graph MATCH
  (t IS transaction)
  COLUMNS (
    VERTEX_ID(t)       AS VERTEX_ID,
    'transaction'     AS label,
    t.transaction_id  AS transaction_id,
    t.risk_score      AS risk_score
  )
) GT
FETCH FIRST 100 ROWS ONLY;

PROMPT === Q1 Edges: performed_transaction (first 100) ===
SELECT
  EDGE_ID,
  SRC_VERTEX_ID,
  DST_VERTEX_ID,
  edge_label
FROM GRAPH_TABLE(fraud_graph MATCH
  (a IS account)-[e IS performed_transaction]->(t IS transaction)
  COLUMNS (
    EDGE_ID(e)       AS EDGE_ID,
    VERTEX_ID(a)       AS SRC_VERTEX_ID,
    VERTEX_ID(t)       AS DST_VERTEX_ID,
    'performed_transaction' AS edge_label
  )
) GT
FETCH FIRST 100 ROWS ONLY;

PROMPT === Q2 Edges: High-risk (>= 90) has_device (first 100) ===
SELECT
  EDGE_ID,
  SRC_VERTEX_ID,
  DST_VERTEX_ID,
  transaction_id,
  device_id,
  risk_score,
  edge_label
FROM GRAPH_TABLE(fraud_graph MATCH
  (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.risk_score >= 90
  COLUMNS (
    EDGE_ID(h)         AS EDGE_ID,
    VERTEX_ID(t)         AS SRC_VERTEX_ID,
    VERTEX_ID(d)         AS DST_VERTEX_ID,
    t.transaction_id  AS transaction_id,
    d.device_id       AS device_id,
    t.risk_score      AS risk_score,
    'has_device'      AS edge_label
  )
) GT
FETCH FIRST 100 ROWS ONLY;

PROMPT === Q3 Edges: Flagged paid_to (first 100) ===
SELECT
  EDGE_ID,
  SRC_VERTEX_ID,
  DST_VERTEX_ID,
  transaction_id,
  merchant_id,
  is_flagged,
  edge_label
FROM GRAPH_TABLE(fraud_graph MATCH
  (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
  COLUMNS (
    EDGE_ID(pm)        AS EDGE_ID,
    VERTEX_ID(t)         AS SRC_VERTEX_ID,
    VERTEX_ID(m)         AS DST_VERTEX_ID,
    t.transaction_id  AS transaction_id,
    m.merchant_id     AS merchant_id,
    t.is_flagged      AS is_flagged,
    'paid_to'         AS edge_label
  )
) GT
FETCH FIRST 100 ROWS ONLY;

PROMPT === Q4 (bounded) Synthetic Edges: Account pairs sharing a device in last 7 days (first 100) ===
-- This creates a synthetic edge between accounts that shared a device recently, with a degree cap to avoid explosion.
SELECT
  EDGE_ID,           -- synthetic edge id suitable for visualization
  SRC_VERTEX_ID,     -- a1 vertex_id
  DST_VERTEX_ID,     -- a2 vertex_id
  a1_id,
  a2_id,
  device_id,
  edge_label
FROM GRAPH_TABLE(fraud_graph MATCH
  (a1 IS account)-[p1 IS performed_transaction]->(t1 IS transaction)-[h1 IS has_device]->(d IS device),
  (a2 IS account)-[p2 IS performed_transaction]->(t2 IS transaction)-[h2 IS has_device]->(d IS device)
  WHERE a1.account_id < a2.account_id
    AND t1.transaction_date >= SYSDATE - 7
    AND t2.transaction_date >= SYSDATE - 7
  COLUMNS (
    -- synthetic identifiers for visualization
    TO_CHAR(a1.account_id) || '-' || TO_CHAR(a2.account_id) || '-' || TO_CHAR(d.device_id) AS EDGE_ID,
    VERTEX_ID(a1) AS SRC_VERTEX_ID,
    VERTEX_ID(a2) AS DST_VERTEX_ID,
    a1.account_id AS a1_id,
    a2.account_id AS a2_id,
    d.device_id   AS device_id,
    'shared_device_7d' AS edge_label
  )
) GT
WHERE EXISTS (
  SELECT 1
  FROM (
    SELECT device_id
    FROM fraud_customer_devices_t
    GROUP BY device_id
    HAVING COUNT(DISTINCT customer_id) <= 10
  ) F
  WHERE F.device_id = GT.device_id
)
FETCH FIRST 10000 ROWS ONLY;

-- Tip:
-- After running any SELECT above, click the Visualize icon in SQL Developer to see a graph view.

PROMPT === Fan-out: Devices -> Accounts in last 7 days (first 200) ===
SELECT
  EDGE_ID,
  SRC_VERTEX_ID,
  DST_VERTEX_ID,
  device_id,
  account_id,
  edge_label
FROM GRAPH_TABLE(fraud_graph MATCH
  (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.transaction_date >= SYSDATE - 7
  COLUMNS (
    TO_CHAR(d.device_id) || '->' || TO_CHAR(a.account_id) AS EDGE_ID,
    VERTEX_ID(d) AS SRC_VERTEX_ID,
    VERTEX_ID(a) AS DST_VERTEX_ID,
    d.device_id   AS device_id,
    a.account_id  AS account_id,
    'device_to_account_7d' AS edge_label
  )
) GT
FETCH FIRST 200 ROWS ONLY;

PROMPT === Fan-in: Flagged Transactions -> Merchants in last 7 days (first 200) ===
SELECT
  EDGE_ID,
  SRC_VERTEX_ID,
  DST_VERTEX_ID,
  transaction_id,
  merchant_id,
  edge_label
FROM GRAPH_TABLE(fraud_graph MATCH
  (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
    AND t.transaction_date >= SYSDATE - 7
  COLUMNS (
    EDGE_ID(pm)        AS EDGE_ID,
    VERTEX_ID(t)       AS SRC_VERTEX_ID,
    VERTEX_ID(m)       AS DST_VERTEX_ID,
    t.transaction_id   AS transaction_id,
    m.merchant_id      AS merchant_id,
    'flagged_paid_to_7d' AS edge_label
  )
) GT
FETCH FIRST 200 ROWS ONLY;

PROMPT === One-to-many (synthetic): Accounts -> Devices in last 30 days (first 200) ===
-- Synthetic edge consolidating (account)-performed_transaction->(transaction)-has_device->(device)
SELECT
  EDGE_ID,
  SRC_VERTEX_ID,
  DST_VERTEX_ID,
  account_id,
  device_id,
  edge_label
FROM GRAPH_TABLE(fraud_graph MATCH
  (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.transaction_date >= SYSDATE - 30
  COLUMNS (
    TO_CHAR(a.account_id) || '->' || TO_CHAR(d.device_id) AS EDGE_ID,
    VERTEX_ID(a) AS SRC_VERTEX_ID,
    VERTEX_ID(d) AS DST_VERTEX_ID,
    a.account_id AS account_id,
    d.device_id  AS device_id,
    'account_to_device_30d' AS edge_label
  )
) GT
FETCH FIRST 200 ROWS ONLY;

PROMPT === Many-to-one: All Transactions -> Merchants (first 200) ===
-- Non-flagged inclusive; shows many transactions converging on merchants
SELECT
  EDGE_ID,
  SRC_VERTEX_ID,
  DST_VERTEX_ID,
  transaction_id,
  merchant_id,
  edge_label
FROM GRAPH_TABLE(fraud_graph MATCH
  (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  COLUMNS (
    EDGE_ID(pm)        AS EDGE_ID,
    VERTEX_ID(t)       AS SRC_VERTEX_ID,
    VERTEX_ID(m)       AS DST_VERTEX_ID,
    t.transaction_id   AS transaction_id,
    m.merchant_id      AS merchant_id,
    'paid_to'          AS edge_label
  )
) GT
FETCH FIRST 200 ROWS ONLY;

PROMPT === Two-hop ribbons: Accounts -> Transactions and Transactions -> Merchants (first 200 edges) ===
-- Returns both edge types to visualize a typical purchase ribbon
SELECT
  EDGE_ID,
  SRC_VERTEX_ID,
  DST_VERTEX_ID,
  edge_label
FROM (
  SELECT EDGE_ID(p) AS EDGE_ID, VERTEX_ID(a) AS SRC_VERTEX_ID, VERTEX_ID(t) AS DST_VERTEX_ID, 'performed_transaction' AS edge_label
  FROM GRAPH_TABLE(fraud_graph MATCH
    (a IS account)-[p IS performed_transaction]->(t IS transaction)
    COLUMNS (
      EDGE_ID(p)   AS EDGE_ID,
      VERTEX_ID(a) AS SRC_VERTEX_ID,
      VERTEX_ID(t) AS DST_VERTEX_ID
    )
  ) GT1
  UNION ALL
  SELECT EDGE_ID(pm) AS EDGE_ID, VERTEX_ID(t) AS SRC_VERTEX_ID, VERTEX_ID(m) AS DST_VERTEX_ID, 'paid_to' AS edge_label
  FROM GRAPH_TABLE(fraud_graph MATCH
    (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
    COLUMNS (
      EDGE_ID(pm)  AS EDGE_ID,
      VERTEX_ID(t) AS SRC_VERTEX_ID,
      VERTEX_ID(m) AS DST_VERTEX_ID
    )
  ) GT2
)
FETCH FIRST 200 ROWS ONLY;

-- Tip:
-- After running any of these SELECTs, use the Visualize icon in SQL Developer to render the fan-in/fan-out structures.

PROMPT === Potential Fraud Verification: Shared device flagged account pairs (last 7 days) ===
-- Lists account pairs that share a device with flagged transactions within the last 7 days.
-- Increase HAVING threshold to tighten signal (e.g., >= 3)
SELECT
  did       AS device_id,
  a1        AS account_1,
  a2        AS account_2,
  flagged_count
FROM (
  SELECT
    d.device_id AS did,
    a1.account_id AS a1,
    a2.account_id AS a2,
    COUNT(*) AS flagged_count
  FROM GRAPH_TABLE(fraud_graph MATCH
    (a1 IS account)-[p1 IS performed_transaction]->(t1 IS transaction)-[h1 IS has_device]->(d IS device),
    (a2 IS account)-[p2 IS performed_transaction]->(t2 IS transaction)-[h2 IS has_device]->(d IS device)
    WHERE a1.account_id < a2.account_id
      AND (t1.is_flagged = 1 OR t2.is_flagged = 1)
      AND t1.transaction_date >= SYSDATE - 7
      AND t2.transaction_date >= SYSDATE - 7
    COLUMNS (
      a1.account_id AS a1,
      a2.account_id AS a2,
      d.device_id   AS device_id
    )
  ) GT
  GROUP BY d.device_id, a1, a2
  HAVING COUNT(*) >= 2
) S
ORDER BY flagged_count DESC, device_id, account_1, account_2
FETCH FIRST 200 ROWS ONLY;

PROMPT === Potential Fraud Verification: Merchants with many flagged transactions (last 7 days) ===
-- Adds MERCHANT_VERTEX_ID to satisfy SQL Developer Visualization (vertex view).
-- Increase HAVING threshold to surface higher-risk merchants (e.g., >= 5)
SELECT
  MERCHANT_VERTEX_ID,
  merchant_id,
  COUNT(*) AS flagged_tx_last_7d
FROM GRAPH_TABLE(fraud_graph MATCH
  (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
    AND t.transaction_date >= SYSDATE - 7
  COLUMNS (
    VERTEX_ID(m)   AS MERCHANT_VERTEX_ID,
    m.merchant_id  AS merchant_id
  )
) GT
GROUP BY MERCHANT_VERTEX_ID, merchant_id
HAVING COUNT(*) >= 3
ORDER BY flagged_tx_last_7d DESC, merchant_id
FETCH FIRST 200 ROWS ONLY;
