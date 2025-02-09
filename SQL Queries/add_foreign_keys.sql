USE [e-commerce_sales_in_usa];

GO
BEGIN TRANSACTION;

ALTER TABLE [products]
ADD CONSTRAINT FK_products_distribution_centers
FOREIGN KEY ([distribution_center_id]) REFERENCES [distribution_centers]([id]);

ALTER TABLE [inventory_items]
ADD CONSTRAINT FK_inventory_items_products
FOREIGN KEY ([product_id]) REFERENCES [products]([id]);

ALTER TABLE [order_items]
ADD
    CONSTRAINT FK_order_items_orders
    FOREIGN KEY ([order_id]) REFERENCES [orders]([id]),
    CONSTRAINT FK_order_items_users
    FOREIGN KEY ([user_id]) REFERENCES [users]([id]),
    CONSTRAINT FK_order_items_products
    FOREIGN KEY ([product_id]) REFERENCES [products]([id]),
    CONSTRAINT FK_order_items_inventory_items
    FOREIGN KEY ([inventory_item_id]) REFERENCES [inventory_items]([id]);

ALTER TABLE [events]
ADD CONSTRAINT FK_events_users
FOREIGN KEY ([user_id]) REFERENCES [users]([id]);

ALTER TABLE [orders]
ADD CONSTRAINT FK_orders_users
FOREIGN KEY ([user_id]) REFERENCES [users]([id]);

COMMIT TRANSACTION;