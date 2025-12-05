SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON
SET DEFINE OFF
WHENEVER SQLERROR CONTINUE

SPOOL scripts/create_fraud_graph_via_tables_out.txt

-- Adjust connection as needed; if already connected, you can comment this line.
CONNECT graphuser/Admin123@//localhost:1521/FREEPDB1

PROMPT === Drop existing graph (ignore if missing) ===
BEGIN
  BEGIN
    EXECUTE IMMEDIATE 'DROP PROPERTY GRAPH fraud_graph';
  EXCEPTION WHEN OTHERS THEN NULL;
  END;
END;
/

PROMPT === Drop existing derived tables (ignore if missing) ===
BEGIN
  FOR t IN (SELECT table_name FROM user_tables WHERE table_name IN (
    'FRAUD_CUSTOMERS_T','FRAUD_ACCOUNTS_T','FRAUD_TRANSACTIONS_T',
    'FRAUD_DEVICES_T','FRAUD_MERCHANTS_T','FRAUD_CUSTOMER_DEVICES_T',
    'FRAUD_REGIONS_T'
  )) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE '||t.table_name||' PURGE';
  END LOOP;
END;
/

PROMPT === Create base tables (no materialized views) ===
-- Customers
CREATE TABLE fraud_customers_t AS
SELECT
  c.client_id                         AS customer_id,
  REGEXP_SUBSTR(c.name, '^[^ ]+')     AS first_name,
  CAST(NULL AS VARCHAR2(80))          AS last_name,
  c.risk_score                         AS risk_score,
  CASE WHEN NVL(c.risk_score,0) >= 80 THEN 1 ELSE 0 END AS is_flagged
FROM clients c;

-- Accounts (1 per customer; include customer_id for owns edge)
CREATE TABLE fraud_accounts_t AS
SELECT
  c.client_id                                 AS account_id,
  c.client_id                                 AS customer_id,
  'ACCT' || TO_CHAR(c.client_id)              AS account_number,
  CASE WHEN MOD(c.client_id,2)=0 THEN 'CHECKING' ELSE 'SAVINGS' END AS account_type,
  MOD(c.client_id * 113, 100000) / 10         AS balance,
  c.risk_score                                AS risk_score,
  CASE WHEN NVL(c.risk_score,0) >= 80 THEN 1 ELSE 0 END AS is_flagged
FROM clients c;

-- Transactions (add account_id, device_id)
CREATE TABLE fraud_transactions_t AS
SELECT
  t.tx_id                                     AS transaction_id,
  t.amount                                    AS amount,
  t.tx_ts                                     AS transaction_date,
  CASE WHEN t.is_fraud = 1 THEN 95 ELSE ROUND(MOD(t.amount,100)) END AS risk_score,
  CASE WHEN t.is_fraud = 1 THEN 1 ELSE 0 END  AS is_flagged,
  t.client_id                                 AS account_id,
  MOD(ABS(t.client_id*131 + t.merchant_id*17 + t.tx_id), 100000) + 1 AS device_id,
  t.merchant_id                               AS merchant_id
FROM transactions t;

PROMPT === Add Oracle Spatial column and metadata for transaction locations ===
ALTER TABLE fraud_transactions_t ADD (tx_location SDO_GEOMETRY);

BEGIN
  INSERT INTO user_sdo_geom_metadata (table_name, column_name, diminfo, srid)
  VALUES ('FRAUD_TRANSACTIONS_T','TX_LOCATION',
          SDO_DIM_ARRAY(
            SDO_DIM_ELEMENT('LONG', -180, 180, 0.5),
            SDO_DIM_ELEMENT('LAT',  -90,  90,  0.5)
          ), 4326);
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
CREATE INDEX idx_ft_txloc ON fraud_transactions_t(tx_location) INDEXTYPE IS MDSYS.SPATIAL_INDEX;

-- Devices (distinct from transactions)
CREATE TABLE fraud_devices_t AS
SELECT
  d.device_id                                 AS device_id,
  'DFP' || TO_CHAR(d.device_id)               AS device_fingerprint,
  CASE MOD(d.device_id,3)
    WHEN 0 THEN 'MOBILE'
    WHEN 1 THEN 'DESKTOP'
    ELSE 'TABLET'
  END                                         AS device_type,
  MOD(d.device_id,100)                        AS risk_score,
  CASE WHEN MOD(d.device_id,50)=0 THEN 1 ELSE 0 END AS is_flagged
FROM (
  SELECT DISTINCT MOD(ABS(t.client_id*131 + t.merchant_id*17 + t.tx_id), 100000) + 1 AS device_id
  FROM transactions t
) d;

-- Merchants
CREATE TABLE fraud_merchants_t AS
SELECT
  m.merchant_id                               AS merchant_id,
  m.name                                      AS merchant_name,
  m.category                                  AS category,
  MOD(ABS(m.merchant_id*37),100)              AS risk_score,
  0                                           AS is_flagged
FROM merchants m;

PROMPT === Regions (sample polygons) for location grouping ===
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE fraud_regions_t PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
CREATE TABLE fraud_regions_t (
  region_id   NUMBER PRIMARY KEY,
  region_name VARCHAR2(100),
  geom        SDO_GEOMETRY
);

BEGIN
  INSERT INTO user_sdo_geom_metadata (table_name, column_name, diminfo, srid)
  VALUES ('FRAUD_REGIONS_T','GEOM',
          SDO_DIM_ARRAY(
            SDO_DIM_ELEMENT('LONG', -180, 180, 0.5),
            SDO_DIM_ELEMENT('LAT',  -90,  90,  0.5)
          ), 4326);
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
CREATE INDEX idx_regions_geom ON fraud_regions_t(geom) INDEXTYPE IS MDSYS.SPATIAL_INDEX;

-- Two hemispheric regions for demo (NORTH, SOUTH)
INSERT INTO fraud_regions_t(region_id, region_name, geom)
VALUES (1,'NORTH', SDO_GEOMETRY(2003,4326,NULL,
  SDO_ELEM_INFO_ARRAY(1,1003,3),
  SDO_ORDINATE_ARRAY(-180,0, 180,90)));

INSERT INTO fraud_regions_t(region_id, region_name, geom)
VALUES (2,'SOUTH', SDO_GEOMETRY(2003,4326,NULL,
  SDO_ELEM_INFO_ARRAY(1,1003,3),
  SDO_ORDINATE_ARRAY(-180,-90, 180,0)));

COMMIT;

-- Customer <-> Device associations
CREATE TABLE fraud_customer_devices_t AS
SELECT DISTINCT
  t.client_id                                 AS customer_id,
  MOD(ABS(t.client_id*131 + t.merchant_id*17 + t.tx_id), 100000) + 1 AS device_id
FROM transactions t;

PROMPT === Add primary keys (and not null via PK) ===
ALTER TABLE fraud_customers_t ADD CONSTRAINT pk_fraud_customers_t PRIMARY KEY (customer_id);
ALTER TABLE fraud_accounts_t  ADD CONSTRAINT pk_fraud_accounts_t  PRIMARY KEY (account_id);
ALTER TABLE fraud_transactions_t ADD CONSTRAINT pk_fraud_transactions_t PRIMARY KEY (transaction_id);
ALTER TABLE fraud_devices_t   ADD CONSTRAINT pk_fraud_devices_t   PRIMARY KEY (device_id);
ALTER TABLE fraud_merchants_t ADD CONSTRAINT pk_fraud_merchants_t PRIMARY KEY (merchant_id);
-- Edge tables are not vertices; optional supporting unique/composite keys
ALTER TABLE fraud_customer_devices_t MODIFY (customer_id NOT NULL, device_id NOT NULL);

-- Helpful indexes for joins
CREATE INDEX ix_fa_customer ON fraud_accounts_t(customer_id);
CREATE INDEX ix_ft_account  ON fraud_transactions_t(account_id);
CREATE INDEX ix_ft_device   ON fraud_transactions_t(device_id);
CREATE INDEX ix_ft_merchant ON fraud_transactions_t(merchant_id);

COMMIT;

PROMPT === Create Property Graph using base tables (no MVs, no views) ===
BEGIN
  EXECUTE IMMEDIATE q'[
CREATE PROPERTY GRAPH fraud_graph
  VERTEX TABLES (
    fraud_customers_t   KEY (customer_id) LABEL customer  PROPERTIES (customer_id, first_name, last_name, risk_score, is_flagged),
    fraud_accounts_t    KEY (account_id)  LABEL account   PROPERTIES (account_id, account_number, account_type, balance, risk_score, is_flagged),
    fraud_transactions_t KEY (transaction_id) LABEL transaction PROPERTIES (transaction_id, amount, transaction_date, risk_score, is_flagged, tx_location),
    fraud_devices_t     KEY (device_id)   LABEL device    PROPERTIES (device_id, device_fingerprint, device_type, risk_score, is_flagged),
    fraud_merchants_t   KEY (merchant_id) LABEL merchant  PROPERTIES (merchant_id, merchant_name, category, risk_score, is_flagged)
  )
  EDGE TABLES (
    fraud_accounts_t AS owns_account
      KEY (customer_id, account_id)
      SOURCE KEY (customer_id) REFERENCES fraud_customers_t (customer_id)
      DESTINATION KEY (account_id) REFERENCES fraud_accounts_t (account_id),
    fraud_transactions_t AS performed_transaction
      KEY (transaction_id)
      SOURCE KEY (account_id) REFERENCES fraud_accounts_t (account_id)
      DESTINATION KEY (transaction_id) REFERENCES fraud_transactions_t (transaction_id),
    fraud_transactions_t AS has_device
      KEY (transaction_id, device_id)
      SOURCE KEY (transaction_id) REFERENCES fraud_transactions_t (transaction_id)
      DESTINATION KEY (device_id) REFERENCES fraud_devices_t (device_id),
    fraud_transactions_t AS paid_to
      KEY (transaction_id, merchant_id)
      SOURCE KEY (transaction_id) REFERENCES fraud_transactions_t (transaction_id)
      DESTINATION KEY (merchant_id) REFERENCES fraud_merchants_t (merchant_id),
    fraud_customer_devices_t AS uses_device
      KEY (customer_id, device_id)
      SOURCE KEY (customer_id) REFERENCES fraud_customers_t (customer_id)
      DESTINATION KEY (device_id) REFERENCES fraud_devices_t (device_id)
  )
]';
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('CREATE PROPERTY GRAPH failed (ignore if tooling lacks DDL support): '||SQLERRM);
END;
/

PROMPT === Verify graph exists (if DDL supported) ===
SET SQLFORMAT CSV
SELECT graph_name FROM user_property_graphs WHERE UPPER(graph_name)='FRAUD_GRAPH';

SPOOL OFF
EXIT
