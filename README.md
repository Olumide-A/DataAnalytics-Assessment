# DataAnalytics-Assessment

This repository contains SQL queries for a data analytics assessment focused on analyzing customer data, savings accounts, plans, and withdrawal transactions.

## Question 1: High-Value Customers with Multiple Products

### Approach
For this question, I needed to identify customers who have both savings and investment plans, sorted by their total deposits.
Key elements of my approach:

1. Joined the users_customuser, plans_plan, and savings_savingsaccount tables to connect customers with their plans and deposit transactions
2. Used CASE WHEN statements with COUNT DISTINCT to accurately count unique savings plans and investment plans per customer
3. Used the HAVING clause to filter for customers who have at least one of each plan type
4. Created a full name by concatenating first_name and last_name fields
5. Sorted results by total deposits in descending order

The query identifies:
- Customers with at least one savings plan (is_regular_savings = 1)
- AND at least one investment plan (is_a_fund = 1)
- Their total deposit amount from the confirmed_amount field
- Count of each plan type

### Challenges

1. **Name field identification**
   - Challenge: Initially I tried to use a non-existent name column in the users table.
   - Solution: After examining the database schema more carefully, I realized I needed to concatenate first_name and last_name fields to display the customer's full name.

2. **Accurate plan counting**
   - Challenge: Getting an accurate count of each plan type per customer required careful consideration.
   - Solution: I used COUNT(DISTINCT CASE WHEN [condition] THEN p.id END) to count unique plan IDs of each type. This approach counts each unique plan ID only once when it matches the condition, avoiding double-counting and ensuring accurate results.

3. **Validation of high counts**
   - Challenge: Some customers showed unusually high savings plan counts (200+), which seemed suspicious.
   - Solution: Created diagnostic queries to examine:
     - Distribution of savings counts across customers
     - All plans for specific high-count customers
     - Potential duplicate transactions
   - This helped confirm whether high counts were legitimate or indicated data anomalies.

4. **Efficiency in grouping**
   - Challenge: Initial grouping included unnecessary columns.
   - Solution: Simplified the GROUP BY clause to use only the primary key (u.id), improving efficiency while maintaining correct aggregation.

## Question 2: Transaction Frequency Analysis

### Approach
This question required me to analyze transaction frequency patterns to segment customers into different categories based on their activity level.
Key elements of my approach:

1. Used a nested query structure with an inner subquery calculating per-customer metrics
2. Calculated average transactions per month by dividing total transactions by distinct months of activity
3. Applied categorization logic to segment customers into frequency groups
4. Aggregated results to get counts and average metrics per category

The query implements:
- Calculation of transactions per month for each customer
- Categorization into "High Frequency" (≥10/month), "Medium Frequency" (3-9/month), and "Low Frequency" (≤2/month)
- Aggregation to get count of customers in each category
- Calculation of average transactions per month within each category

### Challenges

1. **Group By Error**
   - Challenge: Initially encountered "Error Code: 1056. Can't group on 'frequency_category'" when trying to group by a derived column in the SELECT statement.
   - Solution: Restructured the query to perform categorization in the inner subquery, then grouped by this pre-calculated column in the outer query.

2. **Calculating Monthly Average**
   - Challenge: Needed to determine how many transactions each customer makes per month on average.
   - Solution: Used EXTRACT(YEAR_MONTH FROM transaction_date) to convert dates to YYYYMM format, allowing me to count distinct months of activity and divide the total transaction count by this number.

3. **Appropriate Categorization**
   - Challenge: Ensuring that the categorization logic correctly placed customers in the right frequency buckets.
   - Solution: Applied the CASE statement with clear boundary conditions to create three distinct categories, making sure that every customer would fall into exactly one category.

4. **Result Ordering**
   - Challenge: Needed to present results in a logical order (High → Medium → Low) rather than alphabetical.
   - Solution: Used a CASE statement in the ORDER BY clause to assign numeric sort values to each category, ensuring consistent presentation of results.

## Question 3: Account Inactivity Alert

### Approach
For this question, I needed to identify savings and investment accounts with no transaction activity for over a year (365 days). My approach was to:

1. Join the `plans_plan` table with `savings_savingsaccount` using a LEFT JOIN to ensure we include accounts that might have no transactions.
2. Use a CASE statement to properly categorize accounts as either "Savings" or "Investment" based on the boolean flags in the database.
3. Find the most recent transaction date for each account using MAX(transaction_date).
4. Calculate the inactivity period using DATEDIFF() between the current date and the last transaction date.
5. Filter only active accounts by excluding deleted or archived plans.
6. Use a HAVING clause to include only accounts with inactivity exceeding 365 days.

### Query Explanation
```sql
SELECT 
    p.id AS plan_id,
    p.owner_id,
    CASE 
        WHEN p.is_regular_savings = 1 THEN 'Savings'
        WHEN p.is_a_fund = 1 THEN 'Investment'
        ELSE 'Other'
    END AS type,
    MAX(s.transaction_date) AS last_transaction_date,
    DATEDIFF(CURRENT_DATE(), MAX(s.transaction_date)) AS inactivity_days
FROM 
    plans_plan p
LEFT JOIN 
    savings_savingsaccount s ON p.id = s.plan_id
WHERE 
    p.is_deleted = 0 
    AND p.is_archived = 0
    AND (p.is_regular_savings = 1 OR p.is_a_fund = 1)
GROUP BY 
    p.id, p.owner_id
HAVING 
    DATEDIFF(CURRENT_DATE(), last_transaction_date) > 365
ORDER BY 
    inactivity_days DESC;
```

### Challenges
1. **Handling NULL Values**: Originally, I included a condition in the HAVING clause to handle accounts with no transactions ever (NULL last_transaction_date). However, these would produce NULL in the DATEDIFF calculation, which wouldn't satisfy the `> 365` condition. The final implementation focuses on accounts with transactions older than 365 days.

2. **Identifying Account Types**: The database uses boolean flags rather than a single type column, requiring careful use of the CASE statement to properly categorize accounts.

## Question 4: Customer Lifetime Value (CLV) Estimation

### Approach
For calculating the Customer Lifetime Value, I needed to create a complex calculation based on account tenure, transaction frequency, and average transaction value. My strategy was to:

1. Calculate the account tenure in months using TIMESTAMPDIFF between signup date and current date.
2. Count each customer's total number of transactions.
3. Calculate the average profit per transaction as 0.1% of the transaction value.
4. Apply the CLV formula: (transactions/tenure) * 12 * avg_profit_per_transaction
5. Filter to include only successful transactions.
6. Exclude accounts with zero tenure to prevent division by zero errors.

### Query Explanation
```sql
SELECT 
    u.id AS customer_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    TIMESTAMPDIFF(MONTH, u.date_joined, CURRENT_DATE()) AS tenure_months,
    COUNT(s.id) AS total_transactions,
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
    s.transaction_status = 'success' 
GROUP BY 
    u.id, 
    u.first_name, 
    u.last_name, 
    u.date_joined
HAVING 
    tenure_months > 0
ORDER BY 
    estimated_clv DESC;
```

### Challenges
1. **Complex CLV Formula**: Implementing the multi-part formula correctly required careful attention to calculation order and proper use of aggregation functions.

2. **Handling New Accounts**: Accounts with very short tenures could cause division by zero errors or skew results with unrealistically high CLV. The HAVING clause prevents division by zero.

3. **Transaction Value Interpretation**: Understanding that the confirmed_amount field contains the transaction value and applying the correct profit margin (0.1%) was crucial for accurate CLV calculation.

4. **Data Type Management**: Ensuring proper handling of date calculations and numeric precision for financial calculations required careful consideration of MySQL's functions and handling of numeric types.

## General Learnings

Throughout this assessment, I gained valuable insights into:

1. The importance of careful data filtering for business analytics
2. Techniques for handling NULL values and edge cases in financial data
3. Effective use of MySQL date and time functions for temporal analysis
4. Methods for calculating customer value metrics in a financial context

These queries demonstrate my ability to extract meaningful business insights from complex relational data structures while handling real-world data challenges.
