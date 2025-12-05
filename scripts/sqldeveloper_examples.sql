-- Simple SQL Developer queries to visualize FRAUD_GRAPH patterns
-- Notes:
-- - Use SQL/PGQ label syntax: (n IS label)
-- - GRAPH_TABLE header: GRAPH_TABLE(fraud_graph MATCH ... COLUMNS (...))
-- - Include COLUMNS even for simple queries
-- - You can run any query here in SQL Developer and use the Visualize feature

PROMPT === Q1: Accounts -> Transactions (first 100) ===
SELECT
  account_id,
  transaction_id,
  edge_type,
  risk_score
FROM GRAPH_TABLE(fraud_graph MATCH
  (a IS account)-[e IS performed_transaction]->(t IS transaction)
  COLUMNS (
    a.account_id           AS account_id,
    t.transaction_id       AS transaction_id,
    'performed_transaction' AS edge_type,
    t.risk_score           AS risk_score
  )
) GT
FETCH FIRST 100 ROWS ONLY;

PROMPT === Q2: High-risk transactions (>= 90) and their devices (first 100) ===
SELECT
  account_id,
  transaction_id,
  device_id,
  risk_score
FROM GRAPH_TABLE(fraud_graph MATCH
  (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.risk_score >= 90
  COLUMNS (
    a.account_id     AS account_id,
    t.transaction_id AS transaction_id,
    d.device_id      AS device_id,
    t.risk_score     AS risk_score
  )
) GT
FETCH FIRST 100 ROWS ONLY;

PROMPT === Q3: Flagged transactions to merchants (first 100) ===
SELECT
  account_id,
  transaction_id,
  merchant_id,
  is_flagged
FROM GRAPH_TABLE(fraud_graph MATCH
  (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
  COLUMNS (
    a.account_id     AS account_id,
    t.transaction_id AS transaction_id,
    m.merchant_id    AS merchant_id,
    t.is_flagged     AS is_flagged
  )
) GT
FETCH FIRST 100 ROWS ONLY;

PROMPT === Q4 (bounded): Account pairs sharing a device in last 7 days (first 100) ===
-- Bounded version to keep results small for visualization.
-- Adjust days and degree cap as needed (see final WHERE EXISTS filter).
SELECT
  a1,
  a2,
  did
FROM (
  SELECT
    a1.account_id AS a1,
    a2.account_id AS a2,
    d.device_id   AS did
  FROM GRAPH_TABLE(fraud_graph MATCH
    (a1 IS account)-[p1 IS performed_transaction]->(t1 IS transaction)-[h1 IS has_device]->(d IS device),
    (a2 IS account)-[p2 IS performed_transaction]->(t2 IS transaction)-[h2 IS has_device]->(d IS device)
    WHERE a1.account_id < a2.account_id
      AND t1.transaction_date >= SYSDATE - 7
      AND t2.transaction_date >= SYSDATE - 7
    COLUMNS (
      a1.account_id AS a1,
      a2.account_id AS a2,
      d.device_id   AS did
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
    WHERE F.device_id = GT.did
  )
)
FETCH FIRST 100 ROWS ONLY;

-- Tip:
-- After running any SELECT above, click the Visualize icon in SQL Developer to see a graph view.
-- For a nice overview screenshot, run Q1 or Q2 and visualize.
