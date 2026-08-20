create database company114;
use company114;

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

create table dep(
Dname varchar(50) not null,
Dnum integer primary key not null,
mgrstartdate date,
mgrssn integer not null 
);

create table dep_loc(
Dloc varchar(50)  not null,
Dnum integer not null
);

create table proj(
Pname varchar(50) not null,
Pnum integer primary key not null,
Ploc varchar(50),
Dnum integer not null 
);

create table works_on(
essn integer not null,
hours integer not null ,
pnum integer not null 
);

create table dependant(
depname varchar(20) not null,
essn integer not null,
bdate date,
address varchar(50),
relationship varchar(20),
sex varchar(10)
);
alter table employee
add foreign key(Dnum) references dep(Dnum);

alter table dep
add foreign key(mgrssn) references employee(ssn);

alter table dep_loc
add foreign key(Dnum) references dep(Dnum);

alter table dep_loc
add primary key(Dnum, Dloc);

alter table proj
add foreign key(Dnum) references dep(Dnum);

alter table works_on
add foreign key(Pnum) references proj(Pnum);

alter table works_on
add foreign key(essn) references employee(ssn);

alter table works_on
add primary key(essn, Pnum);

alter table dependant
add foreign key(essn) references employee(ssn);

alter table dependant
add primary key(essn, depname);

SET FOREIGN_KEY_CHECKS = 0;
INSERT INTO employee
(fname,minit,lname,ssn,bdate,address,salary,superssn,Dnum,sex)
VALUES
('John','A','Smith',1001,'1985-03-15','New York',70000,NUll,1,'M'),
('Alice','B','Johnson',1002,'1990-07-21','California',65000,1001,2,'F'),
('Robert','C','Brown',1003,'1988-01-10','Texas',60000,1001,3,'M'),
('Emily','D','Davis',1004,'1992-11-05','Florida',62000,1002,2,'F'),
('Michael','E','Wilson',1005,'1987-06-18','Chicago',68000,1003,1,'M');

INSERT INTO dep
(Dname,Dnum,mgrstartdate,mgrssn)
VALUES
('HR',1,'2020-01-01',1001),
('Finance',2,'2019-06-15',1002),
('IT',3,'2021-03-20',1003),
('Marketing',4,'2022-08-10',1004),
('Sales',5,'2018-11-25',1005);

INSERT INTO dep_loc
(Dloc,Dnum)
VALUES
('New York',1),
('California',2),
('Texas',3),
('Florida',4),
('Chicago',5);

INSERT INTO proj
(Pname,Pnum,Ploc,Dnum)
VALUES
('Payroll System',101,'New York',2),
('Website Upgrade',102,'California',3),
('Recruitment Portal',103,'Texas',1),
('Marketing Campaign',104,'Florida',4),
('Sales Dashboard',105,'Chicago',5);

INSERT INTO works_on
(essn,hours,pnum)
VALUES
(1001,20,103),
(1002,35,101),
(1003,40,102),
(1004,25,104),
(1005,30,105);

INSERT INTO dependant
(depname,essn,bdate,address,relationship,sex)
VALUES
('Anna',1001,'2012-05-10','New York','Daughter','F'),
('David',1002,'2015-07-18','California','Son','M'),
('Sophia',1003,'1989-09-22','Texas','Spouse','F'),
('James',1004,'2018-02-14','Florida','Son','M'),
('Olivia',1005,'1991-12-01','Chicago','Spouse','F');
SET FOREIGN_KEY_CHECKS = 1;

Show Tables;
DESC Employee;
DESC dep;
DESC dep_loc;
DESC proj;
DESC works_on;
DESC dependant;

select * from employee;
select * from dep;
select * from dep_loc;
select * from proj;
select * from works_on;
select * from dependant;


select * from employee;
select ssn, fname, lname from employee;
select  fname, ssn, lname from employee;
select  fname, ssn, lname from employee order by ssn;
select ssn, fname, lname from employee order by fname;

select  fname, lname, salary from employee ;
select  fname, lname, salary from employee Where salary >50000;
select  fname, lname, salary from employee Where salary Between 50000 and 65000;

select  fname, lname, sex from employee ;
select  fname, lname, sex from employee Where sex = 'M';
select  fname, lname, sex from employee Where sex = 'F';
select* from employee Where sex = 'F';
select* from employee Where sex = 'M';

select  fname, lname, dnum from employee where dnum = 2;
select* from employee Where dnum = 2;

insert into proj Values
('product2', 12, 'bangalore', 5);

insert into employee Values
('Roberta', 'D', 'Black', 1006, '1989-02-11', 'Dallas', 90000, 1004, 3, 'F');

select * from proj;
select Pnum, Pname from proj;
select Pnum, Pname from proj order by Pnum;
select Pnum, Pname from proj order by Pname;

select * from dep;
select * from employee;
select * from employee where Dnum =(Select Dnum from dep where dname ='HR' and mgrssn = 1001);
select * from employee where Dnum =(Select Dnum from dep where dname ='IT' ) and sex = 'M';
select * from employee where Dnum =(Select Dnum from dep where dname ='IT' ) order by salary;
