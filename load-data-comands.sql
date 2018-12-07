
--------------- OUTSIDE CONTAINER
LOAD DATA LOCAL INFILE '/home/gustavorocha/go-workspace/src/gustavo.org/fusemail/go-utils/file-creator/output/mock-zix-usage-2.csv'
    INTO TABLE vendor_usage.zix_usage
    FIELDS TERMINATED BY ','
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    (@senderAddress, @recipientAddress, @sentTimestamp, @subject, @policyTypes, @policyNames, @deliveryMethod)
    SET
    sender_address=@senderAddress,
    recipient_address=@recipientAddress,
    sent_time_stamp=@sentTimestamp,
    subject=@subject,
    police_types=@policyTypes,
    police_names=@policyNames,
    delivery_method=@deliveryMethod,
    job_id=2;


---------------- INSIDE CONTAINER ------------------
LOAD DATA INFILE '/sql-loadfiles/mock-zix-usage-5M.csv'
    INTO TABLE vendor_usage.zix_usage
    FIELDS TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    (@senderAddress, @recipientAddress, @sentTimestamp, @subject, @policyTypes, @policyNames, @deliveryMethod)
    SET
    sender_address=@senderAddress,
    recipient_address=@recipientAddress,
    sent_time_stamp=STR_TO_DATE(@sentTimestamp,'%d/%m/%Y %H:%i'),
    subject="Something",
    police_types=@policyTypes,
    police_names=@policyNames,
    delivery_method=@deliveryMethod,
    job_id=3;

    LOAD DATA INFILE '/var/lib/mysql-files/mock-zix-usage-100K.csv'
        INTO TABLE vendor_usage.zix_usage
        FIELDS TERMINATED BY ','
        OPTIONALLY ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        IGNORE 1 LINES
        (@senderAddress, @recipientAddress, @sentTimestamp, @subject, @policyTypes, @policyNames, @deliveryMethod)
        SET
        sender_address=@senderAddress,
        recipient_address=@recipientAddress,
        sent_time_stamp=STR_TO_DATE(@sentTimestamp,'%d/%m/%Y %H:%i'),
        subject=@subject,
        police_types=@policyTypes,
        police_names=@policyNames,
        delivery_method=@deliveryMethod,
        job_id=2;

SET @ACTUAL_JOB_ID=2;


select sender_address, recipient_address, sent_time_stamp, job_id
from zix_usage
group by sender_address, recipient_address, sent_time_stamp
having count(distinct(job_id)) > 1;

select z.sender_address, z.recipient_address, z.sent_time_stamp, z.job_id
from zix_usage as z,
(select sender_address, recipient_address, sent_time_stamp, count(distinct(job_id))
from zix_usage
group by sender_address, recipient_address, sent_time_stamp
having count(distinct(job_id)) > 1 ) as duplicates
where
z.sender_address = duplicates.sender_address
AND z.recipient_address = duplicates.recipient_address
AND z.sent_time_stamp = duplicates.sent_time_stamp
AND z.job_id = @ACTUAL_JOB_ID;


select 1
from zix_usage
group by sender_address, recipient_address, sent_time_stamp
having count(distinct(job_id)) > 1

DELIMITER $$
DROP TRIGGER IF EXISTS trigger_ck_insert_zix;
CREATE TRIGGER trigger_ck_insert_zix AFTER INSERT ON zix_usage
FOR EACH ROW
BEGIN
  IF EXISTS (
    select 1 from zix_usage
    group by sender_address, recipient_address, sent_time_stamp
    having count(distinct(job_id)) > 1
  ) THEN signal sqlstate '45100';
  END IF;
END $$
DELIMITER ;
;

DELIMITER $$
DROP TRIGGER IF EXISTS trigger_ck_insert_zix;
CREATE TRIGGER trigger_ck_insert_zix BEFORE INSERT ON zix_usage
FOR EACH ROW
BEGIN
  SET new.job_id = 5;
END $$
DELIMITER ;


select * from zix_usage
WHERE
sender_address = new.sender_address AND
recipient_address = new.recipient_address AND
sent_time_stamp = new.sent_time_stamp AND
job_id <> new.job_id


select 1
from zix_usage
group by sender_address, recipient_address, sent_time_stamp
having count(distinct(job_id)) > 1 ;



select sender_address, recipient_address, sent_time_stamp
from zix_usage
where job_id = @ACTUAL_JOB_ID
group by sender_address, recipient_address, sent_time_stamp
having count(*) > 1;


select 1
from zix_usage
group by sender_address, recipient_address, sent_time_stamp
having count(distinct(job_id)) > 1;

DROP VIEW IF EXISTS next_usage_collect;
CREATE VIEW next_usage_collect AS
SELECT s.id as SourceId, s.name as Source, v.id as VendorId, v.vendor_name as Vendor, s.frequency as Frequency,
  MAX(f.end_date) as LastExecution,
  DATE(NOW()) as Today,
  DATE_SUB(DATE(NOW()), INTERVAL DATEDIFF(DATE(NOW()), f.end_date)-1 DAY) as startDate,
  DATE_SUB(DATE(NOW()), INTERVAL 1 DAY) as endDate
FROM file f
JOIN source s ON f.source_id = s.id
JOIN vendor v ON f.vendor_id = v.id
GROUP BY
  s.id, s.name, v.id, v.vendor_name, s.frequency
HAVING
  (s.frequency = 'DAILY' AND DATEDIFF(DATE(NOW()), LastExecution) > 1) OR
  (s.frequency = 'WEEKLY' AND DATEDIFF(DATE(NOW()), LastExecution) > 7) OR
  (s.frequency = 'MONTHLY' AND PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM DATE(NOW())), EXTRACT(YEAR_MONTH FROM LastExecution)) > 1)
UNION
SELECT
  s.id as SourceId, s.name as Source, v.id as VendorId, v.vendor_name as Vendor, s.frequency as Frequency,
  f.end_date as LastExecution,
  NOW() as Today,
  f.start_date as startDate,
  f.end_date as endDate
FROM file f
LEFT JOIN source s ON f.source_id = s.id
LEFT JOIN vendor v ON f.vendor_id = v.id
WHERE
  f.status = 'ERROR'
  AND NOT EXISTS (SELECT 1 FROM file fl WHERE fl.start_date = f.start_date AND fl.end_date >= f.end_date AND fl.status <> 'ERROR');

--
--
--   SELECT s.name as Source, v.vendor_name as Vendor, s.frequency as Frequency,
--   f.end_date as LastExecution,
--   DATE_ADD(NOW(), INTERVAL 30 DAY) as Today,
--   DATE_SUB(DATE_ADD(NOW(), INTERVAL 30 DAY), INTERVAL DATEDIFF(DATE_ADD(NOW(), INTERVAL 30 DAY), f.end_date)-1 DAY) as startDate,
--   DATE_SUB(DATE_ADD(NOW(), INTERVAL 30 DAY), INTERVAL 1 DAY) as endDate
--   FROM file f
--   LEFT JOIN source s ON f.source_id = s.id
--   LEFT JOIN vendor v ON f.vendor_id = v.id
--   WHERE
--     f.status <> 'ERROR' AND
--     (s.frequency = 'DAILY' AND DATEDIFF(DATE_ADD(NOW(), INTERVAL 30 DAY), f.end_date) > 1) OR
--     (s.frequency = 'WEEKLY' AND DATEDIFF(DATE_ADD(NOW(), INTERVAL 30 DAY), f.end_date) > 7) OR
--     (s.frequency = 'MONTHLY' AND PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM DATE_ADD(NOW(), INTERVAL 30 DAY)), EXTRACT(YEAR_MONTH FROM f.end_date)) > 1);
--
--
--
-- select PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM NOW()), EXTRACT(YEAR_MONTH FROM DATE_SUB(NOW(), INTERVAL 30 DAY)));
-- EXTRACT(YEAR_MONTH FROM DATE_SUB(NOW(), INTERVAL 30 DAY))
-- EXTRACT(YEAR_MONTH FROM NOW())
--
-- ;
--
--
-- end transaction;
--
-- DELIMITER $$
-- DROP FUNCTION IF EXISTS selectNextFileByStatus;
-- CREATE FUNCTION selectNextFileByStatus(p_fileStatus VARCHAR(20)) RETURNS TINYINT(1)
--     DETERMINISTIC
-- BEGIN
--     DECLARE s TINYINT(1);
--
--     IF EXISTS (
--        select * from zix_usage
--        WHERE
--        sender_address = p_senderAddress AND
--        recipient_address = p_recipientAddress AND
--        sent_time_stamp = p_sentTimeStamp AND
--        job_id <> p_jobId
--      )  THEN SET s = 1;
--     ELSE SET s = 0;
--     END IF;
--  RETURN (s);
-- END $$;


  DELIMITER $$
  DROP PROCEDURE IF EXISTS selectNextFileByStatus;
  CREATE PROCEDURE selectNextFileByStatus(IN p_fileStatus VARCHAR(20))
  select_block:BEGIN
    DECLARE tempId INT UNSIGNED DEFAULT 0;
    DECLARE newStatus VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
      BEGIN
          ROLLBACK;
          SET tempId = 0;
      END;
    START TRANSACTION;

      IF p_fileStatus = 'NEW' THEN SET newStatus = 'PREPROCESSING';
      ELSEIF p_fileStatus = 'READY' THEN SET newStatus = 'LOADING';
      ELSEIF p_fileStatus = 'LOADING' THEN SET p_fileStatus = NULL;
      ELSEIF p_fileStatus = 'PREPROCESSING' THEN SET p_fileStatus = NULL;
      ELSEIF p_fileStatus = 'ERROR' THEN SET p_fileStatus = NULL;
      ELSEIF p_fileStatus = 'ARCHIVED' THEN SET p_fileStatus = NULL;
      END IF;

      IF p_fileStatus IS NOT NULL THEN
        -- SELECT 'RUNNING SELECT TO UPDATE';
        SELECT id FROM file WHERE status = p_fileStatus LIMIT 1 INTO tempId FOR UPDATE ;
        -- SELECT tempId as 'SELECTED', newStatus as 'TO UPDATE WITH';
        UPDATE file SET status = newStatus WHERE id = tempId;
      END IF;

    COMMIT;

    SELECT id, name, start_date, update_date, status, source_id, vendor_id FROM file WHERE id = tempId;


  END $$
  DELIMITER ;

call selectNextFileByStatus('PREPROCESSING');


SELECT f.name, f.start_date, f.end_date, f.update_date, f.status, f.source_id, v.vendor_name FROM file f JOIN vendor v ON f.vendor_id = v.id;


SELECT s.id as SourceId, s.name as Source, v.id as VendorId, v.vendor_name as Vendor, s.frequency as Frequency,
MAX(f.end_date) as LastExecution,
NOW() as Today,
DATE_SUB(NOW(), INTERVAL DATEDIFF(NOW(), f.end_date)-1 DAY) as startDate,
DATE_SUB(NOW(), INTERVAL 1 DAY) as endDate
FROM file f
JOIN source s ON f.source_id = s.id
JOIN vendor v ON f.vendor_id = v.id
GROUP BY
  s.id, s.name, v.id, v.vendor_name, s.frequency
HAVING
(s.frequency = 'DAILY' AND DATEDIFF(DATE_SUB(NOW(), INTERVAL 1 DAY), LastExecution) > 1) OR
(s.frequency = 'WEEKLY' AND DATEDIFF(DATE_SUB(NOW(), INTERVAL 1 DAY), LastExecution) > 7) OR
(s.frequency = 'MONTHLY' AND PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM NOW()), EXTRACT(YEAR_MONTH FROM LastExecution)) > 1)
UNION
SELECT s.id as SourceId, s.name as Source, v.id as VendorId, v.vendor_name as Vendor, s.frequency as Frequency,
f.end_date as LastExecution,
NOW() as Today,
f.start_date as startDate,
f.end_date as endDate
FROM file f
LEFT JOIN source s ON f.source_id = s.id
LEFT JOIN vendor v ON f.vendor_id = v.id
WHERE
f.status = 'ERROR'
AND NOT EXISTS (SELECT 1 FROM file fl WHERE fl.start_date = f.start_date AND fl.end_date >= f.end_date AND fl.status <> 'ERROR');


select v.vendor_name as Vendor, s.name, s.frequency as Frequency, max(f.end_date) as "Last successful End Date"
from file f
join vendor v on f.vendor_id = v.id
join source s on s.id = f.source_id
where f.status <> 'ERROR'
group by v.vendor_name, s.frequency, s.id;

select DATEDIFF(DATE(NOW()), file.end_date) AS DIFFDATES, DATE(NOW()) AS TODAY, file.end_date " LAST EXEC" from file;
