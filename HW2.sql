CREATE TABLE customer (
    customer_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(15)
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customer(customer_id),
    total_amount DECIMAL(10, 2),
    order_date DATE
);
INSERT INTO customer (full_name, email, phone) VALUES 
('Nguyen Van A', 'abc@gmail.com', '0901234567'),
('Tran Thi B', 'xyz@gmail.com', '0909876543');

INSERT INTO orders (customer_id, total_amount, order_date) VALUES 
(1, 150.00, '2023-10-01'),
(1, 200.00, '2023-10-15'),
(2, 300.50, '2023-11-05');

-- 1. TẠO VIEW v_order_summary
-- Yêu cầu: Hiển thị full_name, total_amount, order_date (ẩn email, phone)
CREATE OR REPLACE VIEW v_order_summary AS
SELECT 
    c.full_name, 
    o.total_amount, 
    o.order_date
FROM orders o
JOIN customer c ON o.customer_id = c.customer_id;

-- 2. TRUY VẤN XEM DỮ LIỆU TỪ VIEW
SELECT * FROM v_order_summary;

-- 3. CẬP NHẬT TỔNG TIỀN THÔNG QUA VIEW
-- Lưu ý: Trong PostgreSQL, View có JOIN mặc định là READ-ONLY. 
-- Để update được cần dùng Trigger, nhưng dưới đây là câu lệnh theo yêu cầu đề bài:
UPDATE v_order_summary 
SET total_amount = 250.00 
WHERE full_name = 'Nguyen Van A' AND order_date = '2023-10-15';

-- 4. TẠO VIEW v_monthly_sales (DOANH THU THÁNG)
CREATE OR REPLACE VIEW v_monthly_sales AS
SELECT 
    TO_CHAR(order_date, 'YYYY-MM') AS month,
    SUM(total_amount) AS total_revenue
FROM orders
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY month;

-- Xem kết quả doanh thu tháng
SELECT * FROM v_monthly_sales;

-- 5. DROP VIEW & SO SÁNH
DROP VIEW IF EXISTS v_order_summary;

/* SO SÁNH DROP VIEW vs DROP MATERIALIZED VIEW:

   1. DROP VIEW:
      - Xóa định nghĩa logic của View ảo.
      - Không ảnh hưởng đến dữ liệu gốc, vì View thường không lưu trữ dữ liệu (nó chỉ là câu query được lưu lại).

   2. DROP MATERIALIZED VIEW:
      - Xóa Materialized View (loại View có lưu trữ dữ liệu vật lý/snapshot để tăng tốc độ truy vấn).
      - Nó sẽ giải phóng không gian ổ cứng đã dùng để lưu cache dữ liệu của View đó.
*/
