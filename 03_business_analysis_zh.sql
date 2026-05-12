-- ============================================================
-- 電商商業智能分析 — SQL 作品集
-- E-COMMERCE BUSINESS ANALYSIS — SQL PORTFOLIO
-- ============================================================
-- 作者 Author: Pô (quyba2511)
-- 資料庫 Database: PostgreSQL 16
-- 目的 Purpose: 展示資料分析師 SQL 能力 / Demonstrate SQL proficiency for Data Analyst role
-- ============================================================

-- 本檔案包含 11 個商業問題的 SQL 查詢，依難度分類：基礎 → 中等 → 進階。
-- 每個查詢附帶商業洞察，協助利害關係人決策。
-- This file contains 11 business questions answered using SQL,
-- categorized by difficulty: Easy → Medium → Hard.


-- ============================================================
-- 🟢 區塊 A：基礎查詢 (Q1-Q4)
-- 🟢 BLOCK A: EASY QUERIES (Q1-Q4)
-- ============================================================

-- ============================================================
-- Q1: 各國客戶分布 / Customer Demographics by Country
-- 商業問題: 公司在每個國家有多少客戶？哪個是最大市場？
-- Business Question: How many customers are in each country? Which is the largest market?
-- 利害關係人 Stakeholder: 行銷總監 / Marketing Director
-- ============================================================
SELECT 
    country,
    COUNT(*) AS total_customers
FROM customers
GROUP BY country
ORDER BY total_customers DESC;

-- 💡 商業洞察 INSIGHT:
-- 識別最大的客戶市場，以確定行銷投資的優先順序。
-- Identifies the largest customer markets to prioritize marketing investment.
-- 📌 建議 RECOMMENDATION:
-- 將行銷預算集中在前 3 大國家；探索較小市場的擴張機會。
-- Focus marketing budget on top 3 countries; explore expansion in smaller markets.


-- ============================================================
-- Q2: 最貴的 10 個商品 / Top 10 Most Expensive Products
-- 商業問題: 公司最貴的 10 個產品是什麼？屬於哪個類別？
-- Business Question: What are the top 10 most expensive products and their categories?
-- 利害關係人 Stakeholder: 定價經理 / Pricing Manager
-- ============================================================
SELECT 
    product_name, 
    category, 
    price
FROM products
ORDER BY price DESC
LIMIT 10;

-- 💡 商業洞察 INSIGHT:
-- 高端產品組合概覽，了解公司的定價策略上限。
-- Premium product portfolio overview showing pricing ceiling.
-- 📌 建議 RECOMMENDATION:
-- 利用這些高價值商品吸引高端客戶群。
-- Use these high-value products to attract premium customer segments.


-- ============================================================
-- Q3: 訂單狀態分布 / Order Status Distribution
-- 商業問題: 各種訂單狀態的比例如何？取消和退款率是否過高？
-- Business Question: What is the distribution of order statuses? Are cancellation/refund rates concerning?
-- 利害關係人 Stakeholder: 營運經理 / Operations Manager
-- ============================================================
SELECT 
    status,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS percentage
FROM orders
GROUP BY status
ORDER BY total_orders DESC;

-- 💡 商業洞察 INSIGHT:
-- 較高的取消或退款率可能表示客戶不滿或營運問題。
-- 業界標準：取消 + 退款合計應低於 5%。
-- High Cancelled or Refunded rates may indicate customer dissatisfaction.
-- Industry benchmark: Cancelled + Refunded combined should be <5%.
-- 📌 建議 RECOMMENDATION:
-- 若取消 + 退款 > 20%，需深入調查根本原因。
-- Investigate root causes if Cancelled + Refunded > 20%.


-- ============================================================
-- Q4: 2024 年台灣新註冊客戶 / Recent Customer Signups in Taiwan (2024)
-- 商業問題: 2024 年在台灣有哪些新客戶註冊？
-- Business Question: Which customers signed up in Taiwan during 2024?
-- 利害關係人 Stakeholder: 台灣市場經理 / Country Marketing Manager (Taiwan)
-- ============================================================
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    city,
    signup_date
FROM customers
WHERE country = 'Taiwan'
  AND signup_date >= '2024-01-01'
  AND signup_date < '2025-01-01'
ORDER BY signup_date DESC;

-- 💡 商業洞察 INSIGHT:
-- 識別台灣 2024 年的客戶成長，以進行在地化互動。
-- Identifies Taiwan customer growth in 2024 for localized engagement.
-- 📌 建議 RECOMMENDATION:
-- 針對這些新客戶推送歡迎活動和台灣專屬優惠。
-- Target these recent signups with welcome campaigns and Taiwan-specific offers.


-- ============================================================
-- 🟡 區塊 B：中等查詢 (Q5-Q8) — 多表 JOIN 與聚合
-- 🟡 BLOCK B: MEDIUM QUERIES (Q5-Q8) — Multi-table JOINs & Aggregations
-- ============================================================

-- ============================================================
-- Q5: 消費前 10 名客戶 / Top 10 Customers by Total Spending
-- 商業問題: 哪些客戶為公司貢獻了最多營收？
-- Business Question: Which customers contribute the most revenue?
-- 利害關係人 Stakeholder: 執行長 / 業務總監 / CEO / Sales Director
-- ============================================================
SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    c.email,
    c.country,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount)::numeric, 2) AS total_spent
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.country
ORDER BY total_spent DESC
LIMIT 10;

-- 💡 商業洞察 INSIGHT:
-- 前 10 名客戶代表最有價值的帳戶，他們的忠誠度直接影響業務穩定性。
-- Top 10 customers represent the most valuable accounts.
-- Their loyalty directly impacts business stability.
-- 📌 建議 RECOMMENDATION:
-- 為這些客戶實施 VIP 計劃，提供個人化服務。
-- Implement VIP program with personalized service for these accounts.


-- ============================================================
-- Q6: 各類別營收、利潤與毛利率 / Revenue, Profit, and Margin by Category
-- 商業問題: 哪個產品類別最賺錢？毛利率是多少？
-- Business Question: Which product category is most profitable? What are the margins?
-- 利害關係人 Stakeholder: 財務長 / 產品總監 / CFO / Product Director
-- ============================================================
SELECT
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price)::numeric, 2) AS revenue,
    ROUND(SUM(oi.quantity * (oi.unit_price - p.cost))::numeric, 2) AS profit,
    ROUND(
        (SUM(oi.quantity * (oi.unit_price - p.cost)) * 100.0 
        / SUM(oi.quantity * oi.unit_price))::numeric, 2
    ) AS profit_margin_pct
FROM orders o
INNER JOIN order_items oi ON oi.order_id = o.order_id
INNER JOIN products p ON p.product_id = oi.product_id
WHERE o.status = 'Completed'
GROUP BY p.category
ORDER BY profit DESC;

-- 💡 商業洞察 INSIGHT:
-- 毛利率與營收同等重要。一個營收 $1M 但毛利率僅 5% 的類別，
-- 實際獲利不如營收 $500K 但毛利率 40% 的類別。
-- Margin matters as much as revenue. A category with $1M revenue but 5% margin
-- is less profitable than $500K revenue with 40% margin.
-- 📌 建議 RECOMMENDATION:
-- 在營收量與毛利率之間取得平衡，以優化整體獲利能力。
-- Balance revenue volume with margin to optimize overall profitability.


-- ============================================================
-- Q7: 銷量前 10 名商品 / Top 10 Best-Selling Products by Units Sold
-- 商業問題: 銷量最高的 10 個產品是什麼？
-- Business Question: What are the top 10 best-selling products by quantity?
-- 利害關係人 Stakeholder: 庫存經理 / 產品總監 / Inventory Manager / Product Director
-- ============================================================
SELECT
    p.product_name,
    p.category,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price)::numeric, 2) AS revenue,
    COUNT(DISTINCT oi.order_id) AS unique_orders
FROM orders o
INNER JOIN order_items oi ON oi.order_id = o.order_id
INNER JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'Completed'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY units_sold DESC
LIMIT 10;

-- 💡 商業洞察 INSIGHT:
-- 暢銷品驅動客流量。若這些商品缺貨，將嚴重影響營收。
-- Best-sellers drive customer traffic. Stock-out on these would
-- significantly impact revenue.
-- 📌 建議 RECOMMENDATION:
-- 為暢銷品維持安全庫存；絕不能讓它們缺貨。
-- Maintain safety stock for top sellers; never let them go out of stock.


-- ============================================================
-- Q8: VIP 客戶識別 / VIP Customers (HAVING Filter)
-- 商業問題: 誰是 VIP 客戶？(至少 5 筆已完成訂單且消費超過 $5,000)
-- Business Question: Who are VIP customers? (>=5 completed orders AND >$5,000 total spending)
-- 利害關係人 Stakeholder: 客戶成功經理 / Customer Success Manager
-- ============================================================
SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    c.country,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount)::numeric, 2) AS total_spent,
    ROUND(AVG(o.total_amount)::numeric, 2) AS avg_order_value
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.first_name, c.last_name, c.country
HAVING COUNT(o.order_id) >= 5
   AND SUM(o.total_amount) > 5000
ORDER BY total_spent DESC;

-- 💡 商業洞察 INSIGHT:
-- VIP 客戶 (多次下單、高消費) 是最忠誠的客群，留存率最高。
-- VIP customers (multi-order, high-spending) are the most loyal segment
-- with highest retention rate.
-- 📌 建議 RECOMMENDATION:
-- 推出專屬 VIP 計劃：優先客服、早鳥優惠、專屬折扣。
-- Launch exclusive VIP program: priority support, early access, special discounts.


-- ============================================================
-- 🔴 區塊 C：進階查詢 (Q9-Q11) — 子查詢、CTE、Window Functions
-- 🔴 BLOCK C: HARD QUERIES (Q9-Q11) — Subqueries, CTEs, Window Functions
-- ============================================================

-- ============================================================
-- Q9: 消費高於整體平均的客戶 / Customers Spending Above Overall Average
-- 商業問題: 哪些客戶的總消費高於所有客戶的平均水準？差距多少？
-- Business Question: Which customers spend more than the overall average? By how much?
-- 利害關係人 Stakeholder: 行銷總監 / Marketing Director
-- 技術重點: CTE + 純量子查詢 / CTE + Scalar Subquery
-- ============================================================
WITH customer_spending AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS full_name,
        c.country,
        SUM(o.total_amount) AS total_spent
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.country
)
SELECT
    full_name,
    country,
    ROUND(total_spent::numeric, 2) AS total_spent,
    ROUND((total_spent - (SELECT AVG(total_spent) FROM customer_spending))::numeric, 2) 
        AS gap_above_average
FROM customer_spending
WHERE total_spent > (SELECT AVG(total_spent) FROM customer_spending)
ORDER BY total_spent DESC;

-- 💡 商業洞察 INSIGHT:
-- 高於平均消費的客戶是「成長型客群」— 他們的消費已超過一般買家，
-- 但尚未達到 VIP 等級。將他們轉化為 VIP 可使其價值翻倍。
-- Above-average customers are the "growth segment" — they spend more than 
-- typical buyers but aren't yet VIP. Converting them to VIP doubles their value.
-- 📌 建議 RECOMMENDATION:
-- 建立「VIP 進階計劃」，透過獎勵機制激勵這些客戶達到下一個消費等級。
-- Create a "Path to VIP" program incentivizing this segment with rewards.


-- ============================================================
-- Q10: 每個類別銷量前 3 名商品 / Top 3 Best-Selling Products per Category
-- 商業問題: 每個產品類別中，銷量前 3 名的商品是什麼？
-- Business Question: What are the top 3 best-selling products in each category?
-- 利害關係人 Stakeholder: 品類經理 / Category Manager
-- 技術重點: DENSE_RANK() Window Function
-- ============================================================
WITH product_sales AS (
    SELECT
        p.category,
        p.product_name,
        SUM(oi.quantity) AS units_sold,
        DENSE_RANK() OVER(
            PARTITION BY p.category
            ORDER BY SUM(oi.quantity) DESC
        ) AS rank_in_category
    FROM products p
    INNER JOIN order_items oi ON p.product_id = oi.product_id
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'Completed'
    GROUP BY p.category, p.product_name
)
SELECT 
    category, 
    product_name, 
    units_sold, 
    rank_in_category
FROM product_sales
WHERE rank_in_category <= 3
ORDER BY category, rank_in_category;

-- 💡 商業洞察 INSIGHT:
-- 類別領導商品應主導商品陳列策略。
-- 表現不佳的類別可能需要重新審視商品組合。
-- Category leaders should drive merchandising strategy.
-- Underperforming categories may need product mix review.
-- 📌 建議 RECOMMENDATION:
-- 在類別頁面醒目展示前 3 名商品。
-- 持續表現不佳的商品考慮下架或重新定位。
-- Feature top-3 products prominently in category landing pages.


-- ============================================================
-- Q11: 月度營收趨勢 — 累積營收 + 月增率 / Monthly Revenue Trend
-- 商業問題: 2024 年每月營收趨勢如何？累積營收和月度成長率是多少？
-- Business Question: What is the 2024 monthly revenue trend with cumulative total and MoM growth?
-- 利害關係人 Stakeholder: 財務長 / 執行長 / CFO / CEO
-- 技術重點: SUM() OVER (累積加總)、LAG() (月度比較)
-- Technical: SUM() OVER (running total), LAG() (month comparison)
-- ============================================================
WITH monthly_data AS (
    SELECT 
        DATE_TRUNC('month', order_date)::date AS month,
        SUM(total_amount) AS monthly_revenue
    FROM orders
    WHERE status = 'Completed'
      AND order_date >= '2024-01-01' 
      AND order_date < '2025-01-01'
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT 
    month,
    ROUND(monthly_revenue::numeric, 2) AS monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (ORDER BY month)::numeric, 2) AS cumulative_revenue,
    ROUND(LAG(monthly_revenue) OVER (ORDER BY month)::numeric, 2) AS prev_month_revenue,
    ROUND(
        ((monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month)) 
        * 100.0 / LAG(monthly_revenue) OVER (ORDER BY month))::numeric, 
        2
    ) AS mom_growth_pct
FROM monthly_data
ORDER BY month;

-- 💡 商業洞察 INSIGHT:
-- 本查詢在單一視圖中整合 3 個關鍵指標：
-- 1. 月度營收 (Monthly Revenue)：單月表現
-- 2. 累積營收 (Year-to-Date)：年度至今總額
-- 3. 月增率 (MoM Growth %)：成長動能指標
-- This query combines 3 critical metrics in one view:
-- 1. Monthly Revenue: standalone month performance
-- 2. Cumulative Revenue (YTD): year-to-date total
-- 3. MoM Growth %: momentum indicator
--
-- 重要發現 KEY FINDINGS:
-- • 2024 年 4 月月增率 +56% (春季行銷活動效應)
-- • 2024 年 12 月月增率 -42% (資料完整性疑慮，需進一步調查)
-- • April 2024: +56% growth (Spring campaign effect)
-- • December 2024: -42% drop (data completeness issue, requires investigation)
--
-- 📌 建議 RECOMMENDATION:
-- 將此查詢作為每月主管會議的儀表板報表。
-- 設定警示：任何月份月減 20% 以上應觸發調查。
-- Use this as a monthly executive review dashboard query.
-- Set alerts: any month with -20% or worse should trigger investigation.


-- ============================================================
-- 📌 後續擴展 (NEXT STEPS — 待新增):
-- 📌 後續擴展 (To be added):
-- - Q12: 各國平均訂單價值 / Average Order Value by Country
-- - Q13: 月度活躍客戶數趨勢 / Monthly Active Customers (MAC) trend
-- - Q14: 客戶終身價值分層 / Customer Lifetime Value (CLV) tiering with NTILE
-- - Q15: 行銷活動投資報酬率分析 / Campaign ROI Analysis
-- ============================================================
-- ============================================================
-- Q12: 各國平均訂單價值 / Average Order Value (AOV) by Country
-- 商業問題: 哪個國家的客戶平均訂單價值最高？應針對哪個市場推廣高價商品？
-- Business Question: Which country has the highest AOV? Where to focus premium products?
-- 利害關係人 Stakeholder: 行銷總監 / 業務總監 / Marketing Director / Sales Director
-- ============================================================
SELECT
    c.country,
    COUNT(*)                                   AS total_orders,
    ROUND(AVG(o.total_amount)::numeric, 2)     AS aov,
    ROUND(SUM(o.total_amount)::numeric, 2)     AS total_revenue
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.country
ORDER BY aov DESC;
 
-- 💡 商業洞察 INSIGHT:
-- AOV 最高的國家代表高端市場——客戶傾向購買較貴的商品。
-- Countries with highest AOV represent premium markets — customers tend to buy higher-value items.
-- 📌 建議 RECOMMENDATION:
-- 針對高 AOV 市場優先推廣電子產品、高端時尚等高價值商品。
-- Focus premium product marketing (Electronics, luxury Fashion) on highest AOV markets.
 
 
-- ============================================================
-- Q13: 月度活躍客戶數趨勢 / Monthly Active Customers (MAC) in 2024
-- 商業問題: 2024年每月有多少獨立客戶下單？每位客戶平均下幾筆訂單？
-- Business Question: How many unique customers ordered each month? Avg orders per customer?
-- 利害關係人 Stakeholder: 成長團隊 / 產品經理 / Growth Team / Product Manager
-- ============================================================
SELECT
    DATE_TRUNC('month', o.order_date)::date          AS month,
    COUNT(DISTINCT o.customer_id)                     AS active_customers,
    COUNT(*)                                          AS total_orders,
    ROUND(
        (COUNT(*) * 1.0 / COUNT(DISTINCT o.customer_id))::numeric, 2
    )                                                 AS avg_orders_per_customer
FROM orders o
WHERE o.status = 'Completed'
  AND o.order_date >= '2024-01-01'
  AND o.order_date < '2025-01-01'
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY month ASC;
 
-- 💡 商業洞察 INSIGHT:
-- 月度活躍客戶數 (MAC) 是衡量業務健康度的核心指標。
-- MAC 上升 → 客戶基礎擴大；MAC 下降 → 流失風險需關注。
-- Monthly Active Customers (MAC) is a core business health metric.
-- Rising MAC → expanding customer base; Falling MAC → churn risk.
-- 📌 建議 RECOMMENDATION:
-- 當 MAC 連續 2 個月下滑時，應立即啟動客戶挽留計劃。
-- When MAC declines for 2+ consecutive months, activate customer retention campaigns immediately.
 
 
-- ============================================================
-- Q14: 客戶終身價值分層 / Customer Lifetime Value (CLV) Tiering
-- 商業問題: 如何依消費總額將客戶分層？各層客戶特徵為何？
-- Business Question: How to tier customers by lifetime value? What are the characteristics?
-- 利害關係人 Stakeholder: 行銷團隊 / 客戶成功經理 / Marketing Team / Customer Success
-- 技術重點: NTILE() Window Function — 將客戶分為 10 等分
-- Technical: NTILE() Window Function — divides customers into 10 equal groups
-- ============================================================
WITH customer_clv AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name)     AS full_name,
        c.country,
        COUNT(o.order_id)                           AS total_orders,
        ROUND(SUM(o.total_amount)::numeric, 2)      AS total_spent,
        ROUND(AVG(o.total_amount)::numeric, 2)      AS avg_order_value,
        MIN(o.order_date)                           AS first_order,
        MAX(o.order_date)                           AS last_order
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.country
)
SELECT
    full_name,
    country,
    total_orders,
    total_spent,
    avg_order_value,
    first_order,
    last_order,
    -- 將客戶分為 10 個等分 / Divide customers into 10 equal groups (deciles)
    NTILE(10) OVER (ORDER BY total_spent DESC) AS decile,
    -- 依分位數貼標籤 / Label by tier
    CASE
        WHEN NTILE(10) OVER (ORDER BY total_spent DESC) = 1
            THEN '🌟 VIP (前10% / Top 10%)'
        WHEN NTILE(10) OVER (ORDER BY total_spent DESC) <= 3
            THEN '⭐ Premium (前30% / Top 30%)'
        WHEN NTILE(10) OVER (ORDER BY total_spent DESC) <= 7
            THEN '✓ Regular (中間40% / Middle 40%)'
        ELSE '📉 需培育 (後30% / Bottom 30%)'
    END AS customer_tier
FROM customer_clv
ORDER BY total_spent DESC
LIMIT 30;
 
-- 💡 商業洞察 INSIGHT:
-- 依帕累托原則，80% 的營收通常來自前 20% 的客戶 (VIP + Premium)。
-- 各層策略：VIP → 維持忠誠度；Premium → 升級為 VIP；Regular → 提升購買頻率；
-- Bottom → 再激活或接受流失。
-- Per Pareto Principle, 80% of revenue typically comes from top 20% customers.
-- Strategy per tier: VIP → retain loyalty; Premium → upsell to VIP;
-- Regular → increase purchase frequency; Bottom → re-engage or accept churn.
-- 📌 建議 RECOMMENDATION:
-- 為 VIP 客戶提供專屬管理服務；為 Premium 客戶設計「升級 VIP」激勵方案。
-- Provide dedicated account management for VIPs; design "Upgrade to VIP" incentives for Premium.
 
 
-- ============================================================
-- Q15: 行銷活動投資報酬率分析 / Campaign ROI Analysis
-- 商業問題: 哪個行銷活動 ROI 最高？哪個通路最有效？預算應如何分配？
-- Business Question: Which campaign has the best ROI? Which channel is most effective?
-- 利害關係人 Stakeholder: 行銷總監 / 財務長 / CMO / CFO
-- 技術重點: LEFT JOIN (保留無訂單的活動)、COALESCE (處理 NULL 值)
-- Technical: LEFT JOIN (keep campaigns with no orders), COALESCE (handle NULL values)
-- ============================================================
SELECT
    cmp.campaign_name,
    cmp.channel,
    cmp.start_date,
    cmp.end_date,
    (cmp.end_date - cmp.start_date)                     AS duration_days,
    cmp.budget,
    COUNT(DISTINCT o.order_id)                           AS orders_during_campaign,
    ROUND(COALESCE(SUM(o.total_amount), 0)::numeric, 2) AS revenue_during_campaign,
    ROUND(
        ((COALESCE(SUM(o.total_amount), 0) - cmp.budget)
        * 100.0 / cmp.budget)::numeric, 2
    )                                                    AS roi_percentage,
    CASE
        WHEN COALESCE(SUM(o.total_amount), 0) > cmp.budget * 3
            THEN '🚀 Excellent (ROI > 200%)'
        WHEN COALESCE(SUM(o.total_amount), 0) > cmp.budget * 2
            THEN '✅ Good (ROI 100-200%)'
        WHEN COALESCE(SUM(o.total_amount), 0) > cmp.budget
            THEN '✓ Profitable (ROI 0-100%)'
        ELSE '❌ Loss (負 ROI / Negative ROI)'
    END AS performance_tier
FROM campaigns cmp
LEFT JOIN orders o
    ON o.order_date BETWEEN cmp.start_date AND cmp.end_date
    AND o.status = 'Completed'
GROUP BY
    cmp.campaign_id, cmp.campaign_name, cmp.channel,
    cmp.start_date, cmp.end_date, cmp.budget
ORDER BY roi_percentage DESC;
 
-- 💡 商業洞察 INSIGHT:
-- 關鍵發現 KEY FINDINGS:
-- • 農曆新年 (Lunar New Year) 是唯一獲利的活動 (ROI +33.8%)
--   → Multi-channel + 21 天活動期 + $60K 合理預算
-- • Social Media 單一通路效果不佳：中秋節 (-14%) 和雙11 (-27%) 均虧損
-- • 黑色星期五預算最高 ($100K) 但 ROI 最差 (-71%) — 嚴重資源錯配
-- • Lunar New Year: only profitable campaign (ROI +33.8%)
--   → Multi-channel + 21-day duration + reasonable $60K budget
-- • Social Media alone underperforms: Mid-Autumn (-14%) and 11.11 (-27%) both lost money
-- • Black Friday: highest budget ($100K) but worst ROI (-71%) — severe resource misallocation
--
-- 📌 建議 RECOMMENDATION:
-- 1. 以農曆新年的成功模式為範本：Multi-channel、21 天以上、預算 $50-70K
-- 2. 停止 Social Media 單一通路投放；改為 Multi-channel 組合策略
-- 3. 重新規劃黑色星期五策略：縮減預算、延長活動期、改善受眾定向
-- 4. 考慮更精準的活動歸因分析 (UTM tracking) 以提高 ROI 計算準確度
-- 1. Model future campaigns after Lunar New Year: Multi-channel, 21+ days, $50-70K budget
-- 2. Stop single Social Media channel campaigns; adopt Multi-channel strategy
-- 3. Rethink Black Friday: reduce budget, extend duration, improve audience targeting
-- 4. Implement proper campaign attribution (UTM tracking) for more accurate ROI measurement
 