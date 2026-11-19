# Nashville Housing Data Cleaning using MySQL

A SQL data cleaning project that takes a raw Nashville housing sales dataset and turns it into an analysis-ready table. All work is done in MySQL using a staging-table approach, so the raw data is never modified.

## Project Overview

This project cleans a dataset of Nashville property sales by fixing data types, removing duplicates, splitting combined address fields, standardizing inconsistent labels, and handling blank values.

**Goal:** produce a clean, consistent table that can be used directly for analysis or dashboards.

## Tools & Skills Demonstrated

- **MySQL** (MySQL Workbench)
- Data cleaning and standardization
- CTEs and window functions (`ROW_NUMBER() OVER (PARTITION BY ...)`)
- String functions (`SUBSTRING_INDEX`, `TRIM`)
- Date conversion (`STR_TO_DATE`)
- `ALTER TABLE`, `UPDATE`, `DELETE`, `CREATE TABLE ... LIKE`

## Dataset

- **File:** `Nashville_Housing_Data.csv`
- **Contents:** property sales records including parcel ID, address, sale date and price, land use, owner details, acreage, valuation, year built, bedrooms and bathrooms.
- **Source:** Nashville Housing dataset https://www.kaggle.com/datasets/austinkennell/cleaning-data-in-sql-portfolio-project.

## Cleaning Steps

| # | Step | What was done |
|---|------|---------------|
| 1 | **Load & stage** | Imported the CSV with `LOAD DATA LOCAL INFILE`, then created `nashville_housing_staging` so the raw table stays untouched. |
| 2 | **Fix date format** | Converted `SaleDate` from text (e.g. `April 9, 2013`) to a proper `DATE` type using `STR_TO_DATE`. |
| 3 | **Remove duplicates** | Used `ROW_NUMBER()` partitioned by `ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference`, loaded the result into `nashville_housing_staging2`, and deleted rows where `row_num > 1`. |
| 4 | **Split property address** | Split `PropertyAddress` into `PropertySplitAddress` and `PropertySplitCity`. |
| 5 | **Split owner address** | Split `OwnerAddress` into `OwnerSplitAddress`, `OwnerSplitCity` and `OwnerSplitState`. |
| 6 | **Drop unused columns** | Removed the original combined address columns, `TaxDistrict` and the helper `row_num` column. |
| 7 | **Standardize land use** | Merged inconsistent labels such as `VACANT RES LAND` into `VACANT RESIDENTIAL LAND`, and fixed the `GRRENBELT/RES` typo. |
| 8 | **Handle blanks** | Converted empty `OwnerName` values to `NULL`. |


## Results

- `SaleDate` is a true `DATE` column, ready for time-based analysis.
- Duplicate sales records removed.
- Addresses split into separate street, city and state columns for easier filtering and grouping.
- Land use categories standardized and typos fixed.
- Blank owner names stored as `NULL` rather than empty strings.



## Author

**Nikita Maria Johnson**
[LinkedIn](https://www.linkedin.com/in/nikita2000) | [GitHub](https://github.com/Nikitaj-11)
