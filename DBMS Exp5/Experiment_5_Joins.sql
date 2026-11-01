
-- EXPERIMENT NO. 5: SQL JOINS
-- Setup: create database and tables

DROP DATABASE IF EXISTS db5;
CREATE DATABASE db5;
USE db5;

-- Tables for UNION and UNION ALL

CREATE TABLE borrower (
    cust_name VARCHAR(50),
    loan_number VARCHAR(10)
);

INSERT INTO borrower VALUES
('Amit', 'L01'),
('Priya', 'L02'),
('Rahul', 'L03');

CREATE TABLE depositor (
    cust_name VARCHAR(50),
    account_number VARCHAR(10)
);

INSERT INTO depositor VALUES
('Amit', 'A100'),
('Sneha', 'A101'),
('Priya', 'A102');

-- Tables for INNER, LEFT and RIGHT JOIN

CREATE TABLE customer (
    customer_id INT PRIMARY KEY,
    cname VARCHAR(50)
);

INSERT INTO customer VALUES
(1, 'Amit'),
(2, 'Priya'),
(3, 'Rahul');

CREATE TABLE order1 (
    id INT,
    order_number INT PRIMARY KEY
);

INSERT INTO order1 VALUES
(1, 101),
(2, 102),
(2, 103),
(99, 104);

-- INITIAL STATE OF TABLES

SELECT * FROM borrower;
SELECT * FROM depositor;
SELECT * FROM customer;
SELECT * FROM order1;

-- 1. Customers having loan or account or both,
--    eliminating duplicates

SELECT cust_name
FROM borrower
UNION
SELECT cust_name
FROM depositor;

-- 2. Customers having loan or account or both,
--    without eliminating duplicates

SELECT cust_name
FROM borrower
UNION ALL
SELECT cust_name
FROM depositor;

-- 3. List customers who have placed orders

SELECT cname, order_number
FROM customer
INNER JOIN order1
ON order1.id = customer.customer_id;

-- 4. List all customers, whether they placed orders or not

SELECT cname, order_number
FROM customer
LEFT OUTER JOIN order1
ON order1.id = customer.customer_id;

-- 5. List all orders, whether they were placed by customers or not

SELECT cname, order_number
FROM customer
RIGHT OUTER JOIN order1
ON order1.id = customer.customer_id;
