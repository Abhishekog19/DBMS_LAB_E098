use abcd;

create table student3(
nam varchar(50),
sapid integer primary key not null ,
mobilenumber varchar(15),
email  varchar(30)
);


select * from student3;

insert into student3(nam,sapid,mobilenumber,email) values('hi',1231,8355897322,'hello@gmail.com')
