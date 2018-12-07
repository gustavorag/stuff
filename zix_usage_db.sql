drop database IF EXISTS vendor_usage;
create database vendor_usage;
use vendor_usage


CREATE TABLE source (
 id SERIAL PRIMARY KEY,
 name TEXT NOT NULL
);

CREATE TABLE job (
 id SERIAL PRIMARY KEY,
 source_id BIGINT UNSIGNED NOT NULL,
 created_on TIMESTAMP NOT NULL DEFAULT NOW()
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

 CREATE FUNCTION checkDuplicateZix(
   p_senderAddress VARCHAR(255),
   p_recipientAddress VARCHAR(255),
   p_sentTimeStamp TIMESTAMP,
   p_jobId BIGINT
 )
 RETURNS TINYINT(1)
 BEGIN
   IF EXISTS (
      select *
      from zix_usage
      WHERE
      sender_address = p_senderAddress AND
      recipient_address = p_recipientAddress AND
      sent_time_stamp = p_sentTimeStamp AND
      job_id <> p_jobId
    ) THEN RETURN 1;
    END IF;
    RETURN 0
  END;

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

  -- JOB 1
  insert into job(source_id, created_on) values( 1, '2018-05-01 08:00:00');
  -- JOB 2
  insert into job(source_id, created_on) values( 2, '2018-05-01 08:05:00');
  -- JOB 3
  insert into job(source_id, created_on) values( 1, '2018-05-01 08:10:00');
  -- JOB 4
  insert into job(source_id, created_on) values( 2, '2018-05-01 08:15:00');
  -- JOB 5
  insert into job(source_id, created_on) values( 2, '2018-05-01 08:20:00');

-- JOB ONE
  insert into file(checksum, row_count, job_id) values("598435d300f6e006933eaccc70354ebbfd", 5, 1);
  insert into zix_usage(sender_address, recipient_address, sent_time_stamp, subject, police_types, police_names, delivery_method, job_id) values("sender1@senderdoman.com", "receiver2@receiverdoman.com", '2018-04-01 10:05:20', "Hello 1", "Zix encrypt", "", "Zix port", 1);
  insert into zix_usage(sender_address, recipient_address, sent_time_stamp, subject, police_types, police_names, delivery_method, job_id) values("sender1@senderdoman.com", "receiver2@receiverdoman.com", '2018-04-01 11:15:05', "Hello 2", "Zix encrypt", "", "Zix port", 1);
  insert into zix_usage(sender_address, recipient_address, sent_time_stamp, subject, police_types, police_names, delivery_method, job_id) values("sender2@senderdoman.com", "receiver1@receiverdoman.com", '2018-04-02 08:05:10', "Hello 3", "Zix encrypt", "", "Zix port", 1);
  insert into zix_usage(sender_address, recipient_address, sent_time_stamp, subject, police_types, police_names, delivery_method, job_id) values("sender3@senderdoman.com", "receiver3@receiverdoman.com", '2018-04-03 19:57:30', "Hello 4", "Zix encrypt", "", "Zix port", 1);
  insert into zix_usage(sender_address, recipient_address, sent_time_stamp, subject, police_types, police_names, delivery_method, job_id) values("sender2@senderdoman.com", "receiver4@receiverdoman.com", '2018-04-04 15:44:28', "Hello 5", "Zix encrypt", "", "Zix port", 1);
  insert into status(created_on, is_success, job_id) values('2018-05-01 08:05:20', 1, 1);
--
-- -- JOB 2 NO FILE
-- insert into status(created_on, is_success, job_id) values('2018-05-01 08:05:20', 1, 2);
--
-- -- JOB 3 Error AFTER file
-- insert into file(checksum, row_count, job_id) values("5939845d0f6e006933eacss70354eopwb", 0, 3);
-- insert into status(created_on, is_success, job_id) values('2018-05-01 08:14:25', 0, 3);
--
-- --JOB 4  Error BEFORE file
-- insert into status(created_on, is_success, job_id) values('2018-05-01 08:15:53', 0, 4);
--
-- --JOB 5 Still looking for a file. Therefore, it has no register in file or status tables.
--
-- -- Gets jobs that failed before get a file. It should return job 4
-- select j.id as "Failed before get a file"
-- from job j
-- left join file f on j.id = f.job_id
-- join status s on j.id = s.job_id
-- where s.is_success = 0 AND f.job_id is null;
--
-- -- Gets jobs that failed before get a file. It should return job 3
-- select j.id as "Failed to process a file", f.checksum as "File Checksum"
-- from job j
-- join file f on j.id = f.job_id
-- join status s on j.id = s.job_id
-- where s.is_success = 0;
--
-- -- Gets no file jobs - It should return job 2
-- select j.id as "No files"
-- from job j
-- left join file f on j.id = f.job_id
-- join status s on j.id = s.job_id
-- where s.is_success = 1 AND f.job_id is null;
--
-- -- Gets successful jobs - It should return job 1
-- select j.id as "Successful Job", f.checksum as "File Checksum", f.row_count as "Number of Register"
-- from job j
-- join file f on j.id = f.job_id
-- join status s on j.id = s.job_id
-- where s.is_success = 1;
--
--
-- -- Selecting spans
-- set @row_num = 0;
-- SELECT sender_address, recipient_address, sent_time_stamp, count(@row_num)
-- FROM zix_usage
-- GROUP BY sender_address, recipient_address, sent_time_stamp
-- HAVING count( @row_num) > 1;
--
-- SELECT sender_address, recipient_address, sent_time_stamp,  @rowid:=@rowid+1
-- FROM zix_usage
-- LIMIT 10
--
-- select * from zix_usage where sender_address = "sender1@sender1.com";
