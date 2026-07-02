Coldtrack cleaning queries · SQL
-- ============================================================
-- ColdTrack: Dairy Inventory Risk Analysis
-- SQL Data Cleaning Queries
-- Author: Yash Kumar
-- Dataset: Dairy Supply Chain (4,325 records | 2019-2022)
-- ============================================================
 
 
-- ============================================================
-- STEP 1: INSPECT RAW DATA
-- ============================================================
 
-- 1.1 Total row count

SELECT COUNT(*) AS total_rows FROM dairy_dirty;
 
-- 1.2 Check for NULL values in key columns

SELECT
    SUM(CASE WHEN Brand IS NULL THEN 1 ELSE 0 END)             AS null_brand,
    SUM(CASE WHEN Storage_Condition IS NULL THEN 1 ELSE 0 END) AS null_storage,
    SUM(CASE WHEN Price_per_Unit IS NULL THEN 1 ELSE 0 END)    AS null_price,
    SUM(CASE WHEN Production_Date IS NULL THEN 1 ELSE 0 END)   AS null_prod_date,
    SUM(CASE WHEN Expiration_Date IS NULL THEN 1 ELSE 0 END)   AS null_exp_date
FROM dairy_dirty;
 
-- 1.3 Check duplicate rows

SELECT
    Location, Date, Product_ID, Brand,
    Quantity_liters_kg, Price_per_Unit,
    COUNT(*) AS duplicate_count
FROM dairy_dirty
GROUP BY Location, Date, Product_ID, Brand, Quantity_liters_kg, Price_per_Unit
HAVING COUNT(*) > 1;
 
-- 1.4 Check inconsistent Brand names

SELECT DISTINCT Brand, COUNT(*) AS count
FROM dairy_dirty
GROUP BY Brand
ORDER BY Brand;
 
-- 1.5 Check inconsistent Storage_Condition values

SELECT DISTINCT Storage_Condition, COUNT(*) AS count
FROM dairy_dirty
GROUP BY Storage_Condition
ORDER BY Storage_Condition;
 
-- 1.6 Check negative quantities (invalid)
SELECT COUNT(*) AS negative_quantity_count
FROM dairy_dirty
WHERE Quantity_liters_kg < 0;
 
-- 1.7 Check price outliers

SELECT
    MIN(Price_per_Unit)  AS min_price,
    MAX(Price_per_Unit)  AS max_price,
    AVG(Price_per_Unit)  AS avg_price,
    STDDEV(Price_per_Unit) AS stddev_price
FROM dairy_dirty;
 
 
-- ============================================================
-- STEP 2: REMOVE DUPLICATES
-- ============================================================
 
-- 2.1 Keep only first occurrence of each duplicate

WITH ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY Location, Date, Product_ID, Brand,
                         Quantity_liters_kg, Price_per_Unit
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM dairy_dirty
)
DELETE FROM dairy_dirty WHERE rn > 1;
 
-- Verify

SELECT COUNT(*) AS rows_after_dedup FROM dairy_dirty;
 
 
-- ============================================================
-- STEP 3: HANDLE NULL VALUES
-- ============================================================
 
-- 3.1 Fill NULL Brand using Product_ID mapping

UPDATE dairy_dirty
SET Brand = (
    SELECT TOP 1 Brand
    FROM dairy_dirty d2
    WHERE d2.Product_ID = dairy_dirty.Product_ID
      AND d2.Brand IS NOT NULL
    GROUP BY Brand
    ORDER BY COUNT(*) DESC
)
WHERE Brand IS NULL;
 
-- 3.2 Fill NULL Storage_Condition using Product_Name mapping

UPDATE dairy_dirty
SET Storage_Condition = (
    SELECT TOP 1 Storage_Condition
    FROM dairy_dirty d2
    WHERE d2.Product_Name = dairy_dirty.Product_Name
      AND d2.Storage_Condition IS NOT NULL
    GROUP BY Storage_Condition
    ORDER BY COUNT(*) DESC
)
WHERE Storage_Condition IS NULL;
 
-- 3.3 Fill NULL Price_per_Unit with median price per product

UPDATE dairy_dirty
SET Price_per_Unit = (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Price_per_Unit)
            OVER (PARTITION BY Product_ID)
    FROM dairy_dirty d2
    WHERE d2.Product_ID = dairy_dirty.Product_ID
      AND d2.Price_per_Unit IS NOT NULL
    LIMIT 1
)
WHERE Price_per_Unit IS NULL;
 
-- Verify nulls resolved
SELECT
    SUM(CASE WHEN Brand IS NULL THEN 1 ELSE 0 END)             AS null_brand,
    SUM(CASE WHEN Storage_Condition IS NULL THEN 1 ELSE 0 END) AS null_storage,
    SUM(CASE WHEN Price_per_Unit IS NULL THEN 1 ELSE 0 END)    AS null_price
FROM dairy_dirty;
 
 
-- ============================================================
-- STEP 4: STANDARDIZE TEXT VALUES
-- ============================================================
 
-- 4.1 Standardize Brand names (trim + proper case)
UPDATE dairy_dirty
SET Brand = CASE
    WHEN TRIM(LOWER(Brand)) IN ('amul', 'amul ')              THEN 'Amul'
    WHEN TRIM(LOWER(Brand)) IN ('mother dairy', 'motherdairy') THEN 'Mother Dairy'
    WHEN TRIM(LOWER(Brand)) IN ('sudha', 'sudha ')            THEN 'Sudha'
    WHEN TRIM(LOWER(Brand)) IN ('dodla dairy', 'dodladairy')  THEN 'Dodla Dairy'
    WHEN TRIM(LOWER(Brand)) IN ('raj', 'raj ')                THEN 'Raj'
    WHEN TRIM(LOWER(Brand)) LIKE '%britannia%'                THEN 'Britannia Industries'
    WHEN TRIM(LOWER(Brand)) LIKE '%dynamix%'                  THEN 'Dynamix Dairies'
    WHEN TRIM(LOWER(Brand)) LIKE '%passion%'                  THEN 'Passion Cheese'
    WHEN TRIM(LOWER(Brand)) LIKE '%warana%'                   THEN 'Warana'
    WHEN TRIM(LOWER(Brand)) LIKE '%palle%'                    THEN 'Palle2patnam'
    WHEN TRIM(LOWER(Brand)) LIKE '%parag%'                    THEN 'Parag Milk Foods'
    ELSE TRIM(Brand)
END;
 
-- 4.2 Standardize Storage_Condition
UPDATE dairy_dirty
SET Storage_Condition = CASE
    WHEN TRIM(LOWER(Storage_Condition)) LIKE '%refri%'  THEN 'Refrigerated'
    WHEN TRIM(LOWER(Storage_Condition)) LIKE '%freez%'
      OR TRIM(LOWER(Storage_Condition)) LIKE '%froze%'  THEN 'Frozen'
    WHEN TRIM(LOWER(Storage_Condition)) LIKE '%ambi%'   THEN 'Ambient'
    WHEN TRIM(LOWER(Storage_Condition)) LIKE '%tetra%'  THEN 'Tetra Pack'
    WHEN TRIM(LOWER(Storage_Condition)) LIKE '%poly%'   THEN 'Polythene Packet'
    ELSE TRIM(Storage_Condition)
END;
 
-- 4.3 Trim whitespace from Location
UPDATE dairy_dirty
SET Location = TRIM(Location),
    Customer_Location = TRIM(Customer_Location);
 
-- Verify
SELECT DISTINCT Storage_Condition FROM dairy_dirty ORDER BY Storage_Condition;
SELECT DISTINCT Brand FROM dairy_dirty ORDER BY Brand;
 
 
-- ============================================================
-- STEP 5: FIX INVALID NUMERIC VALUES
-- ============================================================
 
-- 5.1 Remove negative quantities (set to absolute value)
UPDATE dairy_dirty
SET Quantity_liters_kg = ABS(Quantity_liters_kg)
WHERE Quantity_liters_kg < 0;
 
-- 5.2 Remove price outliers (beyond 3 standard deviations)
UPDATE dairy_dirty
SET Price_per_Unit = NULL
WHERE Price_per_Unit > (
    SELECT AVG(Price_per_Unit) + (3 * STDDEV(Price_per_Unit))
    FROM dairy_dirty
    WHERE Price_per_Unit IS NOT NULL
);
 
-- Verify
SELECT COUNT(*) AS negative_qty FROM dairy_dirty WHERE Quantity_liters_kg < 0;
SELECT MAX(Price_per_Unit) AS max_price FROM dairy_dirty;
 
 
-- ============================================================
-- STEP 6: STANDARDIZE DATE FORMATS
-- ============================================================
 
-- 6.1 Convert all dates to standard format YYYY-MM-DD
-- (Run this based on your SQL dialect)
 
-- For SQL Server:
UPDATE dairy_dirty
SET Production_Date = CONVERT(DATE, Production_Date, 105),
    Expiration_Date = CONVERT(DATE, Expiration_Date, 105),
    Date            = CONVERT(DATE, Date, 105);
 
-- Verify date range
SELECT
    MIN(Production_Date) AS earliest_production,
    MAX(Expiration_Date) AS latest_expiry
FROM dairy_dirty;
 
 
-- ============================================================
-- STEP 7: FINAL VALIDATION
-- ============================================================
 
-- 7.1 Final row count
SELECT COUNT(*) AS final_row_count FROM dairy_dirty;
 
-- 7.2 No nulls in critical columns
SELECT
    SUM(CASE WHEN Brand IS NULL THEN 1 ELSE 0 END)             AS null_brand,
    SUM(CASE WHEN Storage_Condition IS NULL THEN 1 ELSE 0 END) AS null_storage,
    SUM(CASE WHEN Price_per_Unit IS NULL THEN 1 ELSE 0 END)    AS null_price
FROM dairy_dirty;
 
-- 7.3 All brands valid
SELECT DISTINCT Brand FROM dairy_dirty ORDER BY Brand;
 
-- 7.4 All storage conditions valid
SELECT DISTINCT Storage_Condition FROM dairy_dirty ORDER BY Storage_Condition;
 
-- 7.5 No negative quantities
SELECT COUNT(*) AS negative_check FROM dairy_dirty WHERE Quantity_liters_kg < 0;
 
-- 7.6 Summary statistics post-cleaning
SELECT
    COUNT(*)                        AS total_records,
    COUNT(DISTINCT Brand)           AS unique_brands,
    COUNT(DISTINCT Product_Name)    AS unique_products,
    COUNT(DISTINCT Location)        AS unique_locations,
    ROUND(AVG(Price_per_Unit), 2)   AS avg_price,
    ROUND(AVG(Shelf_Life_days), 1)  AS avg_shelf_life_days
FROM dairy_dirty;

-- ============================================================ 

Raw data issues found:
- 129 duplicates
- 216 null Brand values
- 89 negative quantities
- Mixed date formats

After cleaning: 4,325 clean rows
-- ============================================================
-- CLEANING COMPLETE
-- dairy_dirty → dairy_clean
-- ============================================================
 