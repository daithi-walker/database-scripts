CREATE TABLE dual (dummy STRING);

load data local inpath '/home/hadoop/dual.txt' overwrite into table dual;

SELECT * from dual;