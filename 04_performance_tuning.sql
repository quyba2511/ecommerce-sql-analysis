-- ============================================================
-- SQL 效能調優實驗 / SQL PERFORMANCE TUNING EXPERIMENTS
-- ============================================================
-- 作者 Author: Pô (quyba2511)
-- 資料庫 Database: PostgreSQL 16
-- 目的 Purpose: 展示 SQL 效能調優知識 / Demonstrate SQL performance tuning knowledge
-- ============================================================
-- 實驗結果摘要 / EXPERIMENT RESULTS SUMMARY:
-- • 單一日期查詢加索引後速度提升 47 倍 (38ms → 0.8ms)
-- • 複合索引比兩個單獨索引快 5.6 倍 (1.7ms → 0.3ms)
-- • Correlated Subquery 比 JOIN 慢 7 倍 (367ms → 50ms)
-- • Single date query: 47x faster with index (38ms → 0.8ms)
-- • Composite index: 5.6x faster than 2 separate indexes (1.7ms → 0.3ms)
-- • Correlated Subquery: 7x slower than JOIN (367ms → 50ms)
-- ============================================================


-- ============================================================
-- 區塊 1: EXPLAIN ANALYZE — 讀取查詢執行計畫
-- BLOCK 1: EXPLAIN ANALYZE — Reading Query Execution Plans
-- ============================================================

-- 基本用法 / Basic usage
-- EXPLAIN      → 顯示執行計畫 (不實際執行) / Show plan without executing
-- EXPLAIN ANALYZE → 執行並顯示實際時間 / Execute and show actual timing

-- 範例 1: 全表掃描 (Seq Scan) / Example 1: Sequential Scan
EXPLAIN ANALYZE
SELECT * FROM orders WHERE status = 'Completed';
-- 預期結果 Expected: Seq Scan (資料集小，全表掃描反而更快 / Small dataset, seq scan is faster)

-- 範例 2: 使用索引的日期篩選 / Example 2: Date filter using index
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE order_date >= '2024-01-01' AND order_date < '2025-01-01';

-- 範例 3: JOIN 兩個資料表 / Example 3: JOIN two tables
EXPLAIN ANALYZE
SELECT c.country, COUNT(*)
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.country;


-- ============================================================
-- 區塊 2: 索引效能實驗 / BLOCK 2: INDEX PERFORMANCE EXPERIMENTS
-- ============================================================
-- ⚠️ 注意：以下實驗使用臨時測試資料表，執行後會自動清除
-- ⚠️ Note: Experiments use temporary tables, cleaned up after each test


-- ============================================================
-- 實驗 A: 選擇性 (Selectivity) 對索引效能的影響
-- Experiment A: Impact of Selectivity on Index Performance
-- ============================================================
-- 結論 Conclusion:
--   選擇性 20% (整年資料) → 速度提升 2x  (59ms → 29ms)
--   選擇性 0.05% (單一日期) → 速度提升 47x (38ms → 0.8ms)
--   Selectivity 20% (full year) → 2x faster  (59ms → 29ms)
--   Selectivity 0.05% (single date) → 47x faster (38ms → 0.8ms)

-- 建立 50 萬筆測試資料 / Create 500K test data
CREATE TABLE orders_large AS
SELECT
    generate_series(1, 500000)                          AS order_id,
    (random() * 999 + 1)::int                           AS customer_id,
    DATE '2020-01-01' + (random() * 1826)::int          AS order_date,
    (ARRAY['Completed','Pending','Cancelled','Refunded'])
        [(random()*3+1)::int]                           AS status,
    (random() * 2000 + 10)::numeric(10,2)               AS total_amount;

-- 測試 A1: 無索引 / Test A1: Without index
EXPLAIN ANALYZE
SELECT * FROM orders_large WHERE order_date = '2024-06-15';
-- 實測結果 Result: ~38ms (Seq Scan)

-- 建立索引 / Create index
CREATE INDEX idx_large_date ON orders_large(order_date);

-- 測試 A2: 有索引 / Test A2: With index
EXPLAIN ANALYZE
SELECT * FROM orders_large WHERE order_date = '2024-06-15';
-- 實測結果 Result: ~0.8ms (Index Scan) → 提升 47 倍 / 47x improvement!

DROP TABLE orders_large;


-- ============================================================
-- 實驗 B: 複合索引 vs 兩個單獨索引
-- Experiment B: Composite Index vs Two Separate Indexes
-- ============================================================
-- 結論 Conclusion:
--   無索引           → 26ms  (T1)
--   兩個單獨索引      → 1.7ms (T2) — PostgreSQL 使用 Bitmap AND
--   複合索引 (A,B,C)  → 0.3ms (T3) — 最佳！直接命中，無需排序
--   No index         → 26ms  (T1)
--   Two separate     → 1.7ms (T2) — PostgreSQL uses Bitmap AND
--   Composite (A,B,C)→ 0.3ms (T3) — Best! Direct hit, no extra sort

CREATE TABLE orders_test AS
SELECT
    generate_series(1, 200000)                          AS order_id,
    (random() * 999 + 1)::int                           AS customer_id,
    DATE '2020-01-01' + (random() * 1826)::int          AS order_date,
    (ARRAY['Completed','Pending','Cancelled','Refunded'])
        [(random()*3+1)::int]                           AS status,
    (random() * 2000 + 10)::numeric(10,2)               AS total_amount;

-- T1: 無索引 / No index
EXPLAIN ANALYZE
SELECT * FROM orders_test
WHERE customer_id = 42 AND status = 'Completed'
ORDER BY order_date DESC;
-- 實測 Result: ~26ms

-- T2: 兩個單獨索引 / Two separate indexes
CREATE INDEX idx_test_customer ON orders_test(customer_id);
CREATE INDEX idx_test_status ON orders_test(status);

EXPLAIN ANALYZE
SELECT * FROM orders_test
WHERE customer_id = 42 AND status = 'Completed'
ORDER BY order_date DESC;
-- 實測 Result: ~1.7ms
-- 注意 Note: PostgreSQL 自動使用 BitmapAnd 合併兩個索引
-- PostgreSQL automatically combines indexes using BitmapAnd technique

-- T3: 複合索引 / Composite index (最佳解 / Best solution)
CREATE INDEX idx_test_composite
ON orders_test(customer_id, status, order_date DESC);

EXPLAIN ANALYZE
SELECT * FROM orders_test
WHERE customer_id = 42 AND status = 'Completed'
ORDER BY order_date DESC;
-- 實測 Result: ~0.3ms → 比 T1 快 87 倍！/ 87x faster than T1!

DROP TABLE orders_test;


-- ============================================================
-- 區塊 3: 最左前綴原則 (Left-most Prefix Rule)
-- BLOCK 3: LEFT-MOST PREFIX RULE
-- ============================================================
-- 複合索引 (A, B, C) 使用規則 / Composite Index (A, B, C) usage rules:
-- ✅ WHERE A          → 使用索引 / Index used
-- ✅ WHERE A AND B    → 使用索引 / Index used
-- ✅ WHERE A AND B AND C → 使用索引 / Index used
-- ❌ WHERE B          → 不使用索引 / Index NOT used (跳過 A / skips A)
-- ❌ WHERE C          → 不使用索引 / Index NOT used (跳過 A,B / skips A,B)
-- ❌ WHERE B AND C    → 不使用索引 / Index NOT used (跳過 A / skips A)

CREATE TABLE orders_test AS
SELECT
    generate_series(1, 200000) AS order_id,
    (random() * 999 + 1)::int AS customer_id,
    DATE '2020-01-01' + (random() * 1826)::int AS order_date,
    (ARRAY['Completed','Pending','Cancelled','Refunded'])
        [(random()*3+1)::int] AS status,
    (random() * 2000 + 10)::numeric(10,2) AS total_amount;

CREATE INDEX idx_composite ON orders_test(customer_id, status, order_date);

-- Q1: 使用最左欄位 → ✅ 索引有效 / Leftmost column → ✅ Index used
EXPLAIN ANALYZE SELECT * FROM orders_test WHERE customer_id = 42;

-- Q2: 使用前兩個欄位 → ✅ 索引有效 / First two columns → ✅ Index used
EXPLAIN ANALYZE SELECT * FROM orders_test
WHERE customer_id = 42 AND status = 'Completed';

-- Q3: 跳過第一欄 → ❌ 索引無效 / Skip first column → ❌ Index NOT used
EXPLAIN ANALYZE SELECT * FROM orders_test WHERE status = 'Completed';

-- Q4: 跳過前兩欄 → ❌ 索引無效 / Skip first two columns → ❌ Index NOT used
EXPLAIN ANALYZE SELECT * FROM orders_test WHERE order_date >= '2024-01-01';

DROP TABLE orders_test;


-- ============================================================
-- 區塊 4: 五大效能反模式 / BLOCK 4: FIVE PERFORMANCE ANTI-PATTERNS
-- ============================================================


-- ============================================================
-- 反模式 1: Correlated Subquery (相關子查詢)
-- Anti-pattern 1: Correlated Subquery
-- ============================================================
-- ❌ 問題: 每筆客戶執行一次子查詢 → N 次掃描
-- ❌ Problem: Executes subquery once per customer → N scans
-- 實測結果 Result: 367ms (SLOW) vs 50ms (FAST) → 7x slower

CREATE TABLE orders_large AS
SELECT
    generate_series(1, 100000)                          AS order_id,
    (random() * 999 + 1)::int                           AS customer_id,
    (random() * 2000 + 10)::numeric(10,2)               AS total_amount,
    (ARRAY['Completed','Pending','Cancelled'])
        [(random()*2+1)::int]                           AS status;

-- ❌ 慢：Correlated Subquery / SLOW
EXPLAIN ANALYZE
SELECT
    customer_id,
    (SELECT COUNT(*)
     FROM orders_large o2
     WHERE o2.customer_id = o1.customer_id
       AND o2.status = 'Completed') AS completed_orders
FROM (SELECT DISTINCT customer_id FROM orders_large) o1
LIMIT 50;
-- 實測 Result: ~367ms ❌

-- ✅ 快：JOIN + GROUP BY / FAST
EXPLAIN ANALYZE
SELECT
    o1.customer_id,
    COUNT(o2.order_id) AS completed_orders
FROM (SELECT DISTINCT customer_id FROM orders_large) o1
LEFT JOIN orders_large o2
    ON o1.customer_id = o2.customer_id
    AND o2.status = 'Completed'
GROUP BY o1.customer_id
LIMIT 50;
-- 實測 Result: ~50ms ✅ → 快 7 倍 / 7x faster

DROP TABLE orders_large;


-- ============================================================
-- 反模式 2: LIKE 萬用字元位置 / Anti-pattern 2: LIKE Wildcard Position
-- ============================================================
-- ❌ LIKE '%gmail.com'  → 萬用字元在開頭 → 無法使用索引 (Seq Scan)
-- ✅ LIKE 'nguyen%'     → 萬用字元在結尾 → 可以使用索引 (Index Scan)
-- ❌ Leading wildcard   → Cannot use index (must scan all rows)
-- ✅ Trailing wildcard  → Can use index (B-Tree knows where to start)

CREATE TABLE customers_test AS SELECT * FROM customers;
CREATE INDEX idx_email_test ON customers_test(email);

-- ❌ 開頭萬用字元 → Seq Scan / Leading wildcard → Seq Scan
EXPLAIN ANALYZE
SELECT * FROM customers_test WHERE email LIKE '%gmail.com';

-- ✅ 結尾萬用字元 → Index Scan / Trailing wildcard → Index Scan
EXPLAIN ANALYZE
SELECT * FROM customers_test WHERE email LIKE 'nguyen%';

DROP TABLE customers_test;


-- ============================================================
-- 反模式 3: HAVING 替代 WHERE / Anti-pattern 3: HAVING instead of WHERE
-- ============================================================
-- SQL 執行順序 / SQL Execution Order:
-- FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
--
-- 規則 Rule:
-- WHERE  → 篩選原始資料列 (GROUP BY 之前) / Filter raw rows (before GROUP BY)
-- HAVING → 篩選聚合結果 (GROUP BY 之後) / Filter aggregate results (after GROUP BY)
-- HAVING 僅在需要篩選聚合函數結果時使用！
-- Use HAVING ONLY when filtering on aggregate function results!

-- ❌ 錯誤：用 HAVING 篩選一般欄位 / Wrong: Using HAVING for regular column filter
EXPLAIN ANALYZE
SELECT status, COUNT(*)
FROM orders
GROUP BY status
HAVING status = 'Completed';   -- 先 GROUP 全部再 filter → 浪費！

-- ✅ 正確：用 WHERE 先篩選再 GROUP / Correct: Filter with WHERE before GROUP
EXPLAIN ANALYZE
SELECT status, COUNT(*)
FROM orders
WHERE status = 'Completed'     -- 先 filter 再 GROUP → 有效率！
GROUP BY status;

-- ✅ HAVING 的正確使用場景 / Correct use case for HAVING:
SELECT status, COUNT(*)
FROM orders
GROUP BY status
HAVING COUNT(*) > 500;         -- ✅ 必須用 HAVING，因為 WHERE 無法使用 COUNT(*)
                               -- ✅ Must use HAVING, WHERE cannot use COUNT(*)


-- ============================================================
-- 反模式 4: NOT IN vs NOT EXISTS vs LEFT JOIN IS NULL
-- Anti-pattern 4: NOT IN vs NOT EXISTS vs LEFT JOIN IS NULL
-- ============================================================
-- ⚠️ 最危險的反模式！NOT IN 遇到 NULL 會靜默回傳 0 筆資料！
-- ⚠️ Most dangerous anti-pattern! NOT IN with NULL silently returns 0 rows!
--
-- 原因 Reason:
-- NOT IN (1, 2, NULL, 4) 等同於:
-- != 1 AND != 2 AND != NULL AND != 4
-- 任何值與 NULL 比較 = UNKNOWN → 整個條件 = UNKNOWN → 0 筆結果
-- Any comparison with NULL = UNKNOWN → entire condition = UNKNOWN → 0 rows
-- 沒有 ERROR 訊息！這是無聲的資料遺失！
-- No ERROR message! This is silent data loss!

-- ❌ 危險：NOT IN (NULL 問題) / Dangerous: NOT IN (NULL problem)
EXPLAIN ANALYZE
SELECT customer_id, first_name
FROM customers
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id FROM orders
    -- 若此處有任何 NULL → 回傳 0 筆！
    -- If any NULL here → returns 0 rows!
);

-- ✅ 安全：NOT EXISTS / Safe: NOT EXISTS
EXPLAIN ANALYZE
SELECT c.customer_id, c.first_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.customer_id
);

-- ✅✅ 最佳：LEFT JOIN + IS NULL / Best: LEFT JOIN + IS NULL
EXPLAIN ANALYZE
SELECT c.customer_id, c.first_name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;


-- ============================================================
-- 反模式 5: SELECT * / Anti-pattern 5: SELECT *
-- ============================================================
-- ❌ 問題 Problem:
-- 1. 傳輸不必要的資料 → 慢 / Transfers unnecessary data → slow
-- 2. 程式碼難以理解 → 維護困難 / Code hard to understand → maintenance issues
-- 3. Schema 變更時容易出錯 / Error-prone when schema changes

-- ❌ 差：SELECT * / Bad: SELECT *
EXPLAIN ANALYZE
SELECT customer_id, total_amount
FROM (
    SELECT * FROM orders WHERE status = 'Completed'
) AS completed_orders
WHERE total_amount > 500;

-- ✅ 好：只選需要的欄位 / Good: Select only needed columns
EXPLAIN ANALYZE
SELECT customer_id, total_amount
FROM (
    SELECT customer_id, total_amount
    FROM orders
    WHERE status = 'Completed'
) AS completed_orders
WHERE total_amount > 500;


-- ============================================================
-- 區塊 5: 效能調優清單 / BLOCK 5: PERFORMANCE TUNING CHECKLIST
-- ============================================================
-- 當查詢很慢時，按照以下步驟診斷：
-- When a query is slow, diagnose using these steps:
--
-- 步驟 1: EXPLAIN ANALYZE → 找出最耗時的節點
--         Find the most expensive node
--
-- 步驟 2: 找到 Seq Scan on 大型資料表？
--         Found Seq Scan on large table?
--         → 需要索引 / Need an index
--
-- 步驟 3: 檢查 WHERE 子句
--         Check WHERE clause:
--         → 使用了函數？(EXTRACT, LOWER...) → 改用 range 篩選
--           Used functions? → Rewrite as range filter
--         → SELECT *？→ 只選需要的欄位 / Only select needed columns
--
-- 步驟 4: 檢查 JOIN
--         Check JOINs:
--         → JOIN 鍵有索引嗎？/ Do JOIN keys have indexes?
--         → 是否可改用 Hash Join 取代 Nested Loop？
--           Can Hash Join replace Nested Loop?
--
-- 步驟 5: 建立適當索引後，再次 EXPLAIN ANALYZE 比較
--         Create appropriate index, then EXPLAIN ANALYZE again to compare

-- 驗證現有索引 / Verify existing indexes:
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
