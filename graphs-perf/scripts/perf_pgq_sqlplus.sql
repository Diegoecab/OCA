SET ECHO ON
SET FEEDBACK ON
SET HEADING OFF
SET VERIFY OFF
SET PAGESIZE 0
SET LINESIZE 200
SET TIMING ON
WHENEVER SQLERROR CONTINUE

SPOOL scripts\perf_pgq_sqlplus_out.txt

CONNECT graphuser/Admin123@//localhost:1521/FREEPDB1

PROMPT === Q1 Warmup ===
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[e IS performed_transaction]->(t IS transaction)
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[e IS performed_transaction]->(t IS transaction)
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[e IS performed_transaction]->(t IS transaction)
  COLUMNS (1 AS x)
) GT;

PROMPT === Q1 Measured ===
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[e IS performed_transaction]->(t IS transaction)
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[e IS performed_transaction]->(t IS transaction)
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[e IS performed_transaction]->(t IS transaction)
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[e IS performed_transaction]->(t IS transaction)
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[e IS performed_transaction]->(t IS transaction)
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[e IS performed_transaction]->(t IS transaction)
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[e IS performed_transaction]->(t IS transaction)
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[e IS performed_transaction]->(t IS transaction)
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[e IS performed_transaction]->(t IS transaction)
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[e IS performed_transaction]->(t IS transaction)
  COLUMNS (1 AS x)
) GT;

PROMPT === Q2 Warmup ===
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.risk_score >= 90
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.risk_score >= 90
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.risk_score >= 90
  COLUMNS (1 AS x)
) GT;

PROMPT === Q2 Measured ===
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.risk_score >= 90
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.risk_score >= 90
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.risk_score >= 90
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.risk_score >= 90
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.risk_score >= 90
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.risk_score >= 90
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.risk_score >= 90
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.risk_score >= 90
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.risk_score >= 90
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
  WHERE t.risk_score >= 90
  COLUMNS (1 AS x)
) GT;

PROMPT === Q3 Warmup ===
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
  COLUMNS (1 AS x)
) GT;

PROMPT === Q3 Measured ===
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
  WHERE t.is_flagged = 1
  COLUMNS (1 AS x)
) GT;

PROMPT === Q4 Warmup ===
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a1 IS account)-[p1 IS performed_transaction]->(t1 IS transaction)-[h1 IS has_device]->(d IS device),
        (a2 IS account)-[p2 IS performed_transaction]->(t2 IS transaction)-[h2 IS has_device]->(d IS device)
  WHERE a1.account_id < a2.account_id
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a1 IS account)-[p1 IS performed_transaction]->(t1 IS transaction)-[h1 IS has_device]->(d IS device),
        (a2 IS account)-[p2 IS performed_transaction]->(t2 IS transaction)-[h2 IS has_device]->(d IS device)
  WHERE a1.account_id < a2.account_id
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a1 IS account)-[p1 IS performed_transaction]->(t1 IS transaction)-[h1 IS has_device]->(d IS device),
        (a2 IS account)-[p2 IS performed_transaction]->(t2 IS transaction)-[h2 IS has_device]->(d IS device)
  WHERE a1.account_id < a2.account_id
  COLUMNS (1 AS x)
) GT;

PROMPT === Q4 Measured ===
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a1 IS account)-[p1 IS performed_transaction]->(t1 IS transaction)-[h1 IS has_device]->(d IS device),
        (a2 IS account)-[p2 IS performed_transaction]->(t2 IS transaction)-[h2 IS has_device]->(d IS device)
  WHERE a1.account_id < a2.account_id
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a1 IS account)-[p1 IS performed_transaction]->(t1 IS transaction)-[h1 IS has_device]->(d IS device),
        (a2 IS account)-[p2 IS performed_transaction]->(t2 IS transaction)-[h2 IS has_device]->(d IS device)
  WHERE a1.account_id < a2.account_id
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a1 IS account)-[p1 IS performed_transaction]->(t1 IS transaction)-[h1 IS has_device]->(d IS device),
        (a2 IS account)-[p2 IS performed_transaction]->(t2 IS transaction)-[h2 IS has_device]->(d IS device)
  WHERE a1.account_id < a2.account_id
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a1 IS account)-[p1 IS performed_transaction]->(t1 IS transaction)-[h1 IS has_device]->(d IS device),
        (a2 IS account)-[p2 IS performed_transaction]->(t2 IS transaction)-[h2 IS has_device]->(d IS device)
  WHERE a1.account_id < a2.account_id
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a1 IS account)-[p1 IS performed_transaction]->(t1 IS transaction)-[h1 IS has_device]->(d IS device),
        (a2 IS account)-[p2 IS performed_transaction]->(t2 IS transaction)-[h2 IS has_device]->(d IS device)
  WHERE a1.account_id < a2.account_id
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a1 IS account)-[p1 IS performed_transaction]->(t1 IS transaction)-[h1 IS has_device]->(d IS device),
        (a2 IS account)-[p2 IS performed_transaction]->(t2 IS transaction)-[h2 IS has_device]->(d IS device)
  WHERE a1.account_id < a2.account_id
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a1 IS account)-[p1 IS performed_transaction]->(t1 IS transaction)-[h1 IS has_device]->(d IS device),
        (a2 IS account)-[p2 IS performed_transaction]->(t2 IS transaction)-[h2 IS has_device]->(d IS device)
  WHERE a1.account_id < a2.account_id
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a1 IS account)-[p1 IS performed_transaction]->(t1 IS transaction)-[h1 IS has_device]->(d IS device),
        (a2 IS account)-[p2 IS performed_transaction]->(t2 IS transaction)-[h2 IS has_device]->(d IS device)
  WHERE a1.account_id < a2.account_id
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a1 IS account)-[p1 IS performed_transaction]->(t1 IS transaction)-[h1 IS has_device]->(d IS device),
        (a2 IS account)-[p2 IS performed_transaction]->(t2 IS transaction)-[h2 IS has_device]->(d IS device)
  WHERE a1.account_id < a2.account_id
  COLUMNS (1 AS x)
) GT;
SELECT COUNT(*) FROM GRAPH_TABLE(FRAUD_GRAPH,
  MATCH (a1 IS account)-[p1 IS performed_transaction]->(t1 IS transaction)-[h1 IS has_device]->(d IS device),
        (a2 IS account)-[p2 IS performed_transaction]->(t2 IS transaction)-[h2 IS has_device]->(d IS device)
  WHERE a1.account_id < a2.account_id
  COLUMNS (1 AS x)
) GT;

SPOOL OFF
EXIT
