# Oracle Property Graph Performance Demo (FRAUD_GRAPH)

This project is a self-contained subset focused ONLY on the graph performance test and documentation. It excludes unrelated infrastructure files (e.g., Terraform), per request.

What’s included here:
- scripts/ (minimal set to create FRAUD_GRAPH and run the perf harness)
- scripts/sqldeveloper_examples.sql (simple queries to visualize the graph from SQL Developer/SQL Dev Web)
- docs: inline guidance below on running and tuning

Repo hygiene
- This folder is intended to be the contents of the GitHub repo (no Terraform, no unrelated files).
- You can publish JUST this folder as the repo root.

Prereqs
- Oracle 26ai Free or Oracle with Property Graph enabled
- SQLcl or SQL Developer/SQL Developer Web
- A user with privileges to create tables/indices and create property graphs (GRAPHUSER was used below)

Setup
1) Create/recreate FRAUD_GRAPH from base tables using:
   - graph-perf/scripts/create_fraud_graph_via_tables.sql
   This script:
   - Builds base tables from relational sources (clients, merchants, transactions)
   - Adds keys and helpful indexes
   - Creates FRAUD_GRAPH with labels: customer, account, transaction, device, merchant

2) Run the performance harness:
   - graph-perf/scripts/perf_pgq.sql
   It performs:
   - 3 warmups + 10 measured runs per query (Q1–Q4)
   - Writes per-run results into PERF_PGQ_RESULTS
   - Spools CSV summary and raw samples to scripts/perf_pgq_out.txt

3) Simple queries for SQL Developer (visual exploration):
   Use graph-perf/scripts/sqldeveloper_examples.sql
   Examples include:
   - Q1: Accounts → Transactions
   - Q2: High-risk Transactions joined to Devices
   - Q3: Flagged route to Merchants
   - Q4 (bounded): Recent device-sharing account pairs

Performance improvements summary (Q4)
- Original pattern (historical device sharing across all time) had O(degree^2) growth on popular devices and took ~1–3 seconds.
- Final variant bounds both time and device degree:
  - Only last 7 days of transactions
  - Exclude devices with high distinct-customer degree (>10)
- This reduces intermediate cardinality and improves Q4 to ~255 ms avg (p95 ~302 ms) on this dataset.
- Both the time window and degree cap are tunable.

Add a graph screenshot (optional)
- Use SQL Developer/SQL Developer Web Graph query results “Visualize” to render nodes/edges.
- Export or screenshot and place at:
  - graph-perf/images/graph-overview.png
- Then add the following to the README:
  - ![Graph Overview](images/graph-overview.png)

Files in this project
- graph-perf/scripts/create_fraud_graph_via_tables.sql
- graph-perf/scripts/perf_pgq.sql
- graph-perf/scripts/perf_probe.sql
- graph-perf/scripts/perf_support.sql (optional)
- graph-perf/scripts/recreate_fraud_graph_optimized.sql (optional)
- graph-perf/scripts/sqldeveloper_examples.sql (visualization-ready queries)
- graph-perf/images/.gitkeep (placeholder for adding your PNG/JPG)

How to publish this project as a clean repo
- Initialize a new git repository in the graph-perf/ folder (so only these files are included)
- Commit and push to your target repository (e.g., Diegoecab/OCA or a new repo)
- Do NOT add the parent tree (oke-multi-ad-ha-demo) to avoid Terraform or unrelated files

Notes on GRAPH_TABLE syntax in SQLcl/SQLPlus
- Use SQL/PGQ “IS“ label syntax: (a IS account) not (a:account)
- Use GRAPH_TABLE(fraud_graph MATCH ... COLUMNS (...)) — no comma after graph name
- Always include a COLUMNS clause (even for COUNT(*))
