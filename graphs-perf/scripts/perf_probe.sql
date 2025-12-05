SET ECHO ON
SET FEEDBACK ON
SET SQLFORMAT CSV
WHENEVER SQLERROR CONTINUE

SPOOL scripts\perf_probe_out.txt

CONNECT graphuser/Admin123@//localhost:1521/FREEPDB1

PROMPT === Set default graph to FRAUD_GRAPH ===
ALTER SESSION SET PROPERTY_GRAPH = FRAUD_GRAPH;

PROMPT === Probe 1: GRAPH_TABLE(default_graph) with SQL/PGQ (IS label) + COLUMNS ===
SELECT COUNT(*) AS cnt
FROM GRAPH_TABLE(default_graph,
  MATCH (a IS account)-[e IS performed_transaction]->(t IS transaction)
  COLUMNS (1 AS x)
) GT;

PROMPT === Probe 2: GRAPH_TABLE(default_graph) without COLUMNS (should fail or succeed) ===
SELECT COUNT(*) AS cnt
FROM GRAPH_TABLE(default_graph,
  MATCH (a IS account)-[e IS performed_transaction]->(t IS transaction)
) GT;

SPOOL OFF
EXIT
