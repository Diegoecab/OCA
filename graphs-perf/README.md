# Graphs Performance Demo (FRAUD_GRAPH)

This project focuses ONLY on the graph performance demo, SQL Developer visualization queries, and fraud scenario verification. It lives under the graphs-perf/ folder of the OCA repository.

What’s included
- scripts/ (minimal set to create FRAUD_GRAPH, seed synthetic fraud-like data, run perf harness, and visualize)
  - create_fraud_graph_via_tables.sql
  - simulate_fraud_data.sql (seed scenarios for verification)
  - perf_pgq.sql
  - perf_probe.sql
  - perf_pgq_sqlplus.sql
  - recreate_fraud_graph_optimized.sql (optional)
  - perf_support.sql (optional)
  - sqldeveloper_examples.sql (visualization + verification queries)
- images/.gitkeep (placeholder for screenshots)

Prereqs
- Oracle 26ai Free or Oracle DB with Property Graph enabled
- SQLcl or SQL Developer/SQL Developer Web
- A user with privileges to create tables/indices and create property graphs (e.g., GRAPHUSER)

Setup
1) Create/recreate FRAUD_GRAPH from base tables:
   - graphs-perf/scripts/create_fraud_graph_via_tables.sql
   - This script:
     - Builds base tables (customers, accounts, transactions, devices, merchants)
     - Adds keys and indexes
     - Creates FRAUD_GRAPH with labels: customer, account, transaction, device, merchant

2) Seed synthetic data to verify fraud scenarios:
   - graphs-perf/scripts/simulate_fraud_data.sql
   - Injects:
     - Two accounts sharing a device with flagged transactions in the last 7 days
     - Multiple flagged transactions to the same merchant in the last 7 days

3) Visualize and verify:
   - graphs-perf/scripts/sqldeveloper_examples.sql
   - Includes:
     - Q1–Q4 patterns
     - Fan-out (device→accounts)
     - Fan-in (flagged tx→merchants)
     - One-to-many synthetic (account→device)
     - Two-hop ribbons
     - Potential fraud verification:
       - Shared device flagged account pairs (last 7d)
       - Merchants with many flagged transactions (last 7d)
   - Tip: In SQL Developer, run a SELECT and click the Visualize icon to render nodes/edges.

4) Optional performance harness:
   - graphs-perf/scripts/perf_pgq.sql
   - Warms up and runs queries (Q1–Q4), writes summary + raw samples.

Screenshot
- Use SQL Developer “Visualize” to export a PNG and save at:
  - graphs-perf/images/graph-overview.png
- Embed in docs (if needed):
  - ![Graph Overview](images/graph-overview.png)

Automated with Oracle Code Assist (Model: GPT5)
- End-to-end automation (SQL/PGQ generation, error remediation, performance tuning, Git ops)
- Accelerated iteration, reduced error when refining query shapes and client-specific syntax
- Seeded synthetic fraud-like data for clear visual verification of patterns
