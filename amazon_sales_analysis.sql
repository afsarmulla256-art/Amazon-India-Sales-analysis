-- ============================================================
--  AMAZON SALES PERFORMANCE ANALYSIS
--  Author  : Afsar Ahamed | Data Analyst
--  Dataset : 128,975 orders | Mar–Jun 2022
--  Tools   : MySQL 8.0+
-- ============================================================

CREATE DATABASE IF NOT EXISTS amazon_sales_db;
USE amazon_sales_db;

DROP TABLE IF EXISTS amazon_orders;

CREATE TABLE amazon_orders (
    id               INT            PRIMARY KEY AUTO_INCREMENT,
    OrderID          VARCHAR(30)    NOT NULL,
    OrderDate        DATE           NOT NULL,
    Status           VARCHAR(60)    NOT NULL,
    OrderStatus      VARCHAR(20)    NOT NULL  COMMENT 'Simplified: Delivered/Cancelled/Returned/Shipped/Pending',
    Fulfilment       VARCHAR(20)    NOT NULL  COMMENT 'Amazon or Merchant',
    SalesChannel     VARCHAR(30)    NOT NULL,
    Category         VARCHAR(30)    NOT NULL,
    Size             VARCHAR(10)    NOT NULL,
    Qty              INT            NOT NULL,
    Amount           DECIMAL(12,2)  NOT NULL  COMMENT 'Revenue in INR',
    ShipCity         VARCHAR(60),
    ShipState        VARCHAR(60),
    ShipCountry      VARCHAR(10),
    B2B              TINYINT(1)     NOT NULL  COMMENT '1 = Business order, 0 = Consumer',
    RevenuePerUnit   DECIMAL(10,2)
);

-- Load CSV (update path to your local file)
LOAD DATA INFILE '/var/lib/mysql-files/amazon_sales_powerbi.csv'
INTO TABLE amazon_orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@idx, OrderID, OrderDate, Status, @fulf, @sc, @ssl, @style, @sku,
 Category, Size, @asin, @cs, Qty, @cur, Amount, ShipCity, ShipState,
 @postal, ShipCountry, @promo, B2B, @month, @monthname, @dow,
 OrderStatus, RevenuePerUnit, @b2blabel);


-- ────────────────────────────────────────────────────────────
--  QUERY 1 : EXECUTIVE SUMMARY — Key Business Metrics
-- ────────────────────────────────────────────────────────────
SELECT
    COUNT(DISTINCT OrderID)                           AS total_orders,
    SUM(Qty)                                          AS total_units_sold,
    ROUND(SUM(Amount), 2)                             AS total_revenue_inr,
    ROUND(AVG(Amount), 2)                             AS avg_order_value,
    ROUND(SUM(CASE WHEN OrderStatus = 'Cancelled' THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                              AS cancellation_rate_pct,
    ROUND(SUM(CASE WHEN OrderStatus = 'Delivered' THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                              AS delivery_success_rate_pct
FROM amazon_orders;


-- ────────────────────────────────────────────────────────────
--  QUERY 2 : MONTHLY REVENUE TREND
-- ────────────────────────────────────────────────────────────
SELECT
    DATE_FORMAT(OrderDate, '%Y-%m')                   AS month,
    COUNT(DISTINCT OrderID)                           AS total_orders,
    SUM(Qty)                                          AS units_sold,
    ROUND(SUM(Amount), 2)                             AS revenue,
    ROUND(AVG(Amount), 2)                             AS avg_order_value,
    -- Month-over-month revenue change
    ROUND(SUM(Amount) - LAG(SUM(Amount))
          OVER (ORDER BY DATE_FORMAT(OrderDate,'%Y-%m')), 2) AS mom_change,
    ROUND((SUM(Amount) - LAG(SUM(Amount))
           OVER (ORDER BY DATE_FORMAT(OrderDate,'%Y-%m')))
          / LAG(SUM(Amount)) OVER (ORDER BY DATE_FORMAT(OrderDate,'%Y-%m')) * 100,
          2)                                          AS mom_growth_pct
FROM amazon_orders
GROUP BY DATE_FORMAT(OrderDate, '%Y-%m')
ORDER BY month;


-- ────────────────────────────────────────────────────────────
--  QUERY 3 : CATEGORY PERFORMANCE
-- ────────────────────────────────────────────────────────────
SELECT
    Category,
    COUNT(DISTINCT OrderID)                           AS total_orders,
    SUM(Qty)                                          AS units_sold,
    ROUND(SUM(Amount), 2)                             AS total_revenue,
    ROUND(SUM(Amount) * 100.0 / SUM(SUM(Amount)) OVER (), 2) AS revenue_share_pct,
    ROUND(AVG(Amount), 2)                             AS avg_order_value,
    ROUND(SUM(CASE WHEN OrderStatus='Cancelled' THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                              AS cancellation_rate_pct,
    -- Revenue rank
    RANK() OVER (ORDER BY SUM(Amount) DESC)           AS revenue_rank
FROM amazon_orders
GROUP BY Category
ORDER BY total_revenue DESC;


-- ────────────────────────────────────────────────────────────
--  QUERY 4 : ORDER STATUS BREAKDOWN
-- ────────────────────────────────────────────────────────────
SELECT
    OrderStatus,
    COUNT(*)                                          AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total,
    ROUND(SUM(Amount), 2)                             AS revenue_impact,
    ROUND(AVG(Amount), 2)                             AS avg_order_value
FROM amazon_orders
GROUP BY OrderStatus
ORDER BY order_count DESC;


-- ────────────────────────────────────────────────────────────
--  QUERY 5 : TOP 10 STATES BY REVENUE
-- ────────────────────────────────────────────────────────────
SELECT
    ShipState                                         AS state,
    COUNT(DISTINCT OrderID)                           AS total_orders,
    ROUND(SUM(Amount), 2)                             AS total_revenue,
    ROUND(SUM(Amount) * 100.0 / SUM(SUM(Amount)) OVER (), 2) AS revenue_share_pct,
    ROUND(AVG(Amount), 2)                             AS avg_order_value,
    RANK() OVER (ORDER BY SUM(Amount) DESC)           AS revenue_rank
FROM amazon_orders
WHERE ShipState IS NOT NULL
GROUP BY ShipState
ORDER BY total_revenue DESC
LIMIT 10;


-- ────────────────────────────────────────────────────────────
--  QUERY 6 : FULFILMENT CHANNEL ANALYSIS (Amazon vs Merchant)
-- ────────────────────────────────────────────────────────────
SELECT
    Fulfilment,
    COUNT(DISTINCT OrderID)                           AS total_orders,
    ROUND(SUM(Amount), 2)                             AS total_revenue,
    ROUND(AVG(Amount), 2)                             AS avg_order_value,
    ROUND(SUM(CASE WHEN OrderStatus='Delivered' THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                              AS delivery_rate_pct,
    ROUND(SUM(CASE WHEN OrderStatus='Cancelled' THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                              AS cancellation_rate_pct,
    ROUND(SUM(CASE WHEN OrderStatus='Returned' THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                              AS return_rate_pct
FROM amazon_orders
GROUP BY Fulfilment;


-- ────────────────────────────────────────────────────────────
--  QUERY 7 : SIZE-WISE DEMAND ANALYSIS
-- ────────────────────────────────────────────────────────────
SELECT
    Size,
    COUNT(*)                                          AS total_orders,
    SUM(Qty)                                          AS units_sold,
    ROUND(SUM(Amount), 2)                             AS revenue,
    ROUND(AVG(Amount), 2)                             AS avg_order_value,
    ROUND(SUM(Amount) * 100.0 / SUM(SUM(Amount)) OVER (), 2) AS revenue_share_pct,
    RANK() OVER (ORDER BY SUM(Qty) DESC)              AS demand_rank
FROM amazon_orders
GROUP BY Size
ORDER BY units_sold DESC;


-- ────────────────────────────────────────────────────────────
--  QUERY 8 : B2B vs B2C COMPARISON
-- ────────────────────────────────────────────────────────────
SELECT
    CASE WHEN B2B = 1 THEN 'B2B (Business)' ELSE 'B2C (Consumer)' END AS customer_type,
    COUNT(DISTINCT OrderID)                           AS total_orders,
    ROUND(SUM(Amount), 2)                             AS total_revenue,
    ROUND(AVG(Amount), 2)                             AS avg_order_value,
    ROUND(AVG(Qty), 1)                                AS avg_qty_per_order,
    ROUND(SUM(CASE WHEN OrderStatus='Cancelled' THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                              AS cancellation_rate_pct
FROM amazon_orders
GROUP BY B2B;


-- ────────────────────────────────────────────────────────────
--  QUERY 9 : REVENUE CONTRIBUTION — CUMULATIVE (WINDOW FUNCTION)
-- ────────────────────────────────────────────────────────────
WITH category_revenue AS (
    SELECT
        Category,
        ROUND(SUM(Amount), 2) AS revenue
    FROM amazon_orders
    GROUP BY Category
)
SELECT
    Category,
    revenue,
    ROUND(revenue * 100.0 / SUM(revenue) OVER (), 2)          AS revenue_share_pct,
    ROUND(SUM(revenue) OVER (ORDER BY revenue DESC
          ROWS UNBOUNDED PRECEDING) * 100.0
          / SUM(revenue) OVER (), 2)                           AS cumulative_share_pct,
    RANK() OVER (ORDER BY revenue DESC)                        AS revenue_rank
FROM category_revenue
ORDER BY revenue DESC;


-- ────────────────────────────────────────────────────────────
--  QUERY 10 : CANCELLATION DEEP-DIVE BY CATEGORY & STATE
-- ────────────────────────────────────────────────────────────
SELECT
    Category,
    ShipState,
    COUNT(*)                                          AS total_orders,
    SUM(CASE WHEN OrderStatus = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
    ROUND(SUM(CASE WHEN OrderStatus = 'Cancelled' THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                              AS cancellation_rate_pct,
    ROUND(SUM(CASE WHEN OrderStatus = 'Cancelled' THEN Amount ELSE 0 END), 2) AS lost_revenue
FROM amazon_orders
WHERE ShipState IS NOT NULL
GROUP BY Category, ShipState
HAVING total_orders > 100
ORDER BY cancellation_rate_pct DESC
LIMIT 15;


-- ────────────────────────────────────────────────────────────
--  VIEW FOR POWER BI
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_amazon_summary AS
SELECT
    OrderID,
    OrderDate,
    DATE_FORMAT(OrderDate, '%Y-%m')    AS Month,
    DATE_FORMAT(OrderDate, '%b %Y')    AS MonthName,
    DAYNAME(OrderDate)                 AS DayOfWeek,
    Category,
    Size,
    Qty,
    Amount,
    OrderStatus,
    Fulfilment,
    ShipState,
    ShipCity,
    B2B,
    CASE WHEN B2B=1 THEN 'B2B' ELSE 'B2C' END AS CustomerType,
    RevenuePerUnit,
    CASE
        WHEN Amount < 500  THEN 'Low (<500)'
        WHEN Amount < 1500 THEN 'Mid (500-1500)'
        ELSE 'High (1500+)'
    END AS OrderValueBand
FROM amazon_orders;
