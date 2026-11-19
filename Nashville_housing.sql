USE portfolio;
-- Run once to load the raw CSV (update the path to your local file).
-- Requires: SET GLOBAL local_infile = 1;
/*
TRUNCATE TABLE nashville_housing_data;

LOAD DATA LOCAL INFILE 'path/to/Nashville_Housing_Data.csv'
INTO TABLE nashville_housing_data
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;
*/

-- Quick look at the raw data 
SELECT *
FROM nashville_housing_data
;

-- created staging table to avoid using raw table
CREATE TABLE nashville_housing_staging
LIKE nashville_housing_data;

INSERT nashville_housing_staging
SELECT *
FROM nashville_housing_data;

SELECT *
FROM nashville_housing_staging;

-- change the SaleDate from TEXT to DATE

-- Preview the conversion before applying it
select `SaleDate`,
str_to_date(`SaleDate`, '%M %d, %Y') 
from nashville_housing_staging;

UPDATE nashville_housing_staging
SET `SaleDate` = str_to_date(`SaleDate`, '%M %d, %Y');

ALTER TABLE nashville_housing_staging
MODIFY COLUMN `SaleDate` DATE;


-- Remove Duplicates
-- MySQL cannot DELETE directly from a CTE, so row numbers are stored in a second
-- staging table and the extra rows are deleted from there.

-- Preview duplicates
WITH duplicate_cte AS
(
select *,
ROW_NUMBER() OVER(
PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) AS row_num
from nashville_housing_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1
ORDER BY PropertyAddress;

-- Create second staging table same structure plus row_num column added

CREATE TABLE `nashville_housing_staging2` (
  `UniqueID` int DEFAULT NULL,
  `ParcelID` text,
  `LandUse` text,
  `PropertyAddress` text,
  `SaleDate` date DEFAULT NULL,
  `SalePrice` int DEFAULT NULL,
  `LegalReference` text,
  `SoldAsVacant` text,
  `OwnerName` text,
  `OwnerAddress` text,
  `Acreage` double DEFAULT NULL,
  `TaxDistrict` text,
  `LandValue` int DEFAULT NULL,
  `BuildingValue` int DEFAULT NULL,
  `TotalValue` int DEFAULT NULL,
  `YearBuilt` int DEFAULT NULL,
  `Bedrooms` int DEFAULT NULL,
  `FullBath` int DEFAULT NULL,
  `HalfBath` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Populate with row numbers

INSERT INTO nashville_housing_staging2
SELECT *,
ROW_NUMBER() OVER(
    PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference 
    ORDER BY UniqueID
) AS row_num
FROM nashville_housing_staging;

-- Delete duplicates
DELETE 
FROM nashville_housing_staging2
WHERE row_num > 1;

# remove row_num column
ALTER TABLE nashville_housing_staging2
drop column row_num;


-- Split the property address into street address and city

-- substring_index(col, ',', 1) grabs everything before the 1st comma
-- SUBSTRING_INDEX(col, ',', -1) grabs everything after the last comma 

-- Preview
SELECT PropertyAddress,
SUBSTRING_INDEX(PropertyAddress, ',', 1) StreetAddress,
TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1)) City
FROM nashville_housing_staging2;

-- add the columns and fill them with the split value 
ALTER TABLE nashville_housing_staging2
ADD PropertySplitAddress VARCHAR(255);

ALTER TABLE nashville_housing_staging2
ADD PropertySplitCity VARCHAR(255);

UPDATE nashville_housing_staging2
SET PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1);

UPDATE nashville_housing_staging2
SET PropertySplitCity = TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1));


-- Split Owner Address into street, city, and state

-- Preview
SELECT OwnerAddress,
SUBSTRING_INDEX(OwnerAddress, ',', 1) StreetAddress,
TRIM(substring_index(substring_index(OwnerAddress, ',', 2), ',', -1)) City,
TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1)) State
FROM nashville_housing_staging2;


ALTER TABLE nashville_housing_staging2
ADD OwnerSplitAddress VARCHAR(255);

ALTER TABLE nashville_housing_staging2
ADD OwnerSplitCity VARCHAR(255);

ALTER TABLE nashville_housing_staging2
ADD OwnerSplitState VARCHAR(255);

UPDATE nashville_housing_staging2
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

UPDATE nashville_housing_staging2
SET OwnerSplitCity = TRIM(substring_index(substring_index(OwnerAddress, ',', 2), ',', -1));

UPDATE nashville_housing_staging2
SET OwnerSplitState = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));


-- Drop Unused columns 
-- TaxDistrict is not needed for analysis
ALTER TABLE nashville_housing_staging2
DROP COLUMN PropertyAddress,
DROP COLUMN OwnerAddress;

ALTER TABLE nashville_housing_staging2
DROP COLUMN TaxDistrict; 

-- Standardize categorical values

-- Inspect distinct values to find inconsistencies
SELECT DISTINCT LandUse
FROM nashville_housing_staging2;

-- merge variants of "vacant residential land" into one label
UPDATE nashville_housing_staging2
SET LandUse = 'VACANT RESIDENTIAL LAND'
WHERE LandUse IN ('VACANT RESIENTIAL LAND', 'VACANT RES LAND');

-- Fix Typo : "GREENBELT/RES GRRENBELT/RES"
UPDATE nashville_housing_staging2
SET LandUse = 'GREENBELT/RES'
WHERE LandUse LIKE '%GRRENBELT%';

-- Confirm the cleanup
SELECT distinct LandUse
FROM nashville_housing_staging2
ORDER BY LandUse;


-- Handle Blank Values
-- convert empty string owner names to NULL
UPDATE nashville_housing_staging2
SET OwnerName = NULL
WHERE TRIM(OwnerName) = '';

SELECT *
FROM nashville_housing_staging2;

SELECT *
FROM nashville_housing_data
;

-- created staging table to avoid using raw table
CREATE TABLE nashville_housing_staging
LIKE nashville_housing_data;

INSERT nashville_housing_staging
SELECT *
FROM nashville_housing_data;

SELECT *
FROM nashville_housing_staging;

-- change the SaleDate type to date

select `SaleDate`,
str_to_date(`SaleDate`, '%M %d, %Y')
from nashville_housing_staging;

UPDATE nashville_housing_staging
SET `SaleDate` = str_to_date(`SaleDate`, '%M %d, %Y');

ALTER TABLE nashville_housing_staging
MODIFY COLUMN `SaleDate` DATE;

SELECT *
FROM nashville_housing_staging;


-- Remove Duplicates

WITH duplicate_cte AS
(
select *,
ROW_NUMBER() OVER(
PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) AS row_num
from nashville_housing_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1
ORDER BY PropertyAddress;


SELECT *
FROM nashville_housing_staging
WHERE ParcelID = '164 07 0A 168.00';

CREATE TABLE `nashville_housing_staging2` (
  `UniqueID` int DEFAULT NULL,
  `ParcelID` text,
  `LandUse` text,
  `PropertyAddress` text,
  `SaleDate` date DEFAULT NULL,
  `SalePrice` int DEFAULT NULL,
  `LegalReference` text,
  `SoldAsVacant` text,
  `OwnerName` text,
  `OwnerAddress` text,
  `Acreage` double DEFAULT NULL,
  `TaxDistrict` text,
  `LandValue` int DEFAULT NULL,
  `BuildingValue` int DEFAULT NULL,
  `TotalValue` int DEFAULT NULL,
  `YearBuilt` int DEFAULT NULL,
  `Bedrooms` int DEFAULT NULL,
  `FullBath` int DEFAULT NULL,
  `HalfBath` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


SELECT *
FROM nashville_housing_staging2;

INSERT INTO nashville_housing_staging2
SELECT *,
ROW_NUMBER() OVER(
    PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference 
    ORDER BY UniqueID
) AS row_num
FROM nashville_housing_staging;

DELETE 
FROM nashville_housing_staging2
WHERE row_num > 1;

# remove row_num column
ALTER TABLE nashville_housing_staging2
drop column row_num;


-- Split the property address column into street address and city
SELECT PropertyAddress
FROM nashville_housing_staging2;

-- substring_index(.., ',', 1) grabs everything before the 1st comma
-- SUBSTRING_INDEX(..., ',', -1) grabs everything after the last comma 
SELECT PropertyAddress,
SUBSTRING_INDEX(PropertyAddress, ',', 1) StreetAddress,
TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1)) City
FROM nashville_housing_staging2;

-- add the columns and fill them with the split value 
ALTER TABLE nashville_housing_staging2
ADD PropertySplitAddress VARCHAR(255);


ALTER TABLE nashville_housing_staging2
ADD PropertySplitCity VARCHAR(255);

UPDATE nashville_housing_staging2
SET PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1);

UPDATE nashville_housing_staging2
SET PropertySplitCity = TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1));

SELECT * 
FROM nashville_housing_staging2;

-- Split Owner Address into street address, city, state

SELECT OwnerAddress,
SUBSTRING_INDEX(OwnerAddress, ',', 1) StreetAddress,
TRIM(substring_index(substring_index(OwnerAddress, ',', 2), ',', -1)) City,
TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1)) State
FROM nashville_housing_staging2;


ALTER TABLE nashville_housing_staging2
ADD OwnerSplitAddress VARCHAR(255);

ALTER TABLE nashville_housing_staging2
ADD OwnerSplitCity VARCHAR(255);

ALTER TABLE nashville_housing_staging2
ADD OwnerSplitState VARCHAR(255);

UPDATE nashville_housing_staging2
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

UPDATE nashville_housing_staging2
SET OwnerSplitCity = TRIM(substring_index(substring_index(OwnerAddress, ',', 2), ',', -1));

UPDATE nashville_housing_staging2
SET OwnerSplitState = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));

SELECT *
FROM nashville_housing_staging2;

-- Drop Unused columns 
ALTER TABLE nashville_housing_staging2
DROP COLUMN PropertyAddress,
DROP COLUMN OwnerAddress;

ALTER TABLE nashville_housing_staging2
DROP COLUMN TaxDistrict; 


SELECT DISTINCT LandUse
FROM nashville_housing_staging2;
-- there is vacant resiential land, vacant residential land, and vacant res land
-- standardize into single label

UPDATE nashville_housing_staging2
SET LandUse = 'VACANT RESIDENTIAL LAND'
WHERE LandUse IN ('VACANT RESIENTIAL LAND', 'VACANT RES LAND');

SELECT DISTINCT LandUse
FROM nashville_housing_staging2
ORDER BY 1;

-- Typo in GREENBELT/RES GRRENBELT/RES
UPDATE nashville_housing_staging2
SET LandUse = 'GREENBELT/RES'
WHERE LandUse LIKE '%GRRENBELT%';


-- Standardize the owner name, convert blanks to NULL
UPDATE nashville_housing_staging2
SET OwnerName = NULL
WHERE TRIM(OwnerName) = '';

SELECT *
FROM nashville_housing_staging2;

SELECT *
FROM nashville_housing_data
;

-- created staging table to avoid modifying raw table
CREATE TABLE nashville_housing_staging
LIKE nashville_housing_data;

INSERT nashville_housing_staging
SELECT *
FROM nashville_housing_data;

SELECT *
FROM nashville_housing_staging;

-- change the SaleDate type to date

select `SaleDate`,
str_to_date(`SaleDate`, '%M %d, %Y')
from nashville_housing_staging;

UPDATE nashville_housing_staging
SET `SaleDate` = str_to_date(`SaleDate`, '%M %d, %Y');

ALTER TABLE nashville_housing_staging
MODIFY COLUMN `SaleDate` DATE;

SELECT *
FROM nashville_housing_staging;


-- Remove Duplicates

WITH duplicate_cte AS
(
select *,
ROW_NUMBER() OVER(
PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) AS row_num
from nashville_housing_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1
ORDER BY PropertyAddress;


SELECT *
FROM nashville_housing_staging
WHERE ParcelID = '164 07 0A 168.00';

CREATE TABLE `nashville_housing_staging2` (
  `UniqueID` int DEFAULT NULL,
  `ParcelID` text,
  `LandUse` text,
  `PropertyAddress` text,
  `SaleDate` date DEFAULT NULL,
  `SalePrice` int DEFAULT NULL,
  `LegalReference` text,
  `SoldAsVacant` text,
  `OwnerName` text,
  `OwnerAddress` text,
  `Acreage` double DEFAULT NULL,
  `TaxDistrict` text,
  `LandValue` int DEFAULT NULL,
  `BuildingValue` int DEFAULT NULL,
  `TotalValue` int DEFAULT NULL,
  `YearBuilt` int DEFAULT NULL,
  `Bedrooms` int DEFAULT NULL,
  `FullBath` int DEFAULT NULL,
  `HalfBath` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


SELECT *
FROM nashville_housing_staging2;

INSERT INTO nashville_housing_staging2
SELECT *,
ROW_NUMBER() OVER(
    PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference 
    ORDER BY UniqueID
) AS row_num
FROM nashville_housing_staging;

DELETE 
FROM nashville_housing_staging2
WHERE row_num > 1;

# remove row_num column
ALTER TABLE nashville_housing_staging2
drop column row_num;


-- Split the property address column into street address and city
SELECT PropertyAddress
FROM nashville_housing_staging2;

-- substring_index(.., ',', 1) grabs everything before the 1st comma
-- SUBSTRING_INDEX(..., ',', -1) grabs everything after the last comma 
SELECT PropertyAddress,
SUBSTRING_INDEX(PropertyAddress, ',', 1) StreetAddress,
TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1)) City
FROM nashville_housing_staging2;

-- add the columns and fill them with the split value 
ALTER TABLE nashville_housing_staging2
ADD PropertySplitAddress VARCHAR(255);


ALTER TABLE nashville_housing_staging2
ADD PropertySplitCity VARCHAR(255);

UPDATE nashville_housing_staging2
SET PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1);

UPDATE nashville_housing_staging2
SET PropertySplitCity = TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1));

SELECT * 
FROM nashville_housing_staging2;

-- Split Owner Address into street address, city, state

SELECT OwnerAddress,
SUBSTRING_INDEX(OwnerAddress, ',', 1) StreetAddress,
TRIM(substring_index(substring_index(OwnerAddress, ',', 2), ',', -1)) City,
TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1)) State
FROM nashville_housing_staging2;


ALTER TABLE nashville_housing_staging2
ADD OwnerSplitAddress VARCHAR(255);

ALTER TABLE nashville_housing_staging2
ADD OwnerSplitCity VARCHAR(255);

ALTER TABLE nashville_housing_staging2
ADD OwnerSplitState VARCHAR(255);

UPDATE nashville_housing_staging2
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

UPDATE nashville_housing_staging2
SET OwnerSplitCity = TRIM(substring_index(substring_index(OwnerAddress, ',', 2), ',', -1));

UPDATE nashville_housing_staging2
SET OwnerSplitState = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));

SELECT *
FROM nashville_housing_staging2;

-- Drop Unused columns 
ALTER TABLE nashville_housing_staging2
DROP COLUMN PropertyAddress,
DROP COLUMN OwnerAddress;

ALTER TABLE nashville_housing_staging2
DROP COLUMN TaxDistrict; 


SELECT DISTINCT LandUse
FROM nashville_housing_staging2;
-- there is vacant resiential land, vacant residential land, and vacant res land
-- standardize into single label

UPDATE nashville_housing_staging2
SET LandUse = 'VACANT RESIDENTIAL LAND'
WHERE LandUse IN ('VACANT RESIENTIAL LAND', 'VACANT RES LAND');

SELECT DISTINCT LandUse
FROM nashville_housing_staging2
ORDER BY 1;

-- Typo in GREENBELT/RES GRRENBELT/RES
UPDATE nashville_housing_staging2
SET LandUse = 'GREENBELT/RES'
WHERE LandUse LIKE '%GRRENBELT%';


-- Standardize the owner name, convert blanks to NULL
UPDATE nashville_housing_staging2
SET OwnerName = NULL
WHERE TRIM(OwnerName) = '';


-- Final Cleaned Table    
SELECT *
FROM nashville_housing_staging2;



