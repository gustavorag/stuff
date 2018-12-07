insert into vendor (name, created_by, modified_by) values ('Zix', 'user 1', 'user 1');
insert into source (name, vendor_id,  created_by, modified_by) values ('zix-c01-s4', 1, 'user 1', 'user 1');
insert into source (name, vendor_id, created_by, modified_by) values ('zix-c02-s4', 1, 'user 1', 'user 1');
insert into source (name, vendor_id, created_by, modified_by) values ('zix-c03-s4', 1, 'user 1', 'user 1');
insert into source (name, vendor_id, created_by, modified_by) values ('zix-c04-s4', 1, 'user 1', 'user 1');




insert into file (checksum, name, num_rows) values ('9bb6826905965c13be1c84cc0ff83f429bb6826905965c13be1c84cc0ff83f42', 'zix-report-c01-01-oct-2018.csv', 203);
insert into file (checksum, name, num_rows) values ('84cc0ff83f42c13be129bb6826905965c13be1cc84cc0ff839bb6826905965f4', 'zix-report-c01-01-oct-2018-summarized.csv', 47);
insert into file (checksum, name, num_rows) values ('6905965c13be9bb6821c84cc0ff83f429905965c13be1c84cc0ff83f42bb6826', 'zix-report-c02-01-oct-2018.csv', 1232);
insert into file (checksum, name, num_rows) values ('120EA8A25E5D487BF68B5F7096440019CE114E4501D2F4E2DCEA3E17B546F339', 'zix-report-c01-02-oct-2018.csv', 365);
insert into file (checksum, name, num_rows) values ('CE114E4501D2F4E2DCEA3E17B546F339120EA8A25E5D487BF68B5F7096440019', 'zix-report-c01-02-oct-2018-summarized.csv', 79);
insert into file (checksum, name, num_rows) values ('7BF68B5F7096440019CE120EA8A25E5D48114E4501D2F4E2DCEA3E17B546F339', 'zix-report-c02-02-oct-2018.csv', 155);


insert into collection_job (source_id, status, current_step_type_id, start_date)
values (1, 'IN PROGRESS', 1, STR_TO_DATE('01/10/2018 10:30:21','%d/%m/%Y %H:%i:%s'));
insert into collection_job (source_id, created_on, created_by) values (2, STR_TO_DATE('01/10/2018 10:32:11','%d/%m/%Y %H:%i:%s'), 'em-service-zixreporting-downloader-intanceB');
insert into collection_job (source_id, created_on, created_by) values (1, STR_TO_DATE('02/10/2018 23:56:01','%d/%m/%Y %H:%i:%s'), 'em-service-zixreporting-downloader-intanceA');
insert into collection_job (source_id, created_on, created_by) values (2, STR_TO_DATE('02/10/2018 22:46:01','%d/%m/%Y %H:%i:%s'), 'em-service-zixreporting-downloader-intanceB');
insert into collection_job (source_id, created_on, created_by) values (3, STR_TO_DATE('03/10/2018 22:46:01','%d/%m/%Y %H:%i:%s'), 'em-service-zixreporting-downloader-intanceC');


insert into step_type (source_id, name, step_order) values (1, 'DOWNLOAD', 1);
insert into step_type (source_id, name, step_order) values (1, 'SUMMARIZE', 2);
insert into step_type (source_id, name, step_order) values (1, 'IMPORT', 3);


-- Collection for Zix cluster 1 on October 1, 2018 - Data as collected, transformed and imported to the database
insert into step (step_type_id, collection_job_id, start_date, status)
values (1, 1, STR_TO_DATE('01/10/2018 10:30:21','%d/%m/%Y %H:%i:%s'), 'IN PROGRESS');
insert into step (collection_job_id, type, file_checksum, start_date, created_by, end_date, status)
values (1, 'SUMMARIZER', '84cc0ff83f42c13be129bb6826905965c13be1cc84cc0ff839bb6826905965f4',
        STR_TO_DATE('01/10/2018 10:40:21','%d/%m/%Y %H:%i:%s'), 'em-service-zixreporting-summarizer-c1-s2',
        STR_TO_DATE('01/10/2018 10:40:57','%d/%m/%Y %H:%i:%s'), 'SUCCESS');
insert into step (collection_job_id, type, file_checksum, start_date, created_by, end_date, status)
values (1, 'IMPORTER', '84cc0ff83f42c13be129bb6826905965c13be1cc84cc0ff839bb6826905965f4',
        STR_TO_DATE('01/10/2018 10:42:56','%d/%m/%Y %H:%i:%s'), 'em-service-csv-importer-c1-s4',
        STR_TO_DATE('01/10/2018 10:43:01','%d/%m/%Y %H:%i:%s'), 'SUCCESS');


-- Collection for Zix cluster 2 on October 1, 2018 - Data as collected but SUMMARIZER step ended up in ERROR
insert into step (collection_job_id, type, file_checksum, start_date, created_by, end_date, status)
values (2, 'DOWNLOADER', '6905965c13be9bb6821c84cc0ff83f429905965c13be1c84cc0ff83f42bb6826',
        STR_TO_DATE('01/10/2018 10:32:43','%d/%m/%Y %H:%i:%s'), 'em-service-zixreporting-downloader-intanceB',
        STR_TO_DATE('01/10/2018 10:33:01','%d/%m/%Y %H:%i:%s'), 'SUCCESS');
insert into step (collection_job_id, type, file_checksum, start_date, created_by, end_date, status)
values (2, 'SUMMARIZER', null,
        STR_TO_DATE('01/10/2018 10:45:40','%d/%m/%Y %H:%i:%s'), 'em-service-zixreporting-summarizer-c1-s3',
        STR_TO_DATE('01/10/2018 10:45:52','%d/%m/%Y %H:%i:%s'), 'ERROR');

insert into step_error (step_id, error)  SELECT LAST_INSERT_ID(), 'Malformed File';


-- Collection for Zix cluster 1 on October 2, 2018. Data as collected and transformed. Not imported yet
insert into step (collection_job_id, type, file_checksum, start_date, created_by, end_date, status)
values (3, 'DOWNLOADER', '120EA8A25E5D487BF68B5F7096440019CE114E4501D2F4E2DCEA3E17B546F339',
        STR_TO_DATE('02/10/2018 23:56:05','%d/%m/%Y %H:%i:%s'), 'em-service-zixreporting-downloader-intanceA',
        STR_TO_DATE('02/10/2018 23:57:02','%d/%m/%Y %H:%i:%s'), 'SUCCESS');
insert into step (collection_job_id, type, file_checksum, start_date, created_by, end_date, status)
values (3, 'SUMMARIZER', 'CE114E4501D2F4E2DCEA3E17B546F339120EA8A25E5D487BF68B5F7096440019',
        STR_TO_DATE('02/10/2018 23:58:21','%d/%m/%Y %H:%i:%s'), 'em-service-zixreporting-summarizer-c1-s2',
        STR_TO_DATE('02/10/2018 23:58:57','%d/%m/%Y %H:%i:%s'), 'SUCCESS');


-- Collection for Zix cluster 2 on October 2, 2018. Data as collected only
insert into step (collection_job_id, type, file_checksum, start_date, created_by, end_date, status)
values (4, 'DOWNLOADER', '7BF68B5F7096440019CE120EA8A25E5D48114E4501D2F4E2DCEA3E17B546F339',
        STR_TO_DATE('02/10/2018 22:46:14','%d/%m/%Y %H:%i:%s'), 'em-service-zixreporting-downloader-intanceB',
        STR_TO_DATE('02/10/2018 22:57:01','%d/%m/%Y %H:%i:%s'), 'SUCCESS');


insert into zix_usage(sender_domain, count, collection_job_id) values ("somedomain1.com", 52, 6);
insert into zix_usage(sender_domain, count, collection_job_id) values ("somedomain2.com", 230, 6);
insert into zix_usage(sender_domain, count, collection_job_id) values ("somedomain3.com", 86, 6);
insert into zix_usage(sender_domain, count, collection_job_id) values ("somedomain4.com", 220, 6);
insert into zix_usage(sender_domain, count, collection_job_id) values ("somedomain5.com", 40, 6);

-- Each step produces an OUTPUT file (it is the step.file_checksum). The next step in the flow will work on the output file from the previous step.
-- Therefore, to know which file was the input of a STEP we need to find the previous step with same Collection Job ID

--Supposing that we have Collection Job ID 3, which has a successful summarization
select file_checksum
from step
where collection_job_id = 3
and type = 'DOWNLOADER' -- (this is the previous step for a summarization)
;

-- If we want to know what were the input and out puts for all SUMMARIZER Steps
-- Ps. We can apply same query for other steps that has a file as output and consumes a file from previous steps.
select summirizer.id 'SUMMARIZER', downloader.file_checksum as 'INPUT', summirizer.file_checksum as 'OUTPUT'
from step downloader -- THIS IS THE PREVIOUS STEP
join step summirizer on downloader.collection_job_id = summirizer.collection_job_id
where downloader.type = 'DOWNLOADER'
and downloader.status = 'SUCCESS'
and summirizer.type = 'SUMMARIZER'
and summirizer.status = 'SUCCESS';

--Selecting Steps with error tracking to the previous step.
select summirizer.id as 'STEP_ID', summirizer.type as 'STEP', downloader.file_checksum as 'INPUT', summirizer.status, error.error,  downloader.type as 'PREVIOUS STEP'
from step downloader -- THIS IS THE PREVIOUS STEP
join step summirizer on downloader.collection_job_id = summirizer.collection_job_id
join step_error error on summirizer.id = error.step_id
where downloader.type = 'DOWNLOADER'
and downloader.status = 'SUCCESS'
and summirizer.type = 'SUMMARIZER'
and summirizer.status = 'ERROR';

-- If we want to apply a specific step to a file (let's use as an example file 120EA8A25E5D487BF68B5F7096440019CE114E4501D2F4E2DCEA3E17B546F339
-- that was summarized in the collection job 3) we need to answer two questions. The first question is: Is this file in a valid job collection
 -- (my previous step has this file as output and succeeded)?  And the second question is: There is a STEP with the same type as I for this file
 -- and that succeeded?

-- This query returns a SUMMARIZER Step ID if there is any succeeded for that file.
-- In this case the file is already summarized therefore it should not be processed
 select summirize.id
 from step download
 join step summirize on download.collection_job_id = summirize.collection_job_id
 where download.file_checksum = '120EA8A25E5D487BF68B5F7096440019CE114E4501D2F4E2DCEA3E17B546F339'
 and download.type = 'DOWNLOADER'
 and download.status = 'SUCCESS'
 and summirize.type = 'SUMMARIZER'
 and summirize.status = 'SUCCESS';

-- Supposing the following files:
-- 7BF68B5F7096440019CE120EA8A25E5D48114E4501D2F4E2DCEA3E17B546F339 from job 4.
-- 6905965c13be9bb6821c84cc0ff83f429905965c13be1c84cc0ff83f42bb6826 from job 2.
-- JOB 4 has only a Download step finished. Therefore it can be processed (query will return no summirize step for this file)
-- JOB 2 has a SUMMARIZER STEP but it finished with ERROR status. Therefore it can be processed (query will return no summirize step for this file)
-- JOB 4 query
select summirize.id
from step download
join step summirize on download.collection_job_id = summirize.collection_job_id
where download.file_checksum = '7BF68B5F7096440019CE120EA8A25E5D48114E4501D2F4E2DCEA3E17B546F339'
and download.type = 'DOWNLOADER'
and download.status = 'SUCCESS'
and summirize.type = 'SUMMARIZER'
and summirize.status = 'SUCCESS';
-- JOB 2 query
select summirize.id
from step download
join step summirize on download.collection_job_id = summirize.collection_job_id
where download.file_checksum = '6905965c13be9bb6821c84cc0ff83f429905965c13be1c84cc0ff83f42bb6826'
and download.type = 'DOWNLOADER'
and download.status = 'SUCCESS'
and summirize.type = 'SUMMARIZER'
and summirize.status = 'SUCCESS';

-- This is the query with generic params
select summirize.id
from step download
join step summirize on download.collection_job_id = summirize.collection_job_id
where download.file_checksum = :fileToBeProcessed
and download.type = :previousStep
and download.status = 'SUCCESS'
and summirize.type = :actualStep
and summirize.status = 'SUCCESS';

-- Other option would be find job that have no the actual step. In this case, the SUMMARIZER
select download.collection_job_id, download.id as downloadID, summirize.id as summirizeId
from step download
left join (select id, collection_job_id, type from step where  type = 'SUMMARIZER' and status = 'SUCCESS') as summirize
on download.collection_job_id = summirize.collection_job_id
where summirize.id is null -- Get only that ones with no summirizing process
and download.type = 'DOWNLOADER'
and download.status = 'SUCCESS';

--And if we want to find the job has no SUMMARIZER STEP for a specific file:
-- In this case we only process a file if it belowngs to a Collection JOB with no SUCCEEDED STEPS for the
-- Step to be taken.
select download.collection_job_id, download.id as downloadID, summirize.id as summirizeId
from step download
left join (select id, collection_job_id, type from step where  type = 'SUMMARIZER' and status = 'SUCCESS') as summirize -- this is the step to be taken
on download.collection_job_id = summirize.collection_job_id
where summirize.id is null -- Get only that ones with no summirizing process
and download.file_checksum = '7BF68B5F7096440019CE120EA8A25E5D48114E4501D2F4E2DCEA3E17B546F339'
and download.type = 'DOWNLOADER'
and download.status = 'SUCCESS';


-- Selecting finished Collection Job (not ARCHIVED)
select cj.id as 'collection job id', cj.start_date as 'Started on', s.end_date as 'Ended on'
from collection_job cj
join step s on cj.id = s.collection_job_id
where s.type ='IMPORTER' and s.status = 'SUCCESS';


--Selecting last step for each collection job based on Step ID
select s.collection_job_id, max(s.id)
from step s
where status = 'SUCCESS'
group by s.collection_job_id;

--Selecting last step for each collection job based on Step Start Date
select s.id as step, s.collection_job_id as collectionJob, s.type, s.start_date
from step s
join (
  select collection_job_id, MAX(start_date) as startDate
  from step
  where status = 'SUCCESS'
  group by collection_job_id
) as dateRef
on s.collection_job_id = dateRef.collection_job_id
where s.start_date = dateRef.startDate;

select * from collection_job;
select * from step;
select * from file;
select * from zix_usage;


delete from zix_usage;
delete from step_error;
delete from step;
delete from file;
delete from collection_job;


select s.step_id, s.step_type_id, s.collection_job_id, s.start_date, s.end_date, s.file_id, s.status, s.error
from step s
join collection_job cj using(collection_job_id)
where s.step_type_id = 1 and s.created_by = 'usage-user' and s.status <> 'FINISHED'
and cj.source_id = 2;

SELECT step_id, step_type_id, collection_job_id, start_date, end_date, file_id, status, error
FROM step s
JOIN collection_job cj using(collection_job_id)
WHERE s.step_type_id = 1 and s.created_by = 'usage-user' and s.status <> 'FINISHED'
and cj.source_id = 2;




    FuseMail
    Excel Micro
    
