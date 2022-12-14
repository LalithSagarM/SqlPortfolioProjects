
-- Data Cleaning is seen as the first step for any Data Analysis Project as removing irelevent data and creating a standardized form will help greatly
-- In the proccesses that follow. I try to use Different DDL and DML Commands to clean data and also I use Wildcard Functions, Windows Functions, Case statements
-- and Self Joins to achieve the tasks at hand.

--Selecting the Database and Checking all Columns

USE sqlcleaningdata;

SELECT 
	* 
FROM 
	HousingData;

-----------------------------------------------------------------------------------------------------------------------------------------

-- 1. Standardizing the Date Format
-- Problem: The date field is in date time format
-- Solution: Alter table and update to change this to DATE format

SELECT 
	saledate 
FROM 
	HousingData;

-- Saledate is in the date time format, I want to convert it to a date format

SELECT 
	saledate, convert(DATE,saledate) as ConvertedSaleDate 
FROM 
	HousingData;

-- First I will add a new column to the table using Alter Table

ALTER TABLE
	HousingData
ADD ConvertedSaleDate DATE;

-- Now updating the new column with items in SaleDate buy converted to the Date Format

UPDATE 
	HousingData 
SET 
	ConvertedSaleDate =CONVERT(DATE,SaleDate);

SELECT 
	SaleDate,ConvertedSaleDate 
FROM 
	HousingData;

----------------------------------------------------------------------------------------------------------------------------------------------------
-- 2. Populate PropertyAddress Data
-- Problem: There are NULL values within PropertyAddress Column 
-- Solution: We can Populate these NULL values using the ParcelID column
-- I went through the data and understood that the parcelID repeats for PropertyAdderess so i can
-- use ParcelID to match PropertyAdress that has NULL values

-- Using Self Join to match all Property Adresses with address and all Property Adresses that are null where parcelID is the same

SELECT
	a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress
FROM
	HousingData a
JOIN
	HousingData b
ON 
	a.ParcelID = b.ParcelID
AND
	a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL ;

-- With this above code I have matched all the null values with a parcelID to ParcelID with property Addresses
-- Now all there is left is to populate the null values with addresses that have same parcelID

UPDATE a
SET a.PropertyAddress= ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM
	HousingData a
JOIN
	HousingData b
ON 
	a.ParcelID = b.ParcelID
AND
	a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL ;

-- Now to check if all the null values are populated with property addresses that have same parcelID

Select 
	PropertyAddress
FROM 
	HousingData
Where 
	PropertyAddress IS NULL;

-- Returns Nothing as all NULL values are now Populated
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 3. Spliting the single column Adress to Multiple Columns (Address, City, State)
-- Problem: The PropertyAdress and OwnerAdress columns have addresses in single column like
-- 107  GARNER AVE, MADISON , 
-- Solution: to Make data analysis easier I will split this into two columns (Address and City)
-- A combination of Substring and CharIndex can be use to split the first part
-- A combination of substring and CharIndex and LEN can be used to spit the second part

SELECT
	SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress) - 1) as PropertyAddress,
	SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress) + 1,LEN(PropertyAddress)) as PropertyCity
FROM
	HousingData;

-- To make the updates permenant I will create two new columns, PropertyAddressLine and PropertyCity

ALTER TABLE	
	HousingData
ADD 
	PropertyAddressLine varchar(255)
;

UPDATE 
	HousingData
SET
	PropertyAddressLine = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress) - 1)
;

ALTER TABLE	
	HousingData
ADD 
	PropertyCity varchar(255)
;

UPDATE 
	HousingData
SET
	PropertyCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress) + 1,LEN(PropertyAddress))
;

-- View Results
SELECT 
	*
FROM
	HousingData
;
-----------------------------------------------------------------------------------------------------------------------------------------------
-- Alternativly I can use ParseName function to split the OwnerAddress which is in the form 107  GARNER AVE, MADISON, TN
-- and split them into address, city ,and State
-- ParseName returns sections of the text using the '.' delimiter so I will replace the ',' with '.' and then use ParseName function

Select
	PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM
	HousingData;

-- Gives output as TN which is the State

Select
	PARSENAME(REPLACE(OwnerAddress,',','.'),2)
FROM
	HousingData;

-- gives output as Maddison, which is the CITY

Select
	PARSENAME(REPLACE(OwnerAddress,',','.'),3)
FROM
	HousingData;
-- gives the Address
-- Now to create three new field to add the Address,City,and State seperatly and to populate it with the Split Data 

ALTER TABLE	
	HousingData
ADD 
	OwnerAddressLine varchar(255);

UPDATE 
	HousingData
SET
	OwnerAddressLine = PARSENAME(REPLACE(OwnerAddress,',','.'),3);

ALTER TABLE	
	HousingData
ADD 
	OwnerCity varchar(255);

UPDATE 
	HousingData
SET
	OwnerCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2);

ALTER TABLE	
	HousingData
ADD 
	OwnerState varchar(255);

UPDATE 
	HousingData
SET
	OwnerState = PARSENAME(REPLACE(OwnerAddress,',','.'),1);

-- See Results

SELECT 
	*
FROM
	HousingData;

-----------------------------------------------------------------------------------------------------------------------------------------------------

-- 4. Changing 'Y' and 'N' to 'Yes' and 'No' for SoldAsVacant Column
-- Problem: the items within SoldAsVacant column are mostly Yes and No but some items are 'Y' and 'N'
-- Solution: To use CASE statement to change all the 'Y' to Yes and 'N' to NO


-- Trying the Case Statement 
SELECT
	Soldasvacant,
CASE
	
		When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END AS 'NewSoldAsVacant'
FROM 
	HousingData;

-- Using the Case Statement to Update the SolsAsVacant COLUMN

UPDATE
	HousingData
SET
	SoldAsVacant =
	CASE
	
		When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END;

-- Check Result
SELECT 
	DISTINCT(Soldasvacant),COUNT(Soldasvacant)
FROM 
	HousingData 
GROUP BY 
	soldasvacant 
ORDER BY
	2;
-- -----------------------------------------------------------------------------------------------------------------------------------------------
-- 5. Removing Duplicates using a Common Table Expression (CTE)
-- Problem: Some rows in the table have the same parcelID,Property Address, salesPrice, SalesDate, LegalReference
-- Solution: I can use a windows function to partition by the above column names and delete any row where the row number is greater than 1 
-- (Where there are duplicate values) and this can be done using a DELETE within a CTE


WITH RowNum_CTE AS(
	SELECT
		*,
		ROW_NUMBER() OVER(
			PARTITION BY	
				ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
			ORDER BY 
				UniqueID
				) row_num
	FROM 
		HousingData)
DELETE 
	FROM RowNum_CTE
	WHERE row_num>1;
-- This creates a row_number 1 for all unique rows and the row_number will be 2 for duplicates, so I delete all rows with row_number greater than 1
-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Removing Unused Columns
-- Problem: there are unused columns and also columns that I split to create more usable fields
-- Solution: Use DROP command to delete irrelevent columns to make data clean

ALTER TABLE HousingData
DROP COLUMN SaleDate,OwnerAddress,TaxDistrict,PropertyAddress;

SELECT 
	* 
FROM 
	HousingData;
-- Unused columns are deleted
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- END OF PROJECT
