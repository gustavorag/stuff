
-- Supposing we have:

 select * from vendor;
+----+------+---------------------+------------+---------------------+-------------+
| id | name | created_on          | created_by | modified_on         | modified_by |
+----+------+---------------------+------------+---------------------+-------------+
|  1 | Zix  | 2018-11-20 23:38:18 | user 1     | 2018-11-20 23:38:18 | user 1      |
+----+------+---------------------+------------+---------------------+-------------+
select * from source;
+----+------------+-----------+---------------------+------------+---------------------+-------------+
| id | name       | vendor_id | created_on          | created_by | modified_on         | modified_by |
+----+------------+-----------+---------------------+------------+---------------------+-------------+
|  1 | zix-c01-s4 |         1 | 2018-11-20 23:38:18 | user 1     | 2018-11-20 23:38:18 | user 1      |
|  2 | zix-c02-s4 |         1 | 2018-11-20 23:38:18 | user 1     | 2018-11-20 23:38:18 | user 1      |
|  3 | zix-c03-s4 |         1 | 2018-11-20 23:38:18 | user 1     | 2018-11-20 23:38:18 | user 1      |
|  4 | zix-c04-s4 |         1 | 2018-11-20 23:38:19 | user 1     | 2018-11-20 23:38:19 | user 1      |
+----+------------+-----------+---------------------+------------+---------------------+-------------+

-- Previous Explanation:
-- A vendor might have none or many sources of usage data. The source is "where" the collection job will get the usage.
-- For example, Zix has 10 clusters. For each source there is on the instance for usage collection, more specifically, the
-- DOWNLOADER STEP. The DOWNLOADER knows its source by an environment variable. This variable is an INTEGER and MUST
-- exists in the SOURCE table as ID.


-- SCENARIO A:
-- Downloader Step receives a request for new Usage Downloading.
-- Explanation: Downloader Step is the first Step in the Collection Usage Data Job (named collection_job)
-- therefore it is also responsible for creating a new collection_job register in the database.
-- There is no query at this point. The downloader will use an environment variable to identify there
-- the source of the data (source table), creates a new Collection Job register for that source and save it in the DATABASE

--PARAMS:
--startDate = Date when the service received the request
--user = service instance or username in case of manual process
--sourceId = Retrieved from an environment variable (It must be a valid ID at source table)
insert into collection_job (start_date, created_by, created_on, source_id)
  values (STR_TO_DATE('01/10/2018 10:30:21','%d/%m/%Y %H:%i:%s'), 'zix-downloader-intanceA', NOW(), 1);

  -- - Returns 6 as Collection Job ID

  -- Scenario: Downloader Step finishes successfully
  -- Explanation: After creating the Collection Job register, the Downloader Step moves to the actual collection stage.
  -- At this point, there is no step register in the database. Step register are inserted only at the end of the process
  -- having SUCCESS or ERROR status. In this scenario, we are saving a successful download step.
  --    First, we save the file information: Checksum, Name and Number of rows
  --    Second, we save the step information: type DOWNLOAD, file Checksum, status SUCCESS and Collection Job id from the
  --    register created in the previous insert.

  --PARAMS:
  -- :checksum = Checksum of the downloaded file
  -- :name = Name of the downloaded file
  -- :numRows = Number of rows in the file
insert into file (checksum, name, num_rows) values ('9bb6826905965c13be1c84cc0ff83f429bb6826905965c13be1c84cc0ff83f42', 'zix-usage-c1s4-20181030.csv', 200);

  --PARAMS:
  -- :user = service instance or user name in case of manual proccess
  -- :startDate =  Data and time when the download process started.
  -- :endDate =  Data and time when the download process finished.
  -- :fileChechsum = Checksum of the downloaded file
  -- :collectionJobId = Id of the job in which this step is contained (collection job created at the beginning)
insert into step (type, created_on, created_by, start_date, end_date, file_checksum, status, collection_job_id)
values ('DOWNLOADER', NOW(), 'zix-downloader-intanceA', STR_TO_DATE('01/10/2018 10:30:25','%d/%m/%Y %H:%i:%s'), STR_TO_DATE('01/10/2018 10:30:52','%d/%m/%Y %H:%i:%s'),
'9bb6826905965c13be1c84cc0ff83f429bb6826905965c13be1c84cc0ff83f42', 'SUCCESS', 6);


-- By the end o this scenario we have the data:

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

--Scenario B: Downloader step finishes with an ERROR
-- Explanation: An error might occur before the service have saved a collection job register or after.
-- IF the error occurs before, a collection job register must be saved

--PARAMS:
--startDate = Date when the service received the request
--user = service instance or user name in case of manual proccess
--sourceId = Retrieved from environment variable
insert into collection_job (start_date, created_by, created_on, source_id)
values (STR_TO_DATE('01/10/2018 10:30:21','%d/%m/%Y %H:%i:%s'), 'zix-downloader-intanceA', NOW(), 1)

-- Returns 10 as Collection Job ID


-- After that, a step is created with no file checksum (no download was done):
--PARAMS:
-- :user = service instance or user name in case of manual proccess
-- :startDate =  Data and time when the doownload process started.
-- :endDate =  Data and time when the doownload process finished.
-- :collectionJobId = Id of the job in which this step is contained (collection job created at the beginning)
insert into step (type, created_on, created_by, start_date, end_date, status, collection_job_id)
values ('DOWNLOAD', NOW(),'zix-downloader-intanceA', STR_TO_DATE('01/10/2018 10:30:25','%d/%m/%Y %H:%i:%s'),
STR_TO_DATE('01/10/2018 10:40:12','%d/%m/%Y %H:%i:%s'), 'ERROR', 10)

-- returns 101 as step ID

-- And finally, a Step Error (step_error) is created
--PARAMS:
-- :stepId = Step previously created
-- :error = detail about what caused the error
-- :user = service instance or user name in case of manual procce
insert into step_error (step_id, error, created_on, created_by)
values (101, 'Timeout reached while downloading usage data from ZixReporting', NOW(), 'zix-downloader-intanceA')

-- IF the error occurs after collection job creation but was not possible to download a file
-- the same operation described above is taken beside the creation of a collection job register

-- IF the error occurs after collection job creation and a file was downloaded (error to save the file in a remote repository, for example)
-- the same operation described above is taken and the step register will have the file checksum of the downloaded file.

-- Supposing the service is out and a Billing user with credential "joedoe@exmb.com" is uploading a file manually

insert into collection_job (start_date, created_by, created_on, source_id)
  values (STR_TO_DATE('01/10/2018 10:30:21','%d/%m/%Y %H:%i:%s'), 'joedoe@exmb.com', NOW(), 1)

insert into file (checksum, name, num_rows) values ('9bb6826905965c13be1c84cc0ff83f429bb6826905965c13be1c84cc0ff83f42', 'zix-usage-c1s4-20181030', 200);
insert into step (type, created_on, created_by, start_date, end_date, file_checksum, status, collection_job_id)
  values ('DOWNLOAD', NOW(), 'joedoe@exmb.com', STR_TO_DATE('01/10/2018 10:30:25','%d/%m/%Y %H:%i:%s'), STR_TO_DATE('01/10/2018 10:30:36','%d/%m/%Y %H:%i:%s'),
  '9bb6826905965c13be1c84cc0ff83f429bb6826905965c13be1c84cc0ff83f42', 'SUCCESS', 10)
