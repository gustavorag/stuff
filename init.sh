#!/bin/bash
set -e

mysql --protocol=socket -uroot -p$MYSQL_ROOT_PASSWORD <<EOSQL

CREATE USER 'zix-user'@'%' IDENTIFIED BY '$ZIX_USER_PASSWORD';

DROP DATABASE IF EXISTS vendor_usage;
CREATE DATABASE vendor_usage;

USE vendor_usage;

CREATE TABLE vendor (
  id SMALLINT UNSIGNED PRIMARY KEY,
  vendor_name VARCHAR(255),
  c_date DATE not null DEFAULT DATE(NOW()),
  update_date TIMESTAMP
);

CREATE TABLE source (
 id SMALLINT UNSIGNED PRIMARY KEY,
 name TEXT NOT NULL,
 frequency VARCHAR(20),
 vendor_id SMALLINT UNSIGNED not null,
 CONSTRAINT chk_Frequency CHECK (frequency IN ('DAILY', 'WEEKLY', 'MONTHLY'))
);

# file_checksum BINARY(36) PRIMARY KEY,
CREATE TABLE file (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) not null,
  start_date DATE not null,
  end_date DATE not null,
  update_date TIMESTAMP not null,
  status VARCHAR(20) not null DEFAULT 'NEW',
  source_id SMALLINT UNSIGNED not null,
  vendor_id SMALLINT UNSIGNED not null,
  CONSTRAINT chk_Status CHECK (status IN ('NEW', 'PREPROCESSING', 'READY', 'ERROR', 'LOADING', 'ARCHIVED'))
);

CREATE TABLE zix_usage(
   sender_domain VARCHAR(255) not null,
   count INT not null DEFAULT 0,
   file_id INT UNSIGNED not null,
   CONSTRAINT pk_zix_usage PRIMARY KEY (sender_domain, file_id)
 );

# Creating the constraints

ALTER TABLE file ADD CONSTRAINT fk_file_source FOREIGN KEY (source_id) REFERENCES source (id);
ALTER TABLE file ADD CONSTRAINT fk_file_vendor FOREIGN KEY (vendor_id) REFERENCES vendor (id);
ALTER TABLE source ADD CONSTRAINT fk_source_vendor FOREIGN KEY (vendor_id) REFERENCES vendor (id);
ALTER TABLE zix_usage ADD CONSTRAINT fk_zix_file FOREIGN KEY (file_id) REFERENCES file (id);

insert into vendor(id, vendor_name, c_date) values( 1, 'Zix', '2011-01-01 08:00:00');
insert into vendor(id, vendor_name, c_date) values( 2, 'Fusemail', '2010-02-01 08:00:00');
insert into vendor(id, vendor_name, c_date) values( 3, 'Google', '2015-05-01 08:00:00');
insert into vendor(id, vendor_name, c_date) values( 4, 'Proofpoint', '2014-10-01 08:00:00');

insert into source(id, name, frequency, vendor_id) values (1, "zix-cluster-1", 'DAILY', 1);
insert into source(id, name, frequency, vendor_id) values (2, "zix-cluster-2", 'DAILY', 1);
insert into source(id, name, frequency, vendor_id) values (3, "fusemail-endpoint", 'DAILY', 2);
insert into source(id, name, frequency, vendor_id) values (4, "Google-endpoint", 'WEEKLY', 3);
insert into source(id, name, frequency, vendor_id) values (5, "proofpoint-us", 'MONTHLY', 4);
insert into source(id, name, frequency, vendor_id) values (6, "proofpoint-eu", 'MONTHLY', 4);

insert into file(id, name, start_date, end_date, update_date, status, source_id, vendor_id)
values( 1, "file1", '2018-10-30', '2018-10-30', null,'NEW', 1, 1);
insert into file(id, name, start_date, end_date, update_date, status, source_id, vendor_id)
values( 2, "file2", '2018-10-29', '2018-10-29', null,'PREPROCESSING', 2, 1);
insert into file(id, name, start_date, end_date, update_date, status, source_id, vendor_id)
values( 3, "file3", '2018-10-27', '2018-10-28', null,'READY', 3, 2);
insert into file(id, name, start_date, end_date, update_date, status, source_id, vendor_id)
values( 4, "file4", '2018-10-05', '2018-10-11', null,'ARCHIVED', 4, 3);
insert into file(id, name, start_date, end_date, update_date, status, source_id, vendor_id)
values( 5, "file5", '2018-10-12', '2018-10-18', null,'ERROR', 4, 3);
insert into file(id, name, start_date, end_date, update_date, status, source_id, vendor_id)
values( 6, "file6", '2018-10-19', '2018-10-25', null,'ARCHIVED', 4, 3);
insert into file(id, name, start_date, end_date, update_date, status, source_id, vendor_id)
values( 7, "file7", '2018-09-01', '2018-09-30', null,'ARCHIVED', 5, 4);
insert into file(id, name, start_date, end_date, update_date, status, source_id, vendor_id)
values( 8, "file8", '2018-10-01', '2018-10-31', null,'ARCHIVED', 5, 4);

# TODAY IS 2018-11-01

GRANT SELECT, INSERT, UPDATE ON vendor_usage.* TO 'zix-user'@'%';

ALTER TABLE file DROP CONSTRAINT chk_Status;
ALTER TABLE file ADD CONSTRAINT chk_Status CHECK (status IN ('NEW', 'PREPROCESSING', 'READY', 'ERROR', 'LOADING', 'ARCHIVED'));


EOSQL
#
# mysql --protocol=socket -uroot -p$MYSQL_ROOT_PASSWORD -D vendor_usage < /tempFolder/zix_usage_db.sql
