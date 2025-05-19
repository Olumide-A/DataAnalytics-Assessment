-- Query to find customers with at least one funded savings plan AND one funded investment plan, sorted by total deposits
SELECT 
    u.id AS owner_id,
    -- Concatenate first_name and last_name to create full name
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    -- Count number of unique savings and investment plans
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN p.id END) AS savings_count,
    COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN p.id END) AS investment_count,
    -- Calculate total deposits (sum of confirmed amounts)
    SUM(s.confirmed_amount) AS total_deposits
FROM 
    users_customuser u
    INNER JOIN plans_plan p ON u.id = p.owner_id
    INNER JOIN savings_savingsaccount s ON p.id = s.plan_id AND s.owner_id = u.id
GROUP BY 
    u.id, u.first_name, u.last_name
-- Filter for customers with at least one of each type of plan
HAVING 
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN p.id END) > 0
    AND COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN p.id END) > 0
ORDER BY 
    total_deposits DESC;
