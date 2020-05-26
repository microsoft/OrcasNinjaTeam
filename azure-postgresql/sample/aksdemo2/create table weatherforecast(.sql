create table weatherforecast(
    id  int PRIMARY KEY UNIQUE,
    day date,
    tempf int,
    tempc int,
    summary varchar(50)
);