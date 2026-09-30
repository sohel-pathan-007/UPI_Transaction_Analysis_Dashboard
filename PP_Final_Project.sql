CREATE DATABASE phone_pe;

use phone_pe;

CREATE TABLE upi_transactions (
    Transaction_ID VARCHAR(50) primary key,
    Transaction_Date DATE,
    Transaction_Time TIME,
    UPI_App VARCHAR(50),
    Customer_ID VARCHAR(50),
    Age_Group VARCHAR(30),
    Gender VARCHAR(20),
    State VARCHAR(50),
    City VARCHAR(50),
    Merchant_Name VARCHAR(100),
    Merchant_Category VARCHAR(50),
    Transaction_Type VARCHAR(50),
    Payment_Mode VARCHAR(50),
    Bank_Name VARCHAR(100),
    Amount_INR DECIMAL(15,2),
    Cashback_INR DECIMAL(15,2),
    Transaction_Fee_INR DECIMAL(15,2),
    Status VARCHAR(20),
    Failure_Reason VARCHAR(100),
    Device_OS VARCHAR(30),
    Risk_Score INT,
    Is_Suspected_Fraud VARCHAR(10),
    Hour INT,
    Day VARCHAR(20),
    month VARCHAR(20),
    Amount_Category VARCHAR(20)
);


select * from upi_transactions;

-- state-wise transaction amount using CTE
WITH state_analysis AS (
    SELECT 
        State,
	SUM(Amount_INR) AS total_amount
    FROM upi_transactions
    GROUP BY State
)
SELECT *
FROM state_analysis
ORDER BY total_amount DESC;

-- Top 5 States by Transaction Amount
SELECT *
FROM (
    SELECT 
        State,
        SUM(Amount_INR) AS total_amount
    FROM upi_transactions
    GROUP BY State
) AS state_data
ORDER BY total_amount DESC
LIMIT 5;

-- Rank each transaction within each State
SELECT
    State,
    Transaction_ID,
    Amount_INR,
    ROW_NUMBER() OVER (
        PARTITION BY State
        ORDER BY Amount_INR DESC
    ) AS row_num
FROM upi_transactions;


-- Rank transactions by Amount within each State
SELECT
    State,
    Transaction_ID,
    Amount_INR,
    RANK() OVER (
        PARTITION BY State
        ORDER BY Amount_INR DESC
    ) AS amount_rank
FROM upi_transactions;


-- Dense rank transactions by Amount within each State
SELECT
    State,
    Transaction_ID,
    Amount_INR,
    DENSE_RANK() OVER (
        PARTITION BY State
        ORDER BY Amount_INR DESC
    ) AS dense_ranks
FROM upi_transactions;


-- Compare current transaction with previous transaction
SELECT
    Transaction_Date,
    Amount_INR,
    LAG(Amount_INR) OVER (
        ORDER BY Transaction_Date
    ) AS previous_amount
FROM upi_transactions;

-- Compare current transaction with next transaction
SELECT
    Transaction_Date,
    Amount_INR,
    LEAD(Amount_INR) OVER (
        ORDER BY Transaction_Date
    ) AS next_amount
FROM upi_transactions;

-- States with high transaction amount
SELECT
    State,
    SUM(Amount_INR) AS total_amount
FROM upi_transactions
GROUP BY State
HAVING SUM(Amount_INR) > 4000000
ORDER BY total_amount DESC;


-- Categorize transactions by Risk Score
SELECT
    Transaction_ID,
    Risk_Score,
    CASE
        WHEN Risk_Score >= 80 THEN 'High Risk'
        WHEN Risk_Score >= 50 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS Risk_Category
FROM upi_transactions;


-- Create State Summary Table
CREATE TABLE state_summary AS
SELECT
    State,
    COUNT(*) AS total_transactions,
    SUM(Amount_INR) AS total_amount
FROM upi_transactions
GROUP BY State;

-- Join Transactions with State Summary
SELECT
    u.Transaction_ID,
    u.State,
    u.Amount_INR,
    s.total_transactions,
    s.total_amount
FROM upi_transactions u
INNER JOIN state_summary s
    ON u.State = s.State;
    
-- Daily Transaction Amount
SELECT
    Transaction_Date,
    COUNT(*) AS total_transactions,
    SUM(Amount_INR) AS total_amount
FROM upi_transactions
GROUP BY Transaction_Date
ORDER BY Transaction_Date;


-- Status-wise Transaction Analysis
SELECT
    COUNT(*) AS total_transactions,
    
    SUM(CASE
        WHEN Status = 'Success' THEN 1
        ELSE 0 END) AS successful_transactions,
    
    SUM(CASE
        WHEN Status = 'Failed' THEN 1
        ELSE 0 END) AS failed_transactions,
    
    SUM(CASE
        WHEN Status = 'Pending' THEN 1
        ELSE 0 END) AS pending_transactions
FROM upi_transactions;


-- Running Total of Transaction Amount
SELECT
    Transaction_Date,
    SUM(Amount_INR) AS daily_amount,
    SUM(SUM(Amount_INR)) OVER (
        ORDER BY Transaction_Date
    ) AS running_total
FROM upi_transactions
GROUP BY Transaction_Date
ORDER BY Transaction_Date;

-- Top 5 Merchants by Transaction Amount
SELECT
    Merchant_Name,
    COUNT(*) AS total_transactions,
    SUM(Amount_INR) AS total_amount
FROM upi_transactions
GROUP BY Merchant_Name
ORDER BY total_amount DESC
LIMIT 5;

-- Check duplicate Transaction IDs
SELECT
    Transaction_ID,
    COUNT(*) AS duplicate_count
FROM upi_transactions
GROUP BY Transaction_ID
HAVING COUNT(*) > 1;

-- Check invalid transaction amounts
SELECT *
FROM upi_transactions
WHERE Amount_INR <= 0;

-- Check invalid Risk Scores
SELECT *
FROM upi_transactions
WHERE Risk_Score < 1
   OR Risk_Score > 100;
   
   -- Check important NULL values

SELECT *
FROM upi_transactions
WHERE Transaction_ID IS NULL
   OR Amount_INR IS NULL
   OR Transaction_Date IS NULL;
   
   -- Create UPI Summary View

CREATE VIEW upi_summary AS
SELECT
    State,
    Status,
    COUNT(*) AS total_transactions,
    SUM(Amount_INR) AS total_amount,
    SUM(Cashback_INR) AS total_cashback
FROM upi_transactions
GROUP BY State, Status;

-- shows summary sorted by highest amount
SELECT *
FROM upi_summary
ORDER BY total_amount DESC;


-- Create index for faster date filtering

CREATE INDEX idx_transaction_date
ON upi_transactions(Transaction_Date);

-- Check query execution plan

EXPLAIN
SELECT *
FROM upi_transactions
WHERE Transaction_Date = '2026-05-28';