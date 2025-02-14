USE [e-commerce_sales_in_usa];

GO
-- [products] table
	-- [cost] column
		-- Replace `NULL` values with the average ratio between retail and cost prices
		-- Step 1: Calculate the average ratio between retail and cost prices
WITH [Rate] AS (
	SELECT SUM([retail_price]) / SUM([cost]) AS [avg_rate]
	FROM [e-commerce_sales_in_usa].[dbo].[products]
)

		-- Step 2: Update the cost column where it is NULL
UPDATE [e-commerce_sales_in_usa].[dbo].[products]
SET [cost] = [retail_price] / (SELECT [avg_rate] FROM [Rate])
WHERE [cost] IS NULL;

	-- [name] column
UPDATE products
SET name = 'Unnamed'
WHERE name is NULL;

	-- [brand] column
		-- Replace NULL values with the brand inferred from the product name,
		-- and with 'Unbranded' where the brand can't be inferred
UPDATE products
SET brand = CASE 
	WHEN id = 1629 THEN 'Carhartt'
	WHEN id = 10598 THEN 'JMS'
	WHEN id = 11389 THEN 'Shadowline'
	WHEN id = 11843 THEN 'Wendy Glez'
	WHEN id = 15723 THEN 'Wayfarer'
	WHEN id = 16309 THEN 'Hurley'
	WHEN id = 16559 THEN 'Gildan'
	WHEN id = 16898 THEN 'Quiksilver'
	WHEN id = 21207 THEN 'Ariat'
	WHEN id = 21484 THEN 'True Nation'
	WHEN id = 23769 THEN 'Stormtech'
	WHEN id = 24287 THEN 'Adidas'
	WHEN id = 25135 THEN 'Volcom'
	WHEN id = 25187 THEN 'SockGuy'
	WHEN id = 27543 THEN 'Harbor Bay'
	WHEN id = 27640 THEN 'O''Neill'
    ELSE 'Unbranded'
END
WHERE brand IS NULL;

-- [inventory_items] table
	-- [created_at] column
	BEGIN TRANSACTION
	UPDATE inventory_items
	SET created_at = CAST(REPLACE(created_at, ' UTC', '') AS datetime2)

	ALTER TABLE inventory_items
	ALTER COLUMN created_at datetime2

	COMMIT;

	-- [sold_at] column
	BEGIN TRANSACTION
	UPDATE inventory_items
	SET sold_at = CAST(REPLACE(sold_at, ' UTC', '') AS datetime2)

	ALTER TABLE inventory_items
	ALTER COLUMN sold_at datetime2

	COMMIT;

	-- [cost] column
	SELECT * FROM inventory_items
	WHERE cost IS NULL;

		-- Replace `NULL` values with the average ratio between retail and cost prices
		-- Step 1: Calculate the average ratio between retail and cost prices
	BEGIN TRANSACTION;

		WITH [Rate] AS (
		SELECT SUM([product_retail_price]) / SUM([cost]) AS [avg_rate]
		FROM [inventory_items]
	)

		-- Step 2: Update the cost column where it is NULL
	UPDATE [inventory_items]
	SET [cost] = [product_retail_price] / (SELECT [avg_rate] FROM [Rate])
	WHERE [cost] IS NULL;

	COMMIT;
	
	-- [product_name] column
		-- Replace `NULL` values with corresponding values from the `name` column in the `product` table
		BEGIN TRANSACTION;
		
		UPDATE ii
		SET ii.product_name = p.name
		FROM inventory_items AS ii
		JOIN products AS p ON p.id = ii.product_id
		WHERE ii.product_name IS NULL;

		COMMIT;

	-- [product_brand] column
		-- Replace `NULL` values with corresponding values from the `brand` column in the `product` table
		BEGIN TRANSACTION;
		
		UPDATE ii
		SET ii.product_brand = p.brand
		FROM inventory_items AS ii
		JOIN products AS p ON p.id = ii.product_id
		WHERE ii.product_brand IS NULL;

		COMMIT;

-- [users] table
	-- [city] column
		-- It was found that 135 postal codes are missing corresponding cities in the users table and contain `NULL` values stored as varchar.
		SELECT DISTINCT postal_code, city, country FROM users
		WHERE city LIKE '%null%'
		ORDER BY postal_code ASC;

		-- Since we have corresponding postal codes for these rows, we can extract the missing data from external sources.
		-- Most ZIP codes were downloaded from https://download.geonames.org/export/zip/.
		-- The next step is to extract only the required data using T-SQL and replace the missing values in the city column.
		-- Since ZIP codes are country-specific and not globally unique, we will perform multiple joins, specifying the particular country each time.
		SELECT * FROM ZIP
		WHERE column2 = '30016';
		
		BEGIN TRANSACTION;

		UPDATE u
		SET u.city = z.column3
		FROM users AS u
		LEFT JOIN ZIP AS z ON u.postal_code = z.column2
		WHERE u.city LIKE '%null%'
		AND u.country = 'United States'
		AND z.column1 = 'US';

		COMMIT;

		BEGIN TRANSACTION;

		UPDATE u
		SET u.city = z.column3
		FROM users AS u
		LEFT JOIN ZIP AS z ON u.postal_code = z.column2
		WHERE u.city LIKE '%null%'
		AND u.country = 'Spain'
		AND z.column1 = 'ES';

		COMMIT;

		BEGIN TRANSACTION;

		UPDATE u
		SET u.city = z.column3
		FROM users AS u
		LEFT JOIN ZIP AS z ON u.postal_code = z.column2
		WHERE u.city LIKE '%null%'
		AND u.country = 'Brasil'
		AND z.column1 = 'BR';

		COMMIT;

		BEGIN TRANSACTION;

		UPDATE u
		SET u.city = z.column3
		FROM users AS u
		LEFT JOIN ZIP AS z ON u.postal_code = z.column2
		WHERE u.city LIKE '%null%'
		AND u.country = 'Germany'
		AND z.column1 = 'DE';

		COMMIT;

		-- Replacing the remaining cities that could not be found with 'Unknown'.
		BEGIN TRANSACTION;

		UPDATE users
		SET city = 'Unknown'
		WHERE city LIKE '%null%'

		COMMIT;

		SELECT DISTINCT postal_code, city, country FROM users
		WHERE city LIKE '%null%';

	-- [created_at] column
	BEGIN TRANSACTION;

	UPDATE users
	SET created_at = CAST(REPLACE(created_at, ' UTC', '') AS datetime2)

	ALTER TABLE users
	ALTER COLUMN created_at datetime2

	COMMIT;

-- [orders] table
	-- [datetype columns]
	BEGIN TRANSACTION;
	
	UPDATE orders
	SET
	    created_at = CAST(REPLACE(created_at, ' UTC', '') AS datetime2),
	    returned_at = CAST(REPLACE(returned_at, ' UTC', '') AS datetime2),
	    shipped_at = CAST(REPLACE(shipped_at, ' UTC', '') AS datetime2),
	    delivered_at = CAST(REPLACE(delivered_at, ' UTC', '') AS datetime2);
	
	ALTER TABLE orders
	ALTER COLUMN created_at datetime2;
	ALTER TABLE orders
	ALTER COLUMN returned_at datetime2;
	ALTER TABLE orders
	ALTER COLUMN shipped_at datetime2;
	ALTER TABLE orders
	ALTER COLUMN delivered_at datetime2;
	
	COMMIT;

-- [order_items] table
	-- [datetype columns]
	BEGIN TRANSACTION;
	
	UPDATE order_items
	SET
	    created_at = CAST(REPLACE(created_at, ' UTC', '') AS datetime2),
	    returned_at = CAST(REPLACE(returned_at, ' UTC', '') AS datetime2),
	    shipped_at = CAST(REPLACE(shipped_at, ' UTC', '') AS datetime2),
	    delivered_at = CAST(REPLACE(delivered_at, ' UTC', '') AS datetime2);
	
	ALTER TABLE order_items
	ALTER COLUMN created_at datetime2;
	ALTER TABLE order_items
	ALTER COLUMN returned_at datetime2;
	ALTER TABLE order_items
	ALTER COLUMN shipped_at datetime2;
	ALTER TABLE order_items
	ALTER COLUMN delivered_at datetime2;
	
	COMMIT;

-- [events] table
	-- [city] column	
		-- It was found that 142 postal codes in the events table are missing corresponding cities and contain NULL values stored as VARCHAR.
		-- We will apply the same solution as we did for the users table.
		BEGIN TRANSACTION;

		UPDATE e
		SET e.city = z.column3
		FROM [events] AS e
		LEFT JOIN ZIP AS z ON e.postal_code = z.column2
		WHERE e.city LIKE '%null%'
		AND e.state = z.column4;

		COMMIT;

		BEGIN TRANSACTION;

		UPDATE [events]
		SET city = 'Unknown'
		WHERE city LIKE '%null%'

		COMMIT;

		SELECT postal_code, city, state
		FROM [events]
		WHERE city LIKE 'null';