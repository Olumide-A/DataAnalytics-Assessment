-- Account Inactivity Alert
-- Find all active accounts (savings or investments) with no transactions in the last 1 year
SELECT 
    p.id AS plan_id,
    p.owner_id,
    CASE 
        WHEN p.is_regular_savings = 1 THEN 'Savings'
        WHEN p.is_a_fund = 1 THEN 'Investment'
        ELSE 'Other'
    END AS type,
    -- Get date of last transaction
    MAX(s.transaction_date) AS last_transaction_date,
    -- Calculate days since last transaction
    DATEDIFF(CURRENT_DATE(), MAX(s.transaction_date)) AS inactivity_days
FROM 
    plans_plan p
LEFT JOIN 
    savings_savingsaccount s ON p.id = s.plan_id
WHERE 
    -- Only include active plans
    p.is_deleted = 0 
    AND p.is_archived = 0
    -- Either savings or investment plans
    AND (p.is_regular_savings = 1 OR p.is_a_fund = 1)
GROUP BY 
    p.id, p.owner_id
HAVING 
    -- No transactions in the last 365 days
    DATEDIFF(CURRENT_DATE(), last_transaction_date) > 365
ORDER BY 
    inactivity_days DESC;
