# 🛍️ 電商商業智能分析 (E-commerce Business Intelligence with PostgreSQL)

> **端到端 SQL 作品集專案**：為電商業務設計關聯式資料庫架構，並使用 PostgreSQL 回答 11 個商業問題 — 從基礎查詢到進階 Window Functions。

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue.svg)](https://www.postgresql.org/)
[![SQL](https://img.shields.io/badge/SQL-Advanced-green.svg)](https://www.postgresql.org/docs/)
[![DBeaver](https://img.shields.io/badge/Tool-DBeaver-orange.svg)](https://dbeaver.io/)

---

## 🎯 專案概述

本專案模擬真實世界的電商資料分析師工作流程：

1. **資料庫設計** — 建立正規化的 schema，包含 5 個關聯資料表 (約 13,000 筆真實感資料)
2. **商業分析** — 運用 SQL 回答 11 個商業問題，依難度分類組織
3. **SQL 技能展示** — 展現 JOINs、子查詢 (Subqueries)、CTE、Window Functions 的熟練應用
4. **商業洞察溝通** — 每個查詢搭配商業洞察與建議，協助利害關係人決策

> **本專案的價值：** 資料分析師有 70% 以上的時間在撰寫 SQL。本作品集展示了該職位所需的完整 SQL 技能光譜，從資料探索到進階分析。

---

## 🛠️ 技術棧

- **資料庫：** PostgreSQL 16
- **GUI 工具：** DBeaver Community
- **語言：** SQL (PostgreSQL 方言)
- **核心概念：** ERD 設計、索引優化、JOINs、子查詢、CTE、Window Functions

---

## 📊 資料庫架構 (Database Schema)

本資料庫模擬一個跨國多商品類別的電商平台：

```
┌──────────────┐         ┌──────────────┐
│  customers   │         │   products   │
│  客戶資料表   │         │  商品資料表   │
│──────────────│         │──────────────│
│ customer_id  │         │ product_id   │
│ first_name   │         │ product_name │
│ last_name    │         │ category     │
│ email        │         │ price        │
│ city         │         │ cost         │
│ country      │         │ stock        │
│ signup_date  │         └──────┬───────┘
└──────┬───────┘                │
       │                        │
       │   ┌────────────────┐   │
       └──→│     orders     │←──┘
           │   訂單資料表    │
           │────────────────│
           │ order_id       │
           │ customer_id    │
           │ order_date     │
           │ status         │
           │ total_amount   │
           └────────┬───────┘
                    │
                    │   ┌──────────────────┐
                    └──→│   order_items    │
                        │   訂單明細表      │
                        │──────────────────│
                        │ order_item_id    │
                        │ order_id         │
                        │ product_id       │
                        │ quantity         │
                        │ unit_price       │
                        └──────────────────┘

┌─────────────────┐
│    campaigns    │
│   行銷活動資料表  │
│─────────────────│
│ campaign_id     │
│ campaign_name   │
│ start_date      │
│ end_date        │
│ budget          │
│ channel         │
└─────────────────┘
```

### 資料量

| 資料表 | 筆數 | 說明 |
|-------|------|------|
| customers (客戶) | 1,000 | 跨國客戶 (越南、台灣、日本、美國、新加坡、韓國) |
| products (商品) | 40 | 5 大類別商品 (電子產品、時尚、家居、書籍、運動) |
| orders (訂單) | 2,940 | 2023-2024 年訂單，包含多種狀態 |
| order_items (訂單明細) | 8,966 | 每筆訂單的商品明細 |
| campaigns (行銷活動) | 10 | 行銷活動，包含預算與通路 |
| **總計** | **約 13,000 筆** | |

---

## 📂 專案結構

```
ecommerce-sql-analysis/
├── 01_create_schema.sql         # 資料庫架構 (5 個資料表 + 索引)
├── 02_insert_data.sql           # 模擬資料插入 (約 13,000 筆)
├── 03_business_analysis.sql     # 11 個商業查詢與洞察
└── README.md                    # 本文件
```

---

## 📈 商業問題分析 (11 個問題)

### 🟢 基礎難度 (Q1-Q4) — 基礎查詢

- **Q1：各國客戶分布** — 哪個是最大市場？
- **Q2：最貴的 10 個商品** — 高端產品組合
- **Q3：訂單狀態分布 (含百分比)** — 營運健康度
- **Q4：2024 年台灣新註冊客戶** — 區域成長分析

### 🟡 中等難度 (Q5-Q8) — 多表 JOIN

- **Q5：消費前 10 名客戶** — 重點客戶識別
- **Q6：各類別營收、利潤、毛利率** — 獲利分析
- **Q7：銷量前 10 名商品** — 庫存優先級
- **Q8：VIP 客戶識別 (HAVING 篩選)** — 客戶分層

### 🔴 高等難度 (Q9-Q11) — 子查詢、CTE、Window Functions

- **Q9：消費高於整體平均的客戶** — CTE + 純量子查詢
- **Q10：每個類別銷量前 3 名商品** — `DENSE_RANK()` Window Function
- **Q11：月度營收趨勢 (累積營收 + 月增率)** — `SUM() OVER`、`LAG()`

---

## 💡 重要商業洞察 (Key Insights)

### 🎯 洞察 1：類別獲利能力差異顯著
不同類別的毛利率有明顯差異。**只看營收會誤導決策** — 書籍類可能銷量高但毛利低，時尚類銷量較低但每件毛利更高。

**建議：** 在主管儀表板中同時追蹤毛利率與營收。

---

### 🎯 洞察 2：4 月與 7 月營收高峰
2024 年 4 月月增率高達 **+56%**，可能是春季行銷活動效應。7 月營收達峰值 $167K (開學季效應)。

**建議：** 將 4 月成功的行銷策略複製到類似商品類別。為 7 月高峰提前規劃庫存。

---

### 🎯 洞察 3：12 月異常下跌
2024 年 12 月月增率為 **-42%**，這對電商假日季而言極不尋常。需進一步調查：
- 資料完整性問題 (高度可能)
- 聖誕節活動成效不佳
- 客戶流失

**建議：** 在歸因為績效不佳前，先驗證資料是否完整。

---

### 🎯 洞察 4：類別內銷量分布平均
每個類別前 3 名商品的銷量差距僅 4-22 件，顯示沒有單一主導商品，市場選擇相當平均。

**建議：** 維持商品多樣性，不要過度集中庫存於單一暢銷品。

---

## 🔍 SQL 技能展示

| 技能類別 | 具體技術 |
|---------|---------|
| **資料庫設計** | 正規化 schema、外鍵、索引優化 |
| **資料篩選** | `WHERE` (使用 `>=` 進行索引友善的日期篩選) |
| **聚合函數** | `COUNT`、`SUM`、`AVG`、`MIN`、`MAX`、`COUNT(DISTINCT)` |
| **分組查詢** | `GROUP BY`、`HAVING` (聚合後篩選) |
| **資料表連接** | `INNER JOIN`、`LEFT JOIN`、多表連接 (3+ 個資料表) |
| **子查詢** | WHERE 子句中的純量子查詢 |
| **CTE** | `WITH` 子句撰寫易讀、模組化的查詢 |
| **Window Functions** | `DENSE_RANK()`、`SUM() OVER`、`LAG()` 搭配 `PARTITION BY` |
| **日期函數** | `DATE_TRUNC`、日期範圍篩選 |
| **型別轉換** | `::numeric`、`::date` (PostgreSQL 相容性) |

---

## 🚀 如何在本機執行此專案

### 環境需求
- PostgreSQL 16 ([Postgres.app](https://postgresapp.com/) for macOS)
- DBeaver Community Edition ([下載](https://dbeaver.io/download/))

### 安裝步驟

**1. 建立資料庫：**
```sql
CREATE DATABASE ecommerce_db;
```

**2. 執行 Schema：**
- 在 DBeaver 中連接到 `ecommerce_db`
- 開啟並執行 `01_create_schema.sql`

**3. 載入資料：**
- 執行 `02_insert_data.sql` (約 13,000 筆資料插入)

**4. 執行分析查詢：**
- 開啟 `03_business_analysis.sql`
- 逐一執行每個查詢以查看結果

### 驗證安裝
```sql
SELECT 'customers' AS table_name, COUNT(*) FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'campaigns', COUNT(*) FROM campaigns;
```

預期結果：
```
customers   | 1000
products    | 40
orders      | 2940
order_items | 8966
campaigns   | 10
```

---

## 🎓 我從本專案學到的經驗

透過此專案，我獲得了以下實戰經驗：

1. **資料庫設計原則** — 正規化、主鍵/外鍵、索引策略
2. **以商業需求為導向的查詢** — 將利害關係人的問題轉換為 SQL
3. **效能考量** — 索引友善的 WHERE 子句、避免使用 `SELECT *`
4. **進階分析技術** — Window Functions 用於排名、累積總和、時間序列比較
5. **資料說故事** — 將技術查詢與商業洞察、行動建議結合

---

## 👤 作者資訊

**Pô (阮貴波)**
- 🌍 居住地：台北，台灣
- 📧 Email: nba204953@gmail.com
- 💼 LinkedIn: [](https://linkedin.com/in/your-profile)
- 🐙 GitHub: [@quyba2511](https://github.com/quyba2511)
- 🔗 相關專案: [E-commerce ML 銷售預測系統](https://github.com/quyba2511/ecommerce-sales-predictor)

---

## 📝 授權

本專案僅供教育與作品集用途。資料為合成生成。

---

⭐ **如果您覺得這個專案有幫助，請給個星星！**
