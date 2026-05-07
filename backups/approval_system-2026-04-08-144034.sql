/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19-12.2.2-MariaDB, for Linux (x86_64)
--
-- Host: localhost    Database: approval_system
-- ------------------------------------------------------
-- Server version	12.2.2-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Current Database: `approval_system`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `approval_system` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */;

USE `approval_system`;

--
-- Table structure for table `ACT_EVT_LOG`
--

DROP TABLE IF EXISTS `ACT_EVT_LOG`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_EVT_LOG` (
  `LOG_NR_` bigint(20) NOT NULL AUTO_INCREMENT,
  `TYPE_` varchar(64) DEFAULT NULL,
  `PROC_DEF_ID_` varchar(64) DEFAULT NULL,
  `PROC_INST_ID_` varchar(64) DEFAULT NULL,
  `EXECUTION_ID_` varchar(64) DEFAULT NULL,
  `TASK_ID_` varchar(64) DEFAULT NULL,
  `TIME_STAMP_` timestamp(3) NOT NULL DEFAULT current_timestamp(3),
  `USER_ID_` varchar(255) DEFAULT NULL,
  `DATA_` longblob DEFAULT NULL,
  `LOCK_OWNER_` varchar(255) DEFAULT NULL,
  `LOCK_TIME_` timestamp(3) NULL DEFAULT NULL,
  `IS_PROCESSED_` tinyint(4) DEFAULT 0,
  PRIMARY KEY (`LOG_NR_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_EVT_LOG`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_EVT_LOG` WRITE;
/*!40000 ALTER TABLE `ACT_EVT_LOG` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_EVT_LOG` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_GE_BYTEARRAY`
--

DROP TABLE IF EXISTS `ACT_GE_BYTEARRAY`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_GE_BYTEARRAY` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `NAME_` varchar(255) DEFAULT NULL,
  `DEPLOYMENT_ID_` varchar(64) DEFAULT NULL,
  `BYTES_` longblob DEFAULT NULL,
  `GENERATED_` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`ID_`),
  KEY `ACT_FK_BYTEARR_DEPL` (`DEPLOYMENT_ID_`),
  CONSTRAINT `ACT_FK_BYTEARR_DEPL` FOREIGN KEY (`DEPLOYMENT_ID_`) REFERENCES `ACT_RE_DEPLOYMENT` (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_GE_BYTEARRAY`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_GE_BYTEARRAY` WRITE;
/*!40000 ALTER TABLE `ACT_GE_BYTEARRAY` DISABLE KEYS */;
INSERT INTO `ACT_GE_BYTEARRAY` VALUES
('1cff31ea-3268-11f1-ac2f-dadd23df0f92',1,'hist.var-countersignUsers',NULL,'��\0sr\0java.util.ArrayListx����a�\0I\0sizexp\0\0\0w\0\0\0t\03x',NULL),
('61f5f986-2d11-11f1-b116-b62bdfc0de2a',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-orsign.bpmn20.xml','61f5f985-2d11-11f1-b116-b62bdfc0de2a','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalOrSign\" name=\"Approval Or-Sign\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"orSignTask\"/>\n\n    <userTask id=\"orSignTask\" name=\"Or-Sign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${approveCount >= 1 || rejectCount == nrOfInstances}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToOrSign\" sourceRef=\"applicantRework\" targetRef=\"orSignTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"orSignTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approveCount >= 1}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approveCount == 0}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('61f5f987-2d11-11f1-b116-b62bdfc0de2a',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-sequential.bpmn20.xml','61f5f985-2d11-11f1-b116-b62bdfc0de2a','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalSequential\" name=\"Approval Sequential\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"sequentialTask\"/>\n\n    <userTask id=\"sequentialTask\" name=\"Sequential Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"true\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${rejectCount > 0 || (nrOfCompletedInstances == nrOfInstances)}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToSequential\" sourceRef=\"applicantRework\" targetRef=\"sequentialTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"sequentialTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${rejectCount == 0}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${rejectCount > 0}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('61f5f988-2d11-11f1-b116-b62bdfc0de2a',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-workflow.bpmn20.xml','61f5f985-2d11-11f1-b116-b62bdfc0de2a','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalWorkflow\" name=\"Approval Workflow\" isExecutable=\"true\">\n\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"countersignTask\"/>\n\n    <userTask id=\"countersignTask\" name=\"Countersign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${countersignMode == \'ALL\' ? (rejectCount == 0 &amp;&amp; nrOfCompletedInstances == nrOfInstances)\n            : (approveCount >= requiredApprove || rejectCount > (nrOfInstances - requiredApprove))}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"countersignTask\" targetRef=\"decision\"/>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToCountersign\" sourceRef=\"applicantRework\" targetRef=\"countersignTask\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n\n  </process>\n</definitions>\n',0),
('61f5f989-2d11-11f1-b116-b62bdfc0de2a',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-single.bpmn20.xml','61f5f985-2d11-11f1-b116-b62bdfc0de2a','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalSingle\" name=\"Approval Single\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"singleApprovalTask\"/>\n\n    <userTask id=\"singleApprovalTask\" name=\"Single Approval Task\" flowable:assignee=\"${approverId}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${singleApprovalTaskListener}\"/>\n      </extensionElements>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToApproval\" sourceRef=\"applicantRework\" targetRef=\"singleApprovalTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"singleApprovalTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approvalResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approvalResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('61f5f98a-2d11-11f1-b116-b62bdfc0de2a',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-countersign.bpmn20.xml','61f5f985-2d11-11f1-b116-b62bdfc0de2a','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalCountersign\" name=\"Approval Countersign\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"countersignTask\"/>\n\n    <userTask id=\"countersignTask\" name=\"Countersign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${countersignMode == \'ALL\' ? (rejectCount == 0 &amp;&amp; nrOfCompletedInstances == nrOfInstances)\n            : (approveCount >= requiredApprove || rejectCount > (nrOfInstances - requiredApprove))}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToCountersign\" sourceRef=\"applicantRework\" targetRef=\"countersignTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"countersignTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('915633c3-2d13-11f1-a0b3-b62bdfc0de2a',1,'hist.var-countersignUsers',NULL,'��\0sr\0java.util.ArrayListx����a�\0I\0sizexp\0\0\0w\0\0\0t\03x',NULL),
('a031727c-2efb-11f1-a2e2-122ee0cf0f75',1,'hist.var-countersignUsers',NULL,'��\0sr\0java.util.ArrayListx����a�\0I\0sizexp\0\0\0w\0\0\0t\03x',NULL),
('c753f3b5-2efc-11f1-a2e2-122ee0cf0f75',1,'hist.var-countersignUsers',NULL,'��\0sr\0java.util.ArrayListx����a�\0I\0sizexp\0\0\0w\0\0\0t\03x',NULL);
/*!40000 ALTER TABLE `ACT_GE_BYTEARRAY` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_GE_PROPERTY`
--

DROP TABLE IF EXISTS `ACT_GE_PROPERTY`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_GE_PROPERTY` (
  `NAME_` varchar(64) NOT NULL,
  `VALUE_` varchar(300) DEFAULT NULL,
  `REV_` int(11) DEFAULT NULL,
  PRIMARY KEY (`NAME_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_GE_PROPERTY`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_GE_PROPERTY` WRITE;
/*!40000 ALTER TABLE `ACT_GE_PROPERTY` DISABLE KEYS */;
INSERT INTO `ACT_GE_PROPERTY` VALUES
('batch.schema.version','6.8.1.0',1),
('cfg.execution-related-entities-count','true',1),
('cfg.task-related-entities-count','true',1),
('common.schema.version','6.8.1.0',1),
('entitylink.schema.version','6.8.1.0',1),
('eventsubscription.schema.version','6.8.1.0',1),
('identitylink.schema.version','6.8.1.0',1),
('job.schema.version','6.8.1.0',1),
('next.dbid','1',1),
('schema.history','create(6.8.1.0)',1),
('schema.version','6.8.1.0',1),
('task.schema.version','6.8.1.0',1),
('variable.schema.version','6.8.1.0',1);
/*!40000 ALTER TABLE `ACT_GE_PROPERTY` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_HI_ACTINST`
--

DROP TABLE IF EXISTS `ACT_HI_ACTINST`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_HI_ACTINST` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT 1,
  `PROC_DEF_ID_` varchar(64) NOT NULL,
  `PROC_INST_ID_` varchar(64) NOT NULL,
  `EXECUTION_ID_` varchar(64) NOT NULL,
  `ACT_ID_` varchar(255) NOT NULL,
  `TASK_ID_` varchar(64) DEFAULT NULL,
  `CALL_PROC_INST_ID_` varchar(64) DEFAULT NULL,
  `ACT_NAME_` varchar(255) DEFAULT NULL,
  `ACT_TYPE_` varchar(255) NOT NULL,
  `ASSIGNEE_` varchar(255) DEFAULT NULL,
  `START_TIME_` datetime(3) NOT NULL,
  `END_TIME_` datetime(3) DEFAULT NULL,
  `TRANSACTION_ORDER_` int(11) DEFAULT NULL,
  `DURATION_` bigint(20) DEFAULT NULL,
  `DELETE_REASON_` varchar(4000) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_HI_ACT_INST_START` (`START_TIME_`),
  KEY `ACT_IDX_HI_ACT_INST_END` (`END_TIME_`),
  KEY `ACT_IDX_HI_ACT_INST_PROCINST` (`PROC_INST_ID_`,`ACT_ID_`),
  KEY `ACT_IDX_HI_ACT_INST_EXEC` (`EXECUTION_ID_`,`ACT_ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_HI_ACTINST`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_HI_ACTINST` WRITE;
/*!40000 ALTER TABLE `ACT_HI_ACTINST` DISABLE KEYS */;
INSERT INTO `ACT_HI_ACTINST` VALUES
('1cff5902-3268-11f1-ac2f-dadd23df0f92',1,'approvalSequential:1:620514bc-2d11-11f1-b116-b62bdfc0de2a','1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1cff31f1-3268-11f1-ac2f-dadd23df0f92','start',NULL,NULL,'Start','startEvent',NULL,'2026-04-07 17:56:56.968','2026-04-07 17:56:56.970',1,2,NULL,''),
('1cfff543-3268-11f1-ac2f-dadd23df0f92',1,'approvalSequential:1:620514bc-2d11-11f1-b116-b62bdfc0de2a','1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1cff31f1-3268-11f1-ac2f-dadd23df0f92','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-04-07 17:56:56.972','2026-04-07 17:56:56.972',2,0,NULL,''),
('1d00b89b-3268-11f1-ac2f-dadd23df0f92',2,'approvalSequential:1:620514bc-2d11-11f1-b116-b62bdfc0de2a','1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1d009185-3268-11f1-ac2f-dadd23df0f92','sequentialTask','1d012dcc-3268-11f1-ac2f-dadd23df0f92',NULL,'Sequential Task','userTask','3','2026-04-07 17:56:56.977','2026-04-07 17:57:11.141',3,14164,'CANCELLED',''),
('23d4549c-2efc-11f1-a2e2-122ee0cf0f75',1,'approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a031c0a3-2efb-11f1-a2e2-122ee0cf0f75','flow2',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-04-03 09:26:29.295','2026-04-03 09:26:29.295',1,0,NULL,''),
('23d4a2bd-2efc-11f1-a2e2-122ee0cf0f75',1,'approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a031c0a3-2efb-11f1-a2e2-122ee0cf0f75','decision',NULL,NULL,'Decision','exclusiveGateway',NULL,'2026-04-03 09:26:29.297','2026-04-03 09:26:29.312',2,15,NULL,''),
('23d6ecae-2efc-11f1-a2e2-122ee0cf0f75',1,'approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a031c0a3-2efb-11f1-a2e2-122ee0cf0f75','flow4',NULL,NULL,'Reject','sequenceFlow',NULL,'2026-04-03 09:26:29.312','2026-04-03 09:26:29.312',3,0,NULL,''),
('23d73acf-2efc-11f1-a2e2-122ee0cf0f75',1,'approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a031c0a3-2efb-11f1-a2e2-122ee0cf0f75','rejectEnd',NULL,NULL,'Rejected','endEvent',NULL,'2026-04-03 09:26:29.314','2026-04-03 09:26:29.319',4,5,NULL,''),
('915633cb-2d13-11f1-a0b3-b62bdfc0de2a',1,'approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','915633ca-2d13-11f1-a0b3-b62bdfc0de2a','start',NULL,NULL,'Start','startEvent',NULL,'2026-03-31 23:09:09.117','2026-03-31 23:09:09.119',1,2,NULL,''),
('9156d00c-2d13-11f1-a0b3-b62bdfc0de2a',1,'approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','915633ca-2d13-11f1-a0b3-b62bdfc0de2a','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-03-31 23:09:09.121','2026-03-31 23:09:09.121',2,0,NULL,''),
('9156d00d-2d13-11f1-a0b3-b62bdfc0de2a',2,'approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','915633ca-2d13-11f1-a0b3-b62bdfc0de2a','singleApprovalTask','9157453e-2d13-11f1-a0b3-b62bdfc0de2a',NULL,'Single Approval Task','userTask','3','2026-03-31 23:09:09.121','2026-03-31 23:09:47.365',3,38244,NULL,''),
('a031c0a4-2efb-11f1-a2e2-122ee0cf0f75',1,'approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a031c0a3-2efb-11f1-a2e2-122ee0cf0f75','start',NULL,NULL,'Start','startEvent',NULL,'2026-04-03 09:22:48.449','2026-04-03 09:22:48.457',1,8,NULL,''),
('a0339565-2efb-11f1-a2e2-122ee0cf0f75',1,'approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a031c0a3-2efb-11f1-a2e2-122ee0cf0f75','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-04-03 09:22:48.460','2026-04-03 09:22:48.460',2,0,NULL,''),
('a033bc76-2efb-11f1-a2e2-122ee0cf0f75',2,'approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a031c0a3-2efb-11f1-a2e2-122ee0cf0f75','singleApprovalTask','a0359137-2efb-11f1-a2e2-122ee0cf0f75',NULL,'Single Approval Task','userTask','3','2026-04-03 09:22:48.461','2026-04-03 09:26:29.291',3,220830,NULL,''),
('a8228863-2d13-11f1-a0b3-b62bdfc0de2a',1,'approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','915633ca-2d13-11f1-a0b3-b62bdfc0de2a','flow2',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-03-31 23:09:47.366','2026-03-31 23:09:47.366',1,0,NULL,''),
('a8228864-2d13-11f1-a0b3-b62bdfc0de2a',1,'approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','915633ca-2d13-11f1-a0b3-b62bdfc0de2a','decision',NULL,NULL,'Decision','exclusiveGateway',NULL,'2026-03-31 23:09:47.366','2026-03-31 23:09:47.369',2,3,NULL,''),
('a822fd95-2d13-11f1-a0b3-b62bdfc0de2a',1,'approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','915633ca-2d13-11f1-a0b3-b62bdfc0de2a','flow3',NULL,NULL,'Approve','sequenceFlow',NULL,'2026-03-31 23:09:47.369','2026-03-31 23:09:47.369',3,0,NULL,''),
('a82324a6-2d13-11f1-a0b3-b62bdfc0de2a',1,'approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','915633ca-2d13-11f1-a0b3-b62bdfc0de2a','approveEnd',NULL,NULL,'Approved','endEvent',NULL,'2026-03-31 23:09:47.370','2026-03-31 23:09:47.371',4,1,NULL,''),
('c7541acd-2efc-11f1-a2e2-122ee0cf0f75',1,'approvalCountersign:1:620514bf-2d11-11f1-b116-b62bdfc0de2a','c753a590-2efc-11f1-a2e2-122ee0cf0f75','c7541acc-2efc-11f1-a2e2-122ee0cf0f75','start',NULL,NULL,'Start','startEvent',NULL,'2026-04-03 09:31:03.601','2026-04-03 09:31:03.602',1,1,NULL,''),
('c75441de-2efc-11f1-a2e2-122ee0cf0f75',1,'approvalCountersign:1:620514bf-2d11-11f1-b116-b62bdfc0de2a','c753a590-2efc-11f1-a2e2-122ee0cf0f75','c7541acc-2efc-11f1-a2e2-122ee0cf0f75','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-04-03 09:31:03.602','2026-04-03 09:31:03.602',2,0,NULL,''),
('c7557a66-2efc-11f1-a2e2-122ee0cf0f75',2,'approvalCountersign:1:620514bf-2d11-11f1-b116-b62bdfc0de2a','c753a590-2efc-11f1-a2e2-122ee0cf0f75','c7550533-2efc-11f1-a2e2-122ee0cf0f75','countersignTask','c7557a67-2efc-11f1-a2e2-122ee0cf0f75',NULL,'Countersign Task','userTask','3','2026-04-03 09:31:03.610','2026-04-03 09:31:35.830',3,32220,NULL,''),
('da8c9b4d-2efc-11f1-a2e2-122ee0cf0f75',1,'approvalCountersign:1:620514bf-2d11-11f1-b116-b62bdfc0de2a','c753a590-2efc-11f1-a2e2-122ee0cf0f75','da8c9b4c-2efc-11f1-a2e2-122ee0cf0f75','flow2',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-04-03 09:31:35.848','2026-04-03 09:31:35.848',1,0,NULL,''),
('da8cc25e-2efc-11f1-a2e2-122ee0cf0f75',1,'approvalCountersign:1:620514bf-2d11-11f1-b116-b62bdfc0de2a','c753a590-2efc-11f1-a2e2-122ee0cf0f75','da8c9b4c-2efc-11f1-a2e2-122ee0cf0f75','decision',NULL,NULL,'Decision','exclusiveGateway',NULL,'2026-04-03 09:31:35.849','2026-04-03 09:31:35.850',2,1,NULL,''),
('da8ce96f-2efc-11f1-a2e2-122ee0cf0f75',1,'approvalCountersign:1:620514bf-2d11-11f1-b116-b62bdfc0de2a','c753a590-2efc-11f1-a2e2-122ee0cf0f75','da8c9b4c-2efc-11f1-a2e2-122ee0cf0f75','flow3',NULL,NULL,'Approve','sequenceFlow',NULL,'2026-04-03 09:31:35.850','2026-04-03 09:31:35.850',3,0,NULL,''),
('da8ce970-2efc-11f1-a2e2-122ee0cf0f75',1,'approvalCountersign:1:620514bf-2d11-11f1-b116-b62bdfc0de2a','c753a590-2efc-11f1-a2e2-122ee0cf0f75','da8c9b4c-2efc-11f1-a2e2-122ee0cf0f75','approveEnd',NULL,NULL,'Approved','endEvent',NULL,'2026-04-03 09:31:35.850','2026-04-03 09:31:35.850',4,0,NULL,'');
/*!40000 ALTER TABLE `ACT_HI_ACTINST` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_HI_ATTACHMENT`
--

DROP TABLE IF EXISTS `ACT_HI_ATTACHMENT`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_HI_ATTACHMENT` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `USER_ID_` varchar(255) DEFAULT NULL,
  `NAME_` varchar(255) DEFAULT NULL,
  `DESCRIPTION_` varchar(4000) DEFAULT NULL,
  `TYPE_` varchar(255) DEFAULT NULL,
  `TASK_ID_` varchar(64) DEFAULT NULL,
  `PROC_INST_ID_` varchar(64) DEFAULT NULL,
  `URL_` varchar(4000) DEFAULT NULL,
  `CONTENT_ID_` varchar(64) DEFAULT NULL,
  `TIME_` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_HI_ATTACHMENT`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_HI_ATTACHMENT` WRITE;
/*!40000 ALTER TABLE `ACT_HI_ATTACHMENT` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_HI_ATTACHMENT` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_HI_COMMENT`
--

DROP TABLE IF EXISTS `ACT_HI_COMMENT`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_HI_COMMENT` (
  `ID_` varchar(64) NOT NULL,
  `TYPE_` varchar(255) DEFAULT NULL,
  `TIME_` datetime(3) NOT NULL,
  `USER_ID_` varchar(255) DEFAULT NULL,
  `TASK_ID_` varchar(64) DEFAULT NULL,
  `PROC_INST_ID_` varchar(64) DEFAULT NULL,
  `ACTION_` varchar(255) DEFAULT NULL,
  `MESSAGE_` varchar(4000) DEFAULT NULL,
  `FULL_MSG_` longblob DEFAULT NULL,
  PRIMARY KEY (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_HI_COMMENT`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_HI_COMMENT` WRITE;
/*!40000 ALTER TABLE `ACT_HI_COMMENT` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_HI_COMMENT` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_HI_DETAIL`
--

DROP TABLE IF EXISTS `ACT_HI_DETAIL`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_HI_DETAIL` (
  `ID_` varchar(64) NOT NULL,
  `TYPE_` varchar(255) NOT NULL,
  `PROC_INST_ID_` varchar(64) DEFAULT NULL,
  `EXECUTION_ID_` varchar(64) DEFAULT NULL,
  `TASK_ID_` varchar(64) DEFAULT NULL,
  `ACT_INST_ID_` varchar(64) DEFAULT NULL,
  `NAME_` varchar(255) NOT NULL,
  `VAR_TYPE_` varchar(255) DEFAULT NULL,
  `REV_` int(11) DEFAULT NULL,
  `TIME_` datetime(3) NOT NULL,
  `BYTEARRAY_ID_` varchar(64) DEFAULT NULL,
  `DOUBLE_` double DEFAULT NULL,
  `LONG_` bigint(20) DEFAULT NULL,
  `TEXT_` varchar(4000) DEFAULT NULL,
  `TEXT2_` varchar(4000) DEFAULT NULL,
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_HI_DETAIL_PROC_INST` (`PROC_INST_ID_`),
  KEY `ACT_IDX_HI_DETAIL_ACT_INST` (`ACT_INST_ID_`),
  KEY `ACT_IDX_HI_DETAIL_TIME` (`TIME_`),
  KEY `ACT_IDX_HI_DETAIL_NAME` (`NAME_`),
  KEY `ACT_IDX_HI_DETAIL_TASK_ID` (`TASK_ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_HI_DETAIL`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_HI_DETAIL` WRITE;
/*!40000 ALTER TABLE `ACT_HI_DETAIL` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_HI_DETAIL` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_HI_ENTITYLINK`
--

DROP TABLE IF EXISTS `ACT_HI_ENTITYLINK`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_HI_ENTITYLINK` (
  `ID_` varchar(64) NOT NULL,
  `LINK_TYPE_` varchar(255) DEFAULT NULL,
  `CREATE_TIME_` datetime(3) DEFAULT NULL,
  `SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SUB_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `SCOPE_DEFINITION_ID_` varchar(255) DEFAULT NULL,
  `PARENT_ELEMENT_ID_` varchar(255) DEFAULT NULL,
  `REF_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `REF_SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `REF_SCOPE_DEFINITION_ID_` varchar(255) DEFAULT NULL,
  `ROOT_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `ROOT_SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `HIERARCHY_TYPE_` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_HI_ENT_LNK_SCOPE` (`SCOPE_ID_`,`SCOPE_TYPE_`,`LINK_TYPE_`),
  KEY `ACT_IDX_HI_ENT_LNK_REF_SCOPE` (`REF_SCOPE_ID_`,`REF_SCOPE_TYPE_`,`LINK_TYPE_`),
  KEY `ACT_IDX_HI_ENT_LNK_ROOT_SCOPE` (`ROOT_SCOPE_ID_`,`ROOT_SCOPE_TYPE_`,`LINK_TYPE_`),
  KEY `ACT_IDX_HI_ENT_LNK_SCOPE_DEF` (`SCOPE_DEFINITION_ID_`,`SCOPE_TYPE_`,`LINK_TYPE_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_HI_ENTITYLINK`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_HI_ENTITYLINK` WRITE;
/*!40000 ALTER TABLE `ACT_HI_ENTITYLINK` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_HI_ENTITYLINK` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_HI_IDENTITYLINK`
--

DROP TABLE IF EXISTS `ACT_HI_IDENTITYLINK`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_HI_IDENTITYLINK` (
  `ID_` varchar(64) NOT NULL,
  `GROUP_ID_` varchar(255) DEFAULT NULL,
  `TYPE_` varchar(255) DEFAULT NULL,
  `USER_ID_` varchar(255) DEFAULT NULL,
  `TASK_ID_` varchar(64) DEFAULT NULL,
  `CREATE_TIME_` datetime(3) DEFAULT NULL,
  `PROC_INST_ID_` varchar(64) DEFAULT NULL,
  `SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SUB_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `SCOPE_DEFINITION_ID_` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_HI_IDENT_LNK_USER` (`USER_ID_`),
  KEY `ACT_IDX_HI_IDENT_LNK_SCOPE` (`SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_HI_IDENT_LNK_SUB_SCOPE` (`SUB_SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_HI_IDENT_LNK_SCOPE_DEF` (`SCOPE_DEFINITION_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_HI_IDENT_LNK_TASK` (`TASK_ID_`),
  KEY `ACT_IDX_HI_IDENT_LNK_PROCINST` (`PROC_INST_ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_HI_IDENTITYLINK`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_HI_IDENTITYLINK` WRITE;
/*!40000 ALTER TABLE `ACT_HI_IDENTITYLINK` DISABLE KEYS */;
INSERT INTO `ACT_HI_IDENTITYLINK` VALUES
('1d01a2fd-3268-11f1-ac2f-dadd23df0f92',NULL,'assignee','3','1d012dcc-3268-11f1-ac2f-dadd23df0f92','2026-04-07 17:56:56.983',NULL,NULL,NULL,NULL,NULL),
('1d01ca0e-3268-11f1-ac2f-dadd23df0f92',NULL,'participant','3',NULL,'2026-04-07 17:56:56.984','1cfce7f3-3268-11f1-ac2f-dadd23df0f92',NULL,NULL,NULL,NULL),
('91576c4f-2d13-11f1-a0b3-b62bdfc0de2a',NULL,'assignee','3','9157453e-2d13-11f1-a0b3-b62bdfc0de2a','2026-03-31 23:09:09.125',NULL,NULL,NULL,NULL,NULL),
('91579260-2d13-11f1-a0b3-b62bdfc0de2a',NULL,'participant','3',NULL,'2026-03-31 23:09:09.126','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a',NULL,NULL,NULL,NULL),
('a0367b98-2efb-11f1-a2e2-122ee0cf0f75',NULL,'assignee','3','a0359137-2efb-11f1-a2e2-122ee0cf0f75','2026-04-03 09:22:48.479',NULL,NULL,NULL,NULL,NULL),
('a036c9b9-2efb-11f1-a2e2-122ee0cf0f75',NULL,'participant','3',NULL,'2026-04-03 09:22:48.481','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75',NULL,NULL,NULL,NULL),
('c755a178-2efc-11f1-a2e2-122ee0cf0f75',NULL,'assignee','3','c7557a67-2efc-11f1-a2e2-122ee0cf0f75','2026-04-03 09:31:03.611',NULL,NULL,NULL,NULL,NULL),
('c755a179-2efc-11f1-a2e2-122ee0cf0f75',NULL,'participant','3',NULL,'2026-04-03 09:31:03.611','c753a590-2efc-11f1-a2e2-122ee0cf0f75',NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `ACT_HI_IDENTITYLINK` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_HI_PROCINST`
--

DROP TABLE IF EXISTS `ACT_HI_PROCINST`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_HI_PROCINST` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT 1,
  `PROC_INST_ID_` varchar(64) NOT NULL,
  `BUSINESS_KEY_` varchar(255) DEFAULT NULL,
  `PROC_DEF_ID_` varchar(64) NOT NULL,
  `START_TIME_` datetime(3) NOT NULL,
  `END_TIME_` datetime(3) DEFAULT NULL,
  `DURATION_` bigint(20) DEFAULT NULL,
  `START_USER_ID_` varchar(255) DEFAULT NULL,
  `START_ACT_ID_` varchar(255) DEFAULT NULL,
  `END_ACT_ID_` varchar(255) DEFAULT NULL,
  `SUPER_PROCESS_INSTANCE_ID_` varchar(64) DEFAULT NULL,
  `DELETE_REASON_` varchar(4000) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  `NAME_` varchar(255) DEFAULT NULL,
  `CALLBACK_ID_` varchar(255) DEFAULT NULL,
  `CALLBACK_TYPE_` varchar(255) DEFAULT NULL,
  `REFERENCE_ID_` varchar(255) DEFAULT NULL,
  `REFERENCE_TYPE_` varchar(255) DEFAULT NULL,
  `PROPAGATED_STAGE_INST_ID_` varchar(255) DEFAULT NULL,
  `BUSINESS_STATUS_` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID_`),
  UNIQUE KEY `PROC_INST_ID_` (`PROC_INST_ID_`),
  KEY `ACT_IDX_HI_PRO_INST_END` (`END_TIME_`),
  KEY `ACT_IDX_HI_PRO_I_BUSKEY` (`BUSINESS_KEY_`),
  KEY `ACT_IDX_HI_PRO_SUPER_PROCINST` (`SUPER_PROCESS_INSTANCE_ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_HI_PROCINST`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_HI_PROCINST` WRITE;
/*!40000 ALTER TABLE `ACT_HI_PROCINST` DISABLE KEYS */;
INSERT INTO `ACT_HI_PROCINST` VALUES
('1cfce7f3-3268-11f1-ac2f-dadd23df0f92',2,'1cfce7f3-3268-11f1-ac2f-dadd23df0f92','91a08642-b54e-4a78-867b-c63843b11e00','approvalSequential:1:620514bc-2d11-11f1-b116-b62bdfc0de2a','2026-04-07 17:56:56.952','2026-04-07 17:57:11.181',14229,NULL,'start',NULL,NULL,'CANCELLED','',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a',2,'9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','460d566b-285c-4e19-936f-a5919e6c2f68','approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a','2026-03-31 23:09:09.109','2026-03-31 23:09:47.379',38270,NULL,'start','approveEnd',NULL,NULL,'',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('a02b09d6-2efb-11f1-a2e2-122ee0cf0f75',2,'a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','e2e70aaa-dd3b-40d0-b309-29584e67d562','approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a','2026-04-03 09:22:48.403','2026-04-03 09:26:29.367',220964,NULL,'start','rejectEnd',NULL,NULL,'',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('c753a590-2efc-11f1-a2e2-122ee0cf0f75',2,'c753a590-2efc-11f1-a2e2-122ee0cf0f75','6b76cee6-0fbf-416e-b162-0a0bd8efd297','approvalCountersign:1:620514bf-2d11-11f1-b116-b62bdfc0de2a','2026-04-03 09:31:03.598','2026-04-03 09:31:35.869',32271,NULL,'start','approveEnd',NULL,NULL,'',NULL,NULL,NULL,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `ACT_HI_PROCINST` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_HI_TASKINST`
--

DROP TABLE IF EXISTS `ACT_HI_TASKINST`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_HI_TASKINST` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT 1,
  `PROC_DEF_ID_` varchar(64) DEFAULT NULL,
  `TASK_DEF_ID_` varchar(64) DEFAULT NULL,
  `TASK_DEF_KEY_` varchar(255) DEFAULT NULL,
  `PROC_INST_ID_` varchar(64) DEFAULT NULL,
  `EXECUTION_ID_` varchar(64) DEFAULT NULL,
  `SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SUB_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `SCOPE_DEFINITION_ID_` varchar(255) DEFAULT NULL,
  `PROPAGATED_STAGE_INST_ID_` varchar(255) DEFAULT NULL,
  `NAME_` varchar(255) DEFAULT NULL,
  `PARENT_TASK_ID_` varchar(64) DEFAULT NULL,
  `DESCRIPTION_` varchar(4000) DEFAULT NULL,
  `OWNER_` varchar(255) DEFAULT NULL,
  `ASSIGNEE_` varchar(255) DEFAULT NULL,
  `START_TIME_` datetime(3) NOT NULL,
  `CLAIM_TIME_` datetime(3) DEFAULT NULL,
  `END_TIME_` datetime(3) DEFAULT NULL,
  `DURATION_` bigint(20) DEFAULT NULL,
  `DELETE_REASON_` varchar(4000) DEFAULT NULL,
  `PRIORITY_` int(11) DEFAULT NULL,
  `DUE_DATE_` datetime(3) DEFAULT NULL,
  `FORM_KEY_` varchar(255) DEFAULT NULL,
  `CATEGORY_` varchar(255) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  `LAST_UPDATED_TIME_` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_HI_TASK_SCOPE` (`SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_HI_TASK_SUB_SCOPE` (`SUB_SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_HI_TASK_SCOPE_DEF` (`SCOPE_DEFINITION_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_HI_TASK_INST_PROCINST` (`PROC_INST_ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_HI_TASKINST`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_HI_TASKINST` WRITE;
/*!40000 ALTER TABLE `ACT_HI_TASKINST` DISABLE KEYS */;
INSERT INTO `ACT_HI_TASKINST` VALUES
('1d012dcc-3268-11f1-ac2f-dadd23df0f92',2,'approvalSequential:1:620514bc-2d11-11f1-b116-b62bdfc0de2a',NULL,'sequentialTask','1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1d009185-3268-11f1-ac2f-dadd23df0f92',NULL,NULL,NULL,NULL,NULL,'Sequential Task',NULL,NULL,NULL,'3','2026-04-07 17:56:56.978',NULL,'2026-04-07 17:57:11.134',14156,'CANCELLED',50,NULL,NULL,NULL,'','2026-04-07 17:57:11.134'),
('9157453e-2d13-11f1-a0b3-b62bdfc0de2a',2,'approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a',NULL,'singleApprovalTask','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','915633ca-2d13-11f1-a0b3-b62bdfc0de2a',NULL,NULL,NULL,NULL,NULL,'Single Approval Task',NULL,NULL,NULL,'3','2026-03-31 23:09:09.121',NULL,'2026-03-31 23:09:47.362',38241,NULL,50,NULL,NULL,NULL,'','2026-03-31 23:09:47.362'),
('a0359137-2efb-11f1-a2e2-122ee0cf0f75',2,'approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a',NULL,'singleApprovalTask','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a031c0a3-2efb-11f1-a2e2-122ee0cf0f75',NULL,NULL,NULL,NULL,NULL,'Single Approval Task',NULL,NULL,NULL,'3','2026-04-03 09:22:48.461',NULL,'2026-04-03 09:26:29.281',220820,NULL,50,NULL,NULL,NULL,'','2026-04-03 09:26:29.281'),
('c7557a67-2efc-11f1-a2e2-122ee0cf0f75',2,'approvalCountersign:1:620514bf-2d11-11f1-b116-b62bdfc0de2a',NULL,'countersignTask','c753a590-2efc-11f1-a2e2-122ee0cf0f75','c7550533-2efc-11f1-a2e2-122ee0cf0f75',NULL,NULL,NULL,NULL,NULL,'Countersign Task',NULL,NULL,NULL,'3','2026-04-03 09:31:03.610',NULL,'2026-04-03 09:31:35.821',32211,NULL,50,NULL,NULL,NULL,'','2026-04-03 09:31:35.821');
/*!40000 ALTER TABLE `ACT_HI_TASKINST` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_HI_TSK_LOG`
--

DROP TABLE IF EXISTS `ACT_HI_TSK_LOG`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_HI_TSK_LOG` (
  `ID_` bigint(20) NOT NULL AUTO_INCREMENT,
  `TYPE_` varchar(64) DEFAULT NULL,
  `TASK_ID_` varchar(64) NOT NULL,
  `TIME_STAMP_` timestamp(3) NOT NULL,
  `USER_ID_` varchar(255) DEFAULT NULL,
  `DATA_` varchar(4000) DEFAULT NULL,
  `EXECUTION_ID_` varchar(64) DEFAULT NULL,
  `PROC_INST_ID_` varchar(64) DEFAULT NULL,
  `PROC_DEF_ID_` varchar(64) DEFAULT NULL,
  `SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SCOPE_DEFINITION_ID_` varchar(255) DEFAULT NULL,
  `SUB_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  PRIMARY KEY (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_HI_TSK_LOG`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_HI_TSK_LOG` WRITE;
/*!40000 ALTER TABLE `ACT_HI_TSK_LOG` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_HI_TSK_LOG` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_HI_VARINST`
--

DROP TABLE IF EXISTS `ACT_HI_VARINST`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_HI_VARINST` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT 1,
  `PROC_INST_ID_` varchar(64) DEFAULT NULL,
  `EXECUTION_ID_` varchar(64) DEFAULT NULL,
  `TASK_ID_` varchar(64) DEFAULT NULL,
  `NAME_` varchar(255) NOT NULL,
  `VAR_TYPE_` varchar(100) DEFAULT NULL,
  `SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SUB_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `BYTEARRAY_ID_` varchar(64) DEFAULT NULL,
  `DOUBLE_` double DEFAULT NULL,
  `LONG_` bigint(20) DEFAULT NULL,
  `TEXT_` varchar(4000) DEFAULT NULL,
  `TEXT2_` varchar(4000) DEFAULT NULL,
  `META_INFO_` varchar(4000) DEFAULT NULL,
  `CREATE_TIME_` datetime(3) DEFAULT NULL,
  `LAST_UPDATED_TIME_` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_HI_PROCVAR_NAME_TYPE` (`NAME_`,`VAR_TYPE_`),
  KEY `ACT_IDX_HI_VAR_SCOPE_ID_TYPE` (`SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_HI_VAR_SUB_ID_TYPE` (`SUB_SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_HI_PROCVAR_PROC_INST` (`PROC_INST_ID_`),
  KEY `ACT_IDX_HI_PROCVAR_TASK_ID` (`TASK_ID_`),
  KEY `ACT_IDX_HI_PROCVAR_EXE` (`EXECUTION_ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_HI_VARINST`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_HI_VARINST` WRITE;
/*!40000 ALTER TABLE `ACT_HI_VARINST` DISABLE KEYS */;
INSERT INTO `ACT_HI_VARINST` VALUES
('1cfd0f04-3268-11f1-ac2f-dadd23df0f92',0,'1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1cfce7f3-3268-11f1-ac2f-dadd23df0f92',NULL,'requestTemplateKey','string',NULL,NULL,NULL,NULL,NULL,NULL,'expense',NULL,NULL,'2026-04-07 17:56:56.954','2026-04-07 17:56:56.954'),
('1cfd3615-3268-11f1-ac2f-dadd23df0f92',0,'1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1cfce7f3-3268-11f1-ac2f-dadd23df0f92',NULL,'requestTemplateLabel','string',NULL,NULL,NULL,NULL,NULL,NULL,'报销申请',NULL,NULL,'2026-04-07 17:56:56.954','2026-04-07 17:56:56.954'),
('1cfd3616-3268-11f1-ac2f-dadd23df0f92',0,'1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1cfce7f3-3268-11f1-ac2f-dadd23df0f92',NULL,'countersignMode','string',NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL,'2026-04-07 17:56:56.954','2026-04-07 17:56:56.954'),
('1cfd3617-3268-11f1-ac2f-dadd23df0f92',0,'1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1cfce7f3-3268-11f1-ac2f-dadd23df0f92',NULL,'businessKey','string',NULL,NULL,NULL,NULL,NULL,NULL,'91a08642-b54e-4a78-867b-c63843b11e00',NULL,NULL,'2026-04-07 17:56:56.955','2026-04-07 17:56:56.955'),
('1cff31e9-3268-11f1-ac2f-dadd23df0f92',0,'1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1cfce7f3-3268-11f1-ac2f-dadd23df0f92',NULL,'countersignUsers','serializable',NULL,NULL,NULL,'1cff31ea-3268-11f1-ac2f-dadd23df0f92',NULL,NULL,NULL,NULL,NULL,'2026-04-07 17:56:56.967','2026-04-07 17:56:56.967'),
('1cff31eb-3268-11f1-ac2f-dadd23df0f92',0,'1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1cfce7f3-3268-11f1-ac2f-dadd23df0f92',NULL,'requiredApprove','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-04-07 17:56:56.967','2026-04-07 17:56:56.967'),
('1cff31ec-3268-11f1-ac2f-dadd23df0f92',0,'1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1cfce7f3-3268-11f1-ac2f-dadd23df0f92',NULL,'approveCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-04-07 17:56:56.967','2026-04-07 17:56:56.967'),
('1cff31ed-3268-11f1-ac2f-dadd23df0f92',0,'1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1cfce7f3-3268-11f1-ac2f-dadd23df0f92',NULL,'applicantId','long',NULL,NULL,NULL,NULL,NULL,2,'2',NULL,NULL,'2026-04-07 17:56:56.967','2026-04-07 17:56:56.967'),
('1cff31ee-3268-11f1-ac2f-dadd23df0f92',0,'1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1cfce7f3-3268-11f1-ac2f-dadd23df0f92',NULL,'title','string',NULL,NULL,NULL,NULL,NULL,NULL,'请假申请',NULL,NULL,'2026-04-07 17:56:56.967','2026-04-07 17:56:56.967'),
('1cff31ef-3268-11f1-ac2f-dadd23df0f92',0,'1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1cfce7f3-3268-11f1-ac2f-dadd23df0f92',NULL,'rejectCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-04-07 17:56:56.967','2026-04-07 17:56:56.967'),
('1cff31f0-3268-11f1-ac2f-dadd23df0f92',0,'1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1cfce7f3-3268-11f1-ac2f-dadd23df0f92',NULL,'countersignResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'PENDING',NULL,NULL,'2026-04-07 17:56:56.967','2026-04-07 17:56:56.967'),
('1d009186-3268-11f1-ac2f-dadd23df0f92',0,'1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1cfff544-3268-11f1-ac2f-dadd23df0f92',NULL,'nrOfInstances','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-04-07 17:56:56.976','2026-04-07 17:56:56.976'),
('1d009187-3268-11f1-ac2f-dadd23df0f92',0,'1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1cfff544-3268-11f1-ac2f-dadd23df0f92',NULL,'nrOfCompletedInstances','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-04-07 17:56:56.976','2026-04-07 17:56:56.976'),
('1d009188-3268-11f1-ac2f-dadd23df0f92',0,'1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1cfff544-3268-11f1-ac2f-dadd23df0f92',NULL,'nrOfActiveInstances','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-04-07 17:56:56.976','2026-04-07 17:56:56.976'),
('1d009189-3268-11f1-ac2f-dadd23df0f92',0,'1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1d009185-3268-11f1-ac2f-dadd23df0f92',NULL,'countersignUser','string',NULL,NULL,NULL,NULL,NULL,NULL,'3',NULL,NULL,'2026-04-07 17:56:56.976','2026-04-07 17:56:56.976'),
('1d00b89a-3268-11f1-ac2f-dadd23df0f92',0,'1cfce7f3-3268-11f1-ac2f-dadd23df0f92','1d009185-3268-11f1-ac2f-dadd23df0f92',NULL,'loopCounter','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-04-07 17:56:56.977','2026-04-07 17:56:56.977'),
('23d0840a-2efc-11f1-a2e2-122ee0cf0f75',0,'a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75',NULL,'comments','string',NULL,NULL,NULL,NULL,NULL,NULL,'rejected',NULL,NULL,'2026-04-03 09:26:29.271','2026-04-03 09:26:29.271'),
('23d0ab1b-2efc-11f1-a2e2-122ee0cf0f75',0,'a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75',NULL,'approvalResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'REJECT',NULL,NULL,'2026-04-03 09:26:29.271','2026-04-03 09:26:29.271'),
('9155224e-2d13-11f1-a0b3-b62bdfc0de2a',0,'9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a',NULL,'approverId','string',NULL,NULL,NULL,NULL,NULL,NULL,'3',NULL,NULL,'2026-03-31 23:09:09.110','2026-03-31 23:09:09.110'),
('9155224f-2d13-11f1-a0b3-b62bdfc0de2a',0,'9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a',NULL,'countersignMode','string',NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL,'2026-03-31 23:09:09.110','2026-03-31 23:09:09.110'),
('91552250-2d13-11f1-a0b3-b62bdfc0de2a',0,'9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a',NULL,'businessKey','string',NULL,NULL,NULL,NULL,NULL,NULL,'460d566b-285c-4e19-936f-a5919e6c2f68',NULL,NULL,'2026-03-31 23:09:09.110','2026-03-31 23:09:09.110'),
('915633c2-2d13-11f1-a0b3-b62bdfc0de2a',0,'9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a',NULL,'countersignUsers','serializable',NULL,NULL,NULL,'915633c3-2d13-11f1-a0b3-b62bdfc0de2a',NULL,NULL,NULL,NULL,NULL,'2026-03-31 23:09:09.117','2026-03-31 23:09:09.117'),
('915633c4-2d13-11f1-a0b3-b62bdfc0de2a',0,'9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a',NULL,'requiredApprove','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-03-31 23:09:09.117','2026-03-31 23:09:09.117'),
('915633c5-2d13-11f1-a0b3-b62bdfc0de2a',0,'9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a',NULL,'approveCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-31 23:09:09.117','2026-03-31 23:09:09.117'),
('915633c6-2d13-11f1-a0b3-b62bdfc0de2a',0,'9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a',NULL,'applicantId','long',NULL,NULL,NULL,NULL,NULL,2,'2',NULL,NULL,'2026-03-31 23:09:09.117','2026-03-31 23:09:09.117'),
('915633c7-2d13-11f1-a0b3-b62bdfc0de2a',0,'9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a',NULL,'title','string',NULL,NULL,NULL,NULL,NULL,NULL,'111',NULL,NULL,'2026-03-31 23:09:09.117','2026-03-31 23:09:09.117'),
('915633c8-2d13-11f1-a0b3-b62bdfc0de2a',0,'9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a',NULL,'rejectCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-31 23:09:09.117','2026-03-31 23:09:09.117'),
('915633c9-2d13-11f1-a0b3-b62bdfc0de2a',1,'9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a',NULL,'countersignResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'APPROVE',NULL,NULL,'2026-03-31 23:09:09.117','2026-03-31 23:09:47.361'),
('a02b30e7-2efb-11f1-a2e2-122ee0cf0f75',0,'a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75',NULL,'approverId','string',NULL,NULL,NULL,NULL,NULL,NULL,'3',NULL,NULL,'2026-04-03 09:22:48.408','2026-04-03 09:22:48.408'),
('a02ba618-2efb-11f1-a2e2-122ee0cf0f75',0,'a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75',NULL,'countersignMode','string',NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL,'2026-04-03 09:22:48.408','2026-04-03 09:22:48.408'),
('a02bcd29-2efb-11f1-a2e2-122ee0cf0f75',0,'a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75',NULL,'businessKey','string',NULL,NULL,NULL,NULL,NULL,NULL,'e2e70aaa-dd3b-40d0-b309-29584e67d562',NULL,NULL,'2026-04-03 09:22:48.409','2026-04-03 09:22:48.409'),
('a0314b6b-2efb-11f1-a2e2-122ee0cf0f75',0,'a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75',NULL,'countersignUsers','serializable',NULL,NULL,NULL,'a031727c-2efb-11f1-a2e2-122ee0cf0f75',NULL,NULL,NULL,NULL,NULL,'2026-04-03 09:22:48.446','2026-04-03 09:22:48.446'),
('a031727d-2efb-11f1-a2e2-122ee0cf0f75',0,'a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75',NULL,'requiredApprove','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-04-03 09:22:48.446','2026-04-03 09:22:48.446'),
('a031727e-2efb-11f1-a2e2-122ee0cf0f75',0,'a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75',NULL,'approveCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-04-03 09:22:48.447','2026-04-03 09:22:48.447'),
('a031998f-2efb-11f1-a2e2-122ee0cf0f75',0,'a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75',NULL,'applicantId','long',NULL,NULL,NULL,NULL,NULL,2,'2',NULL,NULL,'2026-04-03 09:22:48.447','2026-04-03 09:22:48.447'),
('a0319990-2efb-11f1-a2e2-122ee0cf0f75',0,'a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75',NULL,'title','string',NULL,NULL,NULL,NULL,NULL,NULL,'请假',NULL,NULL,'2026-04-03 09:22:48.447','2026-04-03 09:22:48.447'),
('a0319991-2efb-11f1-a2e2-122ee0cf0f75',0,'a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75',NULL,'rejectCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-04-03 09:22:48.447','2026-04-03 09:22:48.447'),
('a0319992-2efb-11f1-a2e2-122ee0cf0f75',1,'a02b09d6-2efb-11f1-a2e2-122ee0cf0f75','a02b09d6-2efb-11f1-a2e2-122ee0cf0f75',NULL,'countersignResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'REJECT',NULL,NULL,'2026-04-03 09:22:48.448','2026-04-03 09:26:29.277'),
('a8214fe1-2d13-11f1-a0b3-b62bdfc0de2a',0,'9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a',NULL,'comments','string',NULL,NULL,NULL,NULL,NULL,NULL,'agree',NULL,NULL,'2026-03-31 23:09:47.358','2026-03-31 23:09:47.358'),
('a8214fe2-2d13-11f1-a0b3-b62bdfc0de2a',0,'9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a','9154fb3d-2d13-11f1-a0b3-b62bdfc0de2a',NULL,'approvalResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'APPROVE',NULL,NULL,'2026-03-31 23:09:47.358','2026-03-31 23:09:47.358'),
('c753cca1-2efc-11f1-a2e2-122ee0cf0f75',0,'c753a590-2efc-11f1-a2e2-122ee0cf0f75','c753a590-2efc-11f1-a2e2-122ee0cf0f75',NULL,'countersignMode','string',NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL,'2026-04-03 09:31:03.599','2026-04-03 09:31:03.599'),
('c753cca2-2efc-11f1-a2e2-122ee0cf0f75',0,'c753a590-2efc-11f1-a2e2-122ee0cf0f75','c753a590-2efc-11f1-a2e2-122ee0cf0f75',NULL,'businessKey','string',NULL,NULL,NULL,NULL,NULL,NULL,'6b76cee6-0fbf-416e-b162-0a0bd8efd297',NULL,NULL,'2026-04-03 09:31:03.599','2026-04-03 09:31:03.599'),
('c753f3b4-2efc-11f1-a2e2-122ee0cf0f75',0,'c753a590-2efc-11f1-a2e2-122ee0cf0f75','c753a590-2efc-11f1-a2e2-122ee0cf0f75',NULL,'countersignUsers','serializable',NULL,NULL,NULL,'c753f3b5-2efc-11f1-a2e2-122ee0cf0f75',NULL,NULL,NULL,NULL,NULL,'2026-04-03 09:31:03.600','2026-04-03 09:31:03.600'),
('c753f3b6-2efc-11f1-a2e2-122ee0cf0f75',0,'c753a590-2efc-11f1-a2e2-122ee0cf0f75','c753a590-2efc-11f1-a2e2-122ee0cf0f75',NULL,'requiredApprove','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-04-03 09:31:03.600','2026-04-03 09:31:03.600'),
('c753f3b7-2efc-11f1-a2e2-122ee0cf0f75',1,'c753a590-2efc-11f1-a2e2-122ee0cf0f75','c753a590-2efc-11f1-a2e2-122ee0cf0f75',NULL,'approveCount','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-04-03 09:31:03.600','2026-04-03 09:31:35.816'),
('c753f3b8-2efc-11f1-a2e2-122ee0cf0f75',0,'c753a590-2efc-11f1-a2e2-122ee0cf0f75','c753a590-2efc-11f1-a2e2-122ee0cf0f75',NULL,'applicantId','long',NULL,NULL,NULL,NULL,NULL,2,'2',NULL,NULL,'2026-04-03 09:31:03.601','2026-04-03 09:31:03.601'),
('c7541ac9-2efc-11f1-a2e2-122ee0cf0f75',0,'c753a590-2efc-11f1-a2e2-122ee0cf0f75','c753a590-2efc-11f1-a2e2-122ee0cf0f75',NULL,'title','string',NULL,NULL,NULL,NULL,NULL,NULL,'请假1',NULL,NULL,'2026-04-03 09:31:03.601','2026-04-03 09:31:03.601'),
('c7541aca-2efc-11f1-a2e2-122ee0cf0f75',1,'c753a590-2efc-11f1-a2e2-122ee0cf0f75','c753a590-2efc-11f1-a2e2-122ee0cf0f75',NULL,'rejectCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-04-03 09:31:03.601','2026-04-03 09:31:35.818'),
('c7541acb-2efc-11f1-a2e2-122ee0cf0f75',1,'c753a590-2efc-11f1-a2e2-122ee0cf0f75','c753a590-2efc-11f1-a2e2-122ee0cf0f75',NULL,'countersignResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'APPROVE',NULL,NULL,'2026-04-03 09:31:03.601','2026-04-03 09:31:35.819'),
('c754b710-2efc-11f1-a2e2-122ee0cf0f75',0,'c753a590-2efc-11f1-a2e2-122ee0cf0f75','c75441df-2efc-11f1-a2e2-122ee0cf0f75',NULL,'nrOfInstances','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-04-03 09:31:03.605','2026-04-03 09:31:03.605'),
('c754de21-2efc-11f1-a2e2-122ee0cf0f75',1,'c753a590-2efc-11f1-a2e2-122ee0cf0f75','c75441df-2efc-11f1-a2e2-122ee0cf0f75',NULL,'nrOfCompletedInstances','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-04-03 09:31:03.607','2026-04-03 09:31:35.833'),
('c7550532-2efc-11f1-a2e2-122ee0cf0f75',1,'c753a590-2efc-11f1-a2e2-122ee0cf0f75','c75441df-2efc-11f1-a2e2-122ee0cf0f75',NULL,'nrOfActiveInstances','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-04-03 09:31:03.607','2026-04-03 09:31:35.834'),
('c7550534-2efc-11f1-a2e2-122ee0cf0f75',0,'c753a590-2efc-11f1-a2e2-122ee0cf0f75','c7550533-2efc-11f1-a2e2-122ee0cf0f75',NULL,'countersignUser','string',NULL,NULL,NULL,NULL,NULL,NULL,'3',NULL,NULL,'2026-04-03 09:31:03.607','2026-04-03 09:31:03.607'),
('c7555355-2efc-11f1-a2e2-122ee0cf0f75',0,'c753a590-2efc-11f1-a2e2-122ee0cf0f75','c7550533-2efc-11f1-a2e2-122ee0cf0f75',NULL,'loopCounter','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-04-03 09:31:03.609','2026-04-03 09:31:03.609'),
('da876b2a-2efc-11f1-a2e2-122ee0cf0f75',0,'c753a590-2efc-11f1-a2e2-122ee0cf0f75','c753a590-2efc-11f1-a2e2-122ee0cf0f75',NULL,'comments','string',NULL,NULL,NULL,NULL,NULL,NULL,'approved',NULL,NULL,'2026-04-03 09:31:35.814','2026-04-03 09:31:35.814'),
('da876b2b-2efc-11f1-a2e2-122ee0cf0f75',0,'c753a590-2efc-11f1-a2e2-122ee0cf0f75','c753a590-2efc-11f1-a2e2-122ee0cf0f75',NULL,'approvalResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'APPROVE',NULL,NULL,'2026-04-03 09:31:35.814','2026-04-03 09:31:35.814');
/*!40000 ALTER TABLE `ACT_HI_VARINST` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_ID_BYTEARRAY`
--

DROP TABLE IF EXISTS `ACT_ID_BYTEARRAY`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_ID_BYTEARRAY` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `NAME_` varchar(255) DEFAULT NULL,
  `BYTES_` longblob DEFAULT NULL,
  PRIMARY KEY (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_ID_BYTEARRAY`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_ID_BYTEARRAY` WRITE;
/*!40000 ALTER TABLE `ACT_ID_BYTEARRAY` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_ID_BYTEARRAY` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_ID_GROUP`
--

DROP TABLE IF EXISTS `ACT_ID_GROUP`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_ID_GROUP` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `NAME_` varchar(255) DEFAULT NULL,
  `TYPE_` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_ID_GROUP`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_ID_GROUP` WRITE;
/*!40000 ALTER TABLE `ACT_ID_GROUP` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_ID_GROUP` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_ID_INFO`
--

DROP TABLE IF EXISTS `ACT_ID_INFO`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_ID_INFO` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `USER_ID_` varchar(64) DEFAULT NULL,
  `TYPE_` varchar(64) DEFAULT NULL,
  `KEY_` varchar(255) DEFAULT NULL,
  `VALUE_` varchar(255) DEFAULT NULL,
  `PASSWORD_` longblob DEFAULT NULL,
  `PARENT_ID_` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_ID_INFO`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_ID_INFO` WRITE;
/*!40000 ALTER TABLE `ACT_ID_INFO` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_ID_INFO` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_ID_MEMBERSHIP`
--

DROP TABLE IF EXISTS `ACT_ID_MEMBERSHIP`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_ID_MEMBERSHIP` (
  `USER_ID_` varchar(64) NOT NULL,
  `GROUP_ID_` varchar(64) NOT NULL,
  PRIMARY KEY (`USER_ID_`,`GROUP_ID_`),
  KEY `ACT_FK_MEMB_GROUP` (`GROUP_ID_`),
  CONSTRAINT `ACT_FK_MEMB_GROUP` FOREIGN KEY (`GROUP_ID_`) REFERENCES `ACT_ID_GROUP` (`ID_`),
  CONSTRAINT `ACT_FK_MEMB_USER` FOREIGN KEY (`USER_ID_`) REFERENCES `ACT_ID_USER` (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_ID_MEMBERSHIP`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_ID_MEMBERSHIP` WRITE;
/*!40000 ALTER TABLE `ACT_ID_MEMBERSHIP` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_ID_MEMBERSHIP` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_ID_PRIV`
--

DROP TABLE IF EXISTS `ACT_ID_PRIV`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_ID_PRIV` (
  `ID_` varchar(64) NOT NULL,
  `NAME_` varchar(255) NOT NULL,
  PRIMARY KEY (`ID_`),
  UNIQUE KEY `ACT_UNIQ_PRIV_NAME` (`NAME_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_ID_PRIV`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_ID_PRIV` WRITE;
/*!40000 ALTER TABLE `ACT_ID_PRIV` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_ID_PRIV` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_ID_PRIV_MAPPING`
--

DROP TABLE IF EXISTS `ACT_ID_PRIV_MAPPING`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_ID_PRIV_MAPPING` (
  `ID_` varchar(64) NOT NULL,
  `PRIV_ID_` varchar(64) NOT NULL,
  `USER_ID_` varchar(255) DEFAULT NULL,
  `GROUP_ID_` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID_`),
  KEY `ACT_FK_PRIV_MAPPING` (`PRIV_ID_`),
  KEY `ACT_IDX_PRIV_USER` (`USER_ID_`),
  KEY `ACT_IDX_PRIV_GROUP` (`GROUP_ID_`),
  CONSTRAINT `ACT_FK_PRIV_MAPPING` FOREIGN KEY (`PRIV_ID_`) REFERENCES `ACT_ID_PRIV` (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_ID_PRIV_MAPPING`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_ID_PRIV_MAPPING` WRITE;
/*!40000 ALTER TABLE `ACT_ID_PRIV_MAPPING` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_ID_PRIV_MAPPING` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_ID_PROPERTY`
--

DROP TABLE IF EXISTS `ACT_ID_PROPERTY`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_ID_PROPERTY` (
  `NAME_` varchar(64) NOT NULL,
  `VALUE_` varchar(300) DEFAULT NULL,
  `REV_` int(11) DEFAULT NULL,
  PRIMARY KEY (`NAME_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_ID_PROPERTY`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_ID_PROPERTY` WRITE;
/*!40000 ALTER TABLE `ACT_ID_PROPERTY` DISABLE KEYS */;
INSERT INTO `ACT_ID_PROPERTY` VALUES
('schema.version','6.8.1.0',1);
/*!40000 ALTER TABLE `ACT_ID_PROPERTY` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_ID_TOKEN`
--

DROP TABLE IF EXISTS `ACT_ID_TOKEN`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_ID_TOKEN` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `TOKEN_VALUE_` varchar(255) DEFAULT NULL,
  `TOKEN_DATE_` timestamp(3) NULL DEFAULT NULL,
  `IP_ADDRESS_` varchar(255) DEFAULT NULL,
  `USER_AGENT_` varchar(255) DEFAULT NULL,
  `USER_ID_` varchar(255) DEFAULT NULL,
  `TOKEN_DATA_` varchar(2000) DEFAULT NULL,
  PRIMARY KEY (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_ID_TOKEN`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_ID_TOKEN` WRITE;
/*!40000 ALTER TABLE `ACT_ID_TOKEN` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_ID_TOKEN` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_ID_USER`
--

DROP TABLE IF EXISTS `ACT_ID_USER`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_ID_USER` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `FIRST_` varchar(255) DEFAULT NULL,
  `LAST_` varchar(255) DEFAULT NULL,
  `DISPLAY_NAME_` varchar(255) DEFAULT NULL,
  `EMAIL_` varchar(255) DEFAULT NULL,
  `PWD_` varchar(255) DEFAULT NULL,
  `PICTURE_ID_` varchar(64) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  PRIMARY KEY (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_ID_USER`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_ID_USER` WRITE;
/*!40000 ALTER TABLE `ACT_ID_USER` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_ID_USER` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_PROCDEF_INFO`
--

DROP TABLE IF EXISTS `ACT_PROCDEF_INFO`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_PROCDEF_INFO` (
  `ID_` varchar(64) NOT NULL,
  `PROC_DEF_ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `INFO_JSON_ID_` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`ID_`),
  UNIQUE KEY `ACT_UNIQ_INFO_PROCDEF` (`PROC_DEF_ID_`),
  KEY `ACT_IDX_INFO_PROCDEF` (`PROC_DEF_ID_`),
  KEY `ACT_FK_INFO_JSON_BA` (`INFO_JSON_ID_`),
  CONSTRAINT `ACT_FK_INFO_JSON_BA` FOREIGN KEY (`INFO_JSON_ID_`) REFERENCES `ACT_GE_BYTEARRAY` (`ID_`),
  CONSTRAINT `ACT_FK_INFO_PROCDEF` FOREIGN KEY (`PROC_DEF_ID_`) REFERENCES `ACT_RE_PROCDEF` (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_PROCDEF_INFO`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_PROCDEF_INFO` WRITE;
/*!40000 ALTER TABLE `ACT_PROCDEF_INFO` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_PROCDEF_INFO` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_RE_DEPLOYMENT`
--

DROP TABLE IF EXISTS `ACT_RE_DEPLOYMENT`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_RE_DEPLOYMENT` (
  `ID_` varchar(64) NOT NULL,
  `NAME_` varchar(255) DEFAULT NULL,
  `CATEGORY_` varchar(255) DEFAULT NULL,
  `KEY_` varchar(255) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  `DEPLOY_TIME_` timestamp(3) NULL DEFAULT NULL,
  `DERIVED_FROM_` varchar(64) DEFAULT NULL,
  `DERIVED_FROM_ROOT_` varchar(64) DEFAULT NULL,
  `PARENT_DEPLOYMENT_ID_` varchar(255) DEFAULT NULL,
  `ENGINE_VERSION_` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_RE_DEPLOYMENT`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_RE_DEPLOYMENT` WRITE;
/*!40000 ALTER TABLE `ACT_RE_DEPLOYMENT` DISABLE KEYS */;
INSERT INTO `ACT_RE_DEPLOYMENT` VALUES
('61f5f985-2d11-11f1-b116-b62bdfc0de2a','SpringBootAutoDeployment',NULL,NULL,'','2026-03-31 14:53:30.639',NULL,NULL,'61f5f985-2d11-11f1-b116-b62bdfc0de2a',NULL);
/*!40000 ALTER TABLE `ACT_RE_DEPLOYMENT` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_RE_MODEL`
--

DROP TABLE IF EXISTS `ACT_RE_MODEL`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_RE_MODEL` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `NAME_` varchar(255) DEFAULT NULL,
  `KEY_` varchar(255) DEFAULT NULL,
  `CATEGORY_` varchar(255) DEFAULT NULL,
  `CREATE_TIME_` timestamp(3) NULL DEFAULT NULL,
  `LAST_UPDATE_TIME_` timestamp(3) NULL DEFAULT NULL,
  `VERSION_` int(11) DEFAULT NULL,
  `META_INFO_` varchar(4000) DEFAULT NULL,
  `DEPLOYMENT_ID_` varchar(64) DEFAULT NULL,
  `EDITOR_SOURCE_VALUE_ID_` varchar(64) DEFAULT NULL,
  `EDITOR_SOURCE_EXTRA_VALUE_ID_` varchar(64) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  PRIMARY KEY (`ID_`),
  KEY `ACT_FK_MODEL_SOURCE` (`EDITOR_SOURCE_VALUE_ID_`),
  KEY `ACT_FK_MODEL_SOURCE_EXTRA` (`EDITOR_SOURCE_EXTRA_VALUE_ID_`),
  KEY `ACT_FK_MODEL_DEPLOYMENT` (`DEPLOYMENT_ID_`),
  CONSTRAINT `ACT_FK_MODEL_DEPLOYMENT` FOREIGN KEY (`DEPLOYMENT_ID_`) REFERENCES `ACT_RE_DEPLOYMENT` (`ID_`),
  CONSTRAINT `ACT_FK_MODEL_SOURCE` FOREIGN KEY (`EDITOR_SOURCE_VALUE_ID_`) REFERENCES `ACT_GE_BYTEARRAY` (`ID_`),
  CONSTRAINT `ACT_FK_MODEL_SOURCE_EXTRA` FOREIGN KEY (`EDITOR_SOURCE_EXTRA_VALUE_ID_`) REFERENCES `ACT_GE_BYTEARRAY` (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_RE_MODEL`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_RE_MODEL` WRITE;
/*!40000 ALTER TABLE `ACT_RE_MODEL` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_RE_MODEL` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_RE_PROCDEF`
--

DROP TABLE IF EXISTS `ACT_RE_PROCDEF`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_RE_PROCDEF` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `CATEGORY_` varchar(255) DEFAULT NULL,
  `NAME_` varchar(255) DEFAULT NULL,
  `KEY_` varchar(255) NOT NULL,
  `VERSION_` int(11) NOT NULL,
  `DEPLOYMENT_ID_` varchar(64) DEFAULT NULL,
  `RESOURCE_NAME_` varchar(4000) DEFAULT NULL,
  `DGRM_RESOURCE_NAME_` varchar(4000) DEFAULT NULL,
  `DESCRIPTION_` varchar(4000) DEFAULT NULL,
  `HAS_START_FORM_KEY_` tinyint(4) DEFAULT NULL,
  `HAS_GRAPHICAL_NOTATION_` tinyint(4) DEFAULT NULL,
  `SUSPENSION_STATE_` int(11) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  `ENGINE_VERSION_` varchar(255) DEFAULT NULL,
  `DERIVED_FROM_` varchar(64) DEFAULT NULL,
  `DERIVED_FROM_ROOT_` varchar(64) DEFAULT NULL,
  `DERIVED_VERSION_` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID_`),
  UNIQUE KEY `ACT_UNIQ_PROCDEF` (`KEY_`,`VERSION_`,`DERIVED_VERSION_`,`TENANT_ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_RE_PROCDEF`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_RE_PROCDEF` WRITE;
/*!40000 ALTER TABLE `ACT_RE_PROCDEF` DISABLE KEYS */;
INSERT INTO `ACT_RE_PROCDEF` VALUES
('approvalCountersign:1:620514bf-2d11-11f1-b116-b62bdfc0de2a',1,'http://flowable.org/examples','Approval Countersign','approvalCountersign',1,'61f5f985-2d11-11f1-b116-b62bdfc0de2a','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-countersign.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalOrSign:1:62049f8b-2d11-11f1-b116-b62bdfc0de2a',1,'http://flowable.org/examples','Approval Or-Sign','approvalOrSign',1,'61f5f985-2d11-11f1-b116-b62bdfc0de2a','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-orsign.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalSequential:1:620514bc-2d11-11f1-b116-b62bdfc0de2a',1,'http://flowable.org/examples','Approval Sequential','approvalSequential',1,'61f5f985-2d11-11f1-b116-b62bdfc0de2a','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-sequential.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a',1,'http://flowable.org/examples','Approval Single','approvalSingle',1,'61f5f985-2d11-11f1-b116-b62bdfc0de2a','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-single.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalWorkflow:1:620514bd-2d11-11f1-b116-b62bdfc0de2a',1,'http://flowable.org/examples','Approval Workflow','approvalWorkflow',1,'61f5f985-2d11-11f1-b116-b62bdfc0de2a','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-workflow.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0);
/*!40000 ALTER TABLE `ACT_RE_PROCDEF` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_RU_ACTINST`
--

DROP TABLE IF EXISTS `ACT_RU_ACTINST`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_RU_ACTINST` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT 1,
  `PROC_DEF_ID_` varchar(64) NOT NULL,
  `PROC_INST_ID_` varchar(64) NOT NULL,
  `EXECUTION_ID_` varchar(64) NOT NULL,
  `ACT_ID_` varchar(255) NOT NULL,
  `TASK_ID_` varchar(64) DEFAULT NULL,
  `CALL_PROC_INST_ID_` varchar(64) DEFAULT NULL,
  `ACT_NAME_` varchar(255) DEFAULT NULL,
  `ACT_TYPE_` varchar(255) NOT NULL,
  `ASSIGNEE_` varchar(255) DEFAULT NULL,
  `START_TIME_` datetime(3) NOT NULL,
  `END_TIME_` datetime(3) DEFAULT NULL,
  `DURATION_` bigint(20) DEFAULT NULL,
  `TRANSACTION_ORDER_` int(11) DEFAULT NULL,
  `DELETE_REASON_` varchar(4000) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_RU_ACTI_START` (`START_TIME_`),
  KEY `ACT_IDX_RU_ACTI_END` (`END_TIME_`),
  KEY `ACT_IDX_RU_ACTI_PROC` (`PROC_INST_ID_`),
  KEY `ACT_IDX_RU_ACTI_PROC_ACT` (`PROC_INST_ID_`,`ACT_ID_`),
  KEY `ACT_IDX_RU_ACTI_EXEC` (`EXECUTION_ID_`),
  KEY `ACT_IDX_RU_ACTI_EXEC_ACT` (`EXECUTION_ID_`,`ACT_ID_`),
  KEY `ACT_IDX_RU_ACTI_TASK` (`TASK_ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_RU_ACTINST`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_RU_ACTINST` WRITE;
/*!40000 ALTER TABLE `ACT_RU_ACTINST` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_RU_ACTINST` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_RU_DEADLETTER_JOB`
--

DROP TABLE IF EXISTS `ACT_RU_DEADLETTER_JOB`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_RU_DEADLETTER_JOB` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `CATEGORY_` varchar(255) DEFAULT NULL,
  `TYPE_` varchar(255) NOT NULL,
  `EXCLUSIVE_` tinyint(1) DEFAULT NULL,
  `EXECUTION_ID_` varchar(64) DEFAULT NULL,
  `PROCESS_INSTANCE_ID_` varchar(64) DEFAULT NULL,
  `PROC_DEF_ID_` varchar(64) DEFAULT NULL,
  `ELEMENT_ID_` varchar(255) DEFAULT NULL,
  `ELEMENT_NAME_` varchar(255) DEFAULT NULL,
  `SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SUB_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `SCOPE_DEFINITION_ID_` varchar(255) DEFAULT NULL,
  `CORRELATION_ID_` varchar(255) DEFAULT NULL,
  `EXCEPTION_STACK_ID_` varchar(64) DEFAULT NULL,
  `EXCEPTION_MSG_` varchar(4000) DEFAULT NULL,
  `DUEDATE_` timestamp(3) NULL DEFAULT NULL,
  `REPEAT_` varchar(255) DEFAULT NULL,
  `HANDLER_TYPE_` varchar(255) DEFAULT NULL,
  `HANDLER_CFG_` varchar(4000) DEFAULT NULL,
  `CUSTOM_VALUES_ID_` varchar(64) DEFAULT NULL,
  `CREATE_TIME_` timestamp(3) NULL DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_DEADLETTER_JOB_EXCEPTION_STACK_ID` (`EXCEPTION_STACK_ID_`),
  KEY `ACT_IDX_DEADLETTER_JOB_CUSTOM_VALUES_ID` (`CUSTOM_VALUES_ID_`),
  KEY `ACT_IDX_DEADLETTER_JOB_CORRELATION_ID` (`CORRELATION_ID_`),
  KEY `ACT_IDX_DJOB_SCOPE` (`SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_DJOB_SUB_SCOPE` (`SUB_SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_DJOB_SCOPE_DEF` (`SCOPE_DEFINITION_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_FK_DEADLETTER_JOB_EXECUTION` (`EXECUTION_ID_`),
  KEY `ACT_FK_DEADLETTER_JOB_PROCESS_INSTANCE` (`PROCESS_INSTANCE_ID_`),
  KEY `ACT_FK_DEADLETTER_JOB_PROC_DEF` (`PROC_DEF_ID_`),
  CONSTRAINT `ACT_FK_DEADLETTER_JOB_CUSTOM_VALUES` FOREIGN KEY (`CUSTOM_VALUES_ID_`) REFERENCES `ACT_GE_BYTEARRAY` (`ID_`),
  CONSTRAINT `ACT_FK_DEADLETTER_JOB_EXCEPTION` FOREIGN KEY (`EXCEPTION_STACK_ID_`) REFERENCES `ACT_GE_BYTEARRAY` (`ID_`),
  CONSTRAINT `ACT_FK_DEADLETTER_JOB_EXECUTION` FOREIGN KEY (`EXECUTION_ID_`) REFERENCES `ACT_RU_EXECUTION` (`ID_`),
  CONSTRAINT `ACT_FK_DEADLETTER_JOB_PROCESS_INSTANCE` FOREIGN KEY (`PROCESS_INSTANCE_ID_`) REFERENCES `ACT_RU_EXECUTION` (`ID_`),
  CONSTRAINT `ACT_FK_DEADLETTER_JOB_PROC_DEF` FOREIGN KEY (`PROC_DEF_ID_`) REFERENCES `ACT_RE_PROCDEF` (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_RU_DEADLETTER_JOB`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_RU_DEADLETTER_JOB` WRITE;
/*!40000 ALTER TABLE `ACT_RU_DEADLETTER_JOB` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_RU_DEADLETTER_JOB` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_RU_ENTITYLINK`
--

DROP TABLE IF EXISTS `ACT_RU_ENTITYLINK`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_RU_ENTITYLINK` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `CREATE_TIME_` datetime(3) DEFAULT NULL,
  `LINK_TYPE_` varchar(255) DEFAULT NULL,
  `SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SUB_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `SCOPE_DEFINITION_ID_` varchar(255) DEFAULT NULL,
  `PARENT_ELEMENT_ID_` varchar(255) DEFAULT NULL,
  `REF_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `REF_SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `REF_SCOPE_DEFINITION_ID_` varchar(255) DEFAULT NULL,
  `ROOT_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `ROOT_SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `HIERARCHY_TYPE_` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_ENT_LNK_SCOPE` (`SCOPE_ID_`,`SCOPE_TYPE_`,`LINK_TYPE_`),
  KEY `ACT_IDX_ENT_LNK_REF_SCOPE` (`REF_SCOPE_ID_`,`REF_SCOPE_TYPE_`,`LINK_TYPE_`),
  KEY `ACT_IDX_ENT_LNK_ROOT_SCOPE` (`ROOT_SCOPE_ID_`,`ROOT_SCOPE_TYPE_`,`LINK_TYPE_`),
  KEY `ACT_IDX_ENT_LNK_SCOPE_DEF` (`SCOPE_DEFINITION_ID_`,`SCOPE_TYPE_`,`LINK_TYPE_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_RU_ENTITYLINK`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_RU_ENTITYLINK` WRITE;
/*!40000 ALTER TABLE `ACT_RU_ENTITYLINK` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_RU_ENTITYLINK` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_RU_EVENT_SUBSCR`
--

DROP TABLE IF EXISTS `ACT_RU_EVENT_SUBSCR`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_RU_EVENT_SUBSCR` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `EVENT_TYPE_` varchar(255) NOT NULL,
  `EVENT_NAME_` varchar(255) DEFAULT NULL,
  `EXECUTION_ID_` varchar(64) DEFAULT NULL,
  `PROC_INST_ID_` varchar(64) DEFAULT NULL,
  `ACTIVITY_ID_` varchar(64) DEFAULT NULL,
  `CONFIGURATION_` varchar(255) DEFAULT NULL,
  `CREATED_` timestamp(3) NOT NULL DEFAULT current_timestamp(3),
  `PROC_DEF_ID_` varchar(64) DEFAULT NULL,
  `SUB_SCOPE_ID_` varchar(64) DEFAULT NULL,
  `SCOPE_ID_` varchar(64) DEFAULT NULL,
  `SCOPE_DEFINITION_ID_` varchar(64) DEFAULT NULL,
  `SCOPE_TYPE_` varchar(64) DEFAULT NULL,
  `LOCK_TIME_` timestamp(3) NULL DEFAULT NULL,
  `LOCK_OWNER_` varchar(255) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_EVENT_SUBSCR_CONFIG_` (`CONFIGURATION_`),
  KEY `ACT_IDX_EVENT_SUBSCR_SCOPEREF_` (`SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_FK_EVENT_EXEC` (`EXECUTION_ID_`),
  CONSTRAINT `ACT_FK_EVENT_EXEC` FOREIGN KEY (`EXECUTION_ID_`) REFERENCES `ACT_RU_EXECUTION` (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_RU_EVENT_SUBSCR`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_RU_EVENT_SUBSCR` WRITE;
/*!40000 ALTER TABLE `ACT_RU_EVENT_SUBSCR` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_RU_EVENT_SUBSCR` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_RU_EXECUTION`
--

DROP TABLE IF EXISTS `ACT_RU_EXECUTION`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_RU_EXECUTION` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `PROC_INST_ID_` varchar(64) DEFAULT NULL,
  `BUSINESS_KEY_` varchar(255) DEFAULT NULL,
  `PARENT_ID_` varchar(64) DEFAULT NULL,
  `PROC_DEF_ID_` varchar(64) DEFAULT NULL,
  `SUPER_EXEC_` varchar(64) DEFAULT NULL,
  `ROOT_PROC_INST_ID_` varchar(64) DEFAULT NULL,
  `ACT_ID_` varchar(255) DEFAULT NULL,
  `IS_ACTIVE_` tinyint(4) DEFAULT NULL,
  `IS_CONCURRENT_` tinyint(4) DEFAULT NULL,
  `IS_SCOPE_` tinyint(4) DEFAULT NULL,
  `IS_EVENT_SCOPE_` tinyint(4) DEFAULT NULL,
  `IS_MI_ROOT_` tinyint(4) DEFAULT NULL,
  `SUSPENSION_STATE_` int(11) DEFAULT NULL,
  `CACHED_ENT_STATE_` int(11) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  `NAME_` varchar(255) DEFAULT NULL,
  `START_ACT_ID_` varchar(255) DEFAULT NULL,
  `START_TIME_` datetime(3) DEFAULT NULL,
  `START_USER_ID_` varchar(255) DEFAULT NULL,
  `LOCK_TIME_` timestamp(3) NULL DEFAULT NULL,
  `LOCK_OWNER_` varchar(255) DEFAULT NULL,
  `IS_COUNT_ENABLED_` tinyint(4) DEFAULT NULL,
  `EVT_SUBSCR_COUNT_` int(11) DEFAULT NULL,
  `TASK_COUNT_` int(11) DEFAULT NULL,
  `JOB_COUNT_` int(11) DEFAULT NULL,
  `TIMER_JOB_COUNT_` int(11) DEFAULT NULL,
  `SUSP_JOB_COUNT_` int(11) DEFAULT NULL,
  `DEADLETTER_JOB_COUNT_` int(11) DEFAULT NULL,
  `EXTERNAL_WORKER_JOB_COUNT_` int(11) DEFAULT NULL,
  `VAR_COUNT_` int(11) DEFAULT NULL,
  `ID_LINK_COUNT_` int(11) DEFAULT NULL,
  `CALLBACK_ID_` varchar(255) DEFAULT NULL,
  `CALLBACK_TYPE_` varchar(255) DEFAULT NULL,
  `REFERENCE_ID_` varchar(255) DEFAULT NULL,
  `REFERENCE_TYPE_` varchar(255) DEFAULT NULL,
  `PROPAGATED_STAGE_INST_ID_` varchar(255) DEFAULT NULL,
  `BUSINESS_STATUS_` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_EXEC_BUSKEY` (`BUSINESS_KEY_`),
  KEY `ACT_IDC_EXEC_ROOT` (`ROOT_PROC_INST_ID_`),
  KEY `ACT_IDX_EXEC_REF_ID_` (`REFERENCE_ID_`),
  KEY `ACT_FK_EXE_PROCINST` (`PROC_INST_ID_`),
  KEY `ACT_FK_EXE_PARENT` (`PARENT_ID_`),
  KEY `ACT_FK_EXE_SUPER` (`SUPER_EXEC_`),
  KEY `ACT_FK_EXE_PROCDEF` (`PROC_DEF_ID_`),
  CONSTRAINT `ACT_FK_EXE_PARENT` FOREIGN KEY (`PARENT_ID_`) REFERENCES `ACT_RU_EXECUTION` (`ID_`) ON DELETE CASCADE,
  CONSTRAINT `ACT_FK_EXE_PROCDEF` FOREIGN KEY (`PROC_DEF_ID_`) REFERENCES `ACT_RE_PROCDEF` (`ID_`),
  CONSTRAINT `ACT_FK_EXE_PROCINST` FOREIGN KEY (`PROC_INST_ID_`) REFERENCES `ACT_RU_EXECUTION` (`ID_`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `ACT_FK_EXE_SUPER` FOREIGN KEY (`SUPER_EXEC_`) REFERENCES `ACT_RU_EXECUTION` (`ID_`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_RU_EXECUTION`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_RU_EXECUTION` WRITE;
/*!40000 ALTER TABLE `ACT_RU_EXECUTION` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_RU_EXECUTION` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_RU_EXTERNAL_JOB`
--

DROP TABLE IF EXISTS `ACT_RU_EXTERNAL_JOB`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_RU_EXTERNAL_JOB` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `CATEGORY_` varchar(255) DEFAULT NULL,
  `TYPE_` varchar(255) NOT NULL,
  `LOCK_EXP_TIME_` timestamp(3) NULL DEFAULT NULL,
  `LOCK_OWNER_` varchar(255) DEFAULT NULL,
  `EXCLUSIVE_` tinyint(1) DEFAULT NULL,
  `EXECUTION_ID_` varchar(64) DEFAULT NULL,
  `PROCESS_INSTANCE_ID_` varchar(64) DEFAULT NULL,
  `PROC_DEF_ID_` varchar(64) DEFAULT NULL,
  `ELEMENT_ID_` varchar(255) DEFAULT NULL,
  `ELEMENT_NAME_` varchar(255) DEFAULT NULL,
  `SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SUB_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `SCOPE_DEFINITION_ID_` varchar(255) DEFAULT NULL,
  `CORRELATION_ID_` varchar(255) DEFAULT NULL,
  `RETRIES_` int(11) DEFAULT NULL,
  `EXCEPTION_STACK_ID_` varchar(64) DEFAULT NULL,
  `EXCEPTION_MSG_` varchar(4000) DEFAULT NULL,
  `DUEDATE_` timestamp(3) NULL DEFAULT NULL,
  `REPEAT_` varchar(255) DEFAULT NULL,
  `HANDLER_TYPE_` varchar(255) DEFAULT NULL,
  `HANDLER_CFG_` varchar(4000) DEFAULT NULL,
  `CUSTOM_VALUES_ID_` varchar(64) DEFAULT NULL,
  `CREATE_TIME_` timestamp(3) NULL DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_EXTERNAL_JOB_EXCEPTION_STACK_ID` (`EXCEPTION_STACK_ID_`),
  KEY `ACT_IDX_EXTERNAL_JOB_CUSTOM_VALUES_ID` (`CUSTOM_VALUES_ID_`),
  KEY `ACT_IDX_EXTERNAL_JOB_CORRELATION_ID` (`CORRELATION_ID_`),
  KEY `ACT_IDX_EJOB_SCOPE` (`SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_EJOB_SUB_SCOPE` (`SUB_SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_EJOB_SCOPE_DEF` (`SCOPE_DEFINITION_ID_`,`SCOPE_TYPE_`),
  CONSTRAINT `ACT_FK_EXTERNAL_JOB_CUSTOM_VALUES` FOREIGN KEY (`CUSTOM_VALUES_ID_`) REFERENCES `ACT_GE_BYTEARRAY` (`ID_`),
  CONSTRAINT `ACT_FK_EXTERNAL_JOB_EXCEPTION` FOREIGN KEY (`EXCEPTION_STACK_ID_`) REFERENCES `ACT_GE_BYTEARRAY` (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_RU_EXTERNAL_JOB`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_RU_EXTERNAL_JOB` WRITE;
/*!40000 ALTER TABLE `ACT_RU_EXTERNAL_JOB` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_RU_EXTERNAL_JOB` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_RU_HISTORY_JOB`
--

DROP TABLE IF EXISTS `ACT_RU_HISTORY_JOB`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_RU_HISTORY_JOB` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `LOCK_EXP_TIME_` timestamp(3) NULL DEFAULT NULL,
  `LOCK_OWNER_` varchar(255) DEFAULT NULL,
  `RETRIES_` int(11) DEFAULT NULL,
  `EXCEPTION_STACK_ID_` varchar(64) DEFAULT NULL,
  `EXCEPTION_MSG_` varchar(4000) DEFAULT NULL,
  `HANDLER_TYPE_` varchar(255) DEFAULT NULL,
  `HANDLER_CFG_` varchar(4000) DEFAULT NULL,
  `CUSTOM_VALUES_ID_` varchar(64) DEFAULT NULL,
  `ADV_HANDLER_CFG_ID_` varchar(64) DEFAULT NULL,
  `CREATE_TIME_` timestamp(3) NULL DEFAULT NULL,
  `SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  PRIMARY KEY (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_RU_HISTORY_JOB`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_RU_HISTORY_JOB` WRITE;
/*!40000 ALTER TABLE `ACT_RU_HISTORY_JOB` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_RU_HISTORY_JOB` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_RU_IDENTITYLINK`
--

DROP TABLE IF EXISTS `ACT_RU_IDENTITYLINK`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_RU_IDENTITYLINK` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `GROUP_ID_` varchar(255) DEFAULT NULL,
  `TYPE_` varchar(255) DEFAULT NULL,
  `USER_ID_` varchar(255) DEFAULT NULL,
  `TASK_ID_` varchar(64) DEFAULT NULL,
  `PROC_INST_ID_` varchar(64) DEFAULT NULL,
  `PROC_DEF_ID_` varchar(64) DEFAULT NULL,
  `SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SUB_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `SCOPE_DEFINITION_ID_` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_IDENT_LNK_USER` (`USER_ID_`),
  KEY `ACT_IDX_IDENT_LNK_GROUP` (`GROUP_ID_`),
  KEY `ACT_IDX_IDENT_LNK_SCOPE` (`SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_IDENT_LNK_SUB_SCOPE` (`SUB_SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_IDENT_LNK_SCOPE_DEF` (`SCOPE_DEFINITION_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_ATHRZ_PROCEDEF` (`PROC_DEF_ID_`),
  KEY `ACT_FK_TSKASS_TASK` (`TASK_ID_`),
  KEY `ACT_FK_IDL_PROCINST` (`PROC_INST_ID_`),
  CONSTRAINT `ACT_FK_ATHRZ_PROCEDEF` FOREIGN KEY (`PROC_DEF_ID_`) REFERENCES `ACT_RE_PROCDEF` (`ID_`),
  CONSTRAINT `ACT_FK_IDL_PROCINST` FOREIGN KEY (`PROC_INST_ID_`) REFERENCES `ACT_RU_EXECUTION` (`ID_`),
  CONSTRAINT `ACT_FK_TSKASS_TASK` FOREIGN KEY (`TASK_ID_`) REFERENCES `ACT_RU_TASK` (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_RU_IDENTITYLINK`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_RU_IDENTITYLINK` WRITE;
/*!40000 ALTER TABLE `ACT_RU_IDENTITYLINK` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_RU_IDENTITYLINK` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_RU_JOB`
--

DROP TABLE IF EXISTS `ACT_RU_JOB`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_RU_JOB` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `CATEGORY_` varchar(255) DEFAULT NULL,
  `TYPE_` varchar(255) NOT NULL,
  `LOCK_EXP_TIME_` timestamp(3) NULL DEFAULT NULL,
  `LOCK_OWNER_` varchar(255) DEFAULT NULL,
  `EXCLUSIVE_` tinyint(1) DEFAULT NULL,
  `EXECUTION_ID_` varchar(64) DEFAULT NULL,
  `PROCESS_INSTANCE_ID_` varchar(64) DEFAULT NULL,
  `PROC_DEF_ID_` varchar(64) DEFAULT NULL,
  `ELEMENT_ID_` varchar(255) DEFAULT NULL,
  `ELEMENT_NAME_` varchar(255) DEFAULT NULL,
  `SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SUB_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `SCOPE_DEFINITION_ID_` varchar(255) DEFAULT NULL,
  `CORRELATION_ID_` varchar(255) DEFAULT NULL,
  `RETRIES_` int(11) DEFAULT NULL,
  `EXCEPTION_STACK_ID_` varchar(64) DEFAULT NULL,
  `EXCEPTION_MSG_` varchar(4000) DEFAULT NULL,
  `DUEDATE_` timestamp(3) NULL DEFAULT NULL,
  `REPEAT_` varchar(255) DEFAULT NULL,
  `HANDLER_TYPE_` varchar(255) DEFAULT NULL,
  `HANDLER_CFG_` varchar(4000) DEFAULT NULL,
  `CUSTOM_VALUES_ID_` varchar(64) DEFAULT NULL,
  `CREATE_TIME_` timestamp(3) NULL DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_JOB_EXCEPTION_STACK_ID` (`EXCEPTION_STACK_ID_`),
  KEY `ACT_IDX_JOB_CUSTOM_VALUES_ID` (`CUSTOM_VALUES_ID_`),
  KEY `ACT_IDX_JOB_CORRELATION_ID` (`CORRELATION_ID_`),
  KEY `ACT_IDX_JOB_SCOPE` (`SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_JOB_SUB_SCOPE` (`SUB_SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_JOB_SCOPE_DEF` (`SCOPE_DEFINITION_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_FK_JOB_EXECUTION` (`EXECUTION_ID_`),
  KEY `ACT_FK_JOB_PROCESS_INSTANCE` (`PROCESS_INSTANCE_ID_`),
  KEY `ACT_FK_JOB_PROC_DEF` (`PROC_DEF_ID_`),
  CONSTRAINT `ACT_FK_JOB_CUSTOM_VALUES` FOREIGN KEY (`CUSTOM_VALUES_ID_`) REFERENCES `ACT_GE_BYTEARRAY` (`ID_`),
  CONSTRAINT `ACT_FK_JOB_EXCEPTION` FOREIGN KEY (`EXCEPTION_STACK_ID_`) REFERENCES `ACT_GE_BYTEARRAY` (`ID_`),
  CONSTRAINT `ACT_FK_JOB_EXECUTION` FOREIGN KEY (`EXECUTION_ID_`) REFERENCES `ACT_RU_EXECUTION` (`ID_`),
  CONSTRAINT `ACT_FK_JOB_PROCESS_INSTANCE` FOREIGN KEY (`PROCESS_INSTANCE_ID_`) REFERENCES `ACT_RU_EXECUTION` (`ID_`),
  CONSTRAINT `ACT_FK_JOB_PROC_DEF` FOREIGN KEY (`PROC_DEF_ID_`) REFERENCES `ACT_RE_PROCDEF` (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_RU_JOB`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_RU_JOB` WRITE;
/*!40000 ALTER TABLE `ACT_RU_JOB` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_RU_JOB` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_RU_SUSPENDED_JOB`
--

DROP TABLE IF EXISTS `ACT_RU_SUSPENDED_JOB`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_RU_SUSPENDED_JOB` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `CATEGORY_` varchar(255) DEFAULT NULL,
  `TYPE_` varchar(255) NOT NULL,
  `EXCLUSIVE_` tinyint(1) DEFAULT NULL,
  `EXECUTION_ID_` varchar(64) DEFAULT NULL,
  `PROCESS_INSTANCE_ID_` varchar(64) DEFAULT NULL,
  `PROC_DEF_ID_` varchar(64) DEFAULT NULL,
  `ELEMENT_ID_` varchar(255) DEFAULT NULL,
  `ELEMENT_NAME_` varchar(255) DEFAULT NULL,
  `SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SUB_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `SCOPE_DEFINITION_ID_` varchar(255) DEFAULT NULL,
  `CORRELATION_ID_` varchar(255) DEFAULT NULL,
  `RETRIES_` int(11) DEFAULT NULL,
  `EXCEPTION_STACK_ID_` varchar(64) DEFAULT NULL,
  `EXCEPTION_MSG_` varchar(4000) DEFAULT NULL,
  `DUEDATE_` timestamp(3) NULL DEFAULT NULL,
  `REPEAT_` varchar(255) DEFAULT NULL,
  `HANDLER_TYPE_` varchar(255) DEFAULT NULL,
  `HANDLER_CFG_` varchar(4000) DEFAULT NULL,
  `CUSTOM_VALUES_ID_` varchar(64) DEFAULT NULL,
  `CREATE_TIME_` timestamp(3) NULL DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_SUSPENDED_JOB_EXCEPTION_STACK_ID` (`EXCEPTION_STACK_ID_`),
  KEY `ACT_IDX_SUSPENDED_JOB_CUSTOM_VALUES_ID` (`CUSTOM_VALUES_ID_`),
  KEY `ACT_IDX_SUSPENDED_JOB_CORRELATION_ID` (`CORRELATION_ID_`),
  KEY `ACT_IDX_SJOB_SCOPE` (`SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_SJOB_SUB_SCOPE` (`SUB_SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_SJOB_SCOPE_DEF` (`SCOPE_DEFINITION_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_FK_SUSPENDED_JOB_EXECUTION` (`EXECUTION_ID_`),
  KEY `ACT_FK_SUSPENDED_JOB_PROCESS_INSTANCE` (`PROCESS_INSTANCE_ID_`),
  KEY `ACT_FK_SUSPENDED_JOB_PROC_DEF` (`PROC_DEF_ID_`),
  CONSTRAINT `ACT_FK_SUSPENDED_JOB_CUSTOM_VALUES` FOREIGN KEY (`CUSTOM_VALUES_ID_`) REFERENCES `ACT_GE_BYTEARRAY` (`ID_`),
  CONSTRAINT `ACT_FK_SUSPENDED_JOB_EXCEPTION` FOREIGN KEY (`EXCEPTION_STACK_ID_`) REFERENCES `ACT_GE_BYTEARRAY` (`ID_`),
  CONSTRAINT `ACT_FK_SUSPENDED_JOB_EXECUTION` FOREIGN KEY (`EXECUTION_ID_`) REFERENCES `ACT_RU_EXECUTION` (`ID_`),
  CONSTRAINT `ACT_FK_SUSPENDED_JOB_PROCESS_INSTANCE` FOREIGN KEY (`PROCESS_INSTANCE_ID_`) REFERENCES `ACT_RU_EXECUTION` (`ID_`),
  CONSTRAINT `ACT_FK_SUSPENDED_JOB_PROC_DEF` FOREIGN KEY (`PROC_DEF_ID_`) REFERENCES `ACT_RE_PROCDEF` (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_RU_SUSPENDED_JOB`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_RU_SUSPENDED_JOB` WRITE;
/*!40000 ALTER TABLE `ACT_RU_SUSPENDED_JOB` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_RU_SUSPENDED_JOB` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_RU_TASK`
--

DROP TABLE IF EXISTS `ACT_RU_TASK`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_RU_TASK` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `EXECUTION_ID_` varchar(64) DEFAULT NULL,
  `PROC_INST_ID_` varchar(64) DEFAULT NULL,
  `PROC_DEF_ID_` varchar(64) DEFAULT NULL,
  `TASK_DEF_ID_` varchar(64) DEFAULT NULL,
  `SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SUB_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `SCOPE_DEFINITION_ID_` varchar(255) DEFAULT NULL,
  `PROPAGATED_STAGE_INST_ID_` varchar(255) DEFAULT NULL,
  `NAME_` varchar(255) DEFAULT NULL,
  `PARENT_TASK_ID_` varchar(64) DEFAULT NULL,
  `DESCRIPTION_` varchar(4000) DEFAULT NULL,
  `TASK_DEF_KEY_` varchar(255) DEFAULT NULL,
  `OWNER_` varchar(255) DEFAULT NULL,
  `ASSIGNEE_` varchar(255) DEFAULT NULL,
  `DELEGATION_` varchar(64) DEFAULT NULL,
  `PRIORITY_` int(11) DEFAULT NULL,
  `CREATE_TIME_` timestamp(3) NULL DEFAULT NULL,
  `DUE_DATE_` datetime(3) DEFAULT NULL,
  `CATEGORY_` varchar(255) DEFAULT NULL,
  `SUSPENSION_STATE_` int(11) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  `FORM_KEY_` varchar(255) DEFAULT NULL,
  `CLAIM_TIME_` datetime(3) DEFAULT NULL,
  `IS_COUNT_ENABLED_` tinyint(4) DEFAULT NULL,
  `VAR_COUNT_` int(11) DEFAULT NULL,
  `ID_LINK_COUNT_` int(11) DEFAULT NULL,
  `SUB_TASK_COUNT_` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_TASK_CREATE` (`CREATE_TIME_`),
  KEY `ACT_IDX_TASK_SCOPE` (`SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_TASK_SUB_SCOPE` (`SUB_SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_TASK_SCOPE_DEF` (`SCOPE_DEFINITION_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_FK_TASK_EXE` (`EXECUTION_ID_`),
  KEY `ACT_FK_TASK_PROCINST` (`PROC_INST_ID_`),
  KEY `ACT_FK_TASK_PROCDEF` (`PROC_DEF_ID_`),
  CONSTRAINT `ACT_FK_TASK_EXE` FOREIGN KEY (`EXECUTION_ID_`) REFERENCES `ACT_RU_EXECUTION` (`ID_`),
  CONSTRAINT `ACT_FK_TASK_PROCDEF` FOREIGN KEY (`PROC_DEF_ID_`) REFERENCES `ACT_RE_PROCDEF` (`ID_`),
  CONSTRAINT `ACT_FK_TASK_PROCINST` FOREIGN KEY (`PROC_INST_ID_`) REFERENCES `ACT_RU_EXECUTION` (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_RU_TASK`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_RU_TASK` WRITE;
/*!40000 ALTER TABLE `ACT_RU_TASK` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_RU_TASK` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_RU_TIMER_JOB`
--

DROP TABLE IF EXISTS `ACT_RU_TIMER_JOB`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_RU_TIMER_JOB` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `CATEGORY_` varchar(255) DEFAULT NULL,
  `TYPE_` varchar(255) NOT NULL,
  `LOCK_EXP_TIME_` timestamp(3) NULL DEFAULT NULL,
  `LOCK_OWNER_` varchar(255) DEFAULT NULL,
  `EXCLUSIVE_` tinyint(1) DEFAULT NULL,
  `EXECUTION_ID_` varchar(64) DEFAULT NULL,
  `PROCESS_INSTANCE_ID_` varchar(64) DEFAULT NULL,
  `PROC_DEF_ID_` varchar(64) DEFAULT NULL,
  `ELEMENT_ID_` varchar(255) DEFAULT NULL,
  `ELEMENT_NAME_` varchar(255) DEFAULT NULL,
  `SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SUB_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `SCOPE_DEFINITION_ID_` varchar(255) DEFAULT NULL,
  `CORRELATION_ID_` varchar(255) DEFAULT NULL,
  `RETRIES_` int(11) DEFAULT NULL,
  `EXCEPTION_STACK_ID_` varchar(64) DEFAULT NULL,
  `EXCEPTION_MSG_` varchar(4000) DEFAULT NULL,
  `DUEDATE_` timestamp(3) NULL DEFAULT NULL,
  `REPEAT_` varchar(255) DEFAULT NULL,
  `HANDLER_TYPE_` varchar(255) DEFAULT NULL,
  `HANDLER_CFG_` varchar(4000) DEFAULT NULL,
  `CUSTOM_VALUES_ID_` varchar(64) DEFAULT NULL,
  `CREATE_TIME_` timestamp(3) NULL DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_TIMER_JOB_EXCEPTION_STACK_ID` (`EXCEPTION_STACK_ID_`),
  KEY `ACT_IDX_TIMER_JOB_CUSTOM_VALUES_ID` (`CUSTOM_VALUES_ID_`),
  KEY `ACT_IDX_TIMER_JOB_CORRELATION_ID` (`CORRELATION_ID_`),
  KEY `ACT_IDX_TIMER_JOB_DUEDATE` (`DUEDATE_`),
  KEY `ACT_IDX_TJOB_SCOPE` (`SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_TJOB_SUB_SCOPE` (`SUB_SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_TJOB_SCOPE_DEF` (`SCOPE_DEFINITION_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_FK_TIMER_JOB_EXECUTION` (`EXECUTION_ID_`),
  KEY `ACT_FK_TIMER_JOB_PROCESS_INSTANCE` (`PROCESS_INSTANCE_ID_`),
  KEY `ACT_FK_TIMER_JOB_PROC_DEF` (`PROC_DEF_ID_`),
  CONSTRAINT `ACT_FK_TIMER_JOB_CUSTOM_VALUES` FOREIGN KEY (`CUSTOM_VALUES_ID_`) REFERENCES `ACT_GE_BYTEARRAY` (`ID_`),
  CONSTRAINT `ACT_FK_TIMER_JOB_EXCEPTION` FOREIGN KEY (`EXCEPTION_STACK_ID_`) REFERENCES `ACT_GE_BYTEARRAY` (`ID_`),
  CONSTRAINT `ACT_FK_TIMER_JOB_EXECUTION` FOREIGN KEY (`EXECUTION_ID_`) REFERENCES `ACT_RU_EXECUTION` (`ID_`),
  CONSTRAINT `ACT_FK_TIMER_JOB_PROCESS_INSTANCE` FOREIGN KEY (`PROCESS_INSTANCE_ID_`) REFERENCES `ACT_RU_EXECUTION` (`ID_`),
  CONSTRAINT `ACT_FK_TIMER_JOB_PROC_DEF` FOREIGN KEY (`PROC_DEF_ID_`) REFERENCES `ACT_RE_PROCDEF` (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_RU_TIMER_JOB`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_RU_TIMER_JOB` WRITE;
/*!40000 ALTER TABLE `ACT_RU_TIMER_JOB` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_RU_TIMER_JOB` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ACT_RU_VARIABLE`
--

DROP TABLE IF EXISTS `ACT_RU_VARIABLE`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ACT_RU_VARIABLE` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `TYPE_` varchar(255) NOT NULL,
  `NAME_` varchar(255) NOT NULL,
  `EXECUTION_ID_` varchar(64) DEFAULT NULL,
  `PROC_INST_ID_` varchar(64) DEFAULT NULL,
  `TASK_ID_` varchar(64) DEFAULT NULL,
  `SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SUB_SCOPE_ID_` varchar(255) DEFAULT NULL,
  `SCOPE_TYPE_` varchar(255) DEFAULT NULL,
  `BYTEARRAY_ID_` varchar(64) DEFAULT NULL,
  `DOUBLE_` double DEFAULT NULL,
  `LONG_` bigint(20) DEFAULT NULL,
  `TEXT_` varchar(4000) DEFAULT NULL,
  `TEXT2_` varchar(4000) DEFAULT NULL,
  `META_INFO_` varchar(4000) DEFAULT NULL,
  PRIMARY KEY (`ID_`),
  KEY `ACT_IDX_RU_VAR_SCOPE_ID_TYPE` (`SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_IDX_RU_VAR_SUB_ID_TYPE` (`SUB_SCOPE_ID_`,`SCOPE_TYPE_`),
  KEY `ACT_FK_VAR_BYTEARRAY` (`BYTEARRAY_ID_`),
  KEY `ACT_IDX_VARIABLE_TASK_ID` (`TASK_ID_`),
  KEY `ACT_FK_VAR_EXE` (`EXECUTION_ID_`),
  KEY `ACT_FK_VAR_PROCINST` (`PROC_INST_ID_`),
  CONSTRAINT `ACT_FK_VAR_BYTEARRAY` FOREIGN KEY (`BYTEARRAY_ID_`) REFERENCES `ACT_GE_BYTEARRAY` (`ID_`),
  CONSTRAINT `ACT_FK_VAR_EXE` FOREIGN KEY (`EXECUTION_ID_`) REFERENCES `ACT_RU_EXECUTION` (`ID_`),
  CONSTRAINT `ACT_FK_VAR_PROCINST` FOREIGN KEY (`PROC_INST_ID_`) REFERENCES `ACT_RU_EXECUTION` (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACT_RU_VARIABLE`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ACT_RU_VARIABLE` WRITE;
/*!40000 ALTER TABLE `ACT_RU_VARIABLE` DISABLE KEYS */;
/*!40000 ALTER TABLE `ACT_RU_VARIABLE` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `FLW_CHANNEL_DEFINITION`
--

DROP TABLE IF EXISTS `FLW_CHANNEL_DEFINITION`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `FLW_CHANNEL_DEFINITION` (
  `ID_` varchar(255) NOT NULL,
  `NAME_` varchar(255) DEFAULT NULL,
  `VERSION_` int(11) DEFAULT NULL,
  `KEY_` varchar(255) DEFAULT NULL,
  `CATEGORY_` varchar(255) DEFAULT NULL,
  `DEPLOYMENT_ID_` varchar(255) DEFAULT NULL,
  `CREATE_TIME_` datetime(3) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT NULL,
  `RESOURCE_NAME_` varchar(255) DEFAULT NULL,
  `DESCRIPTION_` varchar(255) DEFAULT NULL,
  `TYPE_` varchar(255) DEFAULT NULL,
  `IMPLEMENTATION_` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID_`),
  UNIQUE KEY `ACT_IDX_CHANNEL_DEF_UNIQ` (`KEY_`,`VERSION_`,`TENANT_ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FLW_CHANNEL_DEFINITION`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `FLW_CHANNEL_DEFINITION` WRITE;
/*!40000 ALTER TABLE `FLW_CHANNEL_DEFINITION` DISABLE KEYS */;
/*!40000 ALTER TABLE `FLW_CHANNEL_DEFINITION` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `FLW_EVENT_DEFINITION`
--

DROP TABLE IF EXISTS `FLW_EVENT_DEFINITION`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `FLW_EVENT_DEFINITION` (
  `ID_` varchar(255) NOT NULL,
  `NAME_` varchar(255) DEFAULT NULL,
  `VERSION_` int(11) DEFAULT NULL,
  `KEY_` varchar(255) DEFAULT NULL,
  `CATEGORY_` varchar(255) DEFAULT NULL,
  `DEPLOYMENT_ID_` varchar(255) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT NULL,
  `RESOURCE_NAME_` varchar(255) DEFAULT NULL,
  `DESCRIPTION_` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID_`),
  UNIQUE KEY `ACT_IDX_EVENT_DEF_UNIQ` (`KEY_`,`VERSION_`,`TENANT_ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FLW_EVENT_DEFINITION`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `FLW_EVENT_DEFINITION` WRITE;
/*!40000 ALTER TABLE `FLW_EVENT_DEFINITION` DISABLE KEYS */;
/*!40000 ALTER TABLE `FLW_EVENT_DEFINITION` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `FLW_EVENT_DEPLOYMENT`
--

DROP TABLE IF EXISTS `FLW_EVENT_DEPLOYMENT`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `FLW_EVENT_DEPLOYMENT` (
  `ID_` varchar(255) NOT NULL,
  `NAME_` varchar(255) DEFAULT NULL,
  `CATEGORY_` varchar(255) DEFAULT NULL,
  `DEPLOY_TIME_` datetime(3) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT NULL,
  `PARENT_DEPLOYMENT_ID_` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FLW_EVENT_DEPLOYMENT`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `FLW_EVENT_DEPLOYMENT` WRITE;
/*!40000 ALTER TABLE `FLW_EVENT_DEPLOYMENT` DISABLE KEYS */;
/*!40000 ALTER TABLE `FLW_EVENT_DEPLOYMENT` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `FLW_EVENT_RESOURCE`
--

DROP TABLE IF EXISTS `FLW_EVENT_RESOURCE`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `FLW_EVENT_RESOURCE` (
  `ID_` varchar(255) NOT NULL,
  `NAME_` varchar(255) DEFAULT NULL,
  `DEPLOYMENT_ID_` varchar(255) DEFAULT NULL,
  `RESOURCE_BYTES_` longblob DEFAULT NULL,
  PRIMARY KEY (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FLW_EVENT_RESOURCE`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `FLW_EVENT_RESOURCE` WRITE;
/*!40000 ALTER TABLE `FLW_EVENT_RESOURCE` DISABLE KEYS */;
/*!40000 ALTER TABLE `FLW_EVENT_RESOURCE` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `FLW_EV_DATABASECHANGELOG`
--

DROP TABLE IF EXISTS `FLW_EV_DATABASECHANGELOG`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `FLW_EV_DATABASECHANGELOG` (
  `ID` varchar(255) NOT NULL,
  `AUTHOR` varchar(255) NOT NULL,
  `FILENAME` varchar(255) NOT NULL,
  `DATEEXECUTED` datetime NOT NULL,
  `ORDEREXECUTED` int(11) NOT NULL,
  `EXECTYPE` varchar(10) NOT NULL,
  `MD5SUM` varchar(35) DEFAULT NULL,
  `DESCRIPTION` varchar(255) DEFAULT NULL,
  `COMMENTS` varchar(255) DEFAULT NULL,
  `TAG` varchar(255) DEFAULT NULL,
  `LIQUIBASE` varchar(20) DEFAULT NULL,
  `CONTEXTS` varchar(255) DEFAULT NULL,
  `LABELS` varchar(255) DEFAULT NULL,
  `DEPLOYMENT_ID` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FLW_EV_DATABASECHANGELOG`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `FLW_EV_DATABASECHANGELOG` WRITE;
/*!40000 ALTER TABLE `FLW_EV_DATABASECHANGELOG` DISABLE KEYS */;
INSERT INTO `FLW_EV_DATABASECHANGELOG` VALUES
('1','flowable','org/flowable/eventregistry/db/liquibase/flowable-eventregistry-db-changelog.xml','2026-03-31 22:53:25',1,'EXECUTED','9:63268f536c469325acef35970312551b','createTable tableName=FLW_EVENT_DEPLOYMENT; createTable tableName=FLW_EVENT_RESOURCE; createTable tableName=FLW_EVENT_DEFINITION; createIndex indexName=ACT_IDX_EVENT_DEF_UNIQ, tableName=FLW_EVENT_DEFINITION; createTable tableName=FLW_CHANNEL_DEFIN...','',NULL,'4.31.1',NULL,NULL,'4968805440'),
('2','flowable','org/flowable/eventregistry/db/liquibase/flowable-eventregistry-db-changelog.xml','2026-03-31 22:53:25',2,'EXECUTED','9:dcb58b7dfd6dbda66939123a96985536','addColumn tableName=FLW_CHANNEL_DEFINITION; addColumn tableName=FLW_CHANNEL_DEFINITION','',NULL,'4.31.1',NULL,NULL,'4968805440'),
('3','flowable','org/flowable/eventregistry/db/liquibase/flowable-eventregistry-db-changelog.xml','2026-03-31 22:53:26',3,'EXECUTED','9:d0c05678d57af23ad93699991e3bf4f6','customChange','',NULL,'4.31.1',NULL,NULL,'4968805440');
/*!40000 ALTER TABLE `FLW_EV_DATABASECHANGELOG` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `FLW_EV_DATABASECHANGELOGLOCK`
--

DROP TABLE IF EXISTS `FLW_EV_DATABASECHANGELOGLOCK`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `FLW_EV_DATABASECHANGELOGLOCK` (
  `ID` int(11) NOT NULL,
  `LOCKED` tinyint(1) NOT NULL,
  `LOCKGRANTED` datetime DEFAULT NULL,
  `LOCKEDBY` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FLW_EV_DATABASECHANGELOGLOCK`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `FLW_EV_DATABASECHANGELOGLOCK` WRITE;
/*!40000 ALTER TABLE `FLW_EV_DATABASECHANGELOGLOCK` DISABLE KEYS */;
INSERT INTO `FLW_EV_DATABASECHANGELOGLOCK` VALUES
(1,0,NULL,NULL);
/*!40000 ALTER TABLE `FLW_EV_DATABASECHANGELOGLOCK` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `FLW_RU_BATCH`
--

DROP TABLE IF EXISTS `FLW_RU_BATCH`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `FLW_RU_BATCH` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `TYPE_` varchar(64) NOT NULL,
  `SEARCH_KEY_` varchar(255) DEFAULT NULL,
  `SEARCH_KEY2_` varchar(255) DEFAULT NULL,
  `CREATE_TIME_` datetime(3) NOT NULL,
  `COMPLETE_TIME_` datetime(3) DEFAULT NULL,
  `STATUS_` varchar(255) DEFAULT NULL,
  `BATCH_DOC_ID_` varchar(64) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  PRIMARY KEY (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FLW_RU_BATCH`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `FLW_RU_BATCH` WRITE;
/*!40000 ALTER TABLE `FLW_RU_BATCH` DISABLE KEYS */;
/*!40000 ALTER TABLE `FLW_RU_BATCH` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `FLW_RU_BATCH_PART`
--

DROP TABLE IF EXISTS `FLW_RU_BATCH_PART`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `FLW_RU_BATCH_PART` (
  `ID_` varchar(64) NOT NULL,
  `REV_` int(11) DEFAULT NULL,
  `BATCH_ID_` varchar(64) DEFAULT NULL,
  `TYPE_` varchar(64) NOT NULL,
  `SCOPE_ID_` varchar(64) DEFAULT NULL,
  `SUB_SCOPE_ID_` varchar(64) DEFAULT NULL,
  `SCOPE_TYPE_` varchar(64) DEFAULT NULL,
  `SEARCH_KEY_` varchar(255) DEFAULT NULL,
  `SEARCH_KEY2_` varchar(255) DEFAULT NULL,
  `CREATE_TIME_` datetime(3) NOT NULL,
  `COMPLETE_TIME_` datetime(3) DEFAULT NULL,
  `STATUS_` varchar(255) DEFAULT NULL,
  `RESULT_DOC_ID_` varchar(64) DEFAULT NULL,
  `TENANT_ID_` varchar(255) DEFAULT '',
  PRIMARY KEY (`ID_`),
  KEY `FLW_IDX_BATCH_PART` (`BATCH_ID_`),
  CONSTRAINT `FLW_FK_BATCH_PART_PARENT` FOREIGN KEY (`BATCH_ID_`) REFERENCES `FLW_RU_BATCH` (`ID_`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FLW_RU_BATCH_PART`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `FLW_RU_BATCH_PART` WRITE;
/*!40000 ALTER TABLE `FLW_RU_BATCH_PART` DISABLE KEYS */;
/*!40000 ALTER TABLE `FLW_RU_BATCH_PART` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `ai_suggestion_record`
--

DROP TABLE IF EXISTS `ai_suggestion_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ai_suggestion_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `business_key` varchar(64) NOT NULL,
  `process_instance_id` varchar(64) NOT NULL,
  `task_id` varchar(64) NOT NULL,
  `requester_id` bigint(20) NOT NULL,
  `model` varchar(128) DEFAULT NULL,
  `suggestion_json` tinytext NOT NULL,
  `conversation_json` tinytext DEFAULT NULL,
  `adopted` tinyint(1) NOT NULL DEFAULT 0,
  `adopted_at` datetime DEFAULT NULL,
  `final_approval_result` varchar(32) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_ai_suggestion_record_task_id_created_at` (`task_id`,`created_at`),
  KEY `idx_ai_suggestion_record_business_key_created_at` (`business_key`,`created_at`),
  KEY `idx_ai_suggestion_record_process_instance_id` (`process_instance_id`),
  KEY `idx_ai_suggestion_record_requester_id` (`requester_id`),
  CONSTRAINT `fk_ai_suggestion_record_business` FOREIGN KEY (`business_key`) REFERENCES `biz_request` (`business_key`),
  CONSTRAINT `fk_ai_suggestion_record_requester` FOREIGN KEY (`requester_id`) REFERENCES `sys_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ai_suggestion_record`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `ai_suggestion_record` WRITE;
/*!40000 ALTER TABLE `ai_suggestion_record` DISABLE KEYS */;
/*!40000 ALTER TABLE `ai_suggestion_record` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `biz_request`
--

DROP TABLE IF EXISTS `biz_request`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `biz_request` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `business_key` varchar(64) NOT NULL,
  `process_instance_id` varchar(64) DEFAULT NULL,
  `process_definition_id` varchar(64) DEFAULT NULL,
  `form_instance_id` bigint(20) DEFAULT NULL,
  `applicant_id` bigint(20) NOT NULL,
  `applicant_dept_id` bigint(20) DEFAULT NULL,
  `applicant_post_id` bigint(20) DEFAULT NULL,
  `title` varchar(128) NOT NULL,
  `status` int(11) NOT NULL,
  `current_task_id` varchar(64) DEFAULT NULL,
  `current_assignee_id` bigint(20) DEFAULT NULL,
  `submit_time` datetime DEFAULT NULL,
  `finish_time` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_deleted` int(11) NOT NULL DEFAULT 0,
  `form_version_id` bigint(20) DEFAULT NULL,
  `workflow_definition_id` bigint(20) DEFAULT NULL,
  `workflow_definition_version_id` bigint(20) DEFAULT NULL,
  `request_template_key` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_biz_request_business_key` (`business_key`),
  UNIQUE KEY `uk_biz_request_process_instance_id` (`process_instance_id`),
  KEY `idx_biz_request_form_instance_id` (`form_instance_id`),
  KEY `idx_biz_request_applicant_id` (`applicant_id`),
  KEY `idx_biz_request_applicant_dept_id` (`applicant_dept_id`),
  KEY `idx_biz_request_applicant_post_id` (`applicant_post_id`),
  KEY `idx_biz_request_current_assignee_id` (`current_assignee_id`),
  CONSTRAINT `fk_biz_request_applicant` FOREIGN KEY (`applicant_id`) REFERENCES `sys_user` (`id`),
  CONSTRAINT `fk_biz_request_applicant_dept` FOREIGN KEY (`applicant_dept_id`) REFERENCES `sys_dept` (`id`),
  CONSTRAINT `fk_biz_request_applicant_post` FOREIGN KEY (`applicant_post_id`) REFERENCES `sys_post` (`id`),
  CONSTRAINT `fk_biz_request_current_assignee` FOREIGN KEY (`current_assignee_id`) REFERENCES `sys_user` (`id`),
  CONSTRAINT `fk_biz_request_form_instance` FOREIGN KEY (`form_instance_id`) REFERENCES `form_instance` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `biz_request`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `biz_request` WRITE;
/*!40000 ALTER TABLE `biz_request` DISABLE KEYS */;
/*!40000 ALTER TABLE `biz_request` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `biz_request_log`
--

DROP TABLE IF EXISTS `biz_request_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `biz_request_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `business_key` varchar(64) NOT NULL,
  `process_instance_id` varchar(64) DEFAULT NULL,
  `task_id` varchar(64) DEFAULT NULL,
  `operator_id` bigint(20) NOT NULL,
  `action` varchar(32) NOT NULL,
  `comment` varchar(512) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_biz_request_log_business_key` (`business_key`),
  KEY `idx_biz_request_log_process_instance_id` (`process_instance_id`),
  KEY `idx_biz_request_log_task_id` (`task_id`),
  KEY `idx_biz_request_log_operator_id` (`operator_id`),
  CONSTRAINT `fk_biz_request_log_business` FOREIGN KEY (`business_key`) REFERENCES `biz_request` (`business_key`),
  CONSTRAINT `fk_biz_request_log_operator` FOREIGN KEY (`operator_id`) REFERENCES `sys_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `biz_request_log`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `biz_request_log` WRITE;
/*!40000 ALTER TABLE `biz_request_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `biz_request_log` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `biz_request_task`
--

DROP TABLE IF EXISTS `biz_request_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `biz_request_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `business_key` varchar(64) NOT NULL,
  `process_instance_id` varchar(64) NOT NULL,
  `task_id` varchar(64) NOT NULL,
  `task_name` varchar(128) DEFAULT NULL,
  `assignee_id` bigint(20) DEFAULT NULL,
  `owner_id` bigint(20) DEFAULT NULL,
  `status` int(11) NOT NULL,
  `action` varchar(32) DEFAULT NULL,
  `comment` varchar(512) DEFAULT NULL,
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_biz_request_task_task_id` (`task_id`),
  KEY `idx_biz_request_task_business_key` (`business_key`),
  KEY `idx_biz_request_task_process_instance_id` (`process_instance_id`),
  KEY `idx_biz_request_task_assignee_id` (`assignee_id`),
  KEY `idx_biz_request_task_owner_id` (`owner_id`),
  CONSTRAINT `fk_biz_request_task_assignee` FOREIGN KEY (`assignee_id`) REFERENCES `sys_user` (`id`),
  CONSTRAINT `fk_biz_request_task_business` FOREIGN KEY (`business_key`) REFERENCES `biz_request` (`business_key`),
  CONSTRAINT `fk_biz_request_task_owner` FOREIGN KEY (`owner_id`) REFERENCES `sys_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `biz_request_task`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `biz_request_task` WRITE;
/*!40000 ALTER TABLE `biz_request_task` DISABLE KEYS */;
/*!40000 ALTER TABLE `biz_request_task` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `form_definition`
--

DROP TABLE IF EXISTS `form_definition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `form_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `form_name` varchar(128) NOT NULL,
  `form_key` varchar(64) NOT NULL,
  `status` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_form_definition_form_key` (`form_key`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `form_definition`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `form_definition` WRITE;
/*!40000 ALTER TABLE `form_definition` DISABLE KEYS */;
INSERT INTO `form_definition` VALUES
(1,'请假申请表','leave_request',1),
(2,'报销申请表','expense_request',1),
(3,'出差申请表','travel_request',1),
(4,'采购申请表','purchase_request',1),
(5,'用章申请表','seal_request',1),
(6,'合同审批表','contract_request',1);
/*!40000 ALTER TABLE `form_definition` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `form_field`
--

DROP TABLE IF EXISTS `form_field`;
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
  PRIMARY KEY (`id`),
  KEY `idx_form_field_form_version_id` (`form_version_id`),
  KEY `idx_form_field_field_key` (`field_key`),
  CONSTRAINT `fk_form_field_form_version` FOREIGN KEY (`form_version_id`) REFERENCES `form_version` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=209 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `form_field`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `form_field` WRITE;
/*!40000 ALTER TABLE `form_field` DISABLE KEYS */;
INSERT INTO `form_field` VALUES
(183,1,'leaveType','select','请假类型',1,NULL,NULL,'[\"事假\",\"病假\",\"年假\"]'),
(184,1,'startDate','datetime','开始时间',1,NULL,NULL,NULL),
(185,1,'endDate','datetime','结束时间',1,NULL,NULL,NULL),
(186,1,'days','number','请假天数',1,NULL,NULL,NULL),
(187,1,'reason','string','请假原因',1,NULL,NULL,NULL),
(188,2,'expenseType','select','费用类型',1,NULL,NULL,'[\"差旅\",\"餐饮\",\"办公\"]'),
(189,2,'amount','number','报销金额',1,NULL,NULL,NULL),
(190,2,'occurredOn','date','发生日期',1,NULL,NULL,NULL),
(191,2,'reason','string','报销事由',1,NULL,NULL,NULL),
(192,3,'destination','string','出差地点',1,NULL,NULL,NULL),
(193,3,'startDate','datetime','出差开始时间',1,NULL,NULL,NULL),
(194,3,'endDate','datetime','出差结束时间',1,NULL,NULL,NULL),
(195,3,'budget','number','预计预算',0,NULL,NULL,NULL),
(196,3,'reason','string','出差事由',1,NULL,NULL,NULL),
(197,4,'itemName','string','采购物品',1,NULL,NULL,NULL),
(198,4,'quantity','number','数量',1,NULL,NULL,NULL),
(199,4,'amount','number','预算金额',1,NULL,NULL,NULL),
(200,4,'reason','string','采购原因',1,NULL,NULL,NULL),
(201,5,'sealType','select','用章类型',1,NULL,NULL,'[\"公章\",\"合同章\",\"财务章\"]'),
(202,5,'documentName','string','文件名称',1,NULL,NULL,NULL),
(203,5,'copies','number','份数',1,NULL,NULL,NULL),
(204,5,'reason','string','用章事由',1,NULL,NULL,NULL),
(205,6,'contractName','string','合同名称',1,NULL,NULL,NULL),
(206,6,'counterparty','string','合同对方',1,NULL,NULL,NULL),
(207,6,'amount','number','合同金额',1,NULL,NULL,NULL),
(208,6,'riskNote','string','风险说明',0,NULL,NULL,NULL);
/*!40000 ALTER TABLE `form_field` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `form_instance`
--

DROP TABLE IF EXISTS `form_instance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `form_instance` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `form_version_id` bigint(20) NOT NULL,
  `business_key` varchar(64) NOT NULL,
  `data_json` text NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_form_instance_business_key` (`business_key`),
  KEY `idx_form_instance_form_version_id` (`form_version_id`),
  CONSTRAINT `fk_form_instance_form_version` FOREIGN KEY (`form_version_id`) REFERENCES `form_version` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `form_instance`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `form_instance` WRITE;
/*!40000 ALTER TABLE `form_instance` DISABLE KEYS */;
/*!40000 ALTER TABLE `form_instance` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `form_version`
--

DROP TABLE IF EXISTS `form_version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `form_version` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `form_id` bigint(20) NOT NULL,
  `version` int(11) NOT NULL,
  `schema_json` text NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_form_version_form_id_version` (`form_id`,`version`),
  CONSTRAINT `fk_form_version_form` FOREIGN KEY (`form_id`) REFERENCES `form_definition` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `form_version`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `form_version` WRITE;
/*!40000 ALTER TABLE `form_version` DISABLE KEYS */;
INSERT INTO `form_version` VALUES
(1,1,1,'{\"fields\":[{\"key\":\"leaveType\",\"type\":\"select\",\"label\":\"请假类型\",\"required\":true,\"options\":[\"事假\",\"病假\",\"年假\"]},{\"key\":\"startDate\",\"type\":\"datetime\",\"label\":\"开始时间\",\"required\":true},{\"key\":\"endDate\",\"type\":\"datetime\",\"label\":\"结束时间\",\"required\":true},{\"key\":\"days\",\"type\":\"number\",\"label\":\"请假天数\",\"required\":true},{\"key\":\"reason\",\"type\":\"string\",\"label\":\"请假原因\",\"required\":true}]}'),
(2,2,1,'{\"fields\":[{\"key\":\"expenseType\",\"type\":\"select\",\"label\":\"费用类型\",\"required\":true,\"options\":[\"差旅\",\"餐饮\",\"办公\"]},{\"key\":\"amount\",\"type\":\"number\",\"label\":\"报销金额\",\"required\":true},{\"key\":\"occurredOn\",\"type\":\"date\",\"label\":\"发生日期\",\"required\":true},{\"key\":\"reason\",\"type\":\"string\",\"label\":\"报销事由\",\"required\":true}]}'),
(3,3,1,'{\"fields\":[{\"key\":\"destination\",\"type\":\"string\",\"label\":\"出差地点\",\"required\":true},{\"key\":\"startDate\",\"type\":\"datetime\",\"label\":\"出差开始时间\",\"required\":true},{\"key\":\"endDate\",\"type\":\"datetime\",\"label\":\"出差结束时间\",\"required\":true},{\"key\":\"budget\",\"type\":\"number\",\"label\":\"预计预算\",\"required\":false},{\"key\":\"reason\",\"type\":\"string\",\"label\":\"出差事由\",\"required\":true}]}'),
(4,4,1,'{\"fields\":[{\"key\":\"itemName\",\"type\":\"string\",\"label\":\"采购物品\",\"required\":true},{\"key\":\"quantity\",\"type\":\"number\",\"label\":\"数量\",\"required\":true},{\"key\":\"amount\",\"type\":\"number\",\"label\":\"预算金额\",\"required\":true},{\"key\":\"reason\",\"type\":\"string\",\"label\":\"采购原因\",\"required\":true}]}'),
(5,5,1,'{\"fields\":[{\"key\":\"sealType\",\"type\":\"select\",\"label\":\"用章类型\",\"required\":true,\"options\":[\"公章\",\"合同章\",\"财务章\"]},{\"key\":\"documentName\",\"type\":\"string\",\"label\":\"文件名称\",\"required\":true},{\"key\":\"copies\",\"type\":\"number\",\"label\":\"份数\",\"required\":true},{\"key\":\"reason\",\"type\":\"string\",\"label\":\"用章事由\",\"required\":true}]}'),
(6,6,1,'{\"fields\":[{\"key\":\"contractName\",\"type\":\"string\",\"label\":\"合同名称\",\"required\":true},{\"key\":\"counterparty\",\"type\":\"string\",\"label\":\"合同对方\",\"required\":true},{\"key\":\"amount\",\"type\":\"number\",\"label\":\"合同金额\",\"required\":true},{\"key\":\"riskNote\",\"type\":\"string\",\"label\":\"风险说明\",\"required\":false}]}');
/*!40000 ALTER TABLE `form_version` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `request_template`
--

DROP TABLE IF EXISTS `request_template`;
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
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKg2d40qpmcu1dni2i8ph89p0vl` (`template_key`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `request_template`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `request_template` WRITE;
/*!40000 ALTER TABLE `request_template` DISABLE KEYS */;
INSERT INTO `request_template` VALUES
(1,'行政人事','ALL','2026-04-07 17:42:02.414560',0,'用于员工提交事假、病假、年假等请假申请。','直属主管顺序审批，必要时追加部门负责人审批','leave_request','请假申请表','1.0','approvalSequential',10,'ACTIVE','leave','请假申请','2026-04-07 20:11:15.026272',0,0,'{\"rules\":[{\"name\":\"1天及以下\",\"conditions\":null,\"steps\":[{\"type\":\"MANAGER\",\"userId\":null},{\"type\":\"DEPT_LEADER\",\"userId\":null}]},{\"name\":\"超过1天\",\"conditions\":[{\"field\":\"days\",\"operator\":\"GT\",\"value\":1.0}],\"steps\":[{\"type\":\"DEPT_LEADER\",\"userId\":null}]},{\"name\":\"超过3天\",\"conditions\":[{\"field\":\"days\",\"operator\":\"GT\",\"value\":3.0}],\"steps\":[{\"type\":\"PARENT_DEPT_LEADER\",\"userId\":null}]}]}'),
(2,'财务','ALL','2026-04-07 17:42:02.439981',0,'用于日常费用报销、差旅报销和票据提交。','直属主管和财务顺序审批，大额报销可追加更高级别审批','expense_request','报销申请表','1.0','approvalSequential',20,'ACTIVE','expense','报销申请','2026-04-07 20:11:15.036311',0,0,'{\"rules\":[{\"name\":\"基础审批\",\"conditions\":null,\"steps\":[{\"type\":\"MANAGER\",\"userId\":null},{\"type\":\"DEPT_LEADER\",\"userId\":null}]},{\"name\":\"金额超过5000\",\"conditions\":[{\"field\":\"amount\",\"operator\":\"GT\",\"value\":5000.0}],\"steps\":[{\"type\":\"PARENT_DEPT_LEADER\",\"userId\":null}]}]}'),
(3,'行政人事','ALL','2026-04-07 17:42:02.444190',0,'用于出差行程、预算与出差事由审批。','直属主管审批，必要时增加部门负责人和财务审批','travel_request','出差申请表','1.0','approvalSequential',30,'ACTIVE','travel','出差申请','2026-04-07 20:11:15.039576',0,0,'{\"rules\":[{\"name\":\"基础审批\",\"conditions\":null,\"steps\":[{\"type\":\"MANAGER\",\"userId\":null},{\"type\":\"DEPT_LEADER\",\"userId\":null}]},{\"name\":\"预算超过3000\",\"conditions\":[{\"field\":\"budget\",\"operator\":\"GT\",\"value\":3000.0}],\"steps\":[{\"type\":\"PARENT_DEPT_LEADER\",\"userId\":null}]}]}'),
(4,'采购','MAJORITY','2026-04-07 17:42:02.448309',0,'用于办公物资、设备与业务采购审批。','采购相关审批人并行会签，超过预算阈值时追加高级审批','purchase_request','采购申请表','0.5','approvalCountersign',40,'ACTIVE','purchase','采购申请','2026-04-07 20:11:15.042697',0,0,'{\"rules\":[{\"name\":\"基础审批\",\"conditions\":null,\"steps\":[{\"type\":\"DEPT_LEADER\",\"userId\":null}]},{\"name\":\"金额超过10000\",\"conditions\":[{\"field\":\"amount\",\"operator\":\"GT\",\"value\":10000.0}],\"steps\":[{\"type\":\"PARENT_DEPT_LEADER\",\"userId\":null}]}]}'),
(5,'行政','ALL','2026-04-07 17:42:02.451853',0,'用于文件盖章、资料用印和外发材料审批。','由印章管理员或指定负责人单人审批','seal_request','用章申请表','1.0','approvalSingle',50,'ACTIVE','seal','用章申请','2026-04-07 17:42:02.451853',0,0,NULL),
(6,'法务','ALL','2026-04-07 17:42:02.454668',0,'用于合同评审、法务审查和金额审批。','法务、业务和财务协同会签，重大合同再提交高层审批','contract_request','合同审批表','1.0','approvalCountersign',60,'ACTIVE','contract','合同审批','2026-04-07 20:11:15.046683',0,0,'{\"rules\":[{\"name\":\"基础审批\",\"conditions\":null,\"steps\":[{\"type\":\"DEPT_LEADER\",\"userId\":null}]}]}');
/*!40000 ALTER TABLE `request_template` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `sys_dept`
--

DROP TABLE IF EXISTS `sys_dept`;
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

--
-- Dumping data for table `sys_dept`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_dept` WRITE;
/*!40000 ALTER TABLE `sys_dept` DISABLE KEYS */;
INSERT INTO `sys_dept` VALUES
(1,5,'DEV_DEPT','研发部',NULL),
(2,7,'HR_DEPT','人力资源部',NULL),
(3,7,'FINANCE_DEPT','财务部',NULL),
(4,NULL,'COMPANY_HQ','公司总部',NULL),
(5,4,'PRD_CENTER','产品与研发中心',NULL),
(6,4,'GTM_CENTER','市场与增长中心',NULL),
(7,4,'CORP_CENTER','职能支持中心',NULL),
(8,5,'PRODUCT_DEPT','产品部',NULL),
(9,5,'QA_DEPT','测试质量部',NULL),
(10,5,'SRE_DEPT','运维与SRE部',NULL),
(11,5,'DATA_AI_DEPT','数据与算法部',NULL),
(12,6,'MARKETING_DEPT','市场品牌部',NULL),
(13,6,'SALES_DEPT','销售部',NULL),
(14,6,'CS_DEPT','客户成功部',NULL),
(15,7,'LEGAL_DEPT','法务合规部',NULL),
(16,7,'ADMIN_DEPT','行政采购部',NULL),
(17,7,'SECURITY_DEPT','信息安全部',NULL);
/*!40000 ALTER TABLE `sys_dept` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `sys_login_log`
--

DROP TABLE IF EXISTS `sys_login_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_login_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) DEFAULT NULL,
  `username` varchar(64) DEFAULT NULL,
  `login_status` int(11) NOT NULL,
  `message` varchar(512) DEFAULT NULL,
  `ip_address` varchar(64) DEFAULT NULL,
  `user_agent` varchar(512) DEFAULT NULL,
  `login_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sys_login_log_user_id_login_time` (`user_id`,`login_time`),
  KEY `idx_sys_login_log_username_login_time` (`username`,`login_time`),
  KEY `idx_sys_login_log_login_time` (`login_time`),
  CONSTRAINT `fk_sys_login_log_user` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=39 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_login_log`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_login_log` WRITE;
/*!40000 ALTER TABLE `sys_login_log` DISABLE KEYS */;
INSERT INTO `sys_login_log` VALUES
(1,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-03-31 22:56:17'),
(3,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-03-31 23:08:53'),
(5,NULL,'liu',1,'user not found','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-03-31 23:09:22'),
(6,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-03-31 23:09:30'),
(8,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-01 14:55:38'),
(9,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-01 17:08:43'),
(10,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-01 18:28:52'),
(12,NULL,'admin',1,'invalid password','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-01 18:29:14'),
(13,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-01 18:29:19'),
(14,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-02 15:33:18'),
(16,NULL,'admin',1,'invalid password','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-02 18:23:20'),
(17,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-02 18:23:24'),
(18,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-03 09:20:50'),
(22,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-03 09:30:09'),
(26,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-05 20:22:10'),
(27,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-07 17:42:19'),
(29,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-07 17:56:25'),
(33,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-07 19:22:08'),
(34,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-07 20:11:25'),
(36,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-07 20:43:43'),
(37,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-07 22:10:05'),
(38,1,'admin',0,'login successful','0:0:0:0:0:0:0:1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-04-08 09:43:19');
/*!40000 ALTER TABLE `sys_login_log` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `sys_post`
--

DROP TABLE IF EXISTS `sys_post`;
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

--
-- Dumping data for table `sys_post`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_post` WRITE;
/*!40000 ALTER TABLE `sys_post` DISABLE KEYS */;
INSERT INTO `sys_post` VALUES
(4,'CEO','首席执行官'),
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
/*!40000 ALTER TABLE `sys_post` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `sys_role`
--

DROP TABLE IF EXISTS `sys_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_role` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `role_code` varchar(64) NOT NULL,
  `role_name` varchar(64) NOT NULL,
  `status` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sys_role_role_code` (`role_code`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_role`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_role` WRITE;
/*!40000 ALTER TABLE `sys_role` DISABLE KEYS */;
INSERT INTO `sys_role` VALUES
(1,'ADMIN','系统管理员',1),
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
(23,'EMPLOYEE','普通员工',1);
/*!40000 ALTER TABLE `sys_role` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `sys_role_data_scope`
--

DROP TABLE IF EXISTS `sys_role_data_scope`;
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

--
-- Dumping data for table `sys_role_data_scope`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_role_data_scope` WRITE;
/*!40000 ALTER TABLE `sys_role_data_scope` DISABLE KEYS */;
/*!40000 ALTER TABLE `sys_role_data_scope` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `sys_user`
--

DROP TABLE IF EXISTS `sys_user`;
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

--
-- Dumping data for table `sys_user`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_user` WRITE;
/*!40000 ALTER TABLE `sys_user` DISABLE KEYS */;
INSERT INTO `sys_user` VALUES
(1,'admin','$2a$10$.ZsldZ8qP4d84i0JWAmq2.X..WFXvhJ7oBFNAQAUDt/ZFPFovXqqK',NULL,1,0,NULL,NULL,'2026-04-08 09:43:19',0,NULL,NULL),
(4,'accountant_1',NULL,3,1,0,NULL,NULL,NULL,0,NULL,14),
(5,'backend_dev_1',NULL,1,1,0,NULL,NULL,NULL,0,NULL,7),
(6,'backend_dev_2',NULL,1,1,0,NULL,NULL,NULL,0,NULL,7),
(7,'backend_lead',NULL,1,1,0,NULL,NULL,NULL,0,NULL,11),
(8,'ceo',NULL,4,1,0,NULL,NULL,NULL,0,NULL,NULL),
(9,'cs_manager_1',NULL,14,1,0,NULL,NULL,NULL,0,NULL,8),
(10,'cs_specialist_1',NULL,14,1,0,NULL,NULL,NULL,0,NULL,9),
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
/*!40000 ALTER TABLE `sys_user` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `sys_user_import_job`
--

DROP TABLE IF EXISTS `sys_user_import_job`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user_import_job` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `file_name` varchar(255) NOT NULL,
  `file_type` varchar(16) NOT NULL,
  `file_checksum` varchar(128) NOT NULL,
  `strategy` varchar(32) NOT NULL,
  `status` varchar(32) NOT NULL,
  `total_rows` int(11) NOT NULL DEFAULT 0,
  `success_rows` int(11) NOT NULL DEFAULT 0,
  `failed_rows` int(11) NOT NULL DEFAULT 0,
  `operator_id` bigint(20) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `finished_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sys_user_import_job_operator_id` (`operator_id`),
  KEY `idx_sys_user_import_job_status_created_at` (`status`,`created_at`),
  CONSTRAINT `fk_sys_user_import_job_operator` FOREIGN KEY (`operator_id`) REFERENCES `sys_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_user_import_job`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_user_import_job` WRITE;
/*!40000 ALTER TABLE `sys_user_import_job` DISABLE KEYS */;
/*!40000 ALTER TABLE `sys_user_import_job` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `sys_user_import_job_item`
--

DROP TABLE IF EXISTS `sys_user_import_job_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user_import_job_item` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `job_id` bigint(20) NOT NULL,
  `row_no` int(11) NOT NULL,
  `username` varchar(64) DEFAULT NULL,
  `raw_payload` tinytext DEFAULT NULL,
  `result` varchar(32) NOT NULL,
  `error_message` varchar(512) DEFAULT NULL,
  `created_user_id` bigint(20) DEFAULT NULL,
  `before_snapshot` tinytext DEFAULT NULL,
  `after_snapshot` tinytext DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sys_user_import_job_item_job_row` (`job_id`,`row_no`),
  KEY `idx_sys_user_import_job_item_result` (`result`),
  KEY `idx_sys_user_import_job_item_created_user_id` (`created_user_id`),
  CONSTRAINT `fk_sys_user_import_job_item_created_user` FOREIGN KEY (`created_user_id`) REFERENCES `sys_user` (`id`),
  CONSTRAINT `fk_sys_user_import_job_item_job` FOREIGN KEY (`job_id`) REFERENCES `sys_user_import_job` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_user_import_job_item`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_user_import_job_item` WRITE;
/*!40000 ALTER TABLE `sys_user_import_job_item` DISABLE KEYS */;
/*!40000 ALTER TABLE `sys_user_import_job_item` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `sys_user_post`
--

DROP TABLE IF EXISTS `sys_user_post`;
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

--
-- Dumping data for table `sys_user_post`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_user_post` WRITE;
/*!40000 ALTER TABLE `sys_user_post` DISABLE KEYS */;
INSERT INTO `sys_user_post` VALUES
(3,4,22),
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
/*!40000 ALTER TABLE `sys_user_post` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `sys_user_role`
--

DROP TABLE IF EXISTS `sys_user_role`;
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
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_user_role`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_user_role` WRITE;
/*!40000 ALTER TABLE `sys_user_role` DISABLE KEYS */;
INSERT INTO `sys_user_role` VALUES
(1,1,1),
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
(30,30,10);
/*!40000 ALTER TABLE `sys_user_role` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `workflow_definition`
--

DROP TABLE IF EXISTS `workflow_definition`;
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
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `workflow_definition`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `workflow_definition` WRITE;
/*!40000 ALTER TABLE `workflow_definition` DISABLE KEYS */;
INSERT INTO `workflow_definition` VALUES
(1,NULL,'2026-04-01 18:28:42.658584',0,1,'Auto imported from Flowable deployed BPMN resource',0,1,'approvalCountersign','Approval Countersign','ACTIVE','2026-04-01 18:28:42.738615',0),
(2,NULL,'2026-04-01 18:28:42.750153',0,2,'Auto imported from Flowable deployed BPMN resource',0,1,'approvalOrSign','Approval Or-Sign','ACTIVE','2026-04-01 18:28:42.772741',0),
(3,NULL,'2026-04-01 18:28:42.774556',0,3,'Auto imported from Flowable deployed BPMN resource',0,1,'approvalSequential','Approval Sequential','ACTIVE','2026-04-01 18:28:42.792982',0),
(4,NULL,'2026-04-01 18:28:42.795199',0,4,'Auto imported from Flowable deployed BPMN resource',0,1,'approvalSingle','Approval Single','ACTIVE','2026-04-01 18:28:42.815548',0),
(5,NULL,'2026-04-01 18:28:42.817163',0,5,'Auto imported from Flowable deployed BPMN resource',0,1,'approvalWorkflow','Approval Workflow','ACTIVE','2026-04-07 17:43:31.608272',1),
(6,'111','2026-04-02 18:23:46.896178',1,NULL,NULL,0,1,'test1','test11','DRAFT','2026-04-07 17:42:37.094649',1);
/*!40000 ALTER TABLE `workflow_definition` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `workflow_definition_version`
--

DROP TABLE IF EXISTS `workflow_definition_version`;
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
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `workflow_definition_version`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `workflow_definition_version` WRITE;
/*!40000 ALTER TABLE `workflow_definition_version` DISABLE KEYS */;
INSERT INTO `workflow_definition_version` VALUES
(1,'608f7357321c8c3ce377c353d456c41da9b16b08da705d8cbccf086a5bb13984','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalCountersign\" name=\"Approval Countersign\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"countersignTask\"/>\n\n    <userTask id=\"countersignTask\" name=\"Countersign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${countersignMode == \'ALL\' ? (rejectCount == 0 &amp;&amp; nrOfCompletedInstances == nrOfInstances)\n            : (approveCount >= requiredApprove || rejectCount > (nrOfInstances - requiredApprove))}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToCountersign\" sourceRef=\"applicantRework\" targetRef=\"countersignTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"countersignTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n','Auto imported from existing BPMN deployment','2026-04-01 18:28:42.687523',0,1,'61f5f985-2d11-11f1-b116-b62bdfc0de2a','approvalCountersign:1:620514bf-2d11-11f1-b116-b62bdfc0de2a',NULL,NULL,0,'2026-04-01 18:28:42.687106',0,'PUBLISHED','2026-04-01 18:28:42.687523',0,'imported-v1',1),
(2,'6cd316adbbc6971572f0b0bc9c40899a968496a934709217dd56f21e94a39c53','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalOrSign\" name=\"Approval Or-Sign\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"orSignTask\"/>\n\n    <userTask id=\"orSignTask\" name=\"Or-Sign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${approveCount >= 1 || rejectCount == nrOfInstances}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToOrSign\" sourceRef=\"applicantRework\" targetRef=\"orSignTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"orSignTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approveCount >= 1}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approveCount == 0}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n','Auto imported from existing BPMN deployment','2026-04-01 18:28:42.754619',0,2,'61f5f985-2d11-11f1-b116-b62bdfc0de2a','approvalOrSign:1:62049f8b-2d11-11f1-b116-b62bdfc0de2a',NULL,NULL,0,'2026-04-01 18:28:42.754436',0,'PUBLISHED','2026-04-01 18:28:42.754619',0,'imported-v1',1),
(3,'95cc78d8f112e4d3197643757023121d027fd28c4c076327023a8aeb43a60464','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalSequential\" name=\"Approval Sequential\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"sequentialTask\"/>\n\n    <userTask id=\"sequentialTask\" name=\"Sequential Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"true\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${rejectCount > 0 || (nrOfCompletedInstances == nrOfInstances)}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToSequential\" sourceRef=\"applicantRework\" targetRef=\"sequentialTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"sequentialTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${rejectCount == 0}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${rejectCount > 0}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n','Auto imported from existing BPMN deployment','2026-04-01 18:28:42.779334',0,3,'61f5f985-2d11-11f1-b116-b62bdfc0de2a','approvalSequential:1:620514bc-2d11-11f1-b116-b62bdfc0de2a',NULL,NULL,0,'2026-04-01 18:28:42.779191',0,'PUBLISHED','2026-04-01 18:28:42.779334',0,'imported-v1',1),
(4,'7f245843323a16d03f59a6b02fc4061abbcc936e5745b5a656c0ca513bdc7f51','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalSingle\" name=\"Approval Single\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"singleApprovalTask\"/>\n\n    <userTask id=\"singleApprovalTask\" name=\"Single Approval Task\" flowable:assignee=\"${approverId}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${singleApprovalTaskListener}\"/>\n      </extensionElements>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToApproval\" sourceRef=\"applicantRework\" targetRef=\"singleApprovalTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"singleApprovalTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approvalResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approvalResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n','Auto imported from existing BPMN deployment','2026-04-01 18:28:42.801006',0,4,'61f5f985-2d11-11f1-b116-b62bdfc0de2a','approvalSingle:1:620514be-2d11-11f1-b116-b62bdfc0de2a',NULL,NULL,0,'2026-04-01 18:28:42.800773',0,'PUBLISHED','2026-04-01 18:28:42.801006',0,'imported-v1',1),
(5,'4f94219a42cdebada22c6bb0cd0e743941d679b7932cf84e2b254da54f8c4b16','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalWorkflow\" name=\"Approval Workflow\" isExecutable=\"true\">\n\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"countersignTask\"/>\n\n    <userTask id=\"countersignTask\" name=\"Countersign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${countersignMode == \'ALL\' ? (rejectCount == 0 &amp;&amp; nrOfCompletedInstances == nrOfInstances)\n            : (approveCount >= requiredApprove || rejectCount > (nrOfInstances - requiredApprove))}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"countersignTask\" targetRef=\"decision\"/>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToCountersign\" sourceRef=\"applicantRework\" targetRef=\"countersignTask\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n\n  </process>\n</definitions>\n','Auto imported from existing BPMN deployment','2026-04-01 18:28:42.820239',0,5,'61f5f985-2d11-11f1-b116-b62bdfc0de2a','approvalWorkflow:1:620514bd-2d11-11f1-b116-b62bdfc0de2a',NULL,NULL,0,'2026-04-01 18:28:42.820121',0,'PUBLISHED','2026-04-01 18:28:42.820239',0,'imported-v1',1),
(6,NULL,'',NULL,'2026-04-07 17:42:37.092447',1,6,NULL,NULL,NULL,NULL,0,NULL,NULL,'DRAFT','2026-04-07 17:42:37.092447',1,'1',1);
/*!40000 ALTER TABLE `workflow_definition_version` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `workflow_node_config`
--

DROP TABLE IF EXISTS `workflow_node_config`;
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
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `workflow_node_config`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `workflow_node_config` WRITE;
/*!40000 ALTER TABLE `workflow_node_config` DISABLE KEYS */;
INSERT INTO `workflow_node_config` VALUES
(1,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.724304',1,NULL,'start','Start','START',0,NULL,'2026-04-01 18:28:42.724304'),
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
(30,0,1,1,1,1,NULL,NULL,NULL,1,'2026-04-01 18:28:42.826889',5,NULL,'rejectEnd','Rejected','END',5,NULL,'2026-04-01 18:28:42.826889');
/*!40000 ALTER TABLE `workflow_node_config` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `workflow_publish_log`
--

DROP TABLE IF EXISTS `workflow_publish_log`;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `workflow_publish_log`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `workflow_publish_log` WRITE;
/*!40000 ALTER TABLE `workflow_publish_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `workflow_publish_log` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2026-04-08 14:40:34
