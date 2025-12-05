SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON
SET DEFINE OFF
WHENEVER SQLERROR CONTINUE
SET SQLFORMAT CSV

SPOOL scripts\perf_pgq_out.txt

CONNECT graphuser/Admin123@//localhost:1521/FREEPDB1

PROMPT === Prepare results table ===
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE perf_pgq_results PURGE';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
CREATE TABLE perf_pgq_results (
  query_name  VARCHAR2(64),
  run_no      NUMBER,
  elapsed_ms  NUMBER,
  rows_returned NUMBER,
  ts          TIMESTAMP DEFAULT SYSTIMESTAMP
);

PROMPT === Execute PGQ performance runs (warmup + measured) ===
DECLARE
  c_warmup CONSTANT PLS_INTEGER := 3;
  c_runs   CONSTANT PLS_INTEGER := 10;
  v_rows   NUMBER;
  t0_cs    PLS_INTEGER;
  t1_cs    PLS_INTEGER;
  v_ms     NUMBER;

  PROCEDURE record_run(p_name VARCHAR2, p_run NUMBER, p_ms NUMBER, p_rows NUMBER) IS
  BEGIN
    INSERT INTO perf_pgq_results(query_name, run_no, elapsed_ms, rows_returned)
    VALUES (p_name, p_run, p_ms, p_rows);
    COMMIT;
  END;

  PROCEDURE run_query(p_name VARCHAR2, p_sql CLOB) IS
  BEGIN
    FOR i IN 1..c_warmup LOOP
      EXECUTE IMMEDIATE p_sql INTO v_rows;
    END LOOP;
    FOR i IN 1..c_runs LOOP
      t0_cs := DBMS_UTILITY.GET_TIME;
      EXECUTE IMMEDIATE p_sql INTO v_rows;
      t1_cs := DBMS_UTILITY.GET_TIME;
      v_ms := (t1_cs - t0_cs) * 10;
      record_run(p_name, i, v_ms, v_rows);
    END LOOP;
  END;


BEGIN
  run_query('Q1_accounts_to_transactions', q'[SELECT COUNT(*) FROM GRAPH_TABLE(fraud_graph MATCH (a IS account)-[e IS performed_transaction]->(t IS transaction)
    COLUMNS (1 AS x)
  ) GT]');

  run_query('Q2_devices_high_risk', q'[SELECT COUNT(*) FROM GRAPH_TABLE(fraud_graph MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[h IS has_device]->(d IS device)
    WHERE t.risk_score >= 90
    COLUMNS (1 AS x)
  ) GT]');

  run_query('Q3_flagged_to_merchants', q'[SELECT COUNT(*) FROM GRAPH_TABLE(fraud_graph MATCH (a IS account)-[p IS performed_transaction]->(t IS transaction)-[pm IS paid_to]->(m IS merchant)
    WHERE t.is_flagged = 1
    COLUMNS (1 AS x)
  ) GT]');

  run_query('Q4_accounts_sharing_device', q'[SELECT COUNT(*) FROM (
    SELECT a1_id, a2_id
    FROM GRAPH_TABLE(fraud_graph MATCH
      (a1 IS account)-[p1 IS performed_transaction]->(t1 IS transaction)-[h1 IS has_device]->(d IS device),
      (a2 IS account)-[p2 IS performed_transaction]->(t2 IS transaction)-[h2 IS has_device]->(d IS device)
      WHERE a1.account_id < a2.account_id
        AND t1.transaction_date >= SYSDATE - 7
        AND t2.transaction_date >= SYSDATE - 7
      COLUMNS (a1.account_id AS a1_id, a2.account_id AS a2_id, d.device_id AS did)
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
  ) S]');
END;
/

PROMPT === Summary statistics (per query) ===
WITH base AS (
  SELECT query_name, run_no, elapsed_ms, rows_returned
  FROM perf_pgq_results
),
agg AS (
  SELECT
    query_name,
    COUNT(*) AS samples,
    MIN(elapsed_ms) AS min_ms,
    AVG(elapsed_ms) AS avg_ms,
    MEDIAN(elapsed_ms) AS median_ms,
    MAX(elapsed_ms) AS max_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY elapsed_ms) AS p95_ms
  FROM base
  GROUP BY query_name
)
SELECT query_name, samples, ROUND(min_ms,3) AS min_ms, ROUND(avg_ms,3) AS avg_ms,
       ROUND(median_ms,3) AS median_ms, ROUND(p95_ms,3) AS p95_ms, ROUND(max_ms,3) AS max_ms
FROM agg
ORDER BY query_name;

PROMPT === Raw samples (optional) ===
SELECT query_name, run_no, elapsed_ms, rows_returned, TO_CHAR(ts, 'YYYY-MM-DD HH24:MI:SS') AS ts
FROM perf_pgq_results
ORDER BY query_name, run_no;

SPOOL OFF
EXIT
