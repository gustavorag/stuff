#!/bin/bash
set -e

mysql --protocol=socket -uroot -p$MYSQL_ROOT_PASSWORD <<EOSQL

CREATE USER 'zix-user'@'%' IDENTIFIED BY '$ZIX_USER_PASSWORD';

DROP DATABASE IF EXISTS vendor_usage;
CREATE DATABASE vendor_usage;

USE vendor_usage;

CREATE TABLE source (
 id SERIAL PRIMARY KEY,
 name TEXT NOT NULL
);

CREATE TABLE job (
 id SERIAL PRIMARY KEY,
 source_id BIGINT UNSIGNED NOT NULL,
 created_on TIMESTAMP NOT NULL DEFAULT NOW()
);


CREATE TABLE vendor (
  id MEDIUMINT UNSIGNED PRIMARY KEY,
  vendor_name VARCHAR(255),
  c_date TIMESTAMP not null DEFAULT NOW(),
  update_date TIMESTAMP
);

CREATE TABLE source (
 id SMALLINT UNSIGNED PRIMARY KEY,
 name TEXT NOT NULL,
 frequency VARCHAR(20),
 vendor_id SMALLINT UNSIGNED not null,
 CONSTRAINT chk_Frequency CHECK (frequency IN ('DAILY', 'WEEKLY', 'MONTHLY'))
);

CREATE TABLE reporting (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  start_date TIMESTAMP not null,
  end_date TIMESTAMP not null,
  update_date TIMESTAMP not null,
  status VARCHAR(20) not null DEFAULT "PROCESSING"
  source_id SMALLINT UNSIGNED not null,
  vendor_id SMALLINT UNSIGNED not null,
  CONSTRAINT chk_Status CHECK (frequency IN ('PROCESSING', 'FAILED', 'SUCCESS'))
);

ALTER TABLE job ADD CONSTRAINT fk_source FOREIGN KEY (source_id) REFERENCES source (id) ON DELETE CASCADE;

CREATE TABLE zix_usage(
   sender_address VARCHAR(255) not null,
   recipient_address VARCHAR(255) not null,
   sent_time_stamp TIMESTAMP not null,
   subject VARCHAR(255) not null DEFAULT "",
   police_types VARCHAR(255),
   police_names VARCHAR(255),
   delivery_method VARCHAR(255),
   job_id BIGINT UNSIGNED not null,
   CONSTRAINT fk_job FOREIGN KEY (job_id)
   REFERENCES job (id)
 );

 DELIMITER $$
 DROP FUNCTION IF EXISTS checkDuplicateZix;
 CREATE FUNCTION checkDuplicateZix(p_senderAddress VARCHAR(255),
   p_recipientAddress VARCHAR(255),
   p_sentTimeStamp TIMESTAMP,
   p_jobId BIGINT
 ) RETURNS TINYINT(1)
     DETERMINISTIC
 BEGIN
     DECLARE s TINYINT(1);

     IF EXISTS (
        select * from zix_usage
        WHERE
        sender_address = p_senderAddress AND
        recipient_address = p_recipientAddress AND
        sent_time_stamp = p_sentTimeStamp AND
        job_id <> p_jobId
      )  THEN SET s = 1;
     ELSE SET s = 0;
     END IF;
  RETURN (s);
 END $$;

 ALTER TABLE zix_usage ADD CONSTRAINT check_duplicate CHECK ( 0 = (select checkDuplicateZix(sender_address, recipient_address, sent_time_stamp, job_id)));

 ALTER TABLE zix_usage DROP CONSTRAINT check_duplicate;

  CREATE TABLE file (
    id SERIAL PRIMARY KEY,
    checksum VARCHAR(64) NOT NULL,
    row_count NUMERIC NOT NULL,
    job_id BIGINT UNSIGNED not null,
    CONSTRAINT fk_job_file FOREIGN KEY (job_id)
    REFERENCES job (id)
  );

  CREATE TABLE status (
    id SERIAL PRIMARY KEY,
    created_on TIMESTAMP NOT NULL DEFAULT NOW(),
    is_success BOOLEAN NOT NULL,
    job_id BIGINT UNSIGNED not null,
    CONSTRAINT fk_job_status FOREIGN KEY (job_id)
    REFERENCES job (id)
  );

  insert into source(name) values ("zix-cluster-1");
  insert into source(name) values ("zix-cluster-2");

  insert into job(source_id, created_on) values( 1, '2018-05-01 08:00:00');
  insert into job(source_id, created_on) values( 2, '2018-05-01 08:05:00');
  insert into job(source_id, created_on) values( 1, '2018-05-01 08:10:00');
  insert into job(source_id, created_on) values( 2, '2018-05-01 08:15:00');
  insert into job(source_id, created_on) values( 2, '2018-05-01 08:20:00');

  GRANT SELECT, INSERT ON vendor_usage.zix_usage TO 'zix-user'@'%';

EOSQL

#
# mysql --protocol=socket -uroot -p$MYSQL_ROOT_PASSWORD -D vendor_usage < /tempFolder/zix_usage_db.sql
