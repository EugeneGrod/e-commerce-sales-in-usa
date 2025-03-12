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

	-- Checking the result 
	SELECT order_id, product_id, quantity 
	FROM order_items
	JOIN ORDERS ON order_items.order_id = orders.id
	WHERE order_id IN (62658, 34947, 102281, 22593, 96038, 10236, 25056, 111622)
	ORDER BY order_id, product_id;

-- [products] table
	-- 3NF Violation
		-- Create separate tables for category, brand, and department to eliminate redundancy
	CREATE TABLE categories (
    id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(255) UNIQUE NOT NULL);

	CREATE TABLE brands (
    id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(255) UNIQUE NOT NULL);

	CREATE TABLE departments (
    id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(255) UNIQUE NOT NULL);

		-- Populate these tables with unique values extracted from the products table
	INSERT INTO categories (name)
	SELECT DISTINCT category FROM products;

	INSERT INTO brands (name)
	SELECT DISTINCT brand FROM products;

	INSERT INTO departments (name)
	SELECT DISTINCT department FROM products;

		-- Add foreign key columns in the products table to reference the new tables
	ALTER TABLE products
	ADD category_id INT,
		brand_id INT,
		department_id INT,
	    CONSTRAINT FK__products__categories
		FOREIGN KEY (category_id) REFERENCES categories(id),
		CONSTRAINT FK__products__brands
		FOREIGN KEY (brand_id) REFERENCES brands(id),
		CONSTRAINT FK__products__departments
		FOREIGN KEY (department_id) REFERENCES departments(id);

		-- Update products table by assigning the appropriate foreign key IDs
	UPDATE products
	SET category_id = c.id
	FROM products p
	JOIN categories c ON p.category = c.name;

	UPDATE products
	SET brand_id = b.id
	FROM products p
	JOIN brands b ON p.brand = b.name;
	
	UPDATE products
	SET department_id = d.id
	FROM products p
	JOIN departments d ON p.department = d.name;
	
		-- Remove the original category, brand, and department columns from the products table
	ALTER TABLE products
	DROP COLUMN category, brand, department;


-- WHAT TO FIX
-- make a documentation about new table 
-- add product category table (violation of normalization)
-- redundancy in events table
-- BigQuery + check documentation time choise

SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS

SELECT COUNT(*) FROM inventory_items;
SELECT COUNT(*) FROM inventory_items
WHERE sold_at IS NULL;

SELECT *
FROM inventory_items
WHERE product_id = 7615;

SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'order_items';

SELECT * FROM distribution_centers;
SELECT TOP 100 * FROM order_items;
SELECT TOP 100 * FROM products;
SELECT TOP 0 * FROM products;
SELECT DISTINCT category FROM products;
SELECT DISTINCT name FROM products;
SELECT DISTINCT brand FROM products;
SELECT DISTINCT department FROM products;
SELECT COUNT(*) FROM products;
SELECT * FROM products;
SELECT name, COUNT(*) AS repeats FROM products
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY repeats DESC;
SELECT * FROM products
WHERE name = 'Wrangler Men''s Premium Performance Cowboy Cut Jean';

SELECT * FROM products
WHERE name = 'HUGO BOSS Men''s Long Pant'

SELECT TOP 0 * FROM products;