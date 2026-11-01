-- EXPERIMENT 6: VIEWS IN POSTGRESQL

CREATE DATABASE db6;  -- your database name 
USE db6;              -- dont forget this -- yo umust ensure your default DB is this


CREATE TABLE department (
    dept_id INTEGER PRIMARY KEY,
    dept_name VARCHAR(40) NOT NULL UNIQUE,
    location VARCHAR(40) NOT NULL
);
CREATE TABLE employee (
    emp_id INTEGER PRIMARY KEY,
    emp_name VARCHAR(60) NOT NULL,
    dept_id INTEGER REFERENCES department(dept_id),
    designation VARCHAR(50) NOT NULL,
    salary NUMERIC(10,2) NOT NULL CHECK (salary > 0),
    joining_date DATE NOT NULL
);

-- DATA INSERTION
INSERT INTO department VALUES
(10,'Engineering','Mumbai'), (20,'Sales','Pune'),
(30,'HR','Mumbai'), (40,'Research','Bengaluru');

INSERT INTO employee VALUES
(101,'Asha',10,'Engineer',60000,'2022-07-01'),
(102,'Rahul',10,'Senior Engineer',85000,'2020-03-15'),
(103,'Neha',20,'Sales Executive',45000,'2023-01-10'),
(104,'Imran',20,'Sales Manager',75000,'2021-06-20'),
(105,'Priya',30,'HR Executive',50000,'2022-11-05'),
(106,'Vivek',10,'Engineer',55000,'2024-02-12'),
(107,'Meera',30,'HR Manager',70000,'2019-09-01'),
(108,'Karan',NULL,'Trainee',30000,'2025-01-15');

--  Display master tables
SELECT * FROM department ORDER BY dept_id;
SELECT * FROM employee ORDER BY emp_id;

-- Create an employee directory excluding salary (column restriction)
-- Access security also requires restricting privileges on the base table.
CREATE VIEW v_employee_directory AS
SELECT emp_id, emp_name, dept_id, designation FROM employee;
SELECT * FROM v_employee_directory ORDER BY emp_id;

-- Create a view of Engineering employees (row restriction)
CREATE VIEW v_engineering_employees AS
SELECT emp_id, emp_name, dept_id, designation, salary, joining_date
FROM employee WHERE dept_id = 10;
SELECT * FROM v_engineering_employees ORDER BY emp_id;

-- Find Engineering employees earning at least 60000
SELECT emp_id, emp_name, salary FROM v_engineering_employees
WHERE salary >= 60000 ORDER BY salary DESC;

-- Simplify a join using a view; retain unassigned employees
CREATE VIEW v_employee_department AS
SELECT e.emp_id, e.emp_name, e.designation, d.dept_name, d.location
FROM employee e LEFT JOIN department d ON e.dept_id = d.dept_id;
SELECT * FROM v_employee_department ORDER BY emp_id;


-- Create a view with a calculated annual salary
CREATE VIEW v_salary_details AS
SELECT emp_id, emp_name, salary AS monthly_salary,
       salary * 12 AS annual_salary FROM employee;
SELECT * FROM v_salary_details ORDER BY emp_id;

-- Create a department summary, including departments with no employees
CREATE VIEW v_department_summary AS
SELECT d.dept_id, d.dept_name, COUNT(e.emp_id) AS employee_count,
       COALESCE(SUM(e.salary),0) AS total_monthly_salary,
       ROUND(AVG(e.salary),2) AS average_monthly_salary
FROM department d LEFT JOIN employee e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;
SELECT * FROM v_department_summary ORDER BY dept_id;
-- Engineering: 3, 200000, 66666.67; Research: 0, 0, NULL.

-- Demonstrate that ordinary views immediately reflect base-table changes
BEGIN;
UPDATE employee SET salary = 65000 WHERE emp_id = 101;
SELECT * FROM v_salary_details WHERE emp_id = 101;
ROLLBACK;

-- Update a base-table row through an automatically updatable simple view
BEGIN;
UPDATE v_engineering_employees SET salary = salary + 5000 WHERE emp_id = 106;
SELECT emp_id, emp_name, salary FROM employee WHERE emp_id = 106;
ROLLBACK;

-- Insert and delete a row through a simple view
BEGIN;
INSERT INTO v_engineering_employees VALUES
(109,'Riya',10,'Engineer',58000,'2025-06-01');
SELECT * FROM employee WHERE emp_id = 109;
DELETE FROM v_engineering_employees WHERE emp_id = 109;
SELECT * FROM employee WHERE emp_id = 109;
ROLLBACK;

-- Without CHECK OPTION an update can move a row outside the view
BEGIN;
UPDATE v_engineering_employees SET dept_id = 20 WHERE emp_id = 106;
SELECT * FROM employee WHERE emp_id = 106;
SELECT * FROM v_engineering_employees WHERE emp_id = 106;
-- Vivek still exists in employee, but is absent from the Engineering view.
ROLLBACK;

-- Create a view WITH CHECK OPTION
CREATE VIEW v_engineering_checked AS
SELECT emp_id, emp_name, dept_id, designation, salary, joining_date
FROM employee WHERE dept_id = 10 WITH CHECK OPTION;
BEGIN;
UPDATE v_engineering_checked SET salary = 62000 WHERE emp_id = 101;
SELECT * FROM v_engineering_checked WHERE emp_id = 101;
ROLLBACK;


-- Replace a view definition by appending an output column
-- Existing column names, order, and types must remain unchanged here.
CREATE OR REPLACE VIEW v_employee_directory AS
SELECT emp_id, emp_name, dept_id, designation, joining_date FROM employee;
SELECT * FROM v_employee_directory ORDER BY emp_id;


-- Drop a view and verify that its base table remains
DROP VIEW v_employee_directory;
SELECT * FROM employee ORDER BY emp_id;


-- NOT required for journal 
-- this below section is for students practice.. more handson 

-- STUDENT PRACTICE QUESTIONS

-- P01: Create a view showing only employee names and designations.
-- P02: Create a view of employees earning between 50000 and 75000, inclusive.
-- P03: Create a view of employees who joined on or after 1 January 2023.
-- P04: Create a view showing employee names and department names for departments located in Mumbai.
-- P05: Create a view listing departments that have no employees.
-- P06: Create a department summary view containing employee count, minimum salary, and maximum salary. Include empty departments.
-- P07: Create a view of employees earning at least 60000 WITH CHECK OPTION. Test an update that reduces a visible employee salary below 60000.
-- P08: Insert a new Engineering employee through a simple view. Verify the base-table row, then roll back the transaction.
-- P09: Using a transaction, change an employee salary in the base table and show how an annual-salary view reflects the change. Roll back afterward.
-- P10: Compare an update through a simple employee view with an attempted update through an aggregate view. Explain the difference.
-- P11: Use CREATE OR REPLACE VIEW to append a column to one of your practice views, preserving its existing output columns.
-- P12: Drop one practice view and demonstrate that its base-table records remain available.



-- Names and designations only
CREATE VIEW p_employee_roles AS
SELECT emp_name, designation FROM employee;
SELECT * FROM p_employee_roles ORDER BY emp_name;

-- Salaries between 50000 and 75000 inclusive
CREATE VIEW p_salary_range AS
SELECT emp_id, emp_name, salary FROM employee
WHERE salary BETWEEN 50000 AND 75000;
SELECT * FROM p_salary_range ORDER BY emp_id;

-- Employees joining on or after 1 January 2023
CREATE VIEW p_recent_joiners AS
SELECT emp_id, emp_name, joining_date FROM employee
WHERE joining_date >= DATE '2023-01-01';
SELECT * FROM p_recent_joiners ORDER BY emp_id;

-- Employees in departments located in Mumbai
CREATE VIEW p_mumbai_employees AS
SELECT e.emp_id, e.emp_name, d.dept_name
FROM employee e JOIN department d ON e.dept_id = d.dept_id
WHERE d.location = 'Mumbai';
SELECT * FROM p_mumbai_employees ORDER BY emp_id;

-- Departments without employees
CREATE VIEW p_empty_departments AS
SELECT d.dept_id, d.dept_name FROM department d
WHERE NOT EXISTS (SELECT 1 FROM employee e WHERE e.dept_id = d.dept_id);
SELECT * FROM p_empty_departments ORDER BY dept_id;

-- Department counts and salary extremes, including empty departments
CREATE VIEW p_department_extremes AS
SELECT d.dept_id, d.dept_name, COUNT(e.emp_id) AS employee_count,
       MIN(e.salary) AS minimum_salary, MAX(e.salary) AS maximum_salary
FROM department d LEFT JOIN employee e ON e.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name;
SELECT * FROM p_department_extremes ORDER BY dept_id;
-- Research has count 0 and NULL minimum/maximum salary.


-- Insert through an Engineering view and roll back
BEGIN;
INSERT INTO v_engineering_employees VALUES
(110,'Sana',10,'Engineer',61000,DATE '2025-07-01');
SELECT * FROM employee WHERE emp_id = 110;
ROLLBACK;
SELECT * FROM employee WHERE emp_id = 110;
-- No row remains after rollback.

-- Observe an annual salary view after a base-table update
BEGIN;
UPDATE employee SET salary = 68000 WHERE emp_id = 101;
SELECT * FROM v_salary_details WHERE emp_id = 101;
-- Annual salary is 816000 inside this transaction.
ROLLBACK;


-- Append designation while retaining the existing output columns
CREATE OR REPLACE VIEW p_recent_joiners AS
SELECT emp_id, emp_name, joining_date, designation FROM employee
WHERE joining_date >= DATE '2023-01-01';
SELECT * FROM p_recent_joiners ORDER BY emp_id;
-- The appended column here is designation; joining_date was already present.

-- Drop a practice view; base-table records are preserved
DROP VIEW p_employee_roles;
SELECT * FROM employee ORDER BY emp_id;
