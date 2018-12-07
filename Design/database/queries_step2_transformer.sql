
-- Supposing the Downloader Step ended up with scenario A, we have the following Data:

select * from collection_job
    -> ;
+----+-----------+---------------------+---------------------+-------------------------+---------------------+-------------+
| id | source_id | start_date          | created_on          | created_by              | modified_on         | modified_by |
+----+-----------+---------------------+---------------------+-------------------------+---------------------+-------------+
|  6 |         1 | 2018-10-01 10:30:21 | 2018-11-20 21:03:20 | zix-downloader-intanceA | 2018-11-20 21:03:20 |             |
+----+-----------+---------------------+---------------------+-------------------------+---------------------+-------------+

select * from step;
+----+-------------------+------------+------------------------------------------------------------------+---------------------+-------------------------+---------------------+---------------------+---------+
| id | collection_job_id | type       | file_checksum                                                    | created_on          | created_by              | start_date          | end_date            | status  |
+----+-------------------+------------+------------------------------------------------------------------+---------------------+-------------------------+---------------------+---------------------+---------+
|  9 |                 6 | DOWNLOADER | 9bb6826905965c13be1c84cc0ff83f429bb6826905965c13be1c84cc0ff83f42 | 2018-11-20 21:05:38 | zix-downloader-intanceA | 2018-10-01 10:30:25 | 2018-10-01 10:30:52 | SUCCESS |
+----+-------------------+------------+------------------------------------------------------------------+---------------------+-------------------------+---------------------+---------------------+---------+

select * from file;
+------------------------------------------------------------------+-------------------------+----------+---------------------+------------+---------------------+-------------+
| checksum                                                         | name                    | num_rows | created_on          | created_by | modified_on         | modified_by |
+------------------------------------------------------------------+-------------------------+----------+---------------------+------------+---------------------+-------------+
| 9bb6826905965c13be1c84cc0ff83f429bb6826905965c13be1c84cc0ff83f42 | zix-usage-c1s4-20181030.csv |      200 | 2018-11-20 21:04:01 |            | 2018-11-20 21:04:01 |          |
+------------------------------------------------------------------+-------------------------+----------+---------------------+------------+---------------------+-------------+

-- TRANSFORMER SCENARIO A:
-- The transformer step might have different subtypes (a summarization, a translation from json to csv, are instances) or even a vendor might not have a
--  transformer step. The assumption is: If there is an ACTUAL STEP to be taken and before this a PREVIOUS STEP was taken, so the ACTUAL STEP uses the PREVIOUS STEP
--  output file as input. In this example (Zix Vendor) the TRANSFORMER STEP (actual step) summarizes a DOWNLOADED file (previous step) taken this flow:
-- 1 Receives a task request:
-- 2 Gets the next file in the PREVIOUS STEP output folder (download folder in this case)
-- 3 Creates the checksum for this file: Lets assume: 9bb6826905965c13be1c84cc0ff83f429bb6826905965c13be1c84cc0ff83f42
-- 4 Check if this file is related to a successful PREVIOUS STEP (DOWNLOADER) AND check if there is no successful Transform Step for this file:

-- QUERY 1
--PARAMS:
--  previousStep.type : The step that yielded this file
--  actualStep.type : The type of this step: IMPORTER
-- :fileChechsum = Checksum of retrived file from the folder
select previousStep.collection_job_id, previousStep.id as downloadID, actualStep.id as summarizeId
from step previousStep
left join (select id, collection_job_id, type from step where  type = 'SUMMARIZER' and status = 'SUCCESS') as actualStep -- Actual Step
on previousStep.collection_job_id = actualStep.collection_job_id
where actualStep.id is null -- Get only that ones with no summarizing process
and previousStep.file_checksum = '9bb6826905965c13be1c84cc0ff83f429bb6826905965c13be1c84cc0ff83f42'
and previousStep.type = 'DOWNLOADER' -- Previous step
and previousStep.status = 'SUCCESS';

-- This query returns The COLLECTION JOB and the DOWNLOADER STEP for which the given file is related. If there is a SUMMARIZE STEP for this file, it returns Empty set, which means that there
-- is no available SUMMARIZE step for this file. In this scenario we don't have a SUMMARIZE so the query will return:

+-------------------+------------+-------------+
| collection_job_id | downloadID | summarizeId |
+-------------------+------------+-------------+
|                 6 |          9 |        NULL |
+-------------------+------------+-------------+

-- 5 Next, the TRANSFORMER STEP is to process the file applying the required logic. At the end, it will generate a new file with new Checksum
-- Let's assume the checksum to be 120EA8A25E5D487BF68B5F7096440019CE114E4501D2F4E2DCEA3E17B546F339

-- 6 TRANSFORMER STEP saves the new file in TRANSFORMER folder

  -- No database operations at this process.

-- 7 TRANSFORMER STEP saves the FILE register into file table

-- QUERY 2
--PARAMS:
-- :checksum = Checksum of the downloaded file
-- :name = Name of the downloaded file
-- :numRows = Number of rows in the file
insert into file (checksum, name, num_rows) values ('120EA8A25E5D487BF68B5F7096440019CE114E4501D2F4E2DCEA3E17B546F339', 'zix-usage-c1s4-20181030-summ.csv', 365);

-- 8 TRANSFORMER STEP saves the STEP register into step table

-- QUERY 3
--PARAMS:
-- :user = service instance or user name in case of manual proccess
-- :startDate =  Data and time when the summarization process started.
-- :endDate =  Data and time when the summarization process finished.
-- :fileChechsum = Checksum of the summarized file (the output of this step)
-- :collectionJobId = collection_job_id from the QUERY 1
insert into step (type, created_on, created_by, start_date, end_date, file_checksum, status, collection_job_id)
values ('SUMMARIZER', NOW(), 'zix-downloader-intanceA', STR_TO_DATE('01/10/2018 11:10:15','%d/%m/%Y %H:%i:%s'), STR_TO_DATE('01/10/2018 11:12:23','%d/%m/%Y %H:%i:%s'),
'120EA8A25E5D487BF68B5F7096440019CE114E4501D2F4E2DCEA3E17B546F339', 'SUCCESS', 6)

-- By the end o this scenario we have the data:

select * from collection_job;
+----+-----------+---------------------+---------------------+-------------------------+---------------------+-------------+
| id | source_id | start_date          | created_on          | created_by              | modified_on         | modified_by |
+----+-----------+---------------------+---------------------+-------------------------+---------------------+-------------+
|  6 |         1 | 2018-10-01 10:30:21 | 2018-11-20 21:03:20 | zix-downloader-intanceA | 2018-11-20 21:03:20 |             |
+----+-----------+---------------------+---------------------+-------------------------+---------------------+-------------+


select * from step;
+----+-------------------+------------+------------------------------------------------------------------+---------------------+-------------------------+---------------------+---------------------+---------+
| id | collection_job_id | type       | file_checksum                                                    | created_on          | created_by              | start_date          | end_date            | status  |
+----+-------------------+------------+------------------------------------------------------------------+---------------------+-------------------------+---------------------+---------------------+---------+
|  9 |                 6 | DOWNLOADER | 9bb6826905965c13be1c84cc0ff83f429bb6826905965c13be1c84cc0ff83f42 | 2018-11-20 21:05:38 | zix-downloader-intanceA | 2018-10-01 10:30:25 | 2018-10-01 10:30:52 | SUCCESS |
| 10 |                 6 | SUMMARIZER | 120EA8A25E5D487BF68B5F7096440019CE114E4501D2F4E2DCEA3E17B546F339 | 2018-11-20 21:37:38 | zix-downloader-intanceA | 2018-10-01 11:10:15 | 2018-10-01 11:12:23 | SUCCESS |
+----+-------------------+------------+------------------------------------------------------------------+---------------------+-------------------------+---------------------+---------------------+---------+

select * from file;
+------------------------------------------------------------------+----------------------------------+----------+---------------------+------------+---------------------+-------------+
| checksum                                                         | name                             | num_rows | created_on          | created_by | modified_on         | modified_by |
+------------------------------------------------------------------+----------------------------------+----------+---------------------+------------+---------------------+-------------+
| 120EA8A25E5D487BF68B5F7096440019CE114E4501D2F4E2DCEA3E17B546F339 | zix-usage-c1s4-20181030-summ.csv |      365 | 2018-11-20 21:37:30 |            | 2018-11-20 21:37:30 |             |
| 9bb6826905965c13be1c84cc0ff83f429bb6826905965c13be1c84cc0ff83f42 | zix-usage-c1s4-20181030          |      200 | 2018-11-20 21:04:01 |            | 2018-11-20 21:04:01 |             |
+------------------------------------------------------------------+----------------------------------+----------+---------------------+------------+---------------------+-------------+


-- Variance Scenario 1

-- If QUERY 1 returns an Empty Set it means that there is no available actual step type (SUMMARIZER in this case) to be done. Therefore the
-- service will skip the file and get the next file in the DOWNLOAD folder.

-- Variance Scenario 2

-- Supposing any error occurs during the transformation process, a Step Error register will be saved as also as a step register with ERROR status

insert into step (type, created_on, created_by, start_date, end_date, file_checksum, status, collection_job_id)
values ('SUMMARIZER', NOW(), 'zix-downloader-intanceA', STR_TO_DATE('01/10/2018 11:10:15','%d/%m/%Y %H:%i:%s'), STR_TO_DATE('01/10/2018 11:12:23','%d/%m/%Y %H:%i:%s'),
null, 'SUCCESS', 6)

insert into step_error (step_id, error, created_on, created_by)
values (10, 'Malformed file. Cannot procced with summarization process', NOW(), 'zix-downloader-intanceA')
