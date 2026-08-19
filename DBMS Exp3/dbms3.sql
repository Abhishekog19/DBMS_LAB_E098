create database C114;
use C114;

create table employee(
fname varchar(20),
minit varchar(10),
lname varchar(20),
ssn integer primary key not null,
bdate date,
address varchar(50),
salary integer not null,
superssn integer,
Dnum integer,
sex varchar(10)
);

INSERT INTO employee
(fname,minit,lname,ssn,bdate,address,salary,superssn,Dnum,sex)
VALUES
('John','A','Smith',1001,'1985-03-15','New York',70000,NUll,1,'M'),
('Alice','B','Johnson',1002,'1990-07-21','California',65000,1001,2,'F'),
('Robert','C','Brown',1003,'1988-01-10','Texas',60000,1001,3,'M'),
('Emily','D','Davis',1004,'1992-11-05','Florida',62000,1002,2,'F'),
('Michael','E','Wilson',1005,'1987-06-18','Chicago',68000,1003,1,'M'),
('Roberta', 'D', 'Black', 1006, '1989-02-11', 'Dallas', 90000, 1004, 3, 'F');

select*from employee;
update employee set salary = 68000 where ssn = 1006;
update employee set Dnum = 3 where ssn = 1002;
