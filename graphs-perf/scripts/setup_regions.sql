SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON
SET DEFINE OFF
WHENEVER SQLERROR CONTINUE

SPOOL scripts/setup_regions_out.txt

-- Assumes you are already connected as GRAPHUSER. If needed, CONNECT manually before running.
-- CONNECT graphuser/Admin123@//localhost:1521/FREEPDB1

PROMPT === Create FRAUD_REGIONS_T if missing (Oracle Spatial demo polygons) ===
BEGIN
  EXECUTE IMMEDIATE '
    CREATE TABLE fraud_regions_t (
      region_id   NUMBER PRIMARY KEY,
      region_name VARCHAR2(100),
      geom        SDO_GEOMETRY
    )';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -955 THEN
      NULL; -- table already exists
    ELSE
      RAISE;
    END IF;
END;
/

PROMPT === Ensure USER_SDO_GEOM_METADATA for FRAUD_REGIONS_T ===
BEGIN
  INSERT INTO user_sdo_geom_metadata (table_name, column_name, diminfo, srid)
  SELECT 'FRAUD_REGIONS_T', 'GEOM',
         SDO_DIM_ARRAY(
           SDO_DIM_ELEMENT('LONG', -180, 180, 0.5),
           SDO_DIM_ELEMENT('LAT',  -90,  90,  0.5)
         ), 4326
  FROM dual
  WHERE NOT EXISTS (
    SELECT 1 FROM user_sdo_geom_metadata
    WHERE table_name = 'FRAUD_REGIONS_T' AND column_name = 'GEOM'
  );
END;
/

PROMPT === Create spatial index if missing ===
DECLARE
  v_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_exists
  FROM user_indexes
  WHERE index_name = 'IDX_REGIONS_GEOM';
  IF v_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE INDEX idx_regions_geom ON fraud_regions_t(geom) INDEXTYPE IS MDSYS.SPATIAL_INDEX';
  END IF;
END;
/

PROMPT === Seed demo regions (NORTH/SOUTH) if missing ===
INSERT INTO fraud_regions_t (region_id, region_name, geom)
SELECT 1, 'NORTH',
       SDO_GEOMETRY(2003, 4326, NULL,
         SDO_ELEM_INFO_ARRAY(1,1003,3),
         SDO_ORDINATE_ARRAY(-180,0, 180,90))
FROM dual
WHERE NOT EXISTS (SELECT 1 FROM fraud_regions_t WHERE region_id = 1);

INSERT INTO fraud_regions_t (region_id, region_name, geom)
SELECT 2, 'SOUTH',
       SDO_GEOMETRY(2003, 4326, NULL,
         SDO_ELEM_INFO_ARRAY(1,1003,3),
         SDO_ORDINATE_ARRAY(-180,-90, 180,0))
FROM dual
WHERE NOT EXISTS (SELECT 1 FROM fraud_regions_t WHERE region_id = 2);

COMMIT;

PROMPT === Verify regions exist ===
SET SQLFORMAT CSV
SELECT region_id, region_name FROM fraud_regions_t ORDER BY region_id;

SPOOL OFF
EXIT
