-- 1a. Index cho cột genre (B-tree mặc định) - Phục vụ câu: genre = 'Fantasy'
CREATE INDEX idx_book_genre ON book(genre);

-- 1b. Index cho cột author.
-- Cách cơ bản (B-tree): Hiệu quả thấp với '%Rowling%', chỉ tốt với 'Rowling%'
CREATE INDEX idx_book_author ON book(author);

-- 2. So sánh thời gian truy vấn trước và sau khi tạo Index (dùng EXPLAIN ANALYZE)
EXPLAIN ANALYZE SELECT * FROM book WHERE author ILIKE '%Rowling%';
EXPLAIN ANALYZE SELECT * FROM book WHERE genre = 'Fantasy';

-- 3b. GIN cho title hoặc description (phục vụ tìm kiếm full-text)
CREATE INDEX idx_book_description_gin ON book USING GIN (to_tsvector('english', description));

EXPLAIN ANALYZE
SELECT * FROM book
WHERE to_tsvector('english', description) @@ to_tsquery('english', 'magic & hogwarts');

-- 4. Tạo một Clustered Index (sử dụng lệnh CLUSTER) trên bảng book theo cột genre và kiểm tra sự khác biệt trong hiệu suất
-- Sắp xếp lại bảng book dựa trên index idx_book_genre đã tạo ở bước 1
CLUSTER book USING idx_book_genre;

-- Kiểm tra lại hiệu suất sau khi cluster
EXPLAIN ANALYZE SELECT * FROM book WHERE genre = 'Fantasy';

-- 5. Viết báo cáo ngắn (5-7 dòng) giải thích:
-- Loại chỉ mục nào hiệu quả nhất cho từng loại truy vấn?
-- Khi nào Hash index không được khuyến khích trong PostgreSQL?
-- Loại chỉ mục hiệu quả nhất:
-- B-tree: Hiệu quả nhất cho các truy vấn so sánh bằng (=), so sánh phạm vi (<, >, BETWEEN) và sắp xếp (ORDER BY). Phù hợp cho cột genre.
-- GIN: Hiệu quả nhất cho Full-text search (tìm kiếm văn bản) hoặc dữ liệu dạng mảng/JSONB. Phù hợp cho cột description hoặc title khi cần tìm từ khóa phức tạp.

-- b. Khi nào Hash index không được khuyến khích trong PostgreSQL:
-- Hash index không được khuyến khích vì nó chỉ hỗ trợ so sánh bằng (=). Nó không hỗ trợ tìm kiếm theo phạm vi (<, >) hay sắp xếp dữ liệu, và kích thước index đôi khi lớn hơn B-tree.
