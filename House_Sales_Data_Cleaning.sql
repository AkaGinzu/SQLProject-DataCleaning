/* Cleaning data in SQL Queries */

SELECT *
FROM PortfolioProjects.dbo.NashvilleHousing


/* Standardize date format */

SELECT SaleDate
FROM PortfolioProjects.dbo.NashvilleHousing


ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate DATE


/* Populate Property Adress Data */

SELECT *
FROM PortfolioProjects.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

--We will check to see if there are filled PropertyAdresses that have same ParcelID with NULL ones.

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM PortfolioProjects.dbo.NashvilleHousing AS a
JOIN PortfolioProjects.dbo.NashvilleHousing AS b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;


--We find out there is so, it is time to populate those adresses to fill the NULL ones.


UPDATE dbo.NashvilleHousing
SET PropertyAddress = (
    SELECT TOP 1 PropertyAddress
    FROM dbo.NashvilleHousing AS T2
    WHERE T2.ParcelID = dbo.NashvilleHousing.ParcelID
	AND T2.[UniqueID ] <> dbo.NashvilleHousing.[UniqueID ]
        AND T2.PropertyAddress IS NOT NULL
)
WHERE PropertyAddress IS NULL;


/* Breaking Out Adress Into Individual Columns (Adress, City, State) */


-- First, we split the PropertyAddress column

SELECT PropertyAddress
FROM PortfolioProjects.dbo.NashvilleHousing

-- At first, we split Adresses into two temp columns

SELECT
SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Adress
, SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress)) AS City
FROM PortfolioProjects.dbo.NashvilleHousing


--Then we turn this two column into permanent ones

ALTER TABLE PortfolioProjects..NashvilleHousing
ADD PropertyAddresses NVARCHAR(255),
    PropertyCities NVARCHAR(255);

UPDATE PortfolioProjects..NashvilleHousing
SET PropertyAddresses = SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) ,
    PropertyCities = SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress));


-- Now we split the OwnerAddress column

SELECT OwnerAddress
FROM PortfolioProjects..NashvilleHousing;


-- This time we use parse for splitting the column

SELECT
PARSENAME (REPLACE(OwnerAddress, ',', '.'), 3)
,PARSENAME (REPLACE(OwnerAddress, ',', '.'), 2)
,PARSENAME (REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProjects..NashvilleHousing;


-- Then making permanent process once again

ALTER TABLE PortfolioProjects..NashvilleHousing
ADD OwnersAddress NVARCHAR(255),
    OwnersCity NVARCHAR(255),
	OwnersState NVARCHAR(255);

UPDATE PortfolioProjects..NashvilleHousing
SET OwnersAddress = PARSENAME (REPLACE(OwnerAddress, ',', '.'), 3),
    OwnersCity = PARSENAME (REPLACE(OwnerAddress, ',', '.'), 2),
	OwnersState = PARSENAME (REPLACE(OwnerAddress, ',', '.'), 1);


/* Changing Y and N to Yes and No in "SoldAsVacant" field */



-- With that query, we can see there are only few Y and N statements when we compare with Yes and No statements

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProjects..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

-- So, we will change Y and N statements to have more clear dataset

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM PortfolioProjects..NashvilleHousing

UPDATE PortfolioProjects..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END


/* Removing Duplicates */

-- First we detect duplications with using ROW_NUMBER and PARTITION BY COMBINATION with CTE

WITH RowNumCTE AS (

SELECT *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID,
             PropertyAddress,
             SalePrice,
             SaleDate,
             LegalReference
             ORDER BY UniqueID) row_num
FROM PortfolioProjects..NashvilleHousing
)

--Then we delete duplication with small query

DELETE 
FROM RowNumCTE
WHERE row_num > 1


-- You can chance the DELETE statement to SELECT to check if there are any duplications left




/* Delete Unused Columns */

--Since we turn our address columns into more useful once, we can delete them since we will not need them anymore

ALTER TABLE PortfolioProjects..NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress