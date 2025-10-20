----Total Revenue 
SELECT ROUND(SUM(Quantity_Sold *Price), 0) AS Total_Revenue
FROM SalesP;

----Total Cost
WITH AvgWholesale AS (
    SELECT 
        Item_Code,
        AVG(Wholesale_Price) AS Avg_Wholesale_Price
    FROM WholesaleT
    GROUP BY Item_Code
)
SELECT 
    ROUND(SUM(S.Quantity_Sold * AW.Avg_Wholesale_Price), 2) AS Total_Cost
FROM SalesP AS S
JOIN AvgWholesale AS AW
    ON S.Item_Code = AW.Item_Code;


----KPIs and Metrics
WITH AvgWholesale AS (
    SELECT Item_Code, AVG(Wholesale_Price) AS Avg_Wholesale_Price
    FROM WholesaleT
    GROUP BY Item_Code
)
SELECT 
    S.Sales_Date,
    S.Item_Code,
    I.Category_Name,
    ROUND(S.Quantity_Sold,4) AS Quantity,
    ROUND(S.Price, 4) AS Price,
    ROUND(AW.Avg_Wholesale_Price,4) AS Avg_Wholesale_Price,
    ROUND((S.Quantity_Sold * S.Price), 4) AS Revenue,
    ROUND((S.Quantity_Sold * AW.Avg_Wholesale_Price), 4) AS Cost,
    ROUND((S.Quantity_Sold * S.Price) - (S.Quantity_Sold * AW.Avg_Wholesale_Price), 4) AS Profit,
    ROUND(((S.Price - AW.Avg_Wholesale_Price)/S.Price) * 100, 2) AS MarginPercent
FROM SalesP S
JOIN AvgWholesale AW ON S.Item_Code = AW.Item_Code
JOIN Items I ON S.Item_Code = I.Item_Code;


---TOP PERFOMING VEGETABLES
-- Step 1: Calculate average wholesale price per item
WITH AvgWholesale AS (
    SELECT 
        Item_Code,
        AVG(Wholesale_Price) AS Avg_Wholesale_Price
    FROM WholesaleT
    GROUP BY Item_Code
)

-- Step 2: Combine sales, items, and wholesale data
SELECT 
    I.Item_Code,
    I.Item_Name,
    I.Category_Name,
    ROUND(AVG(AW.Avg_Wholesale_Price), 2) AS Avg_Wholesale_Price,
    ROUND(SUM(S.Quantity_Sold * S.Price), 0) AS Total_Revenue,
    ROUND(
        (SUM(S.Quantity_Sold * S.Price) - SUM(S.Quantity_Sold * AW.Avg_Wholesale_Price))
        / NULLIF(SUM(S.Quantity_Sold * S.Price), 0) * 100, 0
    ) AS Profit_Margin_Percent
FROM SalesP AS S
JOIN Items AS I
    ON S.Item_Code = I.Item_Code
JOIN AvgWholesale AS AW
    ON S.Item_Code = AW.Item_Code
GROUP BY 
    I.Item_Code, 
    I.Item_Name, 
    I.Category_Name 
ORDER BY 
    Total_Revenue DESC;


----Do lower-priced vegetables sell more, or are high-priced items still performing well?
-- Step 1: Compute avg price and total quantity per item
WITH PriceVolume AS (
    SELECT 
        S.Item_Code,
        I.Item_Name,
        I.Category_Name,
        ROUND(AVG(S.Price), 2) AS Avg_Price,
        SUM(S.Quantity_Sold) AS Total_Quantity
    FROM SalesP AS S
    JOIN Items AS I
        ON S.Item_Code = I.Item_Code
    GROUP BY S.Item_Code, I.Item_Name, I.Category_Name
),
-- Step 2: Compute overall averages once
Stats AS (
    SELECT 
        AVG(Avg_Price) AS MeanPrice,
        AVG(Total_Quantity) AS MeanQty
    FROM PriceVolume
)
-- Step 3: Use correlation formula safely
SELECT 
   ROUND(SUM((P.Avg_Price - S.MeanPrice) * (P.Total_Quantity - S.MeanQty)) /
    SQRT(
        SUM(POWER(P.Avg_Price - S.MeanPrice, 2)) * 
        SUM(POWER(P.Total_Quantity - S.MeanQty, 2))
    ), 2) AS Price_Quantity_Correlation
FROM PriceVolume AS P
CROSS JOIN Stats AS S;

-- Step 1: Summarize price and quantity by category
WITH CategorySummary AS (
    SELECT 
        I.Category_Name,
        ROUND(AVG(S.Price), 2) AS Avg_Price,
        SUM(S.Quantity_Sold) AS Total_Quantity
    FROM SalesP AS S
    JOIN Items AS I
        ON S.Item_Code = I.Item_Code
    GROUP BY I.Category_Name
),
-- Step 2: Compute overall averages
Stats AS (
    SELECT 
        AVG(Avg_Price) AS MeanPrice,
        AVG(Total_Quantity) AS MeanQty
    FROM CategorySummary
)
-- Step 3: Correlation across categories
SELECT 
    ROUND(SUM((C.Avg_Price - S.MeanPrice) * (C.Total_Quantity - S.MeanQty)) /
    SQRT(
        SUM(POWER(C.Avg_Price - S.MeanPrice, 2)) * 
        SUM(POWER(C.Total_Quantity - S.MeanQty, 2))
    ), 2) AS Category_Price_Quantity_Correlation
FROM CategorySummary AS C
CROSS JOIN Stats AS S;


-----Whether discounts actually boost sales — in both volume (quantity sold) and revenue terms.

SELECT  
    Discount_Status,
    COUNT(*) AS Total_Transactions,
    ROUND(AVG(Quantity_Sold), 0) AS Avg_Quantity_Sold,
    ROUND(SUM(Quantity_Sold), 2) AS Total_Quantity_Sold,
    ROUND(SUM(Quantity_Sold * Price * 7.11), 0) AS Total_Revenue
FROM SalesP
GROUP BY Discount_Status;

---Discount effect to sales categories
-- Discount Performance by Category Over Time
SELECT 
    I.Category_Name,
    I.Category_Code,
    S.Discount_Status,
    FORMAT(S.Sales_Date, 'yyyy-MM') AS Sales_Month,  -- aggregates monthly
    ROUND(SUM(S.Quantity_Sold), 0)AS Total_Quantity_Sold,
    ROUND(SUM(S.Quantity_Sold * S.Price), 2) AS Total_Revenue
FROM SalesP AS S
JOIN Items AS I
    ON S.Item_Code = I.Item_Code
GROUP BY 
    I.Category_Name,
    I.Category_Code,
    S.Discount_Status,
    FORMAT(S.Sales_Date, 'yyyy-MM')
ORDER BY 
    I.Category_Name, 
    Sales_Month;


SELECT SUM(Quantity_Sold) AS quantitysold
FROM SalesP;


-- Step 1: Get average wholesale price per item
WITH AvgWholesale AS (
    SELECT 
        Item_Code,
        AVG(Wholesale_Price) AS Avg_Wholesale_Price
    FROM WholesaleT
    GROUP BY Item_Code
)

-- Step 2: Aggregate profit and sales by category
SELECT 
    I.Category_Name,
    
    ROUND(SUM(S.Quantity_Sold * S.Price), 2) AS Total_Revenue,
    ROUND(SUM(S.Quantity_Sold * AW.Avg_Wholesale_Price), 2) AS Total_Cost,
    
    ROUND(SUM(S.Quantity_Sold * S.Price) - SUM(S.Quantity_Sold * AW.Avg_Wholesale_Price), 2) AS Total_Profit,
    
    ROUND(
        (SUM(S.Quantity_Sold * S.Price) - SUM(S.Quantity_Sold * AW.Avg_Wholesale_Price)) 
        / NULLIF(SUM(S.Quantity_Sold * S.Price), 0) * 100, 2
    ) AS Profit_Margin_Percent,

    ROUND(
        (SUM(S.Quantity_Sold * S.Price) - SUM(S.Quantity_Sold * AW.Avg_Wholesale_Price))
        / NULLIF(
            (SELECT 
                SUM(SP.Quantity_Sold * SP.Price) - SUM(SP.Quantity_Sold * AW2.Avg_Wholesale_Price)
             FROM SalesP SP
             JOIN AvgWholesale AW2 ON SP.Item_Code = AW2.Item_Code), 
        0) * 100, 2
    ) AS Category_Profit_Share_Percent

FROM SalesP AS S
JOIN Items AS I
    ON S.Item_Code = I.Item_Code
JOIN AvgWholesale AS AW
    ON S.Item_Code = AW.Item_Code
GROUP BY I.Category_Name
ORDER BY Total_Profit DESC;

-----Loss Rate Impact on Profitability
-- Step 1: Get average wholesale price per item
WITH AvgWholesale AS (
    SELECT 
        Item_Code,
        AVG(Wholesale_Price) AS Avg_Wholesale_Price
    FROM WholesaleT
    GROUP BY Item_Code
)

-- Step 2: Compute loss-adjusted profit per item
SELECT 
    I.Item_Code,
    I.Item_Name,
    I.Category_Name,
    L.Loss_Rate AS Loss_Rate_Percent,
    ROUND(SUM(S.Quantity_Sold * S.Price), 2) AS Total_Revenue,
    ROUND(SUM(S.Quantity_Sold * AW.Avg_Wholesale_Price), 2) AS Total_Cost,
    
    -- Normal Profit
    ROUND(SUM(S.Quantity_Sold * S.Price) - SUM(S.Quantity_Sold * AW.Avg_Wholesale_Price), 2) AS Total_Profit,

    -- Loss-Adjusted Profit (reduce revenue by loss %)
    ROUND(
        (SUM(S.Quantity_Sold * S.Price) * (1 - (L.Loss_Rate / 100))) 
        - SUM(S.Quantity_Sold * AW.Avg_Wholesale_Price), 2
    ) AS Loss_Adjusted_Profit,

    -- Normal Profit Margin %
    ROUND(
        (SUM(S.Quantity_Sold * S.Price) - SUM(S.Quantity_Sold * AW.Avg_Wholesale_Price)) 
        / NULLIF(SUM(S.Quantity_Sold * S.Price), 0) * 100, 2
    ) AS Profit_Margin_Percent,

    -- Loss-Adjusted Profit Margin %
    ROUND(
        ((SUM(S.Quantity_Sold * S.Price) * (1 - (L.Loss_Rate / 100))) 
        - SUM(S.Quantity_Sold * AW.Avg_Wholesale_Price)) 
        / NULLIF(SUM(S.Quantity_Sold * S.Price), 0) * 100, 2
    ) AS Loss_Adjusted_Profit_Margin_Percent

FROM SalesP AS S
JOIN Items AS I
    ON S.Item_Code = I.Item_Code
JOIN AvgWholesale AS AW
    ON S.Item_Code = AW.Item_Code
JOIN LossRate AS L
    ON S.Item_Code = L.Item_Code
GROUP BY 
    I.Item_Code, I.Item_Name, I.Category_Name, L.Loss_Rate
ORDER BY 
    L.Loss_Rate DESC;


----How do fluctuations in wholesale prices affect profitability over time?
-- Step 1: Calculate average wholesale price per item and month
WITH MonthlyWholesale AS (
    SELECT 
        Item_Code,
        YEAR(Date) AS YearNum,
        MONTH(Date) AS MonthNum,
        AVG(Wholesale_Price) AS Avg_Wholesale_Price
    FROM WholesaleT
    GROUP BY Item_Code, YEAR(Date), MONTH(Date)
),

-- Step 2: Calculate monthly sales and profitability per category
MonthlyProfit AS (
    SELECT 
        I.Category_Name,
        YEAR(S.Sales_Date) AS YearNum,
        MONTH(S.Sales_Date) AS MonthNum,

        ROUND(SUM(S.Quantity_Sold * S.Price), 2) AS Total_Revenue,
        ROUND(SUM(S.Quantity_Sold * MW.Avg_Wholesale_Price), 2) AS Total_Cost,
        
        ROUND(
            (SUM(S.Quantity_Sold * S.Price) - SUM(S.Quantity_Sold * MW.Avg_Wholesale_Price)), 
            2
        ) AS Total_Profit,

        ROUND(
            (SUM(S.Quantity_Sold * S.Price) - SUM(S.Quantity_Sold * MW.Avg_Wholesale_Price))
            / NULLIF(SUM(S.Quantity_Sold * S.Price), 0) * 100, 2
        ) AS Profit_Margin_Percent,

        ROUND(AVG(MW.Avg_Wholesale_Price), 2) AS Avg_Wholesale_Price
    FROM SalesP AS S
    JOIN Items AS I 
        ON S.Item_Code = I.Item_Code
    JOIN MonthlyWholesale AS MW 
        ON S.Item_Code = MW.Item_Code
        AND YEAR(S.Sales_Date) = MW.YearNum
        AND MONTH(S.Sales_Date) = MW.MonthNum
    GROUP BY 
        I.Category_Name, 
        YEAR(S.Sales_Date), 
        MONTH(S.Sales_Date)
)

-- Step 3: Show final trend data
SELECT 
    Category_Name,
     FORMAT(DATEFROMPARTS(YearNum, MonthNum, 1), 'yyyy-MM') AS Period,
    Avg_Wholesale_Price,
    Total_Revenue,
    Total_Profit,
    Profit_Margin_Percent
FROM MonthlyProfit
ORDER BY Category_Name, YearNum, MonthNum;


SELECT * 
FROM Items
WHERE Category_Name IS NULL;

SELECT 
FROM 
