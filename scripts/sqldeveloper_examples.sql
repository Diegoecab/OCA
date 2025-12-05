-- Simple SQL Developer queries to visualize FRAUD_GRAPH patterns
-- Notes:
-- - Use SQL/PGQ label syntax: (n IS label)
-- - GRAPH_TABLE header: GRAPH_TABLE(fraud_graph MATCH ... COLUMNS (...))
-- - Include COLUMNS with vertex_id and/or edge_id for visualization
-- - Run any SELECT and click the Visualize icon in SQL Developer

PROMPT === Q1 Vertices: Accounts (first 100) ===
SELECT
  vertex_id,
  label,
  account_id
FROM GRAPH_TABLE(fraud_graph MATCH
  (a IS account)
  COLUMNS (
    a.vertex_id AS vertex_id,
    'account'   AS label,
    a.account_id AS account_id
  )
) GT
FETCH FIRST 100 ROWS ONLY;

PROMPT === Q1 Vertices: Transactions (first 100) ===
SELECT
  vertex_id,
  label,
  transaction_id,
  risk_score
FROM GRAPH_TABLE(fraud_graph MATCH
  (t IS transaction)
  COLUMNS (
    t.vertex_id       AS vertex_id,
    'transaction'     AS label,
    t.transaction_id  AS transaction_id,
    t.risk_score      AS risk_score
  )
) GT
FETCH FIRST 100 ROWS ONLY;

PROMPT === Q1 Edges: performed_transaction (first 100) ===
SELECT
  edge_id,
  src_vertex_id,
  dst_vertex_id,
  edge_label
FROM GRAPH_TABLE(fraud_graph MATCH
  (a IS account)-[e IS performed_transaction]->(t IS transaction)
  COLUMNS (
    e.edge_id       AS edge_id,
    a.vertex_id     AS src_vertex_id,
    t.vertex_id     AS dst_vertex_id,
    'performed_transaction' AS edge_label
  )
) GT
FETCH FIRST 100 ROWS ONLY;

PROMPT === Q2 Edges: High-risk (>= 90) has_device (first 100) ===
SELECT
  edge_id,
  src_vertex_id,
  dst_vertex_id,
  transaction_id,
  device_id,
  risk_score,
  edge_label
FROM GRAPH_TABLE(fraud_graph MATCH
  (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.risk_score >= 90
  COLUMNS (
    h.edge_id         AS edge_id,
    t.vertex_id       AS src_vertex_id,
    d.vertex_id       AS dst_vertex_id,
    t.transaction_id  AS transaction_id,
    d.device_id       AS device_id,
    t.risk_score      AS risk_score,
    'has_device'      AS edge_label
  )
) GT
FETCH FIRST 100 ROWS ONLY;

PROMPT === Q3 Edges: Flagged paid_to (first 100) ===
SELECT
  edge_id,
  src_vertex_id,
  dst_vertex_id,
  transaction_id,
  merchant_id,
  is_flagged,
  edge_label
FROM GRAPH_TABLE(fraud_graph MATCH
  (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
  COLUMNS (
    pm.edge_id        AS edge_id,
    t.vertex_id       AS src_vertex_id,
    m.vertex_id       AS dst_vertex_id,
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
  edge_id,           -- synthetic edge id suitable for visualization
  src_vertex_id,     -- a1 vertex_id
  dst_vertex_id,     -- a2 vertex_id
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
    TO_CHAR(a1.account_id) || '-' || TO_CHAR(a2.account_id) || '-' || TO_CHAR(d.device_id) AS edge_id,
    a1.vertex_id AS src_vertex_id,
    a2.vertex_id AS dst_vertex_id,
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
FETCH FIRST 100 ROWS ONLY;

-- Tip:
-- After running any SELECT above, click the Visualize icon in SQL Developer to see a graph view.
