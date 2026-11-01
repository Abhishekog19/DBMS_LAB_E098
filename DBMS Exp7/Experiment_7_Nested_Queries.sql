    -- EXPERIMENT 7: NESTED QUERIES 


    CREATE DATABASE db7;  -- your database name 
    USE db7;              -- dont forget this -- yo umust ensure your default DB is this


    CREATE TABLE customer (
        customer_id INTEGER PRIMARY KEY,
        cust_name VARCHAR(60) NOT NULL,
        city VARCHAR(40) NOT NULL
    );

    CREATE TABLE depositor (
        account_no INTEGER PRIMARY KEY,
        customer_id INTEGER NOT NULL REFERENCES customer(customer_id),
        branch VARCHAR(40) NOT NULL,
        balance NUMERIC(12,2) NOT NULL CHECK (balance >= 0)
    );

    CREATE TABLE borrower (
        loan_no INTEGER PRIMARY KEY,
        customer_id INTEGER NOT NULL REFERENCES customer(customer_id),
        branch VARCHAR(40) NOT NULL,
        loan_amount NUMERIC(12,2) NOT NULL CHECK (loan_amount > 0)
    );

    CREATE TABLE borrower_bkp LIKE borrower;

    INSERT INTO borrower_bkp
    SELECT * FROM borrower;

    -- DATA INSERTION
    INSERT INTO customer VALUES
    (1,'Asha','Mumbai'),(2,'Rahul','Pune'),(3,'Neha','Mumbai'),
    (4,'Imran','Pune'),(5,'Priya','Delhi'),(6,'Vivek','Mumbai'),
    (7,'Meera','Delhi'),(8,'Karan','Pune');

    INSERT INTO depositor VALUES
    (1001,1,'Mumbai',10000),(1002,2,'Mumbai',30000),
    (1003,3,'Pune',50000),(1004,4,'Pune',20000),
    (1005,5,'Delhi',70000),(1006,6,'Mumbai',30000),
    (1007,1,'Pune',15000);

    INSERT INTO borrower VALUES
    (501,1,'Mumbai',100000),(502,3,'Pune'   ,200000),
    (503,5,'Delhi',150000),(504,7,'Delhi',80000),
    (505,8,'Pune',120000),(506,1,'Pune',50000);

    -- Display the master data
    SELECT * FROM customer ORDER BY customer_id;
    SELECT * FROM depositor ORDER BY account_no;
    SELECT * FROM borrower ORDER BY loan_no;

    -- Find borrowers who also hold an account using IN
    SELECT customer_id, cust_name FROM customer
    WHERE customer_id IN (SELECT customer_id FROM borrower)
    AND customer_id IN (SELECT customer_id FROM depositor)
    ORDER BY customer_id;

    -- Find borrowers who do not hold an account using NOT IN
    SELECT customer_id, cust_name FROM customer
    WHERE customer_id IN (SELECT customer_id FROM borrower)
    AND customer_id NOT IN (SELECT customer_id FROM depositor)
    ORDER BY customer_id;

    -- Find accounts with balance greater than at least one Mumbai account
    SELECT account_no, customer_id, balance FROM depositor
    WHERE balance > SOME (SELECT balance FROM depositor WHERE branch = 'Mumbai')
    ORDER BY account_no;


    -- Find accounts with balance at least as large as every Mumbai account
    SELECT account_no, customer_id, balance FROM depositor
    WHERE balance >= ALL (SELECT balance FROM depositor WHERE branch = 'Mumbai')
    ORDER BY account_no;

    -- Find borrowers who also hold an account using correlated EXISTS
    SELECT c.customer_id, c.cust_name FROM customer c
    WHERE EXISTS (SELECT 1 FROM borrower b WHERE b.customer_id = c.customer_id)
    AND EXISTS (SELECT 1 FROM depositor d WHERE d.customer_id = c.customer_id)
    ORDER BY c.customer_id;

    -- Find borrowers without accounts using correlated NOT EXISTS
    SELECT c.customer_id, c.cust_name FROM customer c
    WHERE EXISTS (SELECT 1 FROM borrower b WHERE b.customer_id = c.customer_id)
    AND NOT EXISTS (SELECT 1 FROM depositor d WHERE d.customer_id = c.customer_id)
    ORDER BY c.customer_id;

    -- Find accounts with balance above the overall average (scalar subquery)
    SELECT account_no, balance FROM depositor
    WHERE balance > (SELECT AVG(balance) FROM depositor)
    ORDER BY account_no;

    -- Find accounts with balance above their own branch average
    SELECT d.account_no, d.branch, d.balance FROM depositor d
    WHERE d.balance > (
        SELECT AVG(d2.balance) FROM depositor d2 WHERE d2.branch = d.branch
    )
    ORDER BY d.account_no;

    -- Find the highest-balance accounts, retaining ties
    SELECT account_no, customer_id, balance FROM depositor
    WHERE balance = (SELECT MAX(balance) FROM depositor)
    ORDER BY account_no;

    -- Use a subquery as a derived table in FROM
    SELECT branch, average_balance
    FROM (
        SELECT branch, ROUND(AVG(balance),2) AS average_balance
        FROM depositor GROUP BY branch
    ) AS branch_summary
    WHERE average_balance > 30000 ORDER BY branch;

    -- Use a correlated scalar subquery in the SELECT list
    SELECT c.customer_id, c.cust_name,
        (SELECT COUNT(*) FROM depositor d
            WHERE d.customer_id = c.customer_id) AS account_count
    FROM customer c ORDER BY c.customer_id;


    -- Use multiple levels of nesting to find borrowers with Mumbai accounts
    SELECT customer_id, cust_name FROM customer
    WHERE customer_id IN (
        SELECT customer_id FROM borrower
        WHERE customer_id IN (
            SELECT customer_id FROM depositor WHERE branch = 'Mumbai'
        )
    ) ORDER BY customer_id;

    -- Copy borrower records into a backup table using INSERT SELECT
    -- INSERT SELECT is a query-based insert, rather than a WHERE subquery.
    INSERT INTO borrower_bkp (loan_no, customer_id, branch, loan_amount)
    SELECT loan_no, customer_id, branch, loan_amount FROM borrower;
    SELECT * FROM borrower_bkp ORDER BY loan_no;

    -- Use a subquery in UPDATE; restore original data afterward
    BEGIN;
    UPDATE depositor SET balance = balance + 1000
    WHERE customer_id IN (SELECT customer_id FROM borrower);
    SELECT * FROM depositor ORDER BY account_no;
    ROLLBACK;

    -- Use a subquery in DELETE on the backup table only
    BEGIN;
    DELETE FROM borrower_bkp
    WHERE customer_id NOT IN (SELECT customer_id FROM depositor);
    SELECT * FROM borrower_bkp ORDER BY loan_no;
    ROLLBACK;

    -- Explain the NULL trap in NOT IN and compare NOT EXISTS
    -- Deliberately introduce NULL into a subquery result without changing master data.
    SELECT c.customer_id, c.cust_name FROM customer c
    WHERE c.customer_id NOT IN (
        SELECT d.customer_id FROM depositor d
        UNION ALL SELECT NULL::INTEGER
    ) ORDER BY c.customer_id;
    SELECT c.customer_id, c.cust_name FROM customer c
    WHERE NOT EXISTS (
        SELECT 1 FROM (
            SELECT customer_id FROM depositor
            UNION ALL SELECT NULL::INTEGER
        ) AS ids WHERE ids.customer_id = c.customer_id
    ) ORDER BY c.customer_id;

    -- Compare ANY and ALL with an empty subquery
    SELECT
        50000 > ANY (SELECT balance FROM depositor WHERE branch = 'Chennai')
            AS any_empty_result,
        50000 > ALL (SELECT balance FROM depositor WHERE branch = 'Chennai')
            AS all_empty_result;



    -- Below NOT for JOURNAL   - For Students Extra practice

    -- STUDENT PRACTICE QUESTIONS 

    -- P01: Using IN, find customers who have an account but have never borrowed.
    -- P02: Using NOT EXISTS, find customers who have no account. Return each customer only once.
    -- P03: Find accounts whose balance is greater than the overall average account balance using a scalar subquery.
    -- P04: Find accounts whose balance exceeds every Pune account balance using ALL.
    -- P05: Find accounts whose balance exceeds at least one Delhi account balance using ANY.
    -- P06: Using a correlated subquery, find accounts whose balance equals the maximum balance in their own branch. Retain ties.
    -- P07: Find customers whose total loan amount exceeds 150000 using a subquery. Account for customers with multiple loans.
    -- P08: Find customers who have an account in the same branch as at least one of their loans using correlated EXISTS.
    -- P09: Use a subquery in the SELECT list to display every customer and their total account balance. Display zero for customers without accounts.
    -- P10: Using a subquery in FROM, display branches whose average account balance exceeds the overall average account balance.
    -- P11: Within a transaction, increase balances by 2000 for accounts owned by customers who have a Delhi loan. Verify and roll back.
    -- P12: Within a transaction, delete backup loans belonging to customers without accounts. Verify and roll back.
    -- P13: Compare NOT IN and NOT EXISTS when the subquery result contains NULL. Explain the observed difference.
    -- P14: Predict and verify the results of ANY and ALL when their subquery returns no rows.


















































    -- STUDENT PRACTICE SOLUTIONS


    -- Account holders who have never borrowed
    SELECT customer_id, cust_name FROM customer
    WHERE customer_id IN (SELECT customer_id FROM depositor)
    AND customer_id NOT IN (SELECT customer_id FROM borrower)
    ORDER BY customer_id;

    -- Customers without accounts using NOT EXISTS
    SELECT c.customer_id, c.cust_name FROM customer c
    WHERE NOT EXISTS (SELECT 1 FROM depositor d
                    WHERE d.customer_id = c.customer_id)
    ORDER BY c.customer_id;

    -- Accounts above the overall average
    SELECT account_no, balance FROM depositor
    WHERE balance > (SELECT AVG(balance) FROM depositor)
    ORDER BY account_no;

    -- Balance exceeding every Pune account balance
    SELECT account_no, balance FROM depositor
    WHERE balance > ALL (SELECT balance FROM depositor WHERE branch = 'Pune')
    ORDER BY account_no;

    -- Balance exceeding at least one Delhi account balance
    SELECT account_no, balance FROM depositor
    WHERE balance > ANY (SELECT balance FROM depositor WHERE branch = 'Delhi')
    ORDER BY account_no;

    -- Highest-balance accounts in each branch, retaining ties
    SELECT d.account_no, d.branch, d.balance FROM depositor d
    WHERE d.balance = (SELECT MAX(d2.balance) FROM depositor d2
                    WHERE d2.branch = d.branch)
    ORDER BY d.branch, d.account_no;

    -- Customers with total loans exceeding 150000
    SELECT customer_id, cust_name FROM customer
    WHERE customer_id IN (
        SELECT customer_id FROM borrower GROUP BY customer_id
        HAVING SUM(loan_amount) > 150000
    ) ORDER BY customer_id;

    -- Customers with an account and loan at the same branch
    SELECT c.customer_id, c.cust_name FROM customer c
    WHERE EXISTS (
        SELECT 1 FROM depositor d
        WHERE d.customer_id = c.customer_id
        AND EXISTS (SELECT 1 FROM borrower b
                    WHERE b.customer_id = c.customer_id AND b.branch = d.branch)
    ) ORDER BY c.customer_id;

    -- Total account balance per customer, including zero for nonholders
    SELECT c.customer_id, c.cust_name,
        COALESCE((SELECT SUM(d.balance) FROM depositor d
                    WHERE d.customer_id = c.customer_id),0) AS total_balance
    FROM customer c ORDER BY c.customer_id;


    -- Branch averages exceeding the overall account average
    SELECT branch, average_balance FROM (
        SELECT branch, AVG(balance) AS average_balance
        FROM depositor GROUP BY branch
    ) AS branch_averages
    WHERE average_balance > (SELECT AVG(balance) FROM depositor)
    ORDER BY branch;

    -- Increase balances for customers with a Delhi loan, then roll back
    BEGIN;
    UPDATE depositor SET balance = balance + 2000
    WHERE customer_id IN (SELECT customer_id FROM borrower WHERE branch = 'Delhi');
    SELECT * FROM depositor ORDER BY account_no;
    ROLLBACK;

    -- Delete backup loans for customers without accounts, then roll back
    BEGIN;
    DELETE FROM borrower_bkp b
    WHERE NOT EXISTS (SELECT 1 FROM depositor d
                    WHERE d.customer_id = b.customer_id);
    SELECT * FROM borrower_bkp ORDER BY loan_no;
    ROLLBACK;



    -- ANY and ALL over an empty subquery
    SELECT
        50000 > ANY (SELECT balance FROM depositor WHERE branch = 'Chennai') AS any_result,
        50000 > ALL (SELECT balance FROM depositor WHERE branch = 'Chennai') AS all_result;
    -- ANY is false: there is no qualifying comparison.
    -- ALL is true: there is no comparison that violates the condition.
