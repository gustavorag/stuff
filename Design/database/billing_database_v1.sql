
CREATE DATABASE billing;
use billing;

CREATE TABLE file(
  checksum CHAR(128) NOT NULL COMMENT 'The Checksum of the file. It is used as ID to avoid reprocess the same file more than once.',
  name VARCHAR(255) NOT NULL COMMENT 'The name of the file.',
  num_rows INT NOT NULL COMMENT 'The number of rows in the file',
  created_on timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Audit column',
  created_by varchar(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  modified_on timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Audit column',
  modified_by varchar(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  CONSTRAINT pk_file PRIMARY KEY (checksum)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE vendor(
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Sequential ID to uniquely identify a vendor',
  name VARCHAR(255) NOT NULL COMMENT 'The name of the vendor.',
  created_on timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Audit column',
  created_by varchar(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  modified_on timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Audit column',
  modified_by varchar(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  CONSTRAINT pk_source PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE source(
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Sequential ID to uniquely identify a source',
  name VARCHAR(255) NOT NULL COMMENT 'Name of the source, describing the vendor and the specific source of the usage data. One vendor might have one or more sources.',
  vendor_id BIGINT UNSIGNED NOT NULL COMMENT 'The vendor which this source holds the usage data.',
  created_on timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Audit column',
  created_by varchar(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  modified_on timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Audit column',
  modified_by varchar(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  CONSTRAINT pk_source PRIMARY KEY (id),
  CONSTRAINT fk_source_vendor FOREIGN KEY (vendor_id) REFERENCES vendor (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE collection_job(
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Sequential ID to uniquely identify a job',
  source_id BIGINT UNSIGNED NOT NULL COMMENT 'Every job will collect usage data from a specific source. This column is a foreign key to the source where this job is fetching the data.',
  start_date TIMESTAMP NOT NULL COMMENT 'Date and time that represent when the collection job started.',
  created_on timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Audit column',
  created_by varchar(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  modified_on timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Audit column',
  modified_by varchar(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  CONSTRAINT pk_collection_job PRIMARY KEY (id),
  CONSTRAINT fk_cj_source FOREIGN KEY (source_id) REFERENCES source (id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE step(
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Sequential ID to uniquely identify a step',
  collection_job_id BIGINT UNSIGNED NOT NULL COMMENT 'Every job will collect usage data from a specific source. This column is a foreign key to the source where this job is fetching the data.',
  type ENUM('DOWNLOADER', 'TRANSLATER', 'SUMMARIZER', 'IMPORTER', 'ARCHIVER') NOT NULL COMMENT 'Steps can be one of the following: DOWNLOADER, TRANSLATER, SUMMARIZER, IMPORTER, ARCHIVER',
  file_checksum CHAR(128) COMMENT 'A step can output a file or work over one. This column links the step to that file. For download steps, it means the output file, for the others steps it means the file which the step worked over. In some cases, a step might end without having process any file (error status) resulting in a null value for this column.',
  created_on  TIMESTAMP NOT NULL COMMENT 'The time when this register was created in the database.',
  created_by VARCHAR(50) NOT NULL COMMENT 'The user responsible for create the collection job register. It might be a service as also a user operating a manual process.',
  start_date DATETIME NOT NULL COMMENT 'The date and time when the step started.',
  end_date DATETIME NOT NULL COMMENT 'The date and time when the step finished.',
  status ENUM('SUCCESS','ERROR') NOT NULL COMMENT 'Status is the result of the step process. Steps processing can end in one of the following status: SUCCESS - Means the step executed successfully and produced the expected result. ERROR - Means that the step executed improperly and end up in an error. Some causes of error are: error while trying to save a file, network failure, malformed file, etc.',
  CONSTRAINT pk_step PRIMARY KEY (id),
  CONSTRAINT fk_step_cj FOREIGN KEY (collection_job_id) REFERENCES collection_job (id),
  CONSTRAINT fk_step_file FOREIGN KEY (file_checksum) REFERENCES file (checksum)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE zix_usage(
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Sequential ID to uniquely identify a source.',
  sender_domain VARCHAR(255) NOT NULL COMMENT 'The name of the source, describing the vendor and the specific source of usage data. One vendor might have one or more sources.',
  count INT NOT NULL COMMENT 'The usage number for a specific domain.',
  collection_job_id BIGINT UNSIGNED NOT NULL COMMENT 'Each usage data is related to the collection job that loaded this data into the database. This column links the usage to a specific job.',
  CONSTRAINT pk_zix_usage PRIMARY KEY (id),
  CONSTRAINT fk_zix_usage_cj FOREIGN KEY (collection_job_id) REFERENCES collection_job (id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
