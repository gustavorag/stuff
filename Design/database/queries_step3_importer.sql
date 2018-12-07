-- Supposing the Transformer Step ended up with scenario A, we have the following Data:


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

-- IMPORTER SCENARIO A:

-- The IMPORTER STEP uses the PREVIOUS STEP output (the file) and LOADS it in the database (usage table). The previous STEP might be the DOWNLOADER step OR a TRANSFORMER STEP.
-- For this example (Zix Vendor), the PREVIOUS STEP is the TRANSFORMER STEP (SUMMARIZER).
-- The flow for IMPORTER is:

-- 1: Receives a request to start a task
-- 2: Gets the next file in the PREVIOUS STEP output folder (transformer folder in this case)
-- 3: Creates the checksum for this file. Let's assume : 120EA8A25E5D487BF68B5F7096440019CE114E4501D2F4E2DCEA3E17B546F339
-- 4: Check if this file is related to a successful PREVIOUS STEP (TRANSFORMER) AND check if there is no successful IMPORTER STEP for this file:

-- QUERY 1
--PARAMS:
--  previousStep.type : The step that yielded this file
--  actualStep.type : The type of this step: IMPORTER
-- :fileChechsum = Checksum of retrived file from the folder
select previousStep.collection_job_id, previousStep.id as summarizerId, actualStep.id as importerId
from step previousStep
left join (select id, collection_job_id, type from step where type = 'IMPORTER' and status = 'SUCCESS') as actualStep -- Actual Step
on previousStep.collection_job_id = actualStep.collection_job_id
where actualStep.id is null -- Get only that ones with no summarizing process
and previousStep.file_checksum = '120EA8A25E5D487BF68B5F7096440019CE114E4501D2F4E2DCEA3E17B546F339'
and previousStep.type = 'SUMMARIZER' -- Previous step
and previousStep.status = 'SUCCESS';

-- This query returns The COLLECTION JOB and the SUMMARIZER STEP for which the given file is related. If there is a successful IMPORTER STEP for this file, it returns Empty set,
-- which means that there is no available IMPORTER step for this file. In this scenario we don't have an IMPORTER so the query will return:

+-------------------+--------------+------------+
| collection_job_id | summarizerId | importerId |
+-------------------+--------------+------------+
|                 6 |           10 |       NULL |
+-------------------+--------------+------------+

-- 5: Loads the file content into the vendor's usage table. In this case zix_usage.
  -- PS. It is not defined the actual IMPORT process to load the file into the DB. It might be a reader going
  -- line by line inserting by batch (interval commit) or might be MySql LOAD DATA INFILE command. TBD. For
  -- simplification purpose, let's assume that by the end we have the following data:

  +----+-----------------+-------+-------------------+
| id | sender_domain   | count | collection_job_id |
+----+-----------------+-------+-------------------+
|  1 | somedomain1.com |    52 |                 6 |
|  2 | somedomain2.com |   230 |                 6 |
|  3 | somedomain3.com |    86 |                 6 |
|  4 | somedomain4.com |   220 |                 6 |
|  5 | somedomain5.com |    40 |                 6 |
+----+-----------------+-------+-------------------+


-- 6 IMPORTER STEP saves the STEP result into step table

-- QUERY 3
--PARAMS:
-- :user = service instance or user name in case of manual proccess
-- :startDate =  Data and time when the import process started.
-- :endDate =  Data and time when the import process finished.
-- :fileChechsum = Checksum of LOADED file (file from previous step)
-- :collectionJobId = collection_job_id from the QUERY 1
insert into step (type, created_on, created_by, start_date, end_date, file_checksum, status, collection_job_id)
values ('IMPORTER', NOW(), 'zix-downloader-intanceA', STR_TO_DATE('01/10/2018 12:10:15','%d/%m/%Y %H:%i:%s'), STR_TO_DATE('01/10/2018 12:12:23','%d/%m/%Y %H:%i:%s'),
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
| 10 |                 6 | SUMMARIZER | 120EA8A25E5D487BF68B5F7096440019CE114E4501D2F4E2DCEA3E17B546F339 | 2018-11-20 22:19:01 | zix-downloader-intanceA | 2018-10-01 11:10:15 | 2018-10-01 11:12:23 | SUCCESS |
| 11 |                 6 | IMPORTER   | 120EA8A25E5D487BF68B5F7096440019CE114E4501D2F4E2DCEA3E17B546F339 | 2018-11-20 22:22:35 | zix-downloader-intanceA | 2018-10-01 12:10:15 | 2018-10-01 12:12:23 | SUCCESS |
+----+-------------------+------------+------------------------------------------------------------------+---------------------+-------------------------+---------------------+---------------------+---------+

select * from file;
+------------------------------------------------------------------+----------------------------------+----------+---------------------+------------+---------------------+-------------+
| checksum                                                         | name                             | num_rows | created_on          | created_by | modified_on         | modified_by |
+------------------------------------------------------------------+----------------------------------+----------+---------------------+------------+---------------------+-------------+
| 120EA8A25E5D487BF68B5F7096440019CE114E4501D2F4E2DCEA3E17B546F339 | zix-usage-c1s4-20181030-summ.csv |      365 | 2018-11-20 21:37:30 |            | 2018-11-20 21:37:30 |             |
| 9bb6826905965c13be1c84cc0ff83f429bb6826905965c13be1c84cc0ff83f42 | zix-usage-c1s4-20181030          |      200 | 2018-11-20 21:04:01 |            | 2018-11-20 21:04:01 |             |
+------------------------------------------------------------------+----------------------------------+----------+---------------------+------------+---------------------+-------------+

select * from zix_usage;
+----+-----------------+-------+-------------------+
| id | sender_domain   | count | collection_job_id |
+----+-----------------+-------+-------------------+
|  1 | somedomain1.com |    52 |                 6 |
|  2 | somedomain2.com |   230 |                 6 |
|  3 | somedomain3.com |    86 |                 6 |
|  4 | somedomain4.com |   220 |                 6 |
|  5 | somedomain5.com |    40 |                 6 |
+----+-----------------+-------+-------------------+
