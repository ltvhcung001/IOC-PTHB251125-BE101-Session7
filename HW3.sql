CREATE TABLE post (
    post_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT,
    tags TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_public BOOLEAN DEFAULT TRUE
);

CREATE TABLE post_like (
    user_id INT NOT NULL,
    post_id INT NOT NULL,
    liked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, post_id)
);

INSERT INTO post (user_id, content, tags, created_at, is_public)
SELECT 
    (random() * 1000)::INT, -- Random user_id
    'Bài đăng về du lịch ' || md5(random()::text), -- Content ngẫu nhiên chứa từ khóa
    CASE WHEN random() > 0.5 THEN ARRAY['travel', 'food'] ELSE ARRAY['tech', 'news'] END, -- Random tags
    NOW() - (random() * 30 || ' days')::INTERVAL, -- Random ngày trong 30 ngày qua
    (random() > 0.2) -- 80% là public, 20% là private
FROM generate_series(1, 100000);
-- 1. TỐI ƯU HÓA TÌM KIẾM THEO TỪ KHÓA (EXPRESSION INDEX)
-- 1a. Kiểm tra hiệu năng TRƯỚC khi có index (Sẽ dùng Seq Scan - Quét toàn bộ bảng)
EXPLAIN ANALYZE 
SELECT * FROM post 
WHERE is_public = TRUE AND LOWER(content) LIKE '%du lịch%';

-- 1b. Tạo Expression Index sử dụng LOWER(content)
CREATE INDEX idx_post_content_lower ON post(LOWER(content));

-- 1c. Kiểm tra hiệu năng SAU khi có index
EXPLAIN ANALYZE 
SELECT * FROM post 
WHERE is_public = TRUE AND LOWER(content) LIKE '%du lịch%';

-- 2. TỐI ƯU HÓA LỌC THEO THẺ TAGS (GIN INDEX)
-- 2a. Kiểm tra hiệu năng TRƯỚC khi có index (Seq Scan chậm chạp trên mảng)
EXPLAIN ANALYZE 
SELECT * FROM post WHERE tags @> ARRAY['travel'];

-- 2b. Tạo GIN Index cho cột mảng tags
CREATE INDEX idx_post_tags_gin ON post USING GIN (tags);

-- 2c. Kiểm tra hiệu năng SAU khi có index (Bitmap Heap Scan cực nhanh)
EXPLAIN ANALYZE 
SELECT * FROM post WHERE tags @> ARRAY['travel'];

-- 3. TỐI ƯU HÓA TÌM KIẾM BÀI ĐĂNG MỚI (PARTIAL INDEX)
-- 3a. Tạo Partial Index (Chỉ đánh index cho các bài post public, giúp index nhỏ gọn hơn)
CREATE INDEX idx_post_recent_public 
ON post(created_at DESC) 
WHERE is_public = TRUE;

-- 3b. Kiểm tra hiệu suất truy vấn lấy bài public trong 7 ngày qua
EXPLAIN ANALYZE 
SELECT * FROM post 
WHERE is_public = TRUE 
AND created_at >= NOW() - INTERVAL '7 days';

-- 4. PHÂN TÍCH CHỈ MỤC TỔNG HỢP (COMPOSITE INDEX)
-- 4a. Tạo chỉ mục tổng hợp (user_id + created_at)
-- Tối ưu cho câu lệnh: "Lấy các bài mới nhất của user X"
CREATE INDEX idx_post_user_recent ON post(user_id, created_at DESC);

-- 4b. Kiểm tra hiệu suất (Ví dụ: Lấy 10 bài mới nhất của user có id 100)
EXPLAIN ANALYZE 
SELECT * FROM post 
WHERE user_id = 100 
ORDER BY created_at DESC 
LIMIT 10;
