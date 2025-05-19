-- Transaction Frequency Analysis
-- Calculate the average number of transactions per customer per month and categorize them
SELECT 
    frequency_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(transactions_per_month), 1) AS avg_transactions_per_month
FROM (
    -- First calculate transactions per month for each customer
    SELECT 
        s.owner_id AS customer_id,
        -- Count transactions and divide by number of distinct months
        COUNT(s.id) / COUNT(DISTINCT EXTRACT(YEAR_MONTH FROM s.transaction_date)) AS transactions_per_month,
        -- Categorize in the subquery instead
        CASE 
            WHEN COUNT(s.id) / COUNT(DISTINCT EXTRACT(YEAR_MONTH FROM s.transaction_date)) >= 10 THEN 'High Frequency'
            WHEN COUNT(s.id) / COUNT(DISTINCT EXTRACT(YEAR_MONTH FROM s.transaction_date)) BETWEEN 3 AND 9 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category
    FROM 
        savings_savingsaccount s
    GROUP BY 
        s.owner_id
) AS customer_frequency
GROUP BY 
    frequency_category
ORDER BY 
    avg_transactions_per_month DESC;
