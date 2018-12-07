
-- ARCHIVER EXPLANATION
-- The Archiver is the module responsible for identifying if a file is ready for archiving.
-- A file is ready to archiving when the NEXT STEP for the STEP that outputted this file was
-- successfully finished. For example, supposing that a DOWNLOAD STEP for vendor A produces a FILE X and the next STEP
-- is the TRANSFORMER. As soon as the TRANSFORMER STEP succeed and saves a STEP result in the database, the FILE X can be
-- archived. In another hand, if a DOWNLOAD STEP for vendor B produces a FILE Y and the next STEP is the IMPORTER, as soon as
-- the IMPORTER STEP loads the file to the database and saves the STEP result, the FILE Y is ready for archiving.


-- For that reason, there is ONE ARCHIVER per vendor folder structure, as these ARCHIVERS might have different rules to determine when
-- a file will be archived.

-- Some details for ARCHIVER still not defined (for example, One ARCHIVER per VENDOR folder (DOWNLOAD, TRANSFORM, etc), process on file per task or all files in the folder)
-- For that scenario, let's assume that there is ONE ARCHIVER per VENDOR (for all folders under this vendor) and it will process all files per folder for each task

-- Supposing the previous scenarios for ZIX VENDOR:

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

-- 1: ARCHIVER receives a requesting for task
-- 2: Gets NEXT file in the DOWNLOAD folder (9bb6826905965c13be1c84cc0ff83f429bb6826905965c13be1c84cc0ff83f42)
-- 3: Check if this file is ready for archiving. It means, there is a successful SUMMARIZER (NEXT STEP) for this file?

-- QUERY 1
--PARAMS:
--  previousStep.type : The step that yielded this file
--  nextStep.type : The step that processed this file
-- :fileChechsum = Checksum of retrived file from the folder
select nextStep.id, nextStep.collection_job_id
from step previousStep
join step nextStep on previousStep.collection_job_id = nextStep.collection_job_id
where previousStep.file_checksum = '9bb6826905965c13be1c84cc0ff83f429bb6826905965c13be1c84cc0ff83f42'
and previousStep.type = 'DOWNLOADER'
and previousStep.status = 'SUCCESS'
and nextStep.type = 'SUMMARIZER'
and nextStep.status = 'SUCCESS';
+----+-------------------+
| id | collection_job_id |
+----+-------------------+
| 10 |                 6 |
+----+-------------------+

-- As there is a finished SUMMARIZER for this file, it is ready for archiving

-- 4: Move file for archive (or delete depending on the rule)
-- 5: Saves the STEP result in the database

-- QUERY 2
--PARAMS:
-- :user = service instance or user name in case of manual proccess
-- :startDate =  Data and time when the import process started.
-- :endDate =  Data and time when the import process finished.
-- :fileChechsum =  Checksum of retrived file from the folder
-- :collectionJobId = collection_job_id from the QUERY 1
insert into step (type, created_on, created_by, start_date, end_date, file_checksum, status, collection_job_id)
values ('ARCHIVER', NOW(), 'zix-downloader-intanceA', STR_TO_DATE('11/10/2018 12:10:15','%d/%m/%Y %H:%i:%s'), STR_TO_DATE('11/10/2018 12:12:23','%d/%m/%Y %H:%i:%s'),
'9bb6826905965c13be1c84cc0ff83f429bb6826905965c13be1c84cc0ff83f42', 'SUCCESS', 6)

-- 6: IF there is next file in this folder, move back to substep 3
-- 7: IF has no file, MOVE to next folder (TRANSFORMER) (120EA8A25E5D487BF68B5F7096440019CE114E4501D2F4E2DCEA3E17B546F339)
-- 8: Gets NEXT file in the TRANSFORMER folder
-- 9: Check if this file is ready for archiving. It means, there is a successful IMPORTER (NEXT STEP) for this file?

-- QUERY 3
--PARAMS:
--  previousStep.type : The step that yielded this file
--  nextStep.type : The step that processed this file
-- :fileChechsum = Checksum of retrived file from the folder
select nextStep.id
from step previousStep
join step nextStep on previousStep.collection_job_id = nextStep.collection_job_id
where previousStep.file_checksum = '120EA8A25E5D487BF68B5F7096440019CE114E4501D2F4E2DCEA3E17B546F339'
and previousStep.type = 'SUMMARIZER'
and previousStep.status = 'SUCCESS'
and nextStep.type = 'IMPORTER'
and nextStep.status = 'SUCCESS';
+----+-------------------+
| id | collection_job_id |
+----+-------------------+
| 11 |                 6 |
+----+-------------------+
-- As there is a finished IMPORTER for this file, it is ready for archiving

-- 10: Move file for archive (or delete depending on the rule)
-- 11: Saves the STEP result in the database

-- QUERY 2
--PARAMS:
-- :user = service instance or user name in case of manual proccess
-- :startDate =  Data and time when the import process started.
-- :endDate =  Data and time when the import process finished.
-- :fileChechsum =  Checksum of retrived file from the folder
-- :collectionJobId = collection_job_id from the QUERY 1
insert into step (type, created_on, created_by, start_date, end_date, file_checksum, status, collection_job_id)
values ('ARCHIVER', NOW(), 'zix-downloader-intanceA', STR_TO_DATE('11/10/2018 12:10:25','%d/%m/%Y %H:%i:%s'), STR_TO_DATE('11/10/2018 12:10:53','%d/%m/%Y %H:%i:%s'),
'120EA8A25E5D487BF68B5F7096440019CE114E4501D2F4E2DCEA3E17B546F339', 'SUCCESS', 6)
-- 12: IF there is next file in this folder, move back to substep 3
-- 13: IF has no file, finishes the process
