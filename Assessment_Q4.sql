-- Customer Lifetime Value (CLV) Estimation
-- Calculate CLV based on account tenure and transaction volume
SELECT 
    u.id AS customer_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    -- Calculate tenure in months from date_joined to current date
    TIMESTAMPDIFF(MONTH, u.date_joined, CURRENT_DATE()) AS tenure_months,
    -- Count total transactions
    COUNT(s.id) AS total_transactions,
    -- Calculate CLV = (total_transactions / tenure) * 12 * avg_profit_per_transaction
    ROUND(
        (COUNT(s.id) / TIMESTAMPDIFF(MONTH, u.date_joined, CURRENT_DATE())) * 12 * 
        (SUM(s.confirmed_amount) * 0.001 / COUNT(s.id)), 
        2
    ) AS estimated_clv
FROM 
    users_customuser u
JOIN 
    savings_savingsaccount s ON u.id = s.owner_id
WHERE 
    -- Only include verified transactions
    s.transaction_status = 'success' 
GROUP BY 
    u.id, 
    u.first_name, 
    u.last_name, 
    u.date_joined
HAVING 
    -- Avoid division by zero for very new accounts
    tenure_months > 0
ORDER BY 
    estimated_clv DESC;
