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
-- [orders] table
-- [events] table
-- [order_items] table
-- [start_to_end_purchase_events] table

	SELECT TOP 100 product_name FROM inventory_items;

	SELECT DISTINCT product_brand
	FROM inventory_items
	ORDER BY product_brand;
	
	SELECT *
	FROM inventory_items
	WHERE product_name IS NULL;

	SELECT ii.product_name, COUNT(*)
	FROM inventory_items AS ii
	GROUP BY ii.product_name
	HAVING COUNT(*) > 1
	ORDER BY ii.product_name;

			SELECT DISTINCT ii.product_brand AS product_brand_in_inventory_items, p.brand AS product_brand_in_products
		FROM inventory_items AS ii
		JOIN products AS p ON p.id = ii.product_id
		WHERE ii.product_brand IN (
		'Carhartt'   ,
		'JMS'		 ,
		'Shadowline' ,
		'Wendy Glez' ,
		'Wayfarer'	 ,
		'Hurley'	 ,
		'Gildan'	 ,
		'Quiksilver' ,
		'Ariat'		 ,
		'True Nation',
		'Stormtech'	 ,
		'Adidas'	 ,
		'Volcom'	 ,
		'SockGuy'	 ,
		'Harbor Bay' ,
		'O''Neill');
