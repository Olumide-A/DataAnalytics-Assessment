# Cowrywise Assessment

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
   - Challenge: While trying to get familiar with the available data, I realized a name column filled with NULL in the users table, and this field will be needed for my analysis
   - Solution: After examining the database schema more carefully, I knew I needed to concatenate first_name and last_name fields to display the customer's full name.

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


## Question 3: Account Inactivity Alert

### Approach
For this question, I needed to identify savings and investment accounts with no transaction activity for over a year (365 days). My approach was to:

1. Join the `plans_plan` table with `savings_savingsaccount` using a LEFT JOIN to ensure we include accounts that might have no transactions.
2. Use a CASE statement to properly categorize accounts as either "Savings" or "Investment" based on the boolean flags in the database.
3. Find the most recent transaction date for each account using MAX(transaction_date).
4. Calculate the inactivity period using DATEDIFF() between the current date and the last transaction date.
5. Filter only active accounts by excluding deleted or archived plans.
6. Use a HAVING clause to include only accounts with inactivity exceeding 365 days.

### Challenges
1. **Ignoring Archived or Deleted Accounts**
- Challenge: Initially, I didn’t account for the fact that some plans may be archived or deleted. This caused inaccurate results by including plans that were no longer relevant.
- Solution: Upon reviewing the schema more closely, I noticed the is_deleted and is_archived flags. I modified the query to exclude these records in the WHERE clause to ensure only truly active accounts were included.
2.  **Handling NULL Values**
- Challenge: Originally, my inital query included a condition in the HAVING clause to handle accounts with no transactions ever. Which produced NULL in the DATEDIFF calculation and wouldn't satisfy the `> 365` condition. The final implementation focuses on accounts with transactions older than 365 days.
- Solution: I focused the query on accounts with actual transaction history older than 365 days. For accounts with no transactions, a separate analysis might be needed where we would compare the account creation date to the current date instead of transaction dates.

3. **Identifying Account Types**
- Challenge: The database schema uses boolean flags (is_regular_savings and is_a_fund) rather than a single account type column, requiring careful categorization logic.
- Solution: I implemented a CASE statement to properly transform these boolean flags into meaningful account type labels ("Savings" or "Investment"). This approach provides clear classification in the results.

## Question 4: Customer Lifetime Value (CLV) Estimation

### Approach
For calculating the Customer Lifetime Value, I needed to create a complex calculation based on account tenure, transaction frequency, and average transaction value. My strategy was to:

1. Calculate the account tenure in months using TIMESTAMPDIFF between signup date and current date.
2. Count each customer's total number of transactions.
3. Calculate the average profit per transaction as 0.1% of the transaction value.
4. Apply the CLV formula: (transactions/tenure) * 12 * avg_profit_per_transaction
5. Filter to include only successful transactions.
6. Exclude accounts with zero tenure to prevent division by zero errors.

### Challenges
1. **Including Unsuccessful Transactions**
- Challenge: At first, I included all transactions in the CLV calculation without checking their status. This skewed the results because some transactions were failed or reversed, which shouldn't be counted.
- Solution: I revised the query to filter only successful transactions (transaction_status = 'success'). This ensured that only verified deposits contributed to the CLV estimate.
2.  **Complex CLV Formula**
- Challenge: The Customer Lifetime Value calculation required a multi-part formula incorporating account tenure, transaction frequency, and average profit margins. Implementing this correctly within SQL required careful attention to calculation order and proper use of aggregation functions.
- Solution: I leveraged MySQL's order of operations to ensure accurate results. My approach was to structure the calculation as a nested formula that first determined the transaction rate (transactions per month), then annualized it (multiplying by 12), and finally multiplied by the average profit per transaction. I used appropriate SQL functions like TIMESTAMPDIFF for date calculations.

3. **Handling New Accounts**
- Challenge: I realized that newly created accounts with very short tenures (especially zero months) could cause division by zero errors or result in unrealistically high CLV projections that would skew the analysis.
- Solution: I implemented a HAVING clause to filter out accounts with zero tenure months, preventing division by zero errors. This ensures the CLV calculation remains mathematically sound while still including as many valid customers as possible in the analysis.

## General Learnings

Throughout this assessment, I gained valuable insights into:

1. The importance of careful data filtering for business analytics
2. Techniques for handling NULL values and edge cases in financial data
3. Effective use of MySQL date and time functions for temporal analysis
4. Methods for calculating customer value metrics in a financial context
