USE [e-commerce_sales_in_usa];

GO
-- [inventory_items] table
	-- 3NF Violation
SELECT
	product_id,
	cost,
	product_category,
	product_name,
	product_brand,
	product_retail_price,
	product_department,
	product_distribution_center_id
FROM inventory_items
WHERE product_id = 7615;

BEGIN TRANSACTION;

ALTER TABLE inventory_items
DROP COLUMN
	cost,
	product_category,
	product_name,
	product_brand,
	product_retail_price,
	product_department,
	product_sku,
	product_distribution_center_id;

COMMIT;

-- [order_items] table
	-- 3NF Violation

SELECT TOP 100
	oi.created_at,
	o.created_at,
	oi.shipped_at,
	o.shipped_at,
	oi.delivered_at,
	o.delivered_at,
	oi.returned_at,
	o.returned_at
FROM order_items AS oi
JOIN orders AS o ON o.id = oi.order_id;

BEGIN TRANSACTION;

ALTER TABLE order_items
DROP COLUMN
	created_at,
	shipped_at,
	delivered_at,
	returned_at;

COMMIT;

SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'order_items';

	-- More 3NF Violation

SELECT TOP 100
	oi.status,
	o.status,
	oi.user_id,
	o.user_id
FROM order_items AS oi
JOIN orders AS o ON o.id = oi.order_id;

SELECT
    f.name AS ForeignKeyName,
    OBJECT_NAME(f.parent_object_id) AS TableName,
    COL_NAME(fc.parent_object_id, fc.parent_column_id) AS ColumnName,
    OBJECT_NAME(f.referenced_object_id) AS ReferencedTable,
    COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS ReferencedColumn
FROM sys.foreign_keys AS f
JOIN sys.foreign_key_columns AS fc
    ON f.object_id = fc.constraint_object_id
WHERE OBJECT_NAME(f.parent_object_id) = 'inventory_items'

BEGIN TRANSACTION;

ALTER TABLE order_items
DROP CONSTRAINT FK_order_items_users;
ALTER TABLE order_items
DROP COLUMN
	user_id,
	status;

COMMIT;

SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'order_items';

	-- Even more 3NF Violation
		-- Checking for redundancy in the 'sale_price' column of 'order_items' table  
		WITH  
		    CTE_TotalRows AS (  
		        SELECT COUNT(*) AS total_rows  
		        FROM order_items AS oi  
		        JOIN products AS p ON oi.product_id = p.id  
		    ),  
		
		    CTE_RedundantRows AS (  
		        SELECT COUNT(*) AS redundant_rows  
		        FROM order_items AS oi  
		        JOIN products AS p ON oi.product_id = p.id  
		        WHERE oi.sale_price = p.retail_price  
		    )  
		
		SELECT  
		    total_rows,  
		    redundant_rows,  
		    FLOOR((redundant_rows * 100.0 / NULLIF(total_rows, 0))) AS redundancy_percentage  
		FROM CTE_TotalRows, CTE_RedundantRows;
		
		BEGIN TRANSACTION;
		
		ALTER TABLE order_items
		DROP COLUMN sale_price
		
		COMMIT;
		
		SELECT TABLE_NAME, COLUMN_NAME
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME LIKE 'order_items';

	-- Bad Schema Design in orders Table  
		-- The num_of_item column in orders is redundant and prone to inconsistencies  
		-- because the orders table has a one-to-many relationship with users, while  
		-- order_items establishes a many-to-many relationship between orders and products.  
		-- It doesn't track product-specific quantities and duplicates data already available in order_items.  
		-- Fixing it by removing num_of_item from orders and adding quantity to order_items for proper tracking.  
	
	BEGIN TRANSACTION;

	ALTER TABLE orders
	DROP COLUMN num_of_item;
	ALTER TABLE order_items
	ADD quantity INT;

	COMMIT;

	-- Identifying redundancy in the order_items table by partitioning rows with the same order_id and product_id.
	-- The query with ROW_NUMBER() helps detect duplicate entries for the same product in an order.
	-- The second query checks specific order IDs to highlight any redundant product entries in those orders.
	
	WITH CTE AS (
	    SELECT
	        ROW_NUMBER() OVER (PARTITION BY order_id, product_id ORDER BY order_id) as RN,
	        order_id,
	        product_id,
			quantity
	    FROM order_items)
	
	SELECT RN, order_id, product_id, quantity
	FROM CTE
	WHERE RN > 1;
	
	SELECT order_id, product_id, quantity FROM order_items
	JOIN ORDERS ON order_items.order_id = orders.id
	WHERE order_id = 62658
	OR order_id = 34947
	OR order_id = 62658
	OR order_id = 102281
	OR order_id = 22593
	OR order_id = 96038
	OR order_id = 10236
	OR order_id = 25056
	OR order_id = 111622
	ORDER BY order_id, product_id;

	-- Lets's return unique pairs of order_id and product_id, 
	-- and assign the quantity by finding the maximum row number 
	-- within each partition of order_id and product_id, representing 
	-- the total quantity of each product in an order.
	BEGIN TRANSACTION;
	
	WITH CTE AS (
	    SELECT
	        order_id,
	        product_id,
	        COUNT(*) AS quantity 
	    FROM order_items
	    GROUP BY order_id, product_id)

	UPDATE oi
	SET oi.quantity = CTE.quantity
	FROM order_items oi
	JOIN CTE ON oi.order_id = CTE.order_id AND oi.product_id = CTE.product_id;

	COMMIT;

	-- Now we delete all rows where the row number (RN) is greater than 1, effectively removing duplicate entries
	BEGIN TRANSACTION;

	WITH CTE AS (
	    SELECT
	        id,
	        ROW_NUMBER() OVER (PARTITION BY order_id, product_id ORDER BY order_id) AS RN
	    FROM order_items)

	DELETE oi
	FROM order_items oi
	JOIN CTE ON oi.id = CTE.id
	WHERE CTE.RN > 1;

	COMMIT;

	SELECT order_id, product_id, quantity FROM order_items
	JOIN ORDERS ON order_items.order_id = orders.id
	WHERE order_id = 62658
	OR order_id = 34947
	OR order_id = 62658
	OR order_id = 102281
	OR order_id = 22593
	OR order_id = 96038
	OR order_id = 10236
	OR order_id = 25056
	OR order_id = 111622
	ORDER BY order_id, product_id;

-- WHAT TO FIX
-- num_of_item in order 
-- make a documentation about new table 
-- add product category table (violation of normalization)
-- redundancy in events table
-- BigQuery + check documentation time choise



SELECT COUNT(*) FROM inventory_items;
SELECT COUNT(*) FROM inventory_items
WHERE sold_at IS NULL;

SELECT *
FROM inventory_items
WHERE product_id = 7615;

SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'order_items';
