-- Approval System database bootstrap script
-- Target database: MariaDB 10.6+ / MySQL 8+
-- Date synced with codebase: 2026-03-31
--
-- Scope:
-- 1. Creates the application database.
-- 2. Creates application tables currently mapped by JPA entities in this repository.
-- 3. Does not create Flowable engine tables; those remain managed by Flowable.

CREATE DATABASE IF NOT EXISTS approval_system
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE approval_system;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS sys_dept (
  id BIGINT NOT NULL AUTO_INCREMENT,
  parent_id BIGINT NULL,
  dept_code VARCHAR(64) NULL,
  dept_name VARCHAR(64) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_sys_dept_dept_code (dept_code),
  KEY idx_sys_dept_parent_id (parent_id),
  CONSTRAINT fk_sys_dept_parent
    FOREIGN KEY (parent_id) REFERENCES sys_dept (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sys_role (
  id BIGINT NOT NULL AUTO_INCREMENT,
  role_code VARCHAR(64) NOT NULL,
  role_name VARCHAR(64) NOT NULL,
  status INT NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uk_sys_role_role_code (role_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sys_post (
  id BIGINT NOT NULL AUTO_INCREMENT,
  post_code VARCHAR(64) NOT NULL,
  post_name VARCHAR(64) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_sys_post_post_code (post_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sys_user (
  id BIGINT NOT NULL AUTO_INCREMENT,
  username VARCHAR(64) NOT NULL,
  password VARCHAR(128) NULL,
  dept_id BIGINT NULL,
  status INT NOT NULL DEFAULT 1,
  two_factor_enabled INT NOT NULL DEFAULT 0,
  two_factor_secret VARCHAR(128) NULL,
  recovery_codes VARCHAR(512) NULL,
  last_login_at DATETIME NULL,
  login_failures INT NOT NULL DEFAULT 0,
  locked_until DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_sys_user_username (username),
  KEY idx_sys_user_dept_id (dept_id),
  CONSTRAINT fk_sys_user_dept
    FOREIGN KEY (dept_id) REFERENCES sys_dept (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sys_user_role (
  id BIGINT NOT NULL AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  role_id BIGINT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_sys_user_role_user_role (user_id, role_id),
  KEY idx_sys_user_role_role_id (role_id),
  CONSTRAINT fk_sys_user_role_user
    FOREIGN KEY (user_id) REFERENCES sys_user (id),
  CONSTRAINT fk_sys_user_role_role
    FOREIGN KEY (role_id) REFERENCES sys_role (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sys_user_post (
  id BIGINT NOT NULL AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  post_id BIGINT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_sys_user_post_user_post (user_id, post_id),
  KEY idx_sys_user_post_post_id (post_id),
  CONSTRAINT fk_sys_user_post_user
    FOREIGN KEY (user_id) REFERENCES sys_user (id),
  CONSTRAINT fk_sys_user_post_post
    FOREIGN KEY (post_id) REFERENCES sys_post (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sys_role_data_scope (
  id BIGINT NOT NULL AUTO_INCREMENT,
  role_id BIGINT NOT NULL,
  dept_id BIGINT NULL,
  scope_type VARCHAR(32) NOT NULL,
  PRIMARY KEY (id),
  KEY idx_sys_role_data_scope_role_id (role_id),
  KEY idx_sys_role_data_scope_dept_id (dept_id),
  CONSTRAINT fk_sys_role_data_scope_role
    FOREIGN KEY (role_id) REFERENCES sys_role (id),
  CONSTRAINT fk_sys_role_data_scope_dept
    FOREIGN KEY (dept_id) REFERENCES sys_dept (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sys_login_log (
  id BIGINT NOT NULL AUTO_INCREMENT,
  user_id BIGINT NULL,
  username VARCHAR(64) NULL,
  login_status INT NOT NULL,
  message VARCHAR(512) NULL,
  ip_address VARCHAR(64) NULL,
  user_agent VARCHAR(512) NULL,
  login_time DATETIME NULL,
  PRIMARY KEY (id),
  KEY idx_sys_login_log_user_id_login_time (user_id, login_time),
  KEY idx_sys_login_log_username_login_time (username, login_time),
  KEY idx_sys_login_log_login_time (login_time),
  CONSTRAINT fk_sys_login_log_user
    FOREIGN KEY (user_id) REFERENCES sys_user (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sys_user_import_job (
  id BIGINT NOT NULL AUTO_INCREMENT,
  file_name VARCHAR(255) NOT NULL,
  file_type VARCHAR(16) NOT NULL,
  file_checksum VARCHAR(128) NOT NULL,
  strategy VARCHAR(32) NOT NULL,
  status VARCHAR(32) NOT NULL,
  total_rows INT NOT NULL DEFAULT 0,
  success_rows INT NOT NULL DEFAULT 0,
  failed_rows INT NOT NULL DEFAULT 0,
  operator_id BIGINT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  finished_at DATETIME NULL,
  PRIMARY KEY (id),
  KEY idx_sys_user_import_job_operator_id (operator_id),
  KEY idx_sys_user_import_job_status_created_at (status, created_at),
  CONSTRAINT fk_sys_user_import_job_operator
    FOREIGN KEY (operator_id) REFERENCES sys_user (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sys_user_import_job_item (
  id BIGINT NOT NULL AUTO_INCREMENT,
  job_id BIGINT NOT NULL,
  row_no INT NOT NULL,
  username VARCHAR(64) NULL,
  raw_payload LONGTEXT NULL,
  result VARCHAR(32) NOT NULL,
  error_message VARCHAR(512) NULL,
  created_user_id BIGINT NULL,
  before_snapshot LONGTEXT NULL,
  after_snapshot LONGTEXT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_sys_user_import_job_item_job_row (job_id, row_no),
  KEY idx_sys_user_import_job_item_result (result),
  KEY idx_sys_user_import_job_item_created_user_id (created_user_id),
  CONSTRAINT fk_sys_user_import_job_item_job
    FOREIGN KEY (job_id) REFERENCES sys_user_import_job (id),
  CONSTRAINT fk_sys_user_import_job_item_created_user
    FOREIGN KEY (created_user_id) REFERENCES sys_user (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS form_definition (
  id BIGINT NOT NULL AUTO_INCREMENT,
  form_name VARCHAR(128) NOT NULL,
  form_key VARCHAR(64) NOT NULL,
  status INT NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uk_form_definition_form_key (form_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS form_version (
  id BIGINT NOT NULL AUTO_INCREMENT,
  form_id BIGINT NOT NULL,
  version INT NOT NULL,
  schema_json TEXT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_form_version_form_id_version (form_id, version),
  CONSTRAINT fk_form_version_form
    FOREIGN KEY (form_id) REFERENCES form_definition (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS form_field (
  id BIGINT NOT NULL AUTO_INCREMENT,
  form_version_id BIGINT NOT NULL,
  field_key VARCHAR(64) NOT NULL,
  field_type VARCHAR(32) NOT NULL,
  label VARCHAR(128) NULL,
  required INT NOT NULL DEFAULT 0,
  visible_rule TEXT NULL,
  validate_rule TEXT NULL,
  options_json TEXT NULL,
  PRIMARY KEY (id),
  KEY idx_form_field_form_version_id (form_version_id),
  KEY idx_form_field_field_key (field_key),
  CONSTRAINT fk_form_field_form_version
    FOREIGN KEY (form_version_id) REFERENCES form_version (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS form_instance (
  id BIGINT NOT NULL AUTO_INCREMENT,
  form_version_id BIGINT NOT NULL,
  business_key VARCHAR(64) NOT NULL,
  data_json TEXT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_form_instance_business_key (business_key),
  KEY idx_form_instance_form_version_id (form_version_id),
  CONSTRAINT fk_form_instance_form_version
    FOREIGN KEY (form_version_id) REFERENCES form_version (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS biz_request (
  id BIGINT NOT NULL AUTO_INCREMENT,
  business_key VARCHAR(64) NOT NULL,
  process_instance_id VARCHAR(64) NULL,
  process_definition_id VARCHAR(64) NULL,
  form_instance_id BIGINT NULL,
  applicant_id BIGINT NOT NULL,
  applicant_dept_id BIGINT NULL,
  applicant_post_id BIGINT NULL,
  title VARCHAR(128) NOT NULL,
  status INT NOT NULL,
  current_task_id VARCHAR(64) NULL,
  current_assignee_id BIGINT NULL,
  submit_time DATETIME NULL,
  finish_time DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  is_deleted INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk_biz_request_business_key (business_key),
  UNIQUE KEY uk_biz_request_process_instance_id (process_instance_id),
  KEY idx_biz_request_form_instance_id (form_instance_id),
  KEY idx_biz_request_applicant_id (applicant_id),
  KEY idx_biz_request_applicant_dept_id (applicant_dept_id),
  KEY idx_biz_request_applicant_post_id (applicant_post_id),
  KEY idx_biz_request_current_assignee_id (current_assignee_id),
  CONSTRAINT fk_biz_request_form_instance
    FOREIGN KEY (form_instance_id) REFERENCES form_instance (id),
  CONSTRAINT fk_biz_request_applicant
    FOREIGN KEY (applicant_id) REFERENCES sys_user (id),
  CONSTRAINT fk_biz_request_applicant_dept
    FOREIGN KEY (applicant_dept_id) REFERENCES sys_dept (id),
  CONSTRAINT fk_biz_request_applicant_post
    FOREIGN KEY (applicant_post_id) REFERENCES sys_post (id),
  CONSTRAINT fk_biz_request_current_assignee
    FOREIGN KEY (current_assignee_id) REFERENCES sys_user (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS biz_request_task (
  id BIGINT NOT NULL AUTO_INCREMENT,
  business_key VARCHAR(64) NOT NULL,
  process_instance_id VARCHAR(64) NOT NULL,
  task_id VARCHAR(64) NOT NULL,
  task_name VARCHAR(128) NULL,
  assignee_id BIGINT NULL,
  owner_id BIGINT NULL,
  status INT NOT NULL,
  action VARCHAR(32) NULL,
  comment VARCHAR(512) NULL,
  start_time DATETIME NULL,
  end_time DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_biz_request_task_task_id (task_id),
  KEY idx_biz_request_task_business_key (business_key),
  KEY idx_biz_request_task_process_instance_id (process_instance_id),
  KEY idx_biz_request_task_assignee_id (assignee_id),
  KEY idx_biz_request_task_owner_id (owner_id),
  CONSTRAINT fk_biz_request_task_business
    FOREIGN KEY (business_key) REFERENCES biz_request (business_key),
  CONSTRAINT fk_biz_request_task_assignee
    FOREIGN KEY (assignee_id) REFERENCES sys_user (id),
  CONSTRAINT fk_biz_request_task_owner
    FOREIGN KEY (owner_id) REFERENCES sys_user (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS biz_request_log (
  id BIGINT NOT NULL AUTO_INCREMENT,
  business_key VARCHAR(64) NOT NULL,
  process_instance_id VARCHAR(64) NULL,
  task_id VARCHAR(64) NULL,
  operator_id BIGINT NOT NULL,
  action VARCHAR(32) NOT NULL,
  comment VARCHAR(512) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_biz_request_log_business_key (business_key),
  KEY idx_biz_request_log_process_instance_id (process_instance_id),
  KEY idx_biz_request_log_task_id (task_id),
  KEY idx_biz_request_log_operator_id (operator_id),
  CONSTRAINT fk_biz_request_log_business
    FOREIGN KEY (business_key) REFERENCES biz_request (business_key),
  CONSTRAINT fk_biz_request_log_operator
    FOREIGN KEY (operator_id) REFERENCES sys_user (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ai_suggestion_record (
  id BIGINT NOT NULL AUTO_INCREMENT,
  business_key VARCHAR(64) NOT NULL,
  process_instance_id VARCHAR(64) NOT NULL,
  task_id VARCHAR(64) NOT NULL,
  requester_id BIGINT NOT NULL,
  model VARCHAR(128) NULL,
  suggestion_json LONGTEXT NOT NULL,
  conversation_json LONGTEXT NULL,
  adopted TINYINT(1) NOT NULL DEFAULT 0,
  adopted_at DATETIME NULL,
  final_approval_result VARCHAR(32) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_ai_suggestion_record_task_id_created_at (task_id, created_at),
  KEY idx_ai_suggestion_record_business_key_created_at (business_key, created_at),
  KEY idx_ai_suggestion_record_process_instance_id (process_instance_id),
  KEY idx_ai_suggestion_record_requester_id (requester_id),
  CONSTRAINT fk_ai_suggestion_record_business
    FOREIGN KEY (business_key) REFERENCES biz_request (business_key),
  CONSTRAINT fk_ai_suggestion_record_requester
    FOREIGN KEY (requester_id) REFERENCES sys_user (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
