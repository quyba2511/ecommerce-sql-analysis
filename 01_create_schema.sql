-- ============================================================
-- E-COMMERCE DATABASE SCHEMA
-- Author: Pô (quyba2511)
-- Project: E-commerce Business Intelligence with PostgreSQL
-- ============================================================

-- Drop tables if exist (để chạy lại nhiều lần không lỗi)
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS campaigns CASCADE;

-- ============================================================
-- TABLE 1: CUSTOMERS
-- ============================================================
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    city VARCHAR(50),
    country VARCHAR(50),
    signup_date DATE NOT NULL,
    age INT,
    gender VARCHAR(10)
);

-- ============================================================
-- TABLE 2: PRODUCTS
-- ============================================================
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    cost DECIMAL(10, 2) NOT NULL,
    stock_quantity INT DEFAULT 0
);

-- ============================================================
-- TABLE 3: ORDERS
-- ============================================================
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    order_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(20)
);

-- ============================================================
-- TABLE 4: ORDER_ITEMS
-- ============================================================
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(order_id),
    product_id INT NOT NULL REFERENCES products(product_id),
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL
);

-- ============================================================
-- TABLE 5: CAMPAIGNS
-- ============================================================
CREATE TABLE campaigns (
    campaign_id SERIAL PRIMARY KEY,
    campaign_name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    budget DECIMAL(12, 2) NOT NULL,
    channel VARCHAR(50) NOT NULL
);

-- ============================================================
-- INDEXES (tăng tốc query)
-- ============================================================
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_customers_country ON customers(country);
CREATE INDEX idx_products_category ON products(category);

-- ============================================================
-- VERIFY
-- ============================================================
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
