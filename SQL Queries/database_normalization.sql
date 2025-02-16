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

-- WHAT TO FIX
-- num_of_item in order 
-- make a documentation about new table 
-- add product category table (violation of normalization)
-- redundancy in events table



SELECT COUNT(*) FROM inventory_items;
SELECT COUNT(*) FROM inventory_items
WHERE sold_at IS NULL;

SELECT *
FROM inventory_items
WHERE product_id = 7615;

SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'order_items';
