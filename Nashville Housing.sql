CREATE TABLE `Nashville Housing`.`Nashville_Housing_Data_for_Data_Cleaning` (
    UniqueID INTEGER NULL,
    ParcelID VARCHAR(50) NULL,
    LandUse VARCHAR(50) NULL,
    PropertyAddress VARCHAR(50) NULL,
    SaleDate VARCHAR(50) NULL,
    SalePrice INTEGER NULL,
    LegalReference VARCHAR(50) NULL,
    SoldAsVacant VARCHAR(50) NULL,
    OwnerName VARCHAR(64) NULL,
    OwnerAddress VARCHAR(50) NULL,
    Acreage REAL NULL,
    TaxDistrict VARCHAR(50) NULL,
    LandValue INTEGER NULL,
    BuildingValue INTEGER NULL,
    TotalValue INTEGER NULL,
    YearBuilt INTEGER NULL,
    Bedrooms INTEGER NULL,
    FullBath INTEGER NULL,
    HalfBath INTEGER NULL
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- in order to properly import, needed to make sure there were no commas between numbers in the SalePrice
-- also needed to fix extra space in the column heading of UniqueID in CSV before importing to SQL databse


SELECT COUNT(UniqueID)
FROM Nashville_Housing


/* Cleaning Data in SQL Queries */

SELECT *
FROM Nashville_Housing

SELECT `SaleDate`
FROM Nashville_Housing

-- Standardize Date Format - originally varchar50

UPDATE `Nashville Housing`.Nashville_Housing SET SaleDate = STR_TO_DATE(SaleDate, '%M %e, %Y')
WHERE SaleDate IS NOT NULL;

/* ^ This query uses the STR_TO_DATE function to convert the string values in the SaleDate column
 to a date format specified by the '%M %e, %Y' format string. The WHERE clause ensures that only 
 non-null values are updated. 
 
 After running this query to convert the values in the SaleDate column to a valid date format,
 you run the ALTER TABLE statement to modify the data type of the SaleDate column to DATE
 without encountering the truncation error. */


ALTER TABLE `Nashville Housing`.Nashville_Housing MODIFY COLUMN SaleDate DATE NULL;

DESCRIBE `Nashville Housing`.Nashville_Housing;



-- Populate Property Address Data

SELECT PropertyAddress 
FROM Nashville_Housing
WHERE PropertyAddress IS NULL;

SELECT PropertyAddress
FROM `Nashville Housing`.Nashville_Housing
WHERE PropertyAddress = '';

-- *** combining both to find null and empty cells in a given column ***

SELECT PropertyAddress  
FROM `Nashville Housing`.Nashville_Housing
WHERE PropertyAddress IS NULL OR PropertyAddress = '';

-- find all instances where there is blank or NULL values in the table 

SELECT *
FROM `Nashville Housing`.Nashville_Housing
WHERE PropertyAddress IS NULL OR PropertyAddress = '';

SELECT * 
FROM `Nashville Housing`.Nashville_Housing
ORDER BY ParcelID 

-- Self JOIN - to find all - where parcelID is the same but is its own ROW 
-- as it has its own unique ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM `Nashville Housing`.Nashville_Housing a
JOIN `Nashville Housing`.Nashville_Housing b
	ON a.ParcelID = b.ParcelID 
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL OR a.PropertyAddress = '';

-- Copy the address from one ParcelID to another ParcelID where the UniqueID are not equal 
-- by running the above chunk no data should be displayed as there are no longer any null or 
-- empty Property Addresses

UPDATE `Nashville Housing`.Nashville_Housing b
JOIN `Nashville Housing`.Nashville_Housing a
	ON a.ParcelID = b.ParcelID 
	AND a.UniqueID <> b.UniqueID
SET b.PropertyAddress = a.PropertyAddress
WHERE b.PropertyAddress IS NULL OR b.PropertyAddress = '';



-- Breaking out Address into individual (Columns, City, State)

SELECT PropertyAddress 
FROM Nashville_Housing

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1) AS Address
FROM Nashville_Housing

-- CHARINDEX didnt work - tried INSTR function instead, the -1 gets rid of the comma 
-- at the end of the address

SELECT SUBSTRING(PropertyAddress, 1, INSTR(PropertyAddress, ',') - 1) AS Address
FROM Nashville_Housing


SELECT 
SUBSTRING(PropertyAddress, 1, 	(PropertyAddress, ',') - 1) AS Address,
SUBSTRING(PropertyAddress, INSTR(PropertyAddress, ',') + 2) AS Suburb
FROM Nashville_Housing;

/* This query extracts the address and the suburb from the PropertyAddress column using the SUBSTRING
   and INSTR functions. The first SUBSTRING function extracts the part of the PropertyAddress column
   before the first comma, and the second SUBSTRING function extracts the part of the PropertyAddress 
   column after the first comma and space.

The result of this query will be two columns: Address and Suburb, where Address contains the part 
of the PropertyAddress column before the first comma, and Suburb contains the part of the PropertyAddress
column after the first comma and space. */



ALTER TABLE Nashville_Housing 
ADD PropertySplitAddress NVARCHAR(255);

ALTER TABLE Nashville_Housing 
ADD PropertySplitCity NVARCHAR(255);

UPDATE Nashville_Housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, INSTR(PropertyAddress, ',') - 1),
    PropertySplitCity = SUBSTRING(PropertyAddress, INSTR(PropertyAddress, ',') + 2);

-- Create 2 new columns then copy all Property Address data into the PropertySplitAddress 
-- column and copy all the City names into the PropertySplitCity column

-- below check
SELECT *
FROM Nashville_Housing nh 

SELECT OwnerAddress 
FROM Nashville_Housing nh 

-- Need to split the City, Address and State - see below

SELECT 
  SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Address, 
  TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1)) AS Suburb,
  TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1)) AS State
FROM Nashville_Housing nh;



-- adding 3 separate columns - owner address, owner suburb and own state

ALTER TABLE Nashville_Housing 
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE Nashville_Housing 
SET OwnerSplitAddress = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1));




ALTER TABLE Nashville_Housing 
ADD OwnerSplitCity NVARCHAR(255);

UPDATE Nashville_Housing 
SET	OwnerSplitCity = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1));




ALTER TABLE Nashville_Housing 
ADD OwnerSplitState NVARCHAR(255);

UPDATE Nashville_Housing 
SET OwnerSplitState = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));


-- as a whole updating 3 columns with CORRESPONDING data in one go
UPDATE Nashville_Housing
SET OwnerSplitAddress = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1)),
    OwnerSplitCity = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1)),
    OwnerSplitState = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));
   

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Nashville_Housing nh 
GROUP BY (SoldAsVacant)
ORDER BY 2


SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
     WHEN SoldAsVacant = 'N' THEN 'No'
     ELSE SoldAsVacant 
     END
FROM Nashville_Housing nh 

UPDATE Nashville_Housing 
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
     WHEN SoldAsVacant = 'N' THEN 'No'
     ELSE SoldAsVacant 
     END

-- Remove Duplicates - deleting data not standard practice in databases
-- ok to delete dubplicates in temp tables

SELECT *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID,
			 PropertyAddress,
			 SalePrice,
			 SaleDate,
			 LegalReference
			 ORDER BY 
			 	UniqueID
			 	) AS row_num 
FROM Nashville_Housing nh 
ORDER BY ParcelID	

-- therefore create CTE 

WITH RowNumCTE AS (
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID,
			 PropertyAddress,
			 SalePrice,
			 SaleDate,
			 LegalReference
			 ORDER BY 
			 	UniqueID
			 	) AS row_num 
FROM Nashville_Housing nh 
-- ORDER BY ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-- then DELETE

WITH RowNumCTE AS (
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID,
             PropertyAddress,
             SalePrice,
             SaleDate,
             LegalReference
             ORDER BY UniqueID
           ) AS row_num 
FROM Nashville_Housing
)
DELETE FROM RowNumCTE
WHERE row_num > 1;

-- SQL Error [1288] [HY000]: The target table RowNumCTE of the DELETE is not updatable

-- use subquery instead?

DELETE FROM Nashville_Housing
WHERE UniqueID NOT IN (
  SELECT UniqueID
  FROM (
    SELECT UniqueID,
           ROW_NUMBER() OVER (
             PARTITION BY ParcelID,
                          PropertyAddress,
                          SalePrice,
                          SaleDate,
                          LegalReference
             ORDER BY UniqueID
           ) AS row_num 
    FROM Nashville_Housing
  ) AS RowNumSubquery
  WHERE row_num = 1
);

-- Run SELECT to check for duplicates

SELECT *
FROM Nashville_Housing
WHERE UniqueID NOT IN (
  SELECT UniqueID
  FROM (
    SELECT UniqueID,
           ROW_NUMBER() OVER (
             PARTITION BY ParcelID,
                          PropertyAddress,
                          SalePrice,
                          SaleDate,
                          LegalReference
             ORDER BY UniqueID
           ) AS row_num 
    FROM Nashville_Housing
  ) AS RowNumSubquery
  WHERE row_num = 1
);

-- or try code below to check for duplicates

SELECT ParcelID,
       PropertyAddress,
       SalePrice,
       SaleDate,
       LegalReference,
       COUNT(*) AS NumDuplicates
FROM Nashville_Housing
GROUP BY ParcelID,
         PropertyAddress,
         SalePrice,
         SaleDate,
         LegalReference
HAVING COUNT(*) > 1;



-- Delete unused columns

SELECT * 
FROM Nashville_Housing nh -- this is for checking purposes

ALTER TABLE Nashville_Housing 
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress;

-- above did not work - below worked

ALTER TABLE Nashville_Housing
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress,
DROP COLUMN SaleDate;






