CREATE DATABASE billing;
use billing;

CREATE TABLE file(
  file_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Sequential ID to uniquely identify a file',
  checksum CHAR(128) NOT NULL COMMENT 'The Checksum of the file.',
  name VARCHAR(255) NOT NULL COMMENT 'The name of the file.',
  file_path VARCHAR(255) NOT NULL COMMENT 'File full path',
  created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Audit column',
  created_by VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  CONSTRAINT pk_file PRIMARY KEY (file_id),
  CONSTRAINT unique_checksum UNIQUE (checksum)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE vendor(
  vendor_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Sequential ID to uniquely identify a vendor',
  name VARCHAR(255) NOT NULL COMMENT 'The name of the vendor.',
  created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Audit column',
  created_by VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  modified_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Audit column',
  modified_by VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  CONSTRAINT pk_source PRIMARY KEY (vendor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE source(
  source_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Sequential ID to uniquely identify a source',
  name VARCHAR(255) NOT NULL COMMENT 'Name of the source, describing the specific vendor\'s source of the usage data. One vendor might have one or more sources.',
  vendor_id BIGINT UNSIGNED NOT NULL COMMENT 'The vendor which this source holds the usage data.',
  created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Audit column',
  created_by VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  modified_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Audit column',
  modified_by VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  CONSTRAINT pk_source PRIMARY KEY (source_id),
  CONSTRAINT fk_source_vendor FOREIGN KEY (vendor_id) REFERENCES vendor (vendor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE step_type(
  step_type_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Sequential ID to uniquely identify a step type',
  source_id BIGINT UNSIGNED NOT NULL COMMENT 'Every job will collect usage data from a specific source. This column is a foreign key to the source where this job is fetching the data.',
  name ENUM('DOWNLOAD', 'TRANSLATE', 'SUMMARIZE', 'IMPORT', 'ARCHIVE') NOT NULL COMMENT 'Steps can be one of the following: DOWNLOADER, TRANSLATER, SUMMARIZER, IMPORTER, ARCHIVER',
  step_order INT UNSIGNED NOT NULL COMMENT 'Indicates the order of this step for the source. Different sources may have different order for same steps types.',
  created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Audit column',
  created_by VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  modified_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Audit column',
  modified_by VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  CONSTRAINT pk_step_type PRIMARY KEY (step_type_id),
  CONSTRAINT fk_step_type_source FOREIGN KEY (source_id) REFERENCES source (source_id),
  CONSTRAINT unique_source_order UNIQUE (source_id, step_order)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE collection_job(
  collection_job_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Sequential ID to uniquely identify a job',
  source_id BIGINT UNSIGNED NOT NULL COMMENT 'Every job will collect usage data from a specific source. This column is a foreign key to the source FROM where the job is fetching the data.',
  status ENUM ('IN PROGRESS', 'FINISHED', 'ERROR') NOT NULL COMMENT 'Jobs have the following status: PROGRESS: job created and Steps still running. FINISHED: all steps finished. ERROR: some step finished in error status',
  current_step_type_id BIGINT UNSIGNED NOT NULL COMMENT 'Foreign key to the current job\'s step in execution or finished',
  start_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Date and time that represent when the collection job started.',
  end_date TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Date and time that represent when the collection job finished (all steps done).',
  created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Audit column',
  created_by VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  modified_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Audit column',
  modified_by VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  CONSTRAINT pk_collection_job PRIMARY KEY (collection_job_id),
  CONSTRAINT fk_cj_source FOREIGN KEY (source_id) REFERENCES source (source_id),
  CONSTRAINT fk_cj_curr_step_type_id FOREIGN KEY (current_step_type_id) REFERENCES step_type (step_type_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE step(
  step_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Sequential ID to uniquely identify a step',
  step_type_id BIGINT UNSIGNED NOT NULL COMMENT 'foreign key to the Step Type',
  collection_job_id BIGINT UNSIGNED NOT NULL COMMENT 'Every job will collect usage data from a specific source. This column is a foreign key to the source where this job is fetching the data.',
  start_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The date and time when the step started.',
  end_date DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'The date and time when the step finished.',
  file_id BIGINT UNSIGNED COMMENT 'foreign key to the file CREATED or PROCESSED by this step',
  status ENUM('IN PROGRESS', 'FINISHED', 'ERROR') NOT NULL COMMENT 'Represents the step status. When a step is created, is has PROGRESS status. When a step finishes it is updated to FINISHED or ERROR if ended in error.',
  error TEXT NOT NULL DEFAULT '' COMMENT 'The error description if the step ends up in error. For example "Was not possible to save the file. Repository not available".',
  created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Audit column',
  created_by VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  modified_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Audit column',
  modified_by VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'Audit column',
  CONSTRAINT pk_step PRIMARY KEY (step_id),
  CONSTRAINT fk_step_step_type FOREIGN KEY (step_type_id) REFERENCES step_type (step_type_id),
  CONSTRAINT fk_step_cj FOREIGN KEY (collection_job_id) REFERENCES collection_job (collection_job_id),
  CONSTRAINT fk_step_file FOREIGN KEY (file_id) REFERENCES file (file_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
