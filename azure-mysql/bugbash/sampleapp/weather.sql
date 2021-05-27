create database weather;
use weather;
create table weatherhistory(
    id  int PRIMARY KEY UNIQUE AUTO_INCREMENT,
    day date,
    tempf int,
    tempc int,
    summary varchar(50)
);
