ALTER TABLE biz_request ADD COLUMN IF NOT EXISTS workflow_definition_id BIGINT NULL;
ALTER TABLE biz_request ADD COLUMN IF NOT EXISTS workflow_definition_version_id BIGINT NULL;
ALTER TABLE biz_request ADD COLUMN IF NOT EXISTS form_version_id BIGINT NULL;

CREATE TABLE IF NOT EXISTS workflow_definition (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    process_key VARCHAR(64) NOT NULL,
    process_name VARCHAR(128) NOT NULL,
    category VARCHAR(64) NULL,
    description VARCHAR(512) NULL,
    status VARCHAR(32) NOT NULL,
    current_version_id BIGINT NULL,
    latest_version_no INT NOT NULL DEFAULT 0,
    created_by BIGINT NOT NULL,
    updated_by BIGINT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    is_deleted TINYINT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS workflow_definition_version (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    definition_id BIGINT NOT NULL,
    version_no INT NOT NULL,
    version_label VARCHAR(64) NULL,
    status VARCHAR(32) NOT NULL,
    bpmn_xml CLOB NOT NULL,
    bpmn_checksum VARCHAR(64) NULL,
    flowable_deployment_id VARCHAR(64) NULL,
    flowable_process_definition_id VARCHAR(128) NULL,
    form_key VARCHAR(64) NULL,
    form_version_id BIGINT NULL,
    change_summary VARCHAR(1000) NULL,
    published_by BIGINT NULL,
    published_at DATETIME NULL,
    created_by BIGINT NOT NULL,
    updated_by BIGINT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    is_deleted TINYINT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS workflow_node_config (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    definition_version_id BIGINT NOT NULL,
    node_id VARCHAR(64) NOT NULL,
    node_name VARCHAR(128) NOT NULL,
    node_type VARCHAR(32) NOT NULL,
    approval_type VARCHAR(32) NULL,
    assignee_strategy VARCHAR(32) NULL,
    assignee_config_json CLOB NULL,
    comment_required TINYINT NOT NULL DEFAULT 1,
    allow_delegate TINYINT NOT NULL DEFAULT 1,
    allow_reassign TINYINT NOT NULL DEFAULT 1,
    allow_return_previous TINYINT NOT NULL DEFAULT 1,
    allow_return_applicant TINYINT NOT NULL DEFAULT 1,
    ai_enabled TINYINT NOT NULL DEFAULT 0,
    timeout_rule_json CLOB NULL,
    extra_config_json CLOB NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL
);

CREATE TABLE IF NOT EXISTS workflow_publish_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    definition_id BIGINT NOT NULL,
    definition_version_id BIGINT NOT NULL,
    action VARCHAR(32) NOT NULL,
    result VARCHAR(32) NOT NULL,
    message VARCHAR(1000) NULL,
    flowable_deployment_id VARCHAR(64) NULL,
    flowable_process_definition_id VARCHAR(128) NULL,
    operator_id BIGINT NOT NULL,
    operated_at DATETIME NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_workflow_definition_process_key ON workflow_definition(process_key);
CREATE INDEX IF NOT EXISTS idx_workflow_definition_status ON workflow_definition(status);
CREATE INDEX IF NOT EXISTS idx_workflow_definition_category ON workflow_definition(category);
CREATE INDEX IF NOT EXISTS idx_workflow_definition_current_version ON workflow_definition(current_version_id);

CREATE UNIQUE INDEX IF NOT EXISTS uk_wf_definition_version ON workflow_definition_version(definition_id, version_no);
CREATE INDEX IF NOT EXISTS idx_wf_version_status ON workflow_definition_version(status);
CREATE INDEX IF NOT EXISTS idx_wf_version_definition ON workflow_definition_version(definition_id);
CREATE INDEX IF NOT EXISTS idx_wf_version_form_version ON workflow_definition_version(form_version_id);
CREATE INDEX IF NOT EXISTS idx_wf_version_flowable_pd ON workflow_definition_version(flowable_process_definition_id);
CREATE INDEX IF NOT EXISTS idx_wf_version_published_at ON workflow_definition_version(published_at);

CREATE UNIQUE INDEX IF NOT EXISTS uk_wf_node_config ON workflow_node_config(definition_version_id, node_id);
CREATE INDEX IF NOT EXISTS idx_wf_node_config_version ON workflow_node_config(definition_version_id);
CREATE INDEX IF NOT EXISTS idx_wf_node_config_node_type ON workflow_node_config(node_type);
CREATE INDEX IF NOT EXISTS idx_wf_node_config_approval_type ON workflow_node_config(approval_type);

CREATE INDEX IF NOT EXISTS idx_wf_publish_log_definition ON workflow_publish_log(definition_id);
CREATE INDEX IF NOT EXISTS idx_wf_publish_log_version ON workflow_publish_log(definition_version_id);
CREATE INDEX IF NOT EXISTS idx_wf_publish_log_action ON workflow_publish_log(action);
CREATE INDEX IF NOT EXISTS idx_wf_publish_log_result ON workflow_publish_log(result);
CREATE INDEX IF NOT EXISTS idx_wf_publish_log_operated_at ON workflow_publish_log(operated_at);

CREATE INDEX IF NOT EXISTS idx_biz_request_workflow_definition ON biz_request(workflow_definition_id);
CREATE INDEX IF NOT EXISTS idx_biz_request_workflow_definition_version ON biz_request(workflow_definition_version_id);
CREATE INDEX IF NOT EXISTS idx_biz_request_form_version ON biz_request(form_version_id);
