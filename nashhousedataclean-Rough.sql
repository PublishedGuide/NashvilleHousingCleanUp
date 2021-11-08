SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;

-- Standardize the date format
SELECT SaleDate, CONVERT(Date,SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing;

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)
#Lets see if the conversion worked withe the querie below
SELECT SaleDateConverted, CONVERT(Date,SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing;

-- Populate Property Address Data
# see the Property address information
SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing

# Now lets see where this property address is Null
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress is Null
 
# likely that this information could be populated if we had a reference point to work with
# Here we see that there is a relationship between parcel ID and address, often enough that we can tell that Parcel iD is indicative of the Property Address
# This means we can fill in empty or null Property addresses if there is an assigned ParcelID that already has a related address
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID

#Use a self join to run a conditional statement
#Essentially we want to assign the property address for a parcelID on one unique id, to the same parcel ID on another UniqueID that doesnt already have  a property address value
#this query below will show us the section of the table where we need to apply these changes and what the changes would be
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is Null
    
#Here is where we apply the change:
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is Null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is Null
#Now when we select "Where value is Null", no item is shown because all the null values have been assigned the correct address

#To check whether the update was affective we can use the two queries below to find that there is no more null value for property address
#and the ParcelIDs all seem to have their associated Property Addresses consistent
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress is Null;
 
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID;

-- Breaking out Address into individual columns (Address, City) ## State will always be TN
#First we view what the address column values appear as and what delimiters we can find for separation of columns
SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing;

SELECT PropertyAddress
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Adress,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1 , LEN(PropertyAddress) AS City
-- ,SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1 , LEN(PropertyAddress) AS Adress
FROM PortfolioProject.dbo.NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1 , LEN(PropertyAddress);

#ALTER TABLE NashvilleHousing
#ADD PropertySplitState nvarchar(255);

#UPDATE NashvilleHousing
#SET PropertySplitState = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1 , LEN(PropertyAddress);

#Check to see how well the updates were applied
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;

##Now lets look at OwnerAddress using PARSENAME(without the substrings) - more effiient, but updates are still necessary to be applied
SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing;

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject.dbo.NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

#Check updates:
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;

-- Change Y and N to Yes and No in "Sold as Vacant" column
#View all input values within the column and how often they occur
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS SAVCount
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant, 
CASE WHEN SoldAsVacant = "Y" THEN "Yes"
	 WHEN SoldAsVacant = "N" THEN "No"
     ELSE SoldAsVacant
     END
FROM PortfolioProject.dbo.NashvilleHousing;

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = "Y" THEN "Yes"
	 WHEN SoldAsVacant = "N" THEN "No"
     ELSE SoldAsVacant
     END

## Check our update:
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS SAVCount
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

-- Remove Duplicates  (Normally would not remove or delete data, but create a new cleaner table with updates)
##We need to partition by unique values - We will ignore the UniqueID for the case of this example, just to show case ability
#Here we would essentially br creating a temp table where we have a column named 'row_num' that will itentify when all of the
#columns below show the same exact data as another set of columns - -and from there we can narrow down which rows are duplicates
WITH RowNumbCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
    PARTITION BY PaparcelID,
				 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY
					UniqueID
                    ) row_num
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID
)
SELECT*
FROM RowNumbCTE
WHERE row_num > 1
ORDER BY PropertyAddress

#The query above helps us see the duplicated data, the chunk below will be used to delete duplicates
WITH RowNumbCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
    PARTITION BY PaparcelID,
				 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY
					UniqueID
                    ) row_num
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID
)
DELETE
FROM RowNumbCTE
WHERE row_num > 1

#Reuse the first identifier query to find if there are any remaining duplicates

-- Delete Unused Columns
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

#Check to see what is left
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

#Now we have cleaned the data to make it more usable
-------------------------------------------------------- 
----- Importing data using OPENROWSET and BULK INSERT
-- More advanced and looks nicer, but have to configure server appropriately to do correctly
-- Simpler methods above are easier and quicker to do, and are easier to explain for sharing purposes on portfolio

-- sp_configure 'show advanced options', 1:
-- RECONFIGURE;
-- GO
-- sp_configure 'Ad Hoc Distributed Queries', 1:
-- RECONFIGURE;
-- GO

-- USE PortfolioProject ## your database name (amitob1)
-- GO
-- EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0' , N'AllowInProcess', 1
-- GO
-- EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0' , N'AllowInProcess', 1
-- GO

----- Using BULK INSERT
-- USE PortfolioProject ## your database name (amitob1);
-- GO
-- BULK INSERT datatabletitle FROM 'path to table'
-- WITH (
#--	 FIELDTERMINATOR = ",",
#--  ROWTERMINATOR = "\n"
-- );
-- GO

----- Using OPENROWSET
-- USE PortfolioProject ## your database name (amitob1);
-- GO

 


