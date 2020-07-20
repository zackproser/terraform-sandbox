create database golang_webservice; 

use golang_webservice; 

create table visits(hits bigint not null); 

insert into visits (hits) values (0); 

create user 'golang'@'%' IDENTIFIED BY 'gocrazy999'; 

grant all privileges on golang_webservice.* to 'golang'@'%';
