
-- Ferryx Metrics
-- Total Orders per website
select website,count(Order_Number) as Total_Orders
FROM read_csv_auto('Ferryx_Sales_Data.csv')
Group by Website;

--Net Product Sales
SELECT 
    Website,
   Round(SUM(Item_Cost) - SUM(Order_Refund_Amount),2) AS Net_Product_Sales
FROM read_csv_auto('Ferryx_Sales_Data.csv')
GROUP BY Website;


--Net Commercial revenue
SELECT 
    Website,
    ROUND(SUM(Order_Total_Amount - Order_Total_Tax_Amount - Order_Refund_Amount), 2) AS Net_Commercial_Revenue
FROM read_csv_auto('Ferryx_Sales_Data.csv')
GROUP BY Website;



--profitable item considering website
select Item_Name as Item, 
Round(Sum(case when "Website"= 'Woocommerce' then "Item_Cost" else 0 end),2) as Woocommerse_Total_Sales,
Round(Sum(Case when "Website"= 'Squarespace' then "Item_Cost" else 0 end),2) as SquareSpace_Total_Sales
FROM read_csv_auto("Ferryx_Sales_Data.csv")
group by Item_Name
order by Woocommerse_Total_Sales desc,SquareSpace_Total_Sales desc;


--what product had avg increase and decrease in sales after migration
with sales as (select Item_Name as Item, 
Sum(Case when "Website"= 'Woocommerce' then "Item_Cost" else 0 end) as Woocommerse_Total_Sales,
Sum(Case when "Website"= 'Squarespace' then "Item_Cost" else 0 end) as SquareSpace_Total_Sales
FROM read_csv_auto("Ferryx_Sales_Data.csv")
group by Item_Name
order by Woocommerse_Total_Sales desc,SquareSpace_Total_Sales desc)

select *, (SquareSpace_Total_Sales-Woocommerse_Total_Sales) as sales_After_Migration
from sales
Group by Item,Woocommerse_Total_Sales,SquareSpace_Total_Sales;

SELECT 
    SKU,
    Item_Name,
    Website,
    SUM("Quantity_(- Refund)") AS Total_Units_Sold
FROM read_csv_auto('Ferryx_Sales_Data.csv')
GROUP BY SKU, Item_Name, Website
ORDER BY Total_Units_Sold DESC;

--Total dicounts on both platforms
select 
Sum(case when "Website"= 'Woocommerce' then "Discount_Amount" else 0 end) as Woocommerse_Total_Discounts,
Sum(Case when "Website"= 'Squarespace' then "Discount_Amount" else 0 end) as SquareSpace_Total_Discounts
FROM read_csv_auto("Ferryx_Sales_Data.csv")
order by Woocommerse_Total_Discounts desc,SquareSpace_Total_Discounts desc

--How did shipping and discount optimization change across platforms
select Coupon_Code as Coupon_Code, Item_Name,
Sum(case when "Website"= 'Woocommerce' then "Discount_Amount" else 0 end) as Woocommerse_Total_Discounts,
Sum(Case when "Website"= 'Squarespace' then "Discount_Amount" else 0 end) as SquareSpace_Total_Discounts
FROM read_csv_auto("Ferryx_Sales_Data.csv")
group by Coupon_Code,Item_Name
order by Woocommerse_Total_Discounts desc,SquareSpace_Total_Discounts desc,Item_Name

--What is the repeat purchase cadence (Purchase Frequency) for Ferryx customers before vs. after the migration?
SELECT 
    "Customer_identifier",
    sum(CASE WHEN "Website" = 'Woocommerce' THEN 1 ELSE 0 END) AS Woocommerce_Purchase_Frequency,
    sum(CASE WHEN "Website" = 'Squarespace' THEN 1 ELSE 0 END) AS SquareSpace_Purchase_Frequency
FROM read_csv_auto("Ferryx_Sales_Data.csv")
GROUP BY "Customer_identifier"
ORDER BY Woocommerce_Purchase_Frequency DESC , SquareSpace_Purchase_Frequency desc ;


--Identify onetime,repeat and loyal customers
WITH purchase_counts AS (
    SELECT 
        "Customer_identifier", 
        COUNT(*) FILTER (WHERE LOWER("Website") = 'woocommerce') AS woo_count,
        COUNT(*) FILTER (WHERE LOWER("Website") = 'squarespace') AS square_count
    FROM read_csv_auto('Ferryx_Sales_Data.csv') 
    GROUP BY "Customer_identifier"
),

customer_segments AS (
    SELECT 
        "Customer_identifier",
        CASE 
            WHEN woo_count = 1 THEN 'One Time Buyer'
            WHEN woo_count BETWEEN 2 AND 5 THEN 'Repeat Buyer'
            WHEN woo_count > 5 THEN 'Loyal Customer' 
            ELSE 'Never Purchased' 
        END AS woo_Segs,
        CASE 
            WHEN square_count = 1 THEN 'One Time Buyer'
            WHEN square_count BETWEEN 2 AND 5 THEN 'Repeat Buyer'
            WHEN square_count > 5 THEN 'Loyal Customer' 
            ELSE 'Never Purchased' 
        END AS square_Segs
    FROM purchase_counts
),
segments AS (
    SELECT 'One Time Buyer' AS Segment
    UNION ALL SELECT 'Repeat Buyer'
    UNION ALL SELECT 'Loyal Customer'
    UNION ALL SELECT 'Never Purchased'
)

SELECT 
    S.Segment AS Customer_Segment,
    COUNT(DISTINCT CASE WHEN woo_Segs = S.Segment THEN "Customer_identifier" END) AS WooCommerce_Customers,
    COUNT(DISTINCT CASE WHEN square_Segs = S.Segment THEN "Customer_identifier" END) AS Squarespace_Customers
FROM segments s
LEFT JOIN customer_segments C
    ON c.woo_Segs = S.Segment 
    OR c.square_Segs = S.Segment
GROUP BY S.Segment;


-- Average number of days to second purchase on both platforms
WITH RankedOrders AS (
    SELECT 
        Customer_identifier,
        LOWER(Website) AS Website,
        CAST(Order_Date AS DATE) AS Order_Date,
        ROW_NUMBER() OVER (PARTITION BY Customer_identifier, LOWER(Website) ORDER BY Order_Date) AS order_num
    FROM read_csv_auto("Ferryx_Sales_Data.csv")
)
SELECT 
    o1.Website,
    AVG(o2.Order_Date - o1.Order_Date) AS Avg_Days_To_Second_Purchase
FROM RankedOrders o1
JOIN RankedOrders o2 
  ON o1.Customer_identifier = o2.Customer_identifier 
  AND o1.Website = o2.Website
WHERE o1.order_num = 1 AND o2.order_num = 2
GROUP BY o1.Website;


--purchasing frequency before and after migration
SELECT 
    "Customer_identifier",
    COUNT(*) FILTER (WHERE LOWER("Website") = 'woocommerce') AS Purchases_Before_Migration,
    COUNT(*) FILTER (WHERE LOWER("Website") = 'squarespace') AS Purchases_After_Migration,
    -- Check if they became less active
    (COUNT(*) FILTER (WHERE LOWER("Website") = 'squarespace') - COUNT(*) FILTER (WHERE LOWER("Website") = 'woocommerce')) AS Frequency_Delta
FROM read_csv_auto("Ferryx_Sales_Data.csv")
GROUP BY "Customer_identifier"
-- Only look at customers who experienced both platforms
HAVING Purchases_Before_Migration > 0 AND Purchases_After_Migration > 0
ORDER BY Frequency_Delta ASC;

--What customer segments represent hightest cutomer hubs
select Region,count(order_number)as Number_of_Orders, Round(sum(Item_Cost)) as Total_item_cost 
FROM read_csv_auto("Ferryx_Sales_Data.csv")
group by region
Order by order_total desc;

--comparison of sales in regions before and after migration
select  
    Region,
    -- Woocommerce (Legacy Platform)
    ROUND(SUM(CASE WHEN "Website" = 'Woocommerce' THEN "Item_Cost" ELSE 0 END), 2) AS Woocommerce_Total_Sales,
    COUNT(DISTINCT CASE WHEN "Website" = 'Woocommerce' THEN "Order_Number" END) AS Woocommerce_Order_Count,
    ROUND(
        SUM(CASE WHEN "Website" = 'Woocommerce' THEN "Order_Total_Amount" ELSE 0 END) / 
        NULLIF(COUNT(DISTINCT CASE WHEN "Website" = 'Woocommerce' THEN "Order_Number" END), 0), 
        2
    ) AS Woocommerce_AOV,
    -- Squarespace (New Platform)
    ROUND(SUM(CASE WHEN "Website" = 'Squarespace' THEN "Order_Total_Amount" ELSE 0 END), 2) AS Squarespace_Total_Sales,
    COUNT(DISTINCT CASE WHEN "Website" = 'Squarespace' THEN "Order_Number" END) AS Squarespace_Order_Count,
    ROUND(
        SUM(CASE WHEN "Website" = 'Squarespace' THEN "Order_Total_Amount" ELSE 0 END) / 
        NULLIF(COUNT(DISTINCT CASE WHEN "Website" = 'Squarespace' THEN "Order_Number" END), 0), 
        2
    ) AS Squarespace_AOV,
        -- Variance & Percentage Growth
    ROUND(
        SUM(CASE WHEN "Website" = 'Squarespace' THEN "Order_Total_Amount" ELSE 0 END) - 
        SUM(CASE WHEN "Website" = 'Woocommerce' THEN "Order_Total_Amount" ELSE 0 END), 
        2
    ) AS Sales_Variance,
    ROUND(
        (
            SUM(CASE WHEN "Website" = 'Squarespace' THEN "Order_Total_Amount" ELSE 0 END) - 
            SUM(CASE WHEN "Website" = 'Woocommerce' THEN "Order_Total_Amount" ELSE 0 END)
        ) / NULLIF(SUM(CASE WHEN "Website" = 'Woocommerce' THEN "Order_Total_Amount" ELSE 0 END), 0) * 100, 
        2
    ) AS Sales_Growth_Pct
FROM read_csv_auto('Ferryx_Sales_Data.csv')
GROUP BY Region
ORDER BY Squarespace_Total_Sales DESC;





--Promo-Driven vs. Full-Price Segments: What percentage of our customers only buy when a Coupon Code or Discount Amount is applied? 
select  Coupon_Code, count(Order_Number) as Number_of_orders,
Round(sum(order_Total_Amount),2) as 'Total_spend',
Round(sum(Discount_Amount),2) as 'Total_Discount'
FROM read_csv_auto("Ferryx_Sales_Data.csv")
where Coupon_Code is not null
group by Coupon_Code
order by Total_Discount;


WITH Customer_Order_Summary AS (
    SELECT 
        Customer_identifier,
        Order_Number,
        -- Take MAX/ANY of order-level metrics to prevent double counting on multi-line orders
        MAX(Order_Total_Amount - Order_Total_Tax_Amount) AS Net_Order_Spend,
        MAX(CASE 
            WHEN (Coupon_Code IS NOT NULL AND Coupon_Code != '') 
              OR Discount_Amount > 0 
              OR Cart_Discount_Amount > 0 
            THEN 1 ELSE 0 
        END) AS Is_Discounted_Order
    FROM read_csv_auto('Ferryx_Sales_Data.csv')
    GROUP BY Customer_identifier, Order_Number
),

Customer_Segmentation AS (
    SELECT 
        Customer_identifier,
        COUNT(Order_Number) AS Total_Orders,
        SUM(Is_Discounted_Order) AS Discounted_Orders,
        SUM(Net_Order_Spend) AS Total_Customer_Spend,
        CASE 
            WHEN SUM(Is_Discounted_Order) = COUNT(Order_Number) THEN 'Promo-Driven Only'
            WHEN SUM(Is_Discounted_Order) = 0 THEN 'Full-Price Only'
            ELSE 'Hybrid (Promo & Full-Price)'
        END AS Customer_Segment
    FROM Customer_Order_Summary
    GROUP BY Customer_identifier
)

SELECT 
    Customer_Segment,
    COUNT(Customer_identifier) AS Customer_Count,
    ROUND(
        COUNT(Customer_identifier) * 100.0 / SUM(COUNT(Customer_identifier)) OVER (), 
        2
    ) AS Pct_Of_Total_Customers,
    ROUND(SUM(Total_Customer_Spend), 2) AS Total_Segment_Spend,
    ROUND(AVG(Total_Customer_Spend), 2) AS Avg_Spend_Per_Customer
FROM Customer_Segmentation
GROUP BY Customer_Segment
ORDER BY Customer_Count DESC;
with coupon_Sales as(select  Coupon_Code, 
sum(order_Total_Amount) as 'Total_spend',
sum(Discount_Amount)as 'Total_Discount'
FROM read_csv_auto("Ferryx_Sales_Data.csv")
where Coupon_Code is not null
group by Coupon_Code
order by Total_Discount),

non_coupon_sales(select 
sum(order_Total_Amount) as 'Total_spend'
FROM read_csv_auto("Ferryx_Sales_Data.csv")
where Coupon_Code is  null
group by Coupon_Code
order by Total_spend)

select
c.total_spend as coupon_sales,
n.total_spend as non_cupon_sales,
(c.total_spend/n.total_spend)*100 as '% of discounted sales'
from coupon_sales c
join non_coupon_sales n   
on  ;


WITH Order_Level AS (
    -- Step 1: Deduplicate order-level metrics to prevent double counting on multi-line orders
    SELECT 
        Website,
        Order_Number,
        Customer_identifier,
        MIN(Order_Date) AS Order_Date,
        MAX(Order_Subtotal_Amount) AS Gross_Subtotal,
        MAX(Cart_Discount_Amount + Discount_Amount) AS Total_Discount,
        MAX(Order_Shipping_Amount) AS Shipping_Charged,
        MAX(Order_Total_Tax_Amount) AS Tax_Collected,
        MAX(Order_Refund_Amount) AS Refunds,
        MAX(Order_Total_Amount) AS Order_Total,
        MAX(Order_Total_Amount - Order_Total_Tax_Amount - Order_Refund_Amount) AS Net_Commercial_Revenue,
        MAX(CASE WHEN (Coupon_Code IS NOT NULL AND Coupon_Code != '') OR Discount_Amount > 0 OR Cart_Discount_Amount > 0 THEN 1 ELSE 0 END) AS Is_Discounted_Order
    FROM read_csv_auto('Ferryx_Sales_Data.csv')
    GROUP BY Website, Order_Number, Customer_identifier
),

Customer_Orders AS (
    -- Step 2: Track customer order sequence per website
    SELECT 
        Website,
        Customer_identifier,
        Order_Number,
        ROW_NUMBER() OVER (PARTITION BY Website, Customer_identifier ORDER BY Order_Date) AS Customer_Order_Rank
    FROM Order_Level
)

SELECT 
    o.Website,
    
    -- 1. Order Volume & Customer Acquisition
    COUNT(DISTINCT o.Order_Number) AS Total_Orders,
    COUNT(DISTINCT o.Customer_identifier) AS Unique_Customers,
    COUNT(DISTINCT CASE WHEN c.Customer_Order_Rank > 1 THEN o.Customer_identifier END) AS Repeat_Customers,
    ROUND(
        COUNT(DISTINCT CASE WHEN c.Customer_Order_Rank > 1 THEN o.Customer_identifier END) * 100.0 / 
        NULLIF(COUNT(DISTINCT o.Customer_identifier), 0), 2
    ) AS Repeat_Customer_Rate_Pct,

    -- 2. Financial & Revenue Performance
    ROUND(SUM(o.Gross_Subtotal), 2) AS Gross_Subtotal_Sales,
    ROUND(SUM(o.Net_Commercial_Revenue), 2) AS Net_Commercial_Revenue,
    ROUND(AVG(o.Net_Commercial_Revenue), 2) AS Average_Order_Value_AOV,

    -- 3. Discounting & Margin Efficiency
    ROUND(SUM(o.Total_Discount), 2) AS Total_Discounts_Given,
    ROUND(
        SUM(o.Total_Discount) * 100.0 / NULLIF(SUM(o.Gross_Subtotal), 0), 2
    ) AS Effective_Discount_Rate_Pct,
    ROUND(
        SUM(o.Is_Discounted_Order) * 100.0 / NULLIF(COUNT(DISTINCT o.Order_Number), 0), 2
    ) AS Discounted_Orders_Share_Pct,

    -- 4. Shipping & Logistics Dynamics
    ROUND(SUM(o.Shipping_Charged), 2) AS Total_Shipping_Revenue_Collected,
    ROUND(AVG(o.Shipping_Charged), 2) AS Avg_Shipping_Fee_Per_Order,

    -- 5. Refund & Operational Return Rates
    ROUND(SUM(o.Refunds), 2) AS Total_Refund_Amount,
    ROUND(
        SUM(o.Refunds) * 100.0 / NULLIF(SUM(o.Gross_Subtotal), 0), 2
    ) AS Refund_Rate_Pct

FROM Order_Level o
JOIN Customer_Orders c 
  ON o.Website = c.Website 
 AND o.Order_Number = c.Order_Number 
 AND o.Customer_identifier = c.Customer_identifier
GROUP BY o.Website;