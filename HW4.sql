CREATE TABLE customer (
    customer_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    region VARCHAR(50)
);
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customer(customer_id),
    total_amount DECIMAL(10, 2),
    order_date DATE,
    status VARCHAR(20)
);

CREATE TABLE product (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10, 2),
    category VARCHAR(50)
);

CREATE TABLE order_detail (
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES product(product_id),
    quantity INT
);

INSERT INTO customer (full_name, region) VALUES
('Nguyen Van A', 'North'),
('Tran Thi B', 'South'),
('Le Van C', 'Central'),
('Pham Thi D', 'North'),
('Hoang Van E', 'West');

INSERT INTO orders (customer_id, total_amount, order_date, status) VALUES
(1, 100.00, '2023-10-01', 'Pending'),
(1, 50.00, '2023-10-05', 'Completed'),
(2, 200.00, '2023-10-10', 'Shipping'),
(3, 150.00, '2023-11-01', 'Pending'),
(4, 300.00, '2023-11-15', 'Completed'),
(5, 120.00, '2023-11-20', 'Cancelled');

-- 1. VIEW TỔNG HỢP DOANH THU THEO KHU VỰC
-- 1a. Tạo View v_revenue_by_region
CREATE OR REPLACE VIEW v_revenue_by_region AS
SELECT 
    c.region, 
    SUM(o.total_amount) AS total_revenue
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.region;

SELECT * FROM v_revenue_by_region
ORDER BY total_revenue DESC
LIMIT 3;

-- 2. MATERIALIZED VIEW & UPDATE VIEW (WITH CHECK OPTION)
-- 2a. Tạo Materialized View thống kê doanh thu tháng (Theo hình 2)
CREATE MATERIALIZED VIEW mv_monthly_sales AS
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    SUM(total_amount) AS monthly_revenue
FROM orders
GROUP BY DATE_TRUNC('month', order_date);

-- Xem dữ liệu từ Materialized View
SELECT * FROM mv_monthly_sales;


-- 2b. Tạo View cập nhật được (Updatable View) với WITH CHECK OPTION
-- Tạo một View chỉ chứa các đơn hàng đang ở trạng thái 'Pending'
CREATE OR REPLACE VIEW v_pending_orders AS
SELECT order_id, customer_id, total_amount, status
FROM orders
WHERE status = 'Pending'
WITH CHECK OPTION;

-- Thử cập nhật hợp lệ (Vẫn giữ status là Pending -> Thành công)
UPDATE v_pending_orders 
SET total_amount = 110.00 
WHERE order_id = 1;
-- 3. VIEW PHỨC HỢP (NESTED VIEW)
-- Tạo View mới dựa trên View v_revenue_by_region đã tạo ở phần 1
-- Chỉ hiển thị khu vực có doanh thu > mức trung bình toàn quốc

CREATE OR REPLACE VIEW v_revenue_above_avg AS
SELECT *
FROM v_revenue_by_region
WHERE total_revenue > (
    SELECT AVG(total_revenue) FROM v_revenue_by_region
);
