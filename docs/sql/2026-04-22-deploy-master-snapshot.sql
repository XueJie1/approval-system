-- Approval System master-data deployment snapshot
-- Source: local database approval_system (2026-04-22)
-- Purpose: one-shot deploy of current core schema + baseline master/config data on a new machine.
-- Notes:
--   1) This script creates/rebuilds core application tables listed below.
--   2) This script does NOT include Flowable engine tables (ACT_*, FLW_*).
--   3) This script does NOT include request runtime history tables (biz_request*, ai_suggestion_record).

CREATE DATABASE IF NOT EXISTS approval_system
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE approval_system;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS workflow_publish_log;
DROP TABLE IF EXISTS workflow_node_config;
DROP TABLE IF EXISTS workflow_definition_version;
DROP TABLE IF EXISTS workflow_definition;
DROP TABLE IF EXISTS request_template;
DROP TABLE IF EXISTS form_field;
DROP TABLE IF EXISTS form_instance;
DROP TABLE IF EXISTS form_version;
DROP TABLE IF EXISTS form_definition;
DROP TABLE IF EXISTS sys_setting;
DROP TABLE IF EXISTS sys_role_data_scope;
DROP TABLE IF EXISTS sys_user_post;
DROP TABLE IF EXISTS sys_user_role;
DROP TABLE IF EXISTS sys_login_log;
DROP TABLE IF EXISTS sys_user_import_job_item;
DROP TABLE IF EXISTS sys_user_import_job;
DROP TABLE IF EXISTS sys_user;
DROP TABLE IF EXISTS sys_role;
DROP TABLE IF EXISTS sys_post;
DROP TABLE IF EXISTS sys_dept;

/*M!999999\- enable the sandbox mode */ 
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_dept` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `parent_id` bigint(20) DEFAULT NULL,
  `dept_code` varchar(64) DEFAULT NULL,
  `dept_name` varchar(64) NOT NULL,
  `leader_user_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sys_dept_dept_code` (`dept_code`),
  KEY `idx_sys_dept_parent_id` (`parent_id`),
  CONSTRAINT `fk_sys_dept_parent` FOREIGN KEY (`parent_id`) REFERENCES `sys_dept` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
REPLACE INTO `sys_dept` (`id`, `parent_id`, `dept_code`, `dept_name`, `leader_user_id`) VALUES (1,5,'DEV_DEPT','研发部',7),
(2,7,'HR_DEPT','人力资源部',17),
(3,7,'FINANCE_DEPT','财务部',14),
(4,NULL,'COMPANY_HQ','公司总部',8),
(5,4,'PRD_CENTER','产品与研发中心',11),
(6,4,'GTM_CENTER','市场与增长中心',8),
(7,4,'CORP_CENTER','职能支持中心',8),
(8,5,'PRODUCT_DEPT','产品部',21),
(9,5,'QA_DEPT','测试质量部',23),
(10,5,'SRE_DEPT','运维与SRE部',30),
(11,5,'DATA_AI_DEPT','数据与算法部',13),
(12,6,'MARKETING_DEPT','市场品牌部',24),
(13,6,'SALES_DEPT','销售部',24),
(14,6,'CS_DEPT','客户成功部',9),
(15,7,'LEGAL_DEPT','法务合规部',19),
(16,7,'ADMIN_DEPT','行政采购部',17),
(17,7,'SECURITY_DEPT','信息安全部',28);
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_post` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `post_code` varchar(64) NOT NULL,
  `post_name` varchar(64) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sys_post_post_code` (`post_code`)
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
REPLACE INTO `sys_post` (`id`, `post_code`, `post_name`) VALUES (4,'CEO','首席执行官'),
(5,'CTO','首席技术官'),
(6,'HR_DIRECTOR','人力总监'),
(7,'FINANCE_MANAGER','财务经理'),
(8,'LEGAL_MANAGER','法务经理'),
(9,'SECURITY_MANAGER','信息安全负责人'),
(10,'PRODUCT_MANAGER','产品经理'),
(11,'BACKEND_LEAD','后端负责人'),
(12,'BACKEND_ENGINEER','后端开发工程师'),
(13,'FRONTEND_LEAD','前端负责人'),
(14,'FRONTEND_ENGINEER','前端开发工程师'),
(15,'QA_LEAD','测试负责人'),
(16,'QA_ENGINEER','测试工程师'),
(17,'SRE_LEAD','SRE负责人'),
(18,'SRE_ENGINEER','SRE工程师'),
(19,'DATA_LEAD','数据负责人'),
(20,'DATA_ENGINEER','数据工程师'),
(21,'HR_SPECIALIST','人力专员'),
(22,'ACCOUNTANT','会计'),
(23,'LEGAL_SPECIALIST','法务专员'),
(24,'SALES_MANAGER','销售经理'),
(25,'SALES_REP','销售代表'),
(26,'CS_MANAGER','客户成功经理'),
(27,'CS_SPECIALIST','客户成功专员'),
(28,'SECURITY_ENGINEER','安全工程师');
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_role` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `role_code` varchar(64) NOT NULL,
  `role_name` varchar(64) NOT NULL,
  `status` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sys_role_role_code` (`role_code`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
REPLACE INTO `sys_role` (`id`, `role_code`, `role_name`, `status`) VALUES (1,'ADMIN','系统管理员',1),
(3,'CEO','首席执行官',1),
(4,'CTO','首席技术官',1),
(5,'HR_DIRECTOR','人力总监',1),
(6,'FINANCE_MANAGER','财务经理',1),
(7,'LEGAL_MANAGER','法务经理',1),
(8,'SECURITY_MANAGER','安全负责人',1),
(9,'PRODUCT_MANAGER','产品经理',1),
(10,'TECH_LEAD','技术负责人',1),
(11,'BACKEND_ENGINEER','后端工程师',1),
(12,'FRONTEND_ENGINEER','前端工程师',1),
(13,'QA_ENGINEER','测试工程师',1),
(14,'SRE_ENGINEER','SRE工程师',1),
(15,'DATA_ENGINEER','数据工程师',1),
(16,'SECURITY_ENGINEER','安全工程师',1),
(17,'HR_SPECIALIST','人力专员',1),
(18,'FINANCE_SPECIALIST','财务专员',1),
(19,'LEGAL_SPECIALIST','法务专员',1),
(20,'SALES_MANAGER','销售经理',1),
(21,'SALES_REP','销售代表',1),
(22,'CUSTOMER_SUCCESS','客户成功',1),
(23,'EMPLOYEE','普通员工',1),
(24,'SYS_ADMIN','系统超级管理员',1);
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL,
  `password` varchar(128) DEFAULT NULL,
  `dept_id` bigint(20) DEFAULT NULL,
  `status` int(11) NOT NULL DEFAULT 1,
  `two_factor_enabled` int(11) NOT NULL DEFAULT 0,
  `two_factor_secret` varchar(128) DEFAULT NULL,
  `recovery_codes` varchar(512) DEFAULT NULL,
  `last_login_at` datetime DEFAULT NULL,
  `login_failures` int(11) NOT NULL DEFAULT 0,
  `locked_until` datetime DEFAULT NULL,
  `manager_user_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sys_user_username` (`username`),
  KEY `idx_sys_user_dept_id` (`dept_id`),
  CONSTRAINT `fk_sys_user_dept` FOREIGN KEY (`dept_id`) REFERENCES `sys_dept` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
REPLACE INTO `sys_user` (`id`, `username`, `password`, `dept_id`, `status`, `two_factor_enabled`, `two_factor_secret`, `recovery_codes`, `last_login_at`, `login_failures`, `locked_until`, `manager_user_id`) VALUES (1,'admin','$2a$10$.ZsldZ8qP4d84i0JWAmq2.X..WFXvhJ7oBFNAQAUDt/ZFPFovXqqK',NULL,1,0,NULL,NULL,'2026-04-22 18:02:14',0,NULL,NULL),
(4,'accountant_1',NULL,3,1,0,NULL,NULL,NULL,0,NULL,14),
(5,'backend_dev_1','$2a$10$iee.yC08HdJo.DUipbaFMu3J3uz6aQXct79IIvpCvhkI9w3mJJzsy',1,1,0,NULL,NULL,'2026-04-22 18:00:40',0,NULL,7),
(6,'backend_dev_2',NULL,1,1,0,NULL,NULL,NULL,0,NULL,7),
(7,'backend_lead','$2a$10$X7SY0Kkyoev3beSZJtY7.OOgX6bf5Id1zLC0rf3Gh3GjaDjQLGnp.',1,1,0,NULL,NULL,'2026-04-15 22:33:11',0,NULL,11),
(8,'ceo',NULL,4,1,0,NULL,NULL,NULL,0,NULL,NULL),
(9,'cs_manager_1',NULL,14,1,0,NULL,NULL,NULL,0,NULL,8),
(10,'cs_specialist_1','$2a$10$kc0ZBocbj9PmLB9j9IXgGe06Nkfqw0.JtI5YDTm8rt2ush811ZRLC',14,1,0,NULL,NULL,'2026-04-16 10:26:43',0,NULL,9),
(11,'cto',NULL,5,1,0,NULL,NULL,NULL,0,NULL,8),
(12,'data_engineer_1',NULL,11,1,0,NULL,NULL,NULL,0,NULL,13),
(13,'data_lead',NULL,11,1,0,NULL,NULL,NULL,0,NULL,11),
(14,'finance_manager',NULL,3,1,0,NULL,NULL,NULL,0,NULL,8),
(15,'frontend_dev_1',NULL,1,1,0,NULL,NULL,NULL,0,NULL,16),
(16,'frontend_lead',NULL,1,1,0,NULL,NULL,NULL,0,NULL,11),
(17,'hr_director',NULL,2,1,0,NULL,NULL,NULL,0,NULL,8),
(18,'hr_specialist_1',NULL,2,1,0,NULL,NULL,NULL,0,NULL,17),
(19,'legal_manager',NULL,15,1,0,NULL,NULL,NULL,0,NULL,8),
(20,'legal_specialist_1',NULL,15,1,0,NULL,NULL,NULL,0,NULL,19),
(21,'product_manager_1',NULL,8,1,0,NULL,NULL,NULL,0,NULL,11),
(22,'qa_engineer_1',NULL,9,1,0,NULL,NULL,NULL,0,NULL,23),
(23,'qa_lead',NULL,9,1,0,NULL,NULL,NULL,0,NULL,11),
(24,'sales_manager_1',NULL,13,1,0,NULL,NULL,NULL,0,NULL,8),
(25,'sales_rep_1',NULL,13,1,0,NULL,NULL,NULL,0,NULL,24),
(26,'sales_rep_2',NULL,13,1,0,NULL,NULL,NULL,0,NULL,24),
(27,'security_engineer_1',NULL,17,1,0,NULL,NULL,NULL,0,NULL,28),
(28,'security_manager',NULL,17,1,0,NULL,NULL,NULL,0,NULL,8),
(29,'sre_engineer_1',NULL,10,1,0,NULL,NULL,NULL,0,NULL,30),
(30,'sre_lead',NULL,10,1,0,NULL,NULL,NULL,0,NULL,11);
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user_post` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `post_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sys_user_post_user_post` (`user_id`,`post_id`),
  KEY `idx_sys_user_post_post_id` (`post_id`),
  CONSTRAINT `fk_sys_user_post_post` FOREIGN KEY (`post_id`) REFERENCES `sys_post` (`id`),
  CONSTRAINT `fk_sys_user_post_user` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
REPLACE INTO `sys_user_post` (`id`, `user_id`, `post_id`) VALUES (3,4,22),
(4,5,12),
(5,6,12),
(6,7,11),
(7,8,4),
(8,9,26),
(9,10,27),
(10,11,5),
(11,12,20),
(12,13,19),
(13,14,7),
(14,15,14),
(15,16,13),
(16,17,6),
(17,18,21),
(18,19,8),
(19,20,23),
(20,21,10),
(21,22,16),
(22,23,15),
(23,24,24),
(24,25,25),
(25,26,25),
(26,27,28),
(27,28,9),
(28,29,18),
(29,30,17);
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user_role` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `role_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sys_user_role_user_role` (`user_id`,`role_id`),
  KEY `idx_sys_user_role_role_id` (`role_id`),
  CONSTRAINT `fk_sys_user_role_role` FOREIGN KEY (`role_id`) REFERENCES `sys_role` (`id`),
  CONSTRAINT `fk_sys_user_role_user` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
REPLACE INTO `sys_user_role` (`id`, `user_id`, `role_id`) VALUES (1,1,1),
(4,4,18),
(5,5,11),
(6,6,11),
(7,7,10),
(8,8,3),
(9,9,22),
(10,10,22),
(11,11,4),
(12,12,15),
(13,13,10),
(14,14,6),
(15,15,12),
(16,16,10),
(17,17,5),
(18,18,17),
(19,19,7),
(20,20,19),
(21,21,9),
(22,22,13),
(23,23,10),
(24,24,20),
(25,25,21),
(26,26,21),
(27,27,16),
(28,28,8),
(29,29,14),
(30,30,10),
(31,1,24);
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_role_data_scope` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `role_id` bigint(20) NOT NULL,
  `dept_id` bigint(20) DEFAULT NULL,
  `scope_type` varchar(32) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sys_role_data_scope_role_id` (`role_id`),
  KEY `idx_sys_role_data_scope_dept_id` (`dept_id`),
  CONSTRAINT `fk_sys_role_data_scope_dept` FOREIGN KEY (`dept_id`) REFERENCES `sys_dept` (`id`),
  CONSTRAINT `fk_sys_role_data_scope_role` FOREIGN KEY (`role_id`) REFERENCES `sys_role` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_setting` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `encrypted` int(11) NOT NULL,
  `setting_key` varchar(128) NOT NULL,
  `setting_value` text DEFAULT NULL,
  `updated_at` datetime(6) NOT NULL,
  `updated_by` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKfak4nv0gv2peduvjyh41g41ar` (`setting_key`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
REPLACE INTO `sys_setting` (`id`, `created_at`, `encrypted`, `setting_key`, `setting_value`, `updated_at`, `updated_by`) VALUES (1,'2026-04-15 20:36:04.162407',0,'ai.llm.openai.base-url','https://localhost:8317/v1','2026-04-15 20:36:04.162407',1),
(2,'2026-04-15 20:36:04.170287',1,'ai.llm.openai.api-key','v1:KptR4QSAsOAan6zfzTT3ApcBaURnaQqrpMBimbdY1z1sVmnfeUvOywgkGFo2yswM3Ph23YWmiFoeGeE9JIXvuQojedxqex5QheVVv5o06Q==','2026-04-15 20:36:04.170287',1),
(3,'2026-04-15 23:37:31.937550',0,'ai.llm.openai.model','gpt-5.4-mini','2026-04-16 10:31:41.579074',1);
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `form_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `form_name` varchar(128) NOT NULL,
  `form_key` varchar(64) NOT NULL,
  `status` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_form_definition_form_key` (`form_key`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
REPLACE INTO `form_definition` (`id`, `form_name`, `form_key`, `status`) VALUES (1,'请假申请表','leave_request',1),
(2,'报销申请表','expense_request',1),
(3,'出差申请表','travel_request',1),
(4,'采购申请表','purchase_request',1),
(5,'用章申请表','seal_request',1),
(6,'合同审批表','contract_request',1),
(7,'test2','test2',1);
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `form_version` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `form_id` bigint(20) NOT NULL,
  `version` int(11) NOT NULL,
  `schema_json` text NOT NULL,
  `published_at` datetime(6) DEFAULT NULL,
  `published_by` bigint(20) DEFAULT NULL,
  `status` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_form_version_form_id_version` (`form_id`,`version`),
  CONSTRAINT `fk_form_version_form` FOREIGN KEY (`form_id`) REFERENCES `form_definition` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
REPLACE INTO `form_version` (`id`, `form_id`, `version`, `schema_json`, `published_at`, `published_by`, `status`) VALUES (1,1,1,'{\"fields\":[{\"key\":\"leaveType\",\"type\":\"select\",\"label\":\"请假类型\",\"required\":true,\"options\":[\"事假\",\"病假\",\"年假\"]},{\"key\":\"startDate\",\"type\":\"datetime\",\"label\":\"开始时间\",\"required\":true},{\"key\":\"endDate\",\"type\":\"datetime\",\"label\":\"结束时间\",\"required\":true},{\"key\":\"days\",\"type\":\"number\",\"label\":\"请假天数\",\"required\":true},{\"key\":\"reason\",\"type\":\"string\",\"label\":\"请假原因\",\"required\":true}]}','2026-04-22 17:58:34.638389',0,'PUBLISHED'),
(2,2,1,'{\"fields\":[{\"key\":\"expenseType\",\"type\":\"select\",\"label\":\"费用类型\",\"required\":true,\"options\":[\"差旅\",\"餐饮\",\"办公\"]},{\"key\":\"amount\",\"type\":\"number\",\"label\":\"报销金额\",\"required\":true},{\"key\":\"occurredOn\",\"type\":\"date\",\"label\":\"发生日期\",\"required\":true},{\"key\":\"reason\",\"type\":\"string\",\"label\":\"报销事由\",\"required\":true}]}','2026-04-22 17:58:34.667806',0,'PUBLISHED'),
(3,3,1,'{\"fields\":[{\"key\":\"destination\",\"type\":\"string\",\"label\":\"出差地点\",\"required\":true},{\"key\":\"startDate\",\"type\":\"datetime\",\"label\":\"出差开始时间\",\"required\":true},{\"key\":\"endDate\",\"type\":\"datetime\",\"label\":\"出差结束时间\",\"required\":true},{\"key\":\"budget\",\"type\":\"number\",\"label\":\"预计预算\",\"required\":false},{\"key\":\"reason\",\"type\":\"string\",\"label\":\"出差事由\",\"required\":true}]}','2026-04-15 20:32:37.525378',0,'PUBLISHED'),
(4,4,1,'{\"fields\":[{\"key\":\"itemName\",\"type\":\"string\",\"label\":\"采购物品\",\"required\":true},{\"key\":\"quantity\",\"type\":\"number\",\"label\":\"数量\",\"required\":true},{\"key\":\"amount\",\"type\":\"number\",\"label\":\"预算金额\",\"required\":true},{\"key\":\"reason\",\"type\":\"string\",\"label\":\"采购原因\",\"required\":true}]}','2026-04-22 17:58:34.681405',0,'PUBLISHED'),
(5,5,1,'{\"fields\":[{\"key\":\"sealType\",\"type\":\"select\",\"label\":\"用章类型\",\"required\":true,\"options\":[\"公章\",\"合同章\",\"财务章\"]},{\"key\":\"documentName\",\"type\":\"string\",\"label\":\"文件名称\",\"required\":true},{\"key\":\"copies\",\"type\":\"number\",\"label\":\"份数\",\"required\":true},{\"key\":\"reason\",\"type\":\"string\",\"label\":\"用章事由\",\"required\":true}]}','2026-04-22 17:58:34.687962',0,'PUBLISHED'),
(6,6,1,'{\"fields\":[{\"key\":\"contractName\",\"type\":\"string\",\"label\":\"合同名称\",\"required\":true},{\"key\":\"counterparty\",\"type\":\"string\",\"label\":\"合同对方\",\"required\":true},{\"key\":\"amount\",\"type\":\"number\",\"label\":\"合同金额\",\"required\":true},{\"key\":\"riskNote\",\"type\":\"string\",\"label\":\"风险说明\",\"required\":false}]}','2026-04-22 17:58:34.694883',0,'PUBLISHED'),
(7,3,2,'{\"fields\":[{\"key\":\"destination\",\"type\":\"string\",\"label\":\"出差地点\",\"required\":true},{\"key\":\"startDate\",\"type\":\"datetime\",\"label\":\"出差开始时间\",\"required\":true},{\"key\":\"endDate\",\"type\":\"datetime\",\"label\":\"出差结束时间\",\"required\":true},{\"key\":\"budget\",\"type\":\"number\",\"label\":\"预计预算\",\"required\":false},{\"key\":\"reason\",\"type\":\"string\",\"label\":\"出差事由\",\"required\":true}]}','2026-04-22 17:58:34.674152',0,'PUBLISHED'),
(8,7,1,'{\"fields\": []}','2026-04-20 20:38:07.779905',1,'ARCHIVED'),
(9,7,2,'{\"fields\": []}','2026-04-20 20:59:53.152247',1,'PUBLISHED');
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `form_field` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `form_version_id` bigint(20) NOT NULL,
  `field_key` varchar(64) NOT NULL,
  `field_type` varchar(32) NOT NULL,
  `label` varchar(128) DEFAULT NULL,
  `required` int(11) NOT NULL DEFAULT 0,
  `visible_rule` text DEFAULT NULL,
  `validate_rule` text DEFAULT NULL,
  `options_json` text DEFAULT NULL,
  `default_value` text DEFAULT NULL,
  `sort_order` int(11) DEFAULT NULL,
  `variable_key` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_form_field_form_version_id` (`form_version_id`),
  KEY `idx_form_field_field_key` (`field_key`),
  CONSTRAINT `fk_form_field_form_version` FOREIGN KEY (`form_version_id`) REFERENCES `form_version` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=738 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
REPLACE INTO `form_field` (`id`, `form_version_id`, `field_key`, `field_type`, `label`, `required`, `visible_rule`, `validate_rule`, `options_json`, `default_value`, `sort_order`, `variable_key`) VALUES (504,3,'destination','string','出差地点',1,NULL,NULL,NULL,NULL,0,'destination'),
(505,3,'startDate','datetime','出差开始时间',1,NULL,NULL,NULL,NULL,1,'startDate'),
(506,3,'endDate','datetime','出差结束时间',1,NULL,NULL,NULL,NULL,2,'endDate'),
(507,3,'budget','number','预计预算',0,NULL,NULL,NULL,NULL,3,'budget'),
(508,3,'reason','string','出差事由',1,NULL,NULL,NULL,NULL,4,'reason'),
(708,8,'note','string','注释',1,NULL,NULL,NULL,NULL,0,'note'),
(710,9,'note','string','注释',1,NULL,NULL,NULL,NULL,0,'note'),
(711,9,'money','number','金额',1,NULL,NULL,NULL,NULL,1,NULL),
(712,1,'leaveType','select','请假类型',1,NULL,NULL,'[\"事假\",\"病假\",\"年假\"]',NULL,0,'leaveType'),
(713,1,'startDate','datetime','开始时间',1,NULL,NULL,NULL,NULL,1,'startDate'),
(714,1,'endDate','datetime','结束时间',1,NULL,NULL,NULL,NULL,2,'endDate'),
(715,1,'days','number','请假天数',1,NULL,NULL,NULL,NULL,3,'days'),
(716,1,'reason','string','请假原因',1,NULL,NULL,NULL,NULL,4,'reason'),
(717,2,'expenseType','select','费用类型',1,NULL,NULL,'[\"差旅\",\"餐饮\",\"办公\"]',NULL,0,'expenseType'),
(718,2,'amount','number','报销金额',1,NULL,NULL,NULL,NULL,1,'amount'),
(719,2,'occurredOn','date','发生日期',1,NULL,NULL,NULL,NULL,2,'occurredOn'),
(720,2,'reason','string','报销事由',1,NULL,NULL,NULL,NULL,3,'reason'),
(721,7,'destination','string','出差地点',1,NULL,NULL,NULL,NULL,0,'destination'),
(722,7,'startDate','datetime','出差开始时间',1,NULL,NULL,NULL,NULL,1,'startDate'),
(723,7,'endDate','datetime','出差结束时间',1,NULL,NULL,NULL,NULL,2,'endDate'),
(724,7,'budget','number','预计预算',0,NULL,NULL,NULL,NULL,3,'budget'),
(725,7,'reason','string','出差事由',1,NULL,NULL,NULL,NULL,4,'reason'),
(726,4,'itemName','string','采购物品',1,NULL,NULL,NULL,NULL,0,'itemName'),
(727,4,'quantity','number','数量',1,NULL,NULL,NULL,NULL,1,'quantity'),
(728,4,'amount','number','预算金额',1,NULL,NULL,NULL,NULL,2,'amount'),
(729,4,'reason','string','采购原因',1,NULL,NULL,NULL,NULL,3,'reason'),
(730,5,'sealType','select','用章类型',1,NULL,NULL,'[\"公章\",\"合同章\",\"财务章\"]',NULL,0,'sealType'),
(731,5,'documentName','string','文件名称',1,NULL,NULL,NULL,NULL,1,'documentName'),
(732,5,'copies','number','份数',1,NULL,NULL,NULL,NULL,2,'copies'),
(733,5,'reason','string','用章事由',1,NULL,NULL,NULL,NULL,3,'reason'),
(734,6,'contractName','string','合同名称',1,NULL,NULL,NULL,NULL,0,'contractName'),
(735,6,'counterparty','string','合同对方',1,NULL,NULL,NULL,NULL,1,'counterparty'),
(736,6,'amount','number','合同金额',1,NULL,NULL,NULL,NULL,2,'amount'),
(737,6,'riskNote','string','风险说明',0,NULL,NULL,NULL,NULL,3,'riskNote');
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `request_template` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `category` varchar(64) DEFAULT NULL,
  `countersign_mode` varchar(32) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `created_by` bigint(20) NOT NULL,
  `description` varchar(512) DEFAULT NULL,
  `flow_summary` varchar(512) DEFAULT NULL,
  `form_key` varchar(64) DEFAULT NULL,
  `form_name` varchar(128) DEFAULT NULL,
  `pass_ratio` varchar(16) NOT NULL,
  `process_key` varchar(64) NOT NULL,
  `sort_order` int(11) NOT NULL,
  `status` varchar(32) NOT NULL,
  `template_key` varchar(64) NOT NULL,
  `template_name` varchar(128) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `updated_by` bigint(20) DEFAULT NULL,
  `allow_manual_approver_select` int(11) NOT NULL,
  `approval_config_json` text DEFAULT NULL,
  `launch_role_codes_json` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKg2d40qpmcu1dni2i8ph89p0vl` (`template_key`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
REPLACE INTO `request_template` (`id`, `category`, `countersign_mode`, `created_at`, `created_by`, `description`, `flow_summary`, `form_key`, `form_name`, `pass_ratio`, `process_key`, `sort_order`, `status`, `template_key`, `template_name`, `updated_at`, `updated_by`, `allow_manual_approver_select`, `approval_config_json`, `launch_role_codes_json`) VALUES (1,'行政人事','ALL','2026-04-07 17:42:02.414560',0,'用于员工提交事假、病假、年假等请假申请。','直属主管顺序审批，必要时追加部门负责人审批','leave_request','请假申请表','1.0','approvalSequential',10,'ACTIVE','leave','请假申请','2026-04-07 20:11:15.026272',0,0,'{\"rules\":[{\"name\":\"1天及以下\",\"conditions\":null,\"steps\":[{\"type\":\"MANAGER\",\"userId\":null},{\"type\":\"DEPT_LEADER\",\"userId\":null}]},{\"name\":\"超过1天\",\"conditions\":[{\"field\":\"days\",\"operator\":\"GT\",\"value\":1.0}],\"steps\":[{\"type\":\"DEPT_LEADER\",\"userId\":null}]},{\"name\":\"超过3天\",\"conditions\":[{\"field\":\"days\",\"operator\":\"GT\",\"value\":3.0}],\"steps\":[{\"type\":\"PARENT_DEPT_LEADER\",\"userId\":null}]}]}','[\"EMPLOYEE\",\"BACKEND_ENGINEER\"]'),
(2,'财务','ALL','2026-04-07 17:42:02.439981',0,'用于日常费用报销、差旅报销和票据提交。','直属主管和财务顺序审批，大额报销可追加更高级别审批',NULL,NULL,'1.0','approvalSequential',20,'ACTIVE','expense','报销申请','2026-04-22 18:04:26.087734',1,0,'{\"rules\":[{\"name\":\"基础审批\",\"conditions\":[],\"steps\":[{\"type\":\"MANAGER\",\"userId\":null},{\"type\":\"DEPT_LEADER\",\"userId\":null}]},{\"name\":\"金额超过5000\",\"conditions\":[{\"field\":\"amount\",\"operator\":\"GT\",\"value\":5000.0}],\"steps\":[{\"type\":\"PARENT_DEPT_LEADER\",\"userId\":null}]}]}','[\"EMPLOYEE\",\"SALES_REP\"]'),
(3,'行政人事','ALL','2026-04-07 17:42:02.444190',0,'用于出差行程、预算与出差事由审批。','直属主管审批，必要时增加部门负责人和财务审批','travel_request','出差申请表','1.0','approvalSequential',30,'ACTIVE','travel','出差申请','2026-04-15 23:37:08.819476',0,0,'{\"rules\":[{\"name\":\"基础审批\",\"conditions\":[],\"steps\":[{\"type\":\"MANAGER\",\"userId\":null},{\"type\":\"DEPT_LEADER\",\"userId\":null}]},{\"name\":\"预算超过3000\",\"conditions\":[{\"field\":\"budget\",\"operator\":\"GT\",\"value\":3000.0}],\"steps\":[{\"type\":\"PARENT_DEPT_LEADER\",\"userId\":null}]}]}','[\"EMPLOYEE\",\"SECURITY_ENGINEER\",\"QA_ENGINEER\",\"FINANCE_SPECIALIST\",\"FRONTEND_ENGINEER\",\"BACKEND_ENGINEER\",\"DATA_ENGINEER\",\"HR_SPECIALIST\",\"SRE_ENGINEER\"]'),
(4,'采购','MAJORITY','2026-04-07 17:42:02.448309',0,'用于办公物资、设备与业务采购审批。','采购相关审批人并行会签，超过预算阈值时追加高级审批','purchase_request','采购申请表','0.5','approvalCountersign',40,'ACTIVE','purchase','采购申请','2026-04-20 19:22:41.725990',0,0,'{\"rules\":[{\"name\":\"基础审批\",\"conditions\":[],\"steps\":[{\"type\":\"DEPT_LEADER\",\"userId\":null}]},{\"name\":\"金额超过10000\",\"conditions\":[{\"field\":\"amount\",\"operator\":\"GT\",\"value\":10000.0}],\"steps\":[{\"type\":\"PARENT_DEPT_LEADER\",\"userId\":null}]}]}','[\"EMPLOYEE\",\"CUSTOMER_SUCCESS\",\"SALES_REP\",\"SALES_MANAGER\"]'),
(5,'行政','ALL','2026-04-07 17:42:02.451853',0,'用于文件盖章、资料用印和外发材料审批。','由印章管理员或指定负责人单人审批','seal_request','用章申请表','1.0','approvalSingle',50,'ACTIVE','seal','用章申请','2026-04-07 17:42:02.451853',0,0,NULL,'[\"EMPLOYEE\"]'),
(6,'法务','ALL','2026-04-07 17:42:02.454668',0,'用于合同评审、法务审查和金额审批。','法务、业务和财务协同会签，重大合同再提交高层审批','contract_request','合同审批表','1.0','approvalCountersign',60,'ACTIVE','contract','合同审批','2026-04-15 23:37:08.823503',0,0,'{\"rules\":[{\"name\":\"基础审批\",\"conditions\":[],\"steps\":[{\"type\":\"DEPT_LEADER\",\"userId\":null}]}]}','[\"EMPLOYEE\",\"FINANCE_MANAGER\",\"FINANCE_SPECIALIST\",\"HR_DIRECTOR\",\"HR_SPECIALIST\",\"LEGAL_MANAGER\",\"LEGAL_SPECIALIST\",\"SALES_REP\",\"SALES_MANAGER\",\"SECURITY_ENGINEER\",\"SECURITY_MANAGER\",\"SRE_ENGINEER\",\"TECH_LEAD\"]');
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `workflow_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `category` varchar(64) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `created_by` bigint(20) NOT NULL,
  `current_version_id` bigint(20) DEFAULT NULL,
  `description` varchar(512) DEFAULT NULL,
  `is_deleted` int(11) NOT NULL,
  `latest_version_no` int(11) NOT NULL,
  `process_key` varchar(64) NOT NULL,
  `process_name` varchar(128) NOT NULL,
  `status` varchar(32) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `updated_by` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK40jx2f83vsri0vjky68iyjhit` (`process_key`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
REPLACE INTO `workflow_definition` (`id`, `category`, `created_at`, `created_by`, `current_version_id`, `description`, `is_deleted`, `latest_version_no`, `process_key`, `process_name`, `status`, `updated_at`, `updated_by`) VALUES (1,NULL,'2026-04-01 18:28:42.658584',0,1,'Auto imported from Flowable deployed BPMN resource',0,1,'approvalCountersign','Approval Countersign','ACTIVE','2026-04-01 18:28:42.738615',0),
(2,NULL,'2026-04-01 18:28:42.750153',0,2,'Auto imported from Flowable deployed BPMN resource',0,1,'approvalOrSign','Approval Or-Sign','ACTIVE','2026-04-01 18:28:42.772741',0),
(3,NULL,'2026-04-01 18:28:42.774556',0,3,'Auto imported from Flowable deployed BPMN resource',0,1,'approvalSequential','Approval Sequential','ACTIVE','2026-04-01 18:28:42.792982',0),
(4,NULL,'2026-04-01 18:28:42.795199',0,4,'Auto imported from Flowable deployed BPMN resource',0,2,'approvalSingle','Approval Single','ACTIVE','2026-04-20 19:42:59.086619',1),
(5,NULL,'2026-04-01 18:28:42.817163',0,5,'Auto imported from Flowable deployed BPMN resource',0,2,'approvalWorkflow','Approval Workflow','ACTIVE','2026-04-11 19:32:31.715684',1),
(6,'111','2026-04-02 18:23:46.896178',1,NULL,NULL,0,2,'test1','test11','ARCHIVED','2026-04-20 19:43:19.446218',1),
(7,'test','2026-04-20 19:43:33.566208',1,10,NULL,0,2,'test2','test2','ACTIVE','2026-04-20 20:58:23.923467',1),
(8,NULL,'2026-04-20 20:59:12.293511',1,NULL,NULL,0,1,'test3','test3','DRAFT','2026-04-20 20:59:18.819120',1);
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `workflow_definition_version` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `bpmn_checksum` varchar(64) DEFAULT NULL,
  `bpmn_xml` longtext NOT NULL,
  `change_summary` varchar(1000) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `created_by` bigint(20) NOT NULL,
  `definition_id` bigint(20) NOT NULL,
  `flowable_deployment_id` varchar(64) DEFAULT NULL,
  `flowable_process_definition_id` varchar(128) DEFAULT NULL,
  `form_key` varchar(64) DEFAULT NULL,
  `form_version_id` bigint(20) DEFAULT NULL,
  `is_deleted` int(11) NOT NULL,
  `published_at` datetime(6) DEFAULT NULL,
  `published_by` bigint(20) DEFAULT NULL,
  `status` varchar(32) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `updated_by` bigint(20) DEFAULT NULL,
  `version_label` varchar(64) DEFAULT NULL,
  `version_no` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
REPLACE INTO `workflow_definition_version` (`id`, `bpmn_checksum`, `bpmn_xml`, `change_summary`, `created_at`, `created_by`, `definition_id`, `flowable_deployment_id`, `flowable_process_definition_id`, `form_key`, `form_version_id`, `is_deleted`, `published_at`, `published_by`, `status`, `updated_at`, `updated_by`, `version_label`, `version_no`) VALUES (1,'608f7357321c8c3ce377c353d456c41da9b16b08da705d8cbccf086a5bb13984','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalCountersign\" name=\"Approval Countersign\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"countersignTask\"/>\n\n    <userTask id=\"countersignTask\" name=\"Countersign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${countersignMode == \'ALL\' ? (rejectCount == 0 &amp;&amp; nrOfCompletedInstances == nrOfInstances)\n            : (approveCount >= requiredApprove || rejectCount > (nrOfInstances - requiredApprove))}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToCountersign\" sourceRef=\"applicantRework\" targetRef=\"countersignTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"countersignTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n','Auto imported from existing BPMN deployment','2026-04-01 18:28:42.687523',0,1,'61f5f985-2d11-11f1-b116-b62bdfc0de2a','approvalCountersign:1:620514bf-2d11-11f1-b116-b62bdfc0de2a',NULL,NULL,0,'2026-04-01 18:28:42.687106',0,'PUBLISHED','2026-04-01 18:28:42.687523',0,'imported-v1',1),
(2,'6cd316adbbc6971572f0b0bc9c40899a968496a934709217dd56f21e94a39c53','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalOrSign\" name=\"Approval Or-Sign\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"orSignTask\"/>\n\n    <userTask id=\"orSignTask\" name=\"Or-Sign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${approveCount >= 1 || rejectCount == nrOfInstances}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToOrSign\" sourceRef=\"applicantRework\" targetRef=\"orSignTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"orSignTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approveCount >= 1}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approveCount == 0}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n','Auto imported from existing BPMN deployment','2026-04-01 18:28:42.754619',0,2,'61f5f985-2d11-11f1-b116-b62bdfc0de2a','approvalOrSign:1:62049f8b-2d11-11f1-b116-b62bdfc0de2a',NULL,NULL,0,'2026-04-01 18:28:42.754436',0,'PUBLISHED','2026-04-01 18:28:42.754619',0,'imported-v1',1),
(3,'95cc78d8f112e4d3197643757023121d027fd28c4c076327023a8aeb43a60464','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalSequential\" name=\"Approval Sequential\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"sequentialTask\"/>\n\n    <userTask id=\"sequentialTask\" name=\"Sequential Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"true\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${rejectCount > 0 || (nrOfCompletedInstances == nrOfInstances)}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToSequential\" sourceRef=\"applicantRework\" targetRef=\"sequentialTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"sequentialTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${rejectCount == 0}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${rejectCount > 0}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n','Auto imported from existing BPMN deployment','2026-04-01 18:28:42.779334',0,3,'61f5f985-2d11-11f1-b116-b62bdfc0de2a','approvalSequential:1:620514bc-2d11-11f1-b116-b62bdfc0de2a',NULL,NULL,0,'2026-04-01 18:28:42.779191',0,'PUBLISHED','2026-04-01 18:28:42.779334',0,'imported-v1',1),
(4,'7f245843323a16d03f59a6b02fc4061abbcc936e5745b5a656c0ca513bdc7f51','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalSingle\" name=\"Approval Single\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"singleApprovalTask\"/>\n\n    <userTask id=\"singleApprovalTask\" name=\"Single Approval Task\" flowable:assignee=\"${approverId}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${singleApprovalTaskListener}\"/>\n      </extensionElements>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToApproval\" sourceRef=\"applicantRework\" targetRef=\"singleApprovalTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"singleApprovalTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approvalResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approvalResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n','Auto imported from existing BPMN deployment','2026-04-01 18:28:42.801006',0,4,'61f5f985-2d11-11f1-b116-b62bdfc0de2a','approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a',NULL,NULL,0,'2026-04-01 18:28:42.800773',0,'PUBLISHED','2026-04-01 18:28:42.801006',0,'imported-v1',1),
(5,'4f94219a42cdebada22c6bb0cd0e743941d679b7932cf84e2b254da54f8c4b16','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalWorkflow\" name=\"Approval Workflow\" isExecutable=\"true\">\n\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"countersignTask\"/>\n\n    <userTask id=\"countersignTask\" name=\"Countersign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${countersignMode == \'ALL\' ? (rejectCount == 0 &amp;&amp; nrOfCompletedInstances == nrOfInstances)\n            : (approveCount >= requiredApprove || rejectCount > (nrOfInstances - requiredApprove))}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"countersignTask\" targetRef=\"decision\"/>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToCountersign\" sourceRef=\"applicantRework\" targetRef=\"countersignTask\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n\n  </process>\n</definitions>\n','Auto imported from existing BPMN deployment','2026-04-01 18:28:42.820239',0,5,'61f5f985-2d11-11f1-b116-b62bdfc0de2a','approvalWorkflow:1:620514bd-2d11-11f1-b116-b62bdfc0de2a',NULL,NULL,0,'2026-04-01 18:28:42.820121',0,'PUBLISHED','2026-04-01 18:28:42.820239',0,'imported-v1',1),
(6,NULL,'',NULL,'2026-04-07 17:42:37.092447',1,6,NULL,NULL,NULL,NULL,0,NULL,NULL,'DRAFT','2026-04-07 17:42:37.092447',1,'1',1),
(7,'3e25edfa7282318f0543614562d8e861ff7a1b9f53ec47a27f21a3df2e2b3917','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<bpmn:definitions xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:bpmn=\"http://www.omg.org/spec/BPMN/20100524/MODEL\" xmlns:bpmndi=\"http://www.omg.org/spec/BPMN/20100524/DI\" xmlns:dc=\"http://www.omg.org/spec/DD/20100524/DC\" xmlns:di=\"http://www.omg.org/spec/DD/20100524/DI\" id=\"Definitions_1\" targetNamespace=\"http://www.flowable.org/processdef\">\n  <bpmn:process id=\"test1\" name=\"test11\" isExecutable=\"true\">\n    <bpmn:startEvent id=\"StartEvent_1\" name=\"开始\">\n      <bpmn:outgoing>Flow_1</bpmn:outgoing>\n    </bpmn:startEvent>\n    <bpmn:userTask id=\"Activity_Approve\" name=\"审批\">\n      <bpmn:incoming>Flow_1</bpmn:incoming>\n      <bpmn:outgoing>Flow_2</bpmn:outgoing>\n    </bpmn:userTask>\n    <bpmn:endEvent id=\"EndEvent_1\" name=\"结束\">\n      <bpmn:incoming>Flow_2</bpmn:incoming>\n    </bpmn:endEvent>\n    <bpmn:sequenceFlow id=\"Flow_1\" sourceRef=\"StartEvent_1\" targetRef=\"Activity_Approve\" />\n    <bpmn:sequenceFlow id=\"Flow_2\" sourceRef=\"Activity_Approve\" targetRef=\"EndEvent_1\" />\n  </bpmn:process>\n  <bpmndi:BPMNDiagram id=\"BPMNDiagram_1\">\n    <bpmndi:BPMNPlane id=\"BPMNPlane_1\" bpmnElement=\"test1\">\n      <bpmndi:BPMNEdge id=\"Flow_2_di\" bpmnElement=\"Flow_2\">\n        <di:waypoint x=\"350\" y=\"138\" />\n        <di:waypoint x=\"430\" y=\"138\" />\n      </bpmndi:BPMNEdge>\n      <bpmndi:BPMNEdge id=\"Flow_1_di\" bpmnElement=\"Flow_1\">\n        <di:waypoint x=\"186\" y=\"138\" />\n        <di:waypoint x=\"250\" y=\"138\" />\n      </bpmndi:BPMNEdge>\n      <bpmndi:BPMNShape id=\"StartEvent_1_di\" bpmnElement=\"StartEvent_1\">\n        <dc:Bounds x=\"150\" y=\"120\" width=\"36\" height=\"36\" />\n      </bpmndi:BPMNShape>\n      <bpmndi:BPMNShape id=\"Activity_Approve_di\" bpmnElement=\"Activity_Approve\">\n        <dc:Bounds x=\"250\" y=\"98\" width=\"100\" height=\"80\" />\n      </bpmndi:BPMNShape>\n      <bpmndi:BPMNShape id=\"EndEvent_1_di\" bpmnElement=\"EndEvent_1\">\n        <dc:Bounds x=\"430\" y=\"120\" width=\"36\" height=\"36\" />\n      </bpmndi:BPMNShape>\n    </bpmndi:BPMNPlane>\n  </bpmndi:BPMNDiagram>\n</bpmn:definitions>\n',NULL,'2026-04-11 16:55:20.465343',1,6,NULL,NULL,'travel_request',3,0,NULL,NULL,'DRAFT','2026-04-11 16:55:43.996914',1,NULL,2),
(8,'4f94219a42cdebada22c6bb0cd0e743941d679b7932cf84e2b254da54f8c4b16','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalWorkflow\" name=\"Approval Workflow\" isExecutable=\"true\">\n\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"countersignTask\"/>\n\n    <userTask id=\"countersignTask\" name=\"Countersign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${countersignMode == \'ALL\' ? (rejectCount == 0 &amp;&amp; nrOfCompletedInstances == nrOfInstances)\n            : (approveCount >= requiredApprove || rejectCount > (nrOfInstances - requiredApprove))}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"countersignTask\" targetRef=\"decision\"/>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToCountersign\" sourceRef=\"applicantRework\" targetRef=\"countersignTask\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n\n  </process>\n</definitions>\n','Auto imported from existing BPMN deployment','2026-04-11 19:32:31.705553',1,5,NULL,NULL,NULL,NULL,0,NULL,NULL,'DRAFT','2026-04-11 19:32:31.705553',1,NULL,2),
(9,'7f245843323a16d03f59a6b02fc4061abbcc936e5745b5a656c0ca513bdc7f51','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalSingle\" name=\"Approval Single\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"singleApprovalTask\"/>\n\n    <userTask id=\"singleApprovalTask\" name=\"Single Approval Task\" flowable:assignee=\"${approverId}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${singleApprovalTaskListener}\"/>\n      </extensionElements>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToApproval\" sourceRef=\"applicantRework\" targetRef=\"singleApprovalTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"singleApprovalTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approvalResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approvalResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n','test','2026-04-20 19:42:59.046678',1,4,NULL,NULL,NULL,NULL,0,NULL,NULL,'DRAFT','2026-04-20 19:42:59.046678',1,'v2',2),
(10,'8e5f8b0c9aa773abf82a45f40e6052df4eb45c902a26aaeed9fae8dcb1bd8e49','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<bpmn:definitions xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:bpmn=\"http://www.omg.org/spec/BPMN/20100524/MODEL\" xmlns:bpmndi=\"http://www.omg.org/spec/BPMN/20100524/DI\" xmlns:dc=\"http://www.omg.org/spec/DD/20100524/DC\" xmlns:di=\"http://www.omg.org/spec/DD/20100524/DI\" id=\"Definitions_1\" targetNamespace=\"http://www.flowable.org/processdef\">\n  <bpmn:process id=\"test2\" name=\"test2\" isExecutable=\"true\">\n    <bpmn:startEvent id=\"StartEvent_1\" name=\"开始\">\n      <bpmn:outgoing>Flow_05wdtr6</bpmn:outgoing>\n    </bpmn:startEvent>\n    <bpmn:endEvent id=\"EndEvent_1\" name=\"结束\">\n      <bpmn:incoming>Flow_2</bpmn:incoming>\n    </bpmn:endEvent>\n    <bpmn:sequenceFlow id=\"Flow_2\" sourceRef=\"Activity_Approve\" targetRef=\"EndEvent_1\" />\n    <bpmn:task id=\"Activity_Approve\" name=\"审批\">\n      <bpmn:incoming>Flow_1bywxd6</bpmn:incoming>\n      <bpmn:outgoing>Flow_2</bpmn:outgoing>\n    </bpmn:task>\n    <bpmn:sequenceFlow id=\"Flow_05wdtr6\" sourceRef=\"StartEvent_1\" targetRef=\"Gateway_18264ep\" />\n    <bpmn:sequenceFlow id=\"Flow_1bywxd6\" sourceRef=\"Gateway_18264ep\" targetRef=\"Activity_Approve\" />\n    <bpmn:exclusiveGateway id=\"Gateway_18264ep\">\n      <bpmn:incoming>Flow_05wdtr6</bpmn:incoming>\n      <bpmn:outgoing>Flow_1bywxd6</bpmn:outgoing>\n    </bpmn:exclusiveGateway>\n  </bpmn:process>\n  <bpmndi:BPMNDiagram id=\"BPMNDiagram_1\">\n    <bpmndi:BPMNPlane id=\"BPMNPlane_1\" bpmnElement=\"test2\">\n      <bpmndi:BPMNEdge id=\"Flow_1bywxd6_di\" bpmnElement=\"Flow_1bywxd6\">\n        <di:waypoint x=\"135\" y=\"138\" />\n        <di:waypoint x=\"250\" y=\"138\" />\n      </bpmndi:BPMNEdge>\n      <bpmndi:BPMNEdge id=\"Flow_05wdtr6_di\" bpmnElement=\"Flow_05wdtr6\">\n        <di:waypoint x=\"8\" y=\"138\" />\n        <di:waypoint x=\"85\" y=\"138\" />\n      </bpmndi:BPMNEdge>\n      <bpmndi:BPMNEdge id=\"Flow_2_di\" bpmnElement=\"Flow_2\">\n        <di:waypoint x=\"350\" y=\"138\" />\n        <di:waypoint x=\"430\" y=\"138\" />\n      </bpmndi:BPMNEdge>\n      <bpmndi:BPMNShape id=\"StartEvent_1_di\" bpmnElement=\"StartEvent_1\">\n        <dc:Bounds x=\"-28\" y=\"120\" width=\"36\" height=\"36\" />\n        <bpmndi:BPMNLabel>\n          <dc:Bounds x=\"-21\" y=\"156\" width=\"23\" height=\"14\" />\n        </bpmndi:BPMNLabel>\n      </bpmndi:BPMNShape>\n      <bpmndi:BPMNShape id=\"EndEvent_1_di\" bpmnElement=\"EndEvent_1\">\n        <dc:Bounds x=\"430\" y=\"120\" width=\"36\" height=\"36\" />\n      </bpmndi:BPMNShape>\n      <bpmndi:BPMNShape id=\"Activity_0a8l604_di\" bpmnElement=\"Activity_Approve\">\n        <dc:Bounds x=\"250\" y=\"98\" width=\"100\" height=\"80\" />\n      </bpmndi:BPMNShape>\n      <bpmndi:BPMNShape id=\"Gateway_0u1wr0v_di\" bpmnElement=\"Gateway_18264ep\" isMarkerVisible=\"true\">\n        <dc:Bounds x=\"85\" y=\"113\" width=\"50\" height=\"50\" />\n      </bpmndi:BPMNShape>\n    </bpmndi:BPMNPlane>\n  </bpmndi:BPMNDiagram>\n</bpmn:definitions>\n','test2','2026-04-20 19:43:39.988476',1,7,'194383aa-3cb8-11f1-bcc8-86aadccee407','test2:1:196e161d-3cb8-11f1-bcc8-86aadccee407','test2',8,0,'2026-04-20 20:54:42.360535',1,'PUBLISHED','2026-04-20 20:54:42.363350',1,'v1',1),
(11,'8e5f8b0c9aa773abf82a45f40e6052df4eb45c902a26aaeed9fae8dcb1bd8e49','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<bpmn:definitions xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:bpmn=\"http://www.omg.org/spec/BPMN/20100524/MODEL\" xmlns:bpmndi=\"http://www.omg.org/spec/BPMN/20100524/DI\" xmlns:dc=\"http://www.omg.org/spec/DD/20100524/DC\" xmlns:di=\"http://www.omg.org/spec/DD/20100524/DI\" id=\"Definitions_1\" targetNamespace=\"http://www.flowable.org/processdef\">\n  <bpmn:process id=\"test2\" name=\"test2\" isExecutable=\"true\">\n    <bpmn:startEvent id=\"StartEvent_1\" name=\"开始\">\n      <bpmn:outgoing>Flow_05wdtr6</bpmn:outgoing>\n    </bpmn:startEvent>\n    <bpmn:endEvent id=\"EndEvent_1\" name=\"结束\">\n      <bpmn:incoming>Flow_2</bpmn:incoming>\n    </bpmn:endEvent>\n    <bpmn:sequenceFlow id=\"Flow_2\" sourceRef=\"Activity_Approve\" targetRef=\"EndEvent_1\" />\n    <bpmn:task id=\"Activity_Approve\" name=\"审批\">\n      <bpmn:incoming>Flow_1bywxd6</bpmn:incoming>\n      <bpmn:outgoing>Flow_2</bpmn:outgoing>\n    </bpmn:task>\n    <bpmn:sequenceFlow id=\"Flow_05wdtr6\" sourceRef=\"StartEvent_1\" targetRef=\"Gateway_18264ep\" />\n    <bpmn:sequenceFlow id=\"Flow_1bywxd6\" sourceRef=\"Gateway_18264ep\" targetRef=\"Activity_Approve\" />\n    <bpmn:exclusiveGateway id=\"Gateway_18264ep\">\n      <bpmn:incoming>Flow_05wdtr6</bpmn:incoming>\n      <bpmn:outgoing>Flow_1bywxd6</bpmn:outgoing>\n    </bpmn:exclusiveGateway>\n  </bpmn:process>\n  <bpmndi:BPMNDiagram id=\"BPMNDiagram_1\">\n    <bpmndi:BPMNPlane id=\"BPMNPlane_1\" bpmnElement=\"test2\">\n      <bpmndi:BPMNEdge id=\"Flow_1bywxd6_di\" bpmnElement=\"Flow_1bywxd6\">\n        <di:waypoint x=\"135\" y=\"138\" />\n        <di:waypoint x=\"250\" y=\"138\" />\n      </bpmndi:BPMNEdge>\n      <bpmndi:BPMNEdge id=\"Flow_05wdtr6_di\" bpmnElement=\"Flow_05wdtr6\">\n        <di:waypoint x=\"8\" y=\"138\" />\n        <di:waypoint x=\"85\" y=\"138\" />\n      </bpmndi:BPMNEdge>\n      <bpmndi:BPMNEdge id=\"Flow_2_di\" bpmnElement=\"Flow_2\">\n        <di:waypoint x=\"350\" y=\"138\" />\n        <di:waypoint x=\"430\" y=\"138\" />\n      </bpmndi:BPMNEdge>\n      <bpmndi:BPMNShape id=\"StartEvent_1_di\" bpmnElement=\"StartEvent_1\">\n        <dc:Bounds x=\"-28\" y=\"120\" width=\"36\" height=\"36\" />\n        <bpmndi:BPMNLabel>\n          <dc:Bounds x=\"-21\" y=\"156\" width=\"23\" height=\"14\" />\n        </bpmndi:BPMNLabel>\n      </bpmndi:BPMNShape>\n      <bpmndi:BPMNShape id=\"EndEvent_1_di\" bpmnElement=\"EndEvent_1\">\n        <dc:Bounds x=\"430\" y=\"120\" width=\"36\" height=\"36\" />\n      </bpmndi:BPMNShape>\n      <bpmndi:BPMNShape id=\"Activity_0a8l604_di\" bpmnElement=\"Activity_Approve\">\n        <dc:Bounds x=\"250\" y=\"98\" width=\"100\" height=\"80\" />\n      </bpmndi:BPMNShape>\n      <bpmndi:BPMNShape id=\"Gateway_0u1wr0v_di\" bpmnElement=\"Gateway_18264ep\" isMarkerVisible=\"true\">\n        <dc:Bounds x=\"85\" y=\"113\" width=\"50\" height=\"50\" />\n      </bpmndi:BPMNShape>\n    </bpmndi:BPMNPlane>\n  </bpmndi:BPMNDiagram>\n</bpmn:definitions>\n','test2','2026-04-20 20:58:23.915439',1,7,NULL,NULL,'test2',8,0,NULL,NULL,'DRAFT','2026-04-20 20:58:23.915439',1,NULL,2),
(12,'457039a08fd14de2167297889f2084ac42170bad59b8498e29ff0decbeb82a41','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<bpmn:definitions xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:bpmn=\"http://www.omg.org/spec/BPMN/20100524/MODEL\" xmlns:bpmndi=\"http://www.omg.org/spec/BPMN/20100524/DI\" xmlns:dc=\"http://www.omg.org/spec/DD/20100524/DC\" xmlns:di=\"http://www.omg.org/spec/DD/20100524/DI\" id=\"Definitions_1\" targetNamespace=\"http://www.flowable.org/processdef\">\n  <bpmn:process id=\"test3\" name=\"test3\" isExecutable=\"true\">\n    <bpmn:startEvent id=\"StartEvent_1\" name=\"开始\">\n      <bpmn:outgoing>Flow_12rxp5p</bpmn:outgoing>\n    </bpmn:startEvent>\n    <bpmn:userTask id=\"Activity_Approve\" name=\"上级审批\">\n      <bpmn:incoming>Flow_0knuc7q</bpmn:incoming>\n      <bpmn:outgoing>Flow_2</bpmn:outgoing>\n    </bpmn:userTask>\n    <bpmn:endEvent id=\"EndEvent_1\" name=\"结束\">\n      <bpmn:incoming>Flow_2</bpmn:incoming>\n      <bpmn:incoming>Flow_000y5uj</bpmn:incoming>\n    </bpmn:endEvent>\n    <bpmn:sequenceFlow id=\"Flow_2\" sourceRef=\"Activity_Approve\" targetRef=\"EndEvent_1\" />\n    <bpmn:exclusiveGateway id=\"Gateway_055urbj\" name=\"test\">\n      <bpmn:incoming>Flow_12rxp5p</bpmn:incoming>\n      <bpmn:outgoing>Flow_0knuc7q</bpmn:outgoing>\n      <bpmn:outgoing>Flow_0535y1c</bpmn:outgoing>\n    </bpmn:exclusiveGateway>\n    <bpmn:sequenceFlow id=\"Flow_12rxp5p\" sourceRef=\"StartEvent_1\" targetRef=\"Gateway_055urbj\" />\n    <bpmn:sequenceFlow id=\"Flow_0knuc7q\" sourceRef=\"Gateway_055urbj\" targetRef=\"Activity_Approve\">\n      <bpmn:conditionExpression xsi:type=\"bpmn:tFormalExpression\">$(money &gt; 10000)</bpmn:conditionExpression>\n    </bpmn:sequenceFlow>\n    <bpmn:sequenceFlow id=\"Flow_0535y1c\" sourceRef=\"Gateway_055urbj\" targetRef=\"Activity_1infl7s\" />\n    <bpmn:userTask id=\"Activity_1infl7s\" name=\"同级审批\">\n      <bpmn:incoming>Flow_0535y1c</bpmn:incoming>\n      <bpmn:outgoing>Flow_000y5uj</bpmn:outgoing>\n    </bpmn:userTask>\n    <bpmn:sequenceFlow id=\"Flow_000y5uj\" sourceRef=\"Activity_1infl7s\" targetRef=\"EndEvent_1\" />\n  </bpmn:process>\n  <bpmndi:BPMNDiagram id=\"BPMNDiagram_1\">\n    <bpmndi:BPMNPlane id=\"BPMNPlane_1\" bpmnElement=\"test3\">\n      <bpmndi:BPMNEdge id=\"Flow_000y5uj_di\" bpmnElement=\"Flow_000y5uj\">\n        <di:waypoint x=\"370\" y=\"210\" />\n        <di:waypoint x=\"370\" y=\"183\" />\n        <di:waypoint x=\"448\" y=\"183\" />\n        <di:waypoint x=\"448\" y=\"156\" />\n      </bpmndi:BPMNEdge>\n      <bpmndi:BPMNEdge id=\"Flow_0535y1c_di\" bpmnElement=\"Flow_0535y1c\">\n        <di:waypoint x=\"305\" y=\"250\" />\n        <di:waypoint x=\"320\" y=\"250\" />\n      </bpmndi:BPMNEdge>\n      <bpmndi:BPMNEdge id=\"Flow_0knuc7q_di\" bpmnElement=\"Flow_0knuc7q\">\n        <di:waypoint x=\"280\" y=\"225\" />\n        <di:waypoint x=\"280\" y=\"140\" />\n        <di:waypoint x=\"320\" y=\"140\" />\n      </bpmndi:BPMNEdge>\n      <bpmndi:BPMNEdge id=\"Flow_12rxp5p_di\" bpmnElement=\"Flow_12rxp5p\">\n        <di:waypoint x=\"88\" y=\"280\" />\n        <di:waypoint x=\"172\" y=\"280\" />\n        <di:waypoint x=\"172\" y=\"250\" />\n        <di:waypoint x=\"255\" y=\"250\" />\n      </bpmndi:BPMNEdge>\n      <bpmndi:BPMNEdge id=\"Flow_2_di\" bpmnElement=\"Flow_2\">\n        <di:waypoint x=\"370\" y=\"70\" />\n        <di:waypoint x=\"370\" y=\"50\" />\n        <di:waypoint x=\"448\" y=\"50\" />\n        <di:waypoint x=\"448\" y=\"120\" />\n      </bpmndi:BPMNEdge>\n      <bpmndi:BPMNShape id=\"StartEvent_1_di\" bpmnElement=\"StartEvent_1\">\n        <dc:Bounds x=\"52\" y=\"262\" width=\"36\" height=\"36\" />\n        <bpmndi:BPMNLabel>\n          <dc:Bounds x=\"59\" y=\"298\" width=\"23\" height=\"14\" />\n        </bpmndi:BPMNLabel>\n      </bpmndi:BPMNShape>\n      <bpmndi:BPMNShape id=\"Activity_Approve_di\" bpmnElement=\"Activity_Approve\">\n        <dc:Bounds x=\"320\" y=\"70\" width=\"100\" height=\"80\" />\n      </bpmndi:BPMNShape>\n      <bpmndi:BPMNShape id=\"EndEvent_1_di\" bpmnElement=\"EndEvent_1\">\n        <dc:Bounds x=\"430\" y=\"120\" width=\"36\" height=\"36\" />\n        <bpmndi:BPMNLabel>\n          <dc:Bounds x=\"396.5\" y=\"131\" width=\"23\" height=\"14\" />\n        </bpmndi:BPMNLabel>\n      </bpmndi:BPMNShape>\n      <bpmndi:BPMNShape id=\"Gateway_055urbj_di\" bpmnElement=\"Gateway_055urbj\" isMarkerVisible=\"true\">\n        <dc:Bounds x=\"255\" y=\"225\" width=\"50\" height=\"50\" />\n        <bpmndi:BPMNLabel>\n          <dc:Bounds x=\"271\" y=\"282\" width=\"18\" height=\"14\" />\n        </bpmndi:BPMNLabel>\n      </bpmndi:BPMNShape>\n      <bpmndi:BPMNShape id=\"Activity_0sbwqq4_di\" bpmnElement=\"Activity_1infl7s\">\n        <dc:Bounds x=\"320\" y=\"210\" width=\"100\" height=\"80\" />\n      </bpmndi:BPMNShape>\n    </bpmndi:BPMNPlane>\n  </bpmndi:BPMNDiagram>\n</bpmn:definitions>\n',NULL,'2026-04-20 20:59:18.816948',1,8,NULL,NULL,'test2',9,0,NULL,NULL,'DRAFT','2026-04-20 21:08:53.258550',1,'v1',1);
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `workflow_node_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `ai_enabled` int(11) NOT NULL,
  `allow_delegate` int(11) NOT NULL,
  `allow_reassign` int(11) NOT NULL,
  `allow_return_applicant` int(11) NOT NULL,
  `allow_return_previous` int(11) NOT NULL,
  `approval_type` varchar(32) DEFAULT NULL,
  `assignee_config_json` text DEFAULT NULL,
  `assignee_strategy` varchar(32) DEFAULT NULL,
  `comment_required` int(11) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `definition_version_id` bigint(20) NOT NULL,
  `extra_config_json` text DEFAULT NULL,
  `node_id` varchar(64) NOT NULL,
  `node_name` varchar(128) NOT NULL,
  `node_type` varchar(32) NOT NULL,
  `sort_order` int(11) NOT NULL,
  `timeout_rule_json` text DEFAULT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
REPLACE INTO `workflow_node_config` (`id`, `ai_enabled`, `allow_delegate`, `allow_reassign`, `allow_return_applicant`, `allow_return_previous`, `approval_type`, `assignee_config_json`, `assignee_strategy`, `comment_required`, `created_at`, `definition_version_id`, `extra_config_json`, `node_id`, `node_name`, `node_type`, `sort_order`, `timeout_rule_json`, `updated_at`) VALUES (1,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.724304',1,NULL,'start','Start','START',0,NULL,'2026-04-01 18:28:42.724304'),
(2,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.725591',1,NULL,'countersignTask','Countersign Task','USER_TASK',1,NULL,'2026-04-01 18:28:42.725591'),
(3,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.726513',1,NULL,'applicantRework','Applicant Rework','USER_TASK',2,NULL,'2026-04-01 18:28:42.726513'),
(4,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.728964',1,NULL,'decision','Decision','GATEWAY',3,NULL,'2026-04-01 18:28:42.728964'),
(5,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.730345',1,NULL,'approveEnd','Approved','END',4,NULL,'2026-04-01 18:28:42.730345'),
(6,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.731647',1,NULL,'rejectEnd','Rejected','END',5,NULL,'2026-04-01 18:28:42.731647'),
(7,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.761243',2,NULL,'start','Start','START',0,NULL,'2026-04-01 18:28:42.761243'),
(8,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.762998',2,NULL,'orSignTask','Or-Sign Task','USER_TASK',1,NULL,'2026-04-01 18:28:42.762998'),
(9,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.764377',2,NULL,'applicantRework','Applicant Rework','USER_TASK',2,NULL,'2026-04-01 18:28:42.764377'),
(10,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.765633',2,NULL,'decision','Decision','GATEWAY',3,NULL,'2026-04-01 18:28:42.765633'),
(11,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.766856',2,NULL,'approveEnd','Approved','END',4,NULL,'2026-04-01 18:28:42.766856'),
(12,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.768385',2,NULL,'rejectEnd','Rejected','END',5,NULL,'2026-04-01 18:28:42.768385'),
(13,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.783395',3,NULL,'start','Start','START',0,NULL,'2026-04-01 18:28:42.783395'),
(14,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.784219',3,NULL,'sequentialTask','Sequential Task','USER_TASK',1,NULL,'2026-04-01 18:28:42.784219'),
(15,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.784974',3,NULL,'applicantRework','Applicant Rework','USER_TASK',2,NULL,'2026-04-01 18:28:42.784974'),
(16,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.785616',3,NULL,'decision','Decision','GATEWAY',3,NULL,'2026-04-01 18:28:42.785616'),
(17,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.786698',3,NULL,'approveEnd','Approved','END',4,NULL,'2026-04-01 18:28:42.786698'),
(18,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.787460',3,NULL,'rejectEnd','Rejected','END',5,NULL,'2026-04-01 18:28:42.787460'),
(19,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.805734',4,NULL,'start','Start','START',0,NULL,'2026-04-01 18:28:42.805734'),
(20,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.806464',4,NULL,'singleApprovalTask','Single Approval Task','USER_TASK',1,NULL,'2026-04-01 18:28:42.806464'),
(21,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.807084',4,NULL,'applicantRework','Applicant Rework','USER_TASK',2,NULL,'2026-04-01 18:28:42.807084'),
(22,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.807836',4,NULL,'decision','Decision','GATEWAY',3,NULL,'2026-04-01 18:28:42.807836'),
(23,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.808536',4,NULL,'approveEnd','Approved','END',4,NULL,'2026-04-01 18:28:42.808536'),
(24,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.809130',4,NULL,'rejectEnd','Rejected','END',5,NULL,'2026-04-01 18:28:42.809130'),
(25,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.823618',5,NULL,'start','Start','START',0,NULL,'2026-04-01 18:28:42.823618'),
(26,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.824324',5,NULL,'countersignTask','Countersign Task','USER_TASK',1,NULL,'2026-04-01 18:28:42.824324'),
(27,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.824929',5,NULL,'applicantRework','Applicant Rework','USER_TASK',2,NULL,'2026-04-01 18:28:42.824929'),
(28,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.825513',5,NULL,'decision','Decision','GATEWAY',3,NULL,'2026-04-01 18:28:42.825513'),
(29,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.826223',5,NULL,'approveEnd','Approved','END',4,NULL,'2026-04-01 18:28:42.826223'),
(30,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.826889',5,NULL,'rejectEnd','Rejected','END',5,NULL,'2026-04-01 18:28:42.826889'),
(31,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-11 19:32:31.712043',8,NULL,'start','Start','START',0,NULL,'2026-04-11 19:32:31.712043'),
(32,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-11 19:32:31.712864',8,NULL,'countersignTask','Countersign Task','USER_TASK',1,NULL,'2026-04-11 19:32:31.712864'),
(33,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-11 19:32:31.713364',8,NULL,'applicantRework','Applicant Rework','USER_TASK',2,NULL,'2026-04-11 19:32:31.713364'),
(34,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-11 19:32:31.713756',8,NULL,'decision','Decision','GATEWAY',3,NULL,'2026-04-11 19:32:31.713756'),
(35,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-11 19:32:31.714111',8,NULL,'approveEnd','Approved','END',4,NULL,'2026-04-11 19:32:31.714111'),
(36,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-11 19:32:31.714385',8,NULL,'rejectEnd','Rejected','END',5,NULL,'2026-04-11 19:32:31.714385'),
(37,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-20 19:42:59.066975',9,NULL,'start','Start','START',0,NULL,'2026-04-20 19:42:59.066975'),
(38,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-20 19:42:59.071563',9,NULL,'singleApprovalTask','Single Approval Task','USER_TASK',1,NULL,'2026-04-20 19:42:59.071563'),
(39,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-20 19:42:59.074700',9,NULL,'applicantRework','Applicant Rework','USER_TASK',2,NULL,'2026-04-20 19:42:59.074700'),
(40,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-20 19:42:59.077554',9,NULL,'decision','Decision','GATEWAY',3,NULL,'2026-04-20 19:42:59.077554'),
(41,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-20 19:42:59.081358',9,NULL,'approveEnd','Approved','END',4,NULL,'2026-04-20 19:42:59.081358'),
(42,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-20 19:42:59.083971',9,NULL,'rejectEnd','Rejected','END',5,NULL,'2026-04-20 19:42:59.083971'),
(45,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-20 20:54:38.726949',10,NULL,'StartEvent_1','开始','START',0,NULL,'2026-04-20 20:54:38.726949'),
(46,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-20 20:54:38.731191',10,NULL,'EndEvent_1','结束','END',1,NULL,'2026-04-20 20:54:38.731191'),
(47,0,1,1,1,1,NULL,NULL,'ROLE',1,'2026-04-20 20:54:38.732387',10,NULL,'Gateway_18264ep','gateway','GATEWAY',2,NULL,'2026-04-20 20:54:38.732387'),
(48,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-20 20:58:23.920566',11,NULL,'StartEvent_1','开始','START',0,NULL,'2026-04-20 20:58:23.920566'),
(49,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-20 20:58:23.921715',11,NULL,'EndEvent_1','结束','END',1,NULL,'2026-04-20 20:58:23.921715'),
(50,0,1,1,1,1,NULL,NULL,'ROLE',1,'2026-04-20 20:58:23.922778',11,NULL,'Gateway_18264ep','gateway','GATEWAY',2,NULL,'2026-04-20 20:58:23.922778');
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `workflow_publish_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `action` varchar(32) NOT NULL,
  `definition_id` bigint(20) NOT NULL,
  `definition_version_id` bigint(20) NOT NULL,
  `flowable_deployment_id` varchar(64) DEFAULT NULL,
  `flowable_process_definition_id` varchar(128) DEFAULT NULL,
  `message` varchar(1000) DEFAULT NULL,
  `operated_at` datetime(6) NOT NULL,
  `operator_id` bigint(20) NOT NULL,
  `result` varchar(32) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
REPLACE INTO `workflow_publish_log` (`id`, `action`, `definition_id`, `definition_version_id`, `flowable_deployment_id`, `flowable_process_definition_id`, `message`, `operated_at`, `operator_id`, `result`) VALUES (1,'PUBLISH',7,10,'194383aa-3cb8-11f1-bcc8-86aadccee407','test2:1:196e161d-3cb8-11f1-bcc8-86aadccee407','','2026-04-20 20:54:42.361420',1,'SUCCESS');
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

SET FOREIGN_KEY_CHECKS = 1;
