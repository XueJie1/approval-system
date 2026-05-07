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
('6a65e147-25eb-11f1-8a85-d2e071155163',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-orsign.bpmn20.xml','6a65e146-25eb-11f1-8a85-d2e071155163','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalOrSign\" name=\"Approval Or-Sign\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"orSignTask\"/>\n\n    <userTask id=\"orSignTask\" name=\"Or-Sign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${approveCount >= 1 || rejectCount == nrOfInstances}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToOrSign\" sourceRef=\"applicantRework\" targetRef=\"orSignTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"orSignTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approveCount >= 1}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approveCount == 0}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('6a65e148-25eb-11f1-8a85-d2e071155163',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-sequential.bpmn20.xml','6a65e146-25eb-11f1-8a85-d2e071155163','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalSequential\" name=\"Approval Sequential\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"sequentialTask\"/>\n\n    <userTask id=\"sequentialTask\" name=\"Sequential Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"true\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${rejectCount > 0 || (nrOfCompletedInstances == nrOfInstances)}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToSequential\" sourceRef=\"applicantRework\" targetRef=\"sequentialTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"sequentialTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${rejectCount == 0}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${rejectCount > 0}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('6a65e149-25eb-11f1-8a85-d2e071155163',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-workflow.bpmn20.xml','6a65e146-25eb-11f1-8a85-d2e071155163','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalWorkflow\" name=\"Approval Workflow\" isExecutable=\"true\">\n\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"countersignTask\"/>\n\n    <userTask id=\"countersignTask\" name=\"Countersign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${countersignMode == \'ALL\' ? (rejectCount == 0 &amp;&amp; nrOfCompletedInstances == nrOfInstances)\n            : (approveCount >= requiredApprove || rejectCount > (nrOfInstances - requiredApprove))}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"countersignTask\" targetRef=\"decision\"/>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToCountersign\" sourceRef=\"applicantRework\" targetRef=\"countersignTask\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n\n  </process>\n</definitions>\n',0),
('6a65e14a-25eb-11f1-8a85-d2e071155163',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-single.bpmn20.xml','6a65e146-25eb-11f1-8a85-d2e071155163','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalSingle\" name=\"Approval Single\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"singleApprovalTask\"/>\n\n    <userTask id=\"singleApprovalTask\" name=\"Single Approval Task\" flowable:assignee=\"${approverId}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${singleApprovalTaskListener}\"/>\n      </extensionElements>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToApproval\" sourceRef=\"applicantRework\" targetRef=\"singleApprovalTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"singleApprovalTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approvalResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approvalResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('6a65e14b-25eb-11f1-8a85-d2e071155163',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-countersign.bpmn20.xml','6a65e146-25eb-11f1-8a85-d2e071155163','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalCountersign\" name=\"Approval Countersign\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"countersignTask\"/>\n\n    <userTask id=\"countersignTask\" name=\"Countersign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${countersignMode == \'ALL\' ? (rejectCount == 0 &amp;&amp; nrOfCompletedInstances == nrOfInstances)\n            : (approveCount >= requiredApprove || rejectCount > (nrOfInstances - requiredApprove))}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToCountersign\" sourceRef=\"applicantRework\" targetRef=\"countersignTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"countersignTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0);
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
('6a65e146-25eb-11f1-8a85-d2e071155163','SpringBootAutoDeployment',NULL,NULL,'','2026-03-22 12:34:05.779',NULL,NULL,'6a65e146-25eb-11f1-8a85-d2e071155163',NULL);
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
('approvalCountersign:1:6a723d60-25eb-11f1-8a85-d2e071155163',1,'http://flowable.org/examples','Approval Countersign','approvalCountersign',1,'6a65e146-25eb-11f1-8a85-d2e071155163','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-countersign.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalOrSign:1:6a71ef3c-25eb-11f1-8a85-d2e071155163',1,'http://flowable.org/examples','Approval Or-Sign','approvalOrSign',1,'6a65e146-25eb-11f1-8a85-d2e071155163','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-orsign.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalSequential:1:6a723d5d-25eb-11f1-8a85-d2e071155163',1,'http://flowable.org/examples','Approval Sequential','approvalSequential',1,'6a65e146-25eb-11f1-8a85-d2e071155163','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-sequential.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalSingle:1:6a723d5f-25eb-11f1-8a85-d2e071155163',1,'http://flowable.org/examples','Approval Single','approvalSingle',1,'6a65e146-25eb-11f1-8a85-d2e071155163','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-single.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalWorkflow:1:6a723d5e-25eb-11f1-8a85-d2e071155163',1,'http://flowable.org/examples','Approval Workflow','approvalWorkflow',1,'6a65e146-25eb-11f1-8a85-d2e071155163','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-workflow.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0);
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
('1','flowable','org/flowable/eventregistry/db/liquibase/flowable-eventregistry-db-changelog.xml','2026-03-22 20:34:00',1,'EXECUTED','9:63268f536c469325acef35970312551b','createTable tableName=FLW_EVENT_DEPLOYMENT; createTable tableName=FLW_EVENT_RESOURCE; createTable tableName=FLW_EVENT_DEFINITION; createIndex indexName=ACT_IDX_EVENT_DEF_UNIQ, tableName=FLW_EVENT_DEFINITION; createTable tableName=FLW_CHANNEL_DEFIN...','',NULL,'4.31.1',NULL,NULL,'4182840472'),
('2','flowable','org/flowable/eventregistry/db/liquibase/flowable-eventregistry-db-changelog.xml','2026-03-22 20:34:00',2,'EXECUTED','9:dcb58b7dfd6dbda66939123a96985536','addColumn tableName=FLW_CHANNEL_DEFINITION; addColumn tableName=FLW_CHANNEL_DEFINITION','',NULL,'4.31.1',NULL,NULL,'4182840472'),
('3','flowable','org/flowable/eventregistry/db/liquibase/flowable-eventregistry-db-changelog.xml','2026-03-22 20:34:00',3,'EXECUTED','9:d0c05678d57af23ad93699991e3bf4f6','customChange','',NULL,'4.31.1',NULL,NULL,'4182840472');
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `form_definition`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `form_definition` WRITE;
/*!40000 ALTER TABLE `form_definition` DISABLE KEYS */;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `form_field`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `form_field` WRITE;
/*!40000 ALTER TABLE `form_field` DISABLE KEYS */;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `form_version`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `form_version` WRITE;
/*!40000 ALTER TABLE `form_version` DISABLE KEYS */;
/*!40000 ALTER TABLE `form_version` ENABLE KEYS */;
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
  `dept_name` varchar(64) NOT NULL,
  `dept_code` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK3dih4mhk3ocgsi0sdxf9fb0xn` (`dept_code`),
  KEY `idx_sys_dept_parent_id` (`parent_id`),
  CONSTRAINT `fk_sys_dept_parent` FOREIGN KEY (`parent_id`) REFERENCES `sys_dept` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_dept`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_dept` WRITE;
/*!40000 ALTER TABLE `sys_dept` DISABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_login_log`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_login_log` WRITE;
/*!40000 ALTER TABLE `sys_login_log` DISABLE KEYS */;
INSERT INTO `sys_login_log` VALUES
(1,1,'admin',0,'login successful','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-03-22 20:41:43'),
(2,1,'admin',0,'login successful','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-03-22 20:47:19'),
(3,NULL,'admin',1,'invalid password','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-03-22 20:47:33'),
(4,1,'admin',0,'login successful','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','2026-03-22 20:47:36'),
(5,NULL,'admin',1,'invalid password','127.0.0.1','curl/8.19.0','2026-03-29 19:12:36'),
(6,NULL,'admin',1,'invalid password','127.0.0.1','curl/8.19.0','2026-03-29 22:07:51'),
(7,NULL,'admin',1,'invalid password','127.0.0.1','curl/8.19.0','2026-03-29 22:08:06');
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_post`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_post` WRITE;
/*!40000 ALTER TABLE `sys_post` DISABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_role`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_role` WRITE;
/*!40000 ALTER TABLE `sys_role` DISABLE KEYS */;
INSERT INTO `sys_role` VALUES
(1,'ADMIN','System Administrator',1);
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
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sys_user_username` (`username`),
  KEY `idx_sys_user_dept_id` (`dept_id`),
  CONSTRAINT `fk_sys_user_dept` FOREIGN KEY (`dept_id`) REFERENCES `sys_dept` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_user`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_user` WRITE;
/*!40000 ALTER TABLE `sys_user` DISABLE KEYS */;
INSERT INTO `sys_user` VALUES
(1,'admin','a0.vN4v6L6e1F9cTLO.HqJLhVXN4rBqKxG5JZzVhBQvBQvBQv',NULL,1,0,NULL,NULL,'2026-03-22 20:47:36',3,NULL);
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
  `created_at` datetime(6) NOT NULL,
  `failed_rows` int(11) NOT NULL,
  `file_checksum` varchar(128) NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `file_type` varchar(16) NOT NULL,
  `finished_at` datetime(6) DEFAULT NULL,
  `operator_id` bigint(20) NOT NULL,
  `status` varchar(32) NOT NULL,
  `strategy` varchar(32) NOT NULL,
  `success_rows` int(11) NOT NULL,
  `total_rows` int(11) NOT NULL,
  PRIMARY KEY (`id`)
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
  `after_snapshot` tinytext DEFAULT NULL,
  `before_snapshot` tinytext DEFAULT NULL,
  `created_user_id` bigint(20) DEFAULT NULL,
  `error_message` varchar(512) DEFAULT NULL,
  `job_id` bigint(20) NOT NULL,
  `raw_payload` tinytext DEFAULT NULL,
  `result` varchar(32) NOT NULL,
  `row_no` int(11) NOT NULL,
  `username` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`)
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_user_post`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_user_post` WRITE;
/*!40000 ALTER TABLE `sys_user_post` DISABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_user_role`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_user_role` WRITE;
/*!40000 ALTER TABLE `sys_user_role` DISABLE KEYS */;
INSERT INTO `sys_user_role` VALUES
(1,1,1);
/*!40000 ALTER TABLE `sys_user_role` ENABLE KEYS */;
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

-- Dump completed on 2026-03-31 22:50:03
