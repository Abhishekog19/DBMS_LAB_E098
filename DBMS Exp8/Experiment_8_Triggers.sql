
-- EXPERIMENT 8: TRIGGERS 


DROP DATABASE IF EXISTS db8;
CREATE DATABASE db8;
USE db8;


CREATE TABLE depositor (
    account_no INTEGER PRIMARY KEY,
    cust_name  VARCHAR(60) NOT NULL,
    balance    NUMERIC(12,2) NOT NULL CHECK (balance >= 0),
    branch     VARCHAR(40) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE depositor_bkp (
    account_no INTEGER PRIMARY KEY,
    cust_name  VARCHAR(60) NOT NULL,
    balance    NUMERIC(12,2) NOT NULL,
    branch     VARCHAR(40) NOT NULL,
    copied_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE department (
    dnumber   INTEGER PRIMARY KEY,
    dname     VARCHAR(40) NOT NULL,
    total_sal NUMERIC(14,2) NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE employee (
    emp_id   INTEGER PRIMARY KEY,
    emp_name VARCHAR(60) NOT NULL,
    salary   NUMERIC(10,2) NOT NULL CHECK (salary > 0),
    dno      INTEGER,
    FOREIGN KEY (dno) REFERENCES department(dnumber)
) ENGINE=InnoDB;

CREATE TABLE employee_audit (
    audit_id   BIGINT AUTO_INCREMENT PRIMARY KEY,
    emp_id     INTEGER NOT NULL,
    operation  VARCHAR(6) NOT NULL,
    old_salary NUMERIC(10,2),
    new_salary NUMERIC(10,2),
    old_dno    INTEGER,
    new_dno    INTEGER,
    changed_by VARCHAR(288) NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;


--  DATA

INSERT INTO depositor VALUES
(1001,'Asha',10000,'Mumbai'),
(1002,'Rahul',30000,'Pune');

INSERT INTO department (dnumber,dname) VALUES
(1,'General'),(10,'Engineering'),(20,'Sales'),(30,'HR');

INSERT INTO employee VALUES
(101,'Asha',60000,10),
(102,'Rahul',85000,10),
(103,'Neha',45000,20),
(104,'Priya',50000,30);

-- Initialize department payroll totals from the employees just inserted.

UPDATE department d
SET total_sal = COALESCE(
    (SELECT SUM(e.salary) FROM employee e WHERE e.dno = d.dnumber), 0);
COMMIT;

-- Display master tables

SELECT * FROM depositor ORDER BY account_no;
SELECT * FROM department ORDER BY dnumber;
SELECT * FROM employee ORDER BY emp_id;


-- BEFORE INSERT – default NULL balance to 5000

DELIMITER $$
CREATE TRIGGER trg_depositor_default_balance
BEFORE INSERT ON depositor
FOR EACH ROW
BEGIN
    IF NEW.balance IS NULL THEN
        SET NEW.balance = 5000;
    END IF;
END$$
DELIMITER ;

-- Test NULL replacement and preservation of explicit balance
INSERT INTO depositor VALUES
(1003,'Neha',NULL,'Mumbai'),
(1004,'Imran',20000,'Pune');
SELECT * FROM depositor ORDER BY account_no;


-- AFTER INSERT – copy new depositor into backup table

DELIMITER $$
CREATE TRIGGER trg_depositor_copy
AFTER INSERT ON depositor
FOR EACH ROW
BEGIN
    INSERT INTO depositor_bkp (account_no,cust_name,balance,branch)
    VALUES (NEW.account_no,NEW.cust_name,NEW.balance,NEW.branch);
END$$
DELIMITER ;

-- Test interaction of BEFORE and AFTER INSERT triggers
INSERT INTO depositor VALUES
(1005,'Priya',NULL,'Delhi'),
(1006,'Vivek',40000,'Mumbai');
SELECT * FROM depositor      WHERE account_no IN (1005,1006) ORDER BY account_no;
SELECT * FROM depositor_bkp  ORDER BY account_no;


-- Q6: BEFORE UPDATE – default NULL dno to 1 (General)
-- NOTE: must be created BEFORE the payroll/audit AFTER UPDATE triggers only so that the ordering is explicit; 
--  MySQL actually runs all BEFORE triggers before all AFTER ones.

DELIMITER $$
CREATE TRIGGER trg_employee_default_department
BEFORE UPDATE ON employee
FOR EACH ROW
BEGIN
    IF NEW.dno IS NULL THEN
        SET NEW.dno = 1;
    END IF;
END$$
DELIMITER ;

--  Maintain department payroll totals on INSERT/UPDATE/DELETE

DELIMITER $$
CREATE TRIGGER trg_employee_payroll_insert
AFTER INSERT ON employee
FOR EACH ROW
BEGIN
    IF NEW.dno IS NOT NULL THEN
        UPDATE department
           SET total_sal = total_sal + NEW.salary
         WHERE dnumber = NEW.dno;
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_employee_payroll_update
AFTER UPDATE ON employee
FOR EACH ROW
BEGIN
    IF OLD.dno IS NOT NULL THEN
        UPDATE department
           SET total_sal = total_sal - OLD.salary
         WHERE dnumber = OLD.dno;
    END IF;
    IF NEW.dno IS NOT NULL THEN
        UPDATE department
           SET total_sal = total_sal + NEW.salary
         WHERE dnumber = NEW.dno;
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_employee_payroll_delete
AFTER DELETE ON employee
FOR EACH ROW
BEGIN
    IF OLD.dno IS NOT NULL THEN
        UPDATE department
           SET total_sal = total_sal - OLD.salary
         WHERE dnumber = OLD.dno;
    END IF;
END$$
DELIMITER ;


-- Audit INSERT / UPDATE / DELETE on employee

DELIMITER $$
CREATE TRIGGER trg_employee_audit_insert
AFTER INSERT ON employee
FOR EACH ROW
BEGIN
    INSERT INTO employee_audit
        (emp_id,operation,old_salary,new_salary,old_dno,new_dno,changed_by)
    VALUES
        (NEW.emp_id,'INSERT',NULL,NEW.salary,NULL,NEW.dno,USER());
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_employee_audit_update
AFTER UPDATE ON employee
FOR EACH ROW
BEGIN
    INSERT INTO employee_audit
        (emp_id,operation,old_salary,new_salary,old_dno,new_dno,changed_by)
    VALUES
        (NEW.emp_id,'UPDATE',OLD.salary,NEW.salary,OLD.dno,NEW.dno,USER());
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_employee_audit_delete
AFTER DELETE ON employee
FOR EACH ROW
BEGIN
    INSERT INTO employee_audit
        (emp_id,operation,old_salary,new_salary,old_dno,new_dno,changed_by)
    VALUES
        (OLD.emp_id,'DELETE',OLD.salary,NULL,OLD.dno,NULL,USER());
END$$
DELIMITER ;


-- Insert an employee; inspect payroll + audit

INSERT INTO employee VALUES (105,'Vivek',55000,10);
SELECT * FROM department     WHERE dnumber = 10;
SELECT * FROM employee_audit ORDER BY audit_id;


-- Update salary; inspect OLD/NEW in audit

UPDATE employee SET salary = 65000 WHERE emp_id = 101;
SELECT * FROM department     WHERE dnumber = 10;
SELECT * FROM employee_audit WHERE emp_id = 101 ORDER BY audit_id;


-- NUL dno corrected by BEFORE UPDATE trigger

UPDATE employee SET dno = NULL WHERE emp_id = 105;
SELECT * FROM employee   WHERE emp_id = 105;
SELECT * FROM department ORDER BY dnumber;


-- Delete an employee; payroll + retained audit history

DELETE FROM employee WHERE emp_id = 103;
SELECT * FROM department     WHERE dnumber = 20;
SELECT * FROM employee_audit WHERE emp_id = 103 ORDER BY audit_id;


-- Reject salary reductions (business rule)

DELIMITER $$
CREATE TRIGGER trg_employee_no_salary_reduction
BEFORE UPDATE ON employee
FOR EACH ROW
BEGIN
    IF NEW.salary < OLD.salary THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Salary reduction is not permitted';
    END IF;
END$$
DELIMITER ;


-- Test rejection without aborting the script
-- NOTE: DDL (CREATE/DROP PROCEDURE) causes an implicit commit,
--       so START TRANSACTION must come AFTER the CREATE PROCEDURE.

DROP PROCEDURE IF EXISTS test_salary_reduction;
DELIMITER $$
CREATE PROCEDURE test_salary_reduction()
BEGIN
    DECLARE rejection_seen BOOLEAN DEFAULT FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLSTATE '45000'
            SET rejection_seen = TRUE;
        UPDATE employee SET salary = 60000 WHERE emp_id = 101;
    END;
    SELECT rejection_seen AS salary_reduction_rejected;
END$$
DELIMITER ;

START TRANSACTION;
CALL test_salary_reduction();
ROLLBACK;

DROP PROCEDURE test_salary_reduction;
SELECT emp_id, salary FROM employee WHERE emp_id = 101;


-- Triggers participate in transaction rollback

START TRANSACTION;
INSERT INTO employee VALUES (106,'Meera',70000,30);
SELECT * FROM department     WHERE dnumber = 30;
SELECT * FROM employee_audit WHERE emp_id = 106;

ROLLBACK;
SELECT * FROM department     WHERE dnumber = 30;
SELECT * FROM employee_audit WHERE emp_id = 106;

-- Verify stored payroll totals

SELECT d.dnumber, d.dname, d.total_sal AS stored_total,
       COALESCE(SUM(e.salary),0) AS calculated_total,
       d.total_sal = COALESCE(SUM(e.salary),0) AS totals_match
FROM department d
LEFT JOIN employee e ON e.dno = d.dnumber
GROUP BY d.dnumber, d.dname, d.total_sal
ORDER BY d.dnumber;


-- List trigger definitions

SELECT EVENT_OBJECT_TABLE AS table_name, TRIGGER_NAME,
       ACTION_TIMING, EVENT_MANIPULATION, ACTION_STATEMENT
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
ORDER BY EVENT_OBJECT_TABLE, TRIGGER_NAME;


-- Drop the copy trigger and verify copying stops

DROP TRIGGER trg_depositor_copy;
INSERT INTO depositor VALUES (1007,'Meera',NULL,'Delhi');
SELECT * FROM depositor     WHERE account_no = 1007;
SELECT * FROM depositor_bkp WHERE account_no = 1007;


-- Inspect the remaining depositor triggers

SHOW TRIGGERS WHERE `Table` = 'depositor';