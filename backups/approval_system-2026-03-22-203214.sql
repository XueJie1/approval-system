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
('3c5fde84-2142-11f1-9715-9ace7c5eee11',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-orsign.bpmn20.xml','3c5fde83-2142-11f1-9715-9ace7c5eee11','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalOrSign\" name=\"Approval Or-Sign\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"orSignTask\"/>\n\n    <userTask id=\"orSignTask\" name=\"Or-Sign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${approveCount >= 1 || rejectCount == nrOfInstances}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToOrSign\" sourceRef=\"applicantRework\" targetRef=\"orSignTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"orSignTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approveCount >= 1}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approveCount == 0}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('3c5fde85-2142-11f1-9715-9ace7c5eee11',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-sequential.bpmn20.xml','3c5fde83-2142-11f1-9715-9ace7c5eee11','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalSequential\" name=\"Approval Sequential\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"sequentialTask\"/>\n\n    <userTask id=\"sequentialTask\" name=\"Sequential Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"true\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${rejectCount > 0 || (nrOfCompletedInstances == nrOfInstances)}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToSequential\" sourceRef=\"applicantRework\" targetRef=\"sequentialTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"sequentialTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${rejectCount == 0}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${rejectCount > 0}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('3c5fde86-2142-11f1-9715-9ace7c5eee11',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-workflow.bpmn20.xml','3c5fde83-2142-11f1-9715-9ace7c5eee11','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalWorkflow\" name=\"Approval Workflow\" isExecutable=\"true\">\n\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"countersignTask\"/>\n\n    <userTask id=\"countersignTask\" name=\"Countersign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${countersignMode == \'ALL\' ? (rejectCount == 0 &amp;&amp; nrOfCompletedInstances == nrOfInstances)\n            : (approveCount >= requiredApprove || rejectCount > (nrOfInstances - requiredApprove))}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"countersignTask\" targetRef=\"decision\"/>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToCountersign\" sourceRef=\"applicantRework\" targetRef=\"countersignTask\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n\n  </process>\n</definitions>\n',0),
('3c5fde87-2142-11f1-9715-9ace7c5eee11',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-single.bpmn20.xml','3c5fde83-2142-11f1-9715-9ace7c5eee11','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalSingle\" name=\"Approval Single\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"singleApprovalTask\"/>\n\n    <userTask id=\"singleApprovalTask\" name=\"Single Approval Task\" flowable:assignee=\"${approverId}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToApproval\" sourceRef=\"applicantRework\" targetRef=\"singleApprovalTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"singleApprovalTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approvalResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approvalResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('3c5fde88-2142-11f1-9715-9ace7c5eee11',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-countersign.bpmn20.xml','3c5fde83-2142-11f1-9715-9ace7c5eee11','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalCountersign\" name=\"Approval Countersign\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"countersignTask\"/>\n\n    <userTask id=\"countersignTask\" name=\"Countersign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${countersignMode == \'ALL\' ? (rejectCount == 0 &amp;&amp; nrOfCompletedInstances == nrOfInstances)\n            : (approveCount >= requiredApprove || rejectCount > (nrOfInstances - requiredApprove))}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToCountersign\" sourceRef=\"applicantRework\" targetRef=\"countersignTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"countersignTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('44392426-1066-11f1-a1f8-22842007978f',1,'hist.var-countersignUsers',NULL,'¨Ì\0sr\0java.util.ArrayListxÅ“ô«aù\0I\0sizexp\0\0\0w\0\0\0t\02x',NULL),
('4dfcbe03-2147-11f1-8664-9ace7c5eee11',1,'hist.var-countersignUsers',NULL,'¨Ì\0sr\0java.util.CollSerWé´∂:®\0I\0tagxp\0\0\0w\0\0\0t\04x',NULL),
('53eeea55-2151-11f1-9281-9ace7c5eee11',1,'var-countersignUsers',NULL,'¨Ì\0sr\0java.util.CollSerWé´∂:®\0I\0tagxp\0\0\0w\0\0\0t\05x',NULL),
('53eeea57-2151-11f1-9281-9ace7c5eee11',1,'hist.var-countersignUsers',NULL,'¨Ì\0sr\0java.util.CollSerWé´∂:®\0I\0tagxp\0\0\0w\0\0\0t\05x',NULL),
('929d5937-1066-11f1-a1f8-22842007978f',1,'hist.var-countersignUsers',NULL,'¨Ì\0sr\0java.util.ArrayListxÅ“ô«aù\0I\0sizexp\0\0\0w\0\0\0t\02x',NULL),
('97844a52-2147-11f1-8664-9ace7c5eee11',1,'var-countersignUsers',NULL,'¨Ì\0sr\0java.util.CollSerWé´∂:®\0I\0tagxp\0\0\0w\0\0\0t\05x',NULL),
('97844a54-2147-11f1-8664-9ace7c5eee11',1,'hist.var-countersignUsers',NULL,'¨Ì\0sr\0java.util.CollSerWé´∂:®\0I\0tagxp\0\0\0w\0\0\0t\05x',NULL),
('b7d01cec-2147-11f1-8664-9ace7c5eee11',1,'hist.var-countersignUsers',NULL,'¨Ì\0sr\0java.util.CollSerWé´∂:®\0I\0tagxp\0\0\0w\0\0\0t\05x',NULL),
('b9b5e934-2146-11f1-82c2-9ace7c5eee11',1,'var-countersignUsers',NULL,'¨Ì\0sr\0java.util.CollSerWé´∂:®\0I\0tagxp\0\0\0w\0\0\0t\04x',NULL),
('b9b5e936-2146-11f1-82c2-9ace7c5eee11',1,'hist.var-countersignUsers',NULL,'¨Ì\0sr\0java.util.CollSerWé´∂:®\0I\0tagxp\0\0\0w\0\0\0t\04x',NULL),
('c2de2696-21d7-11f1-8dda-a22975756b37',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-orsign.bpmn20.xml','c2de2695-21d7-11f1-8dda-a22975756b37','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalOrSign\" name=\"Approval Or-Sign\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"orSignTask\"/>\n\n    <userTask id=\"orSignTask\" name=\"Or-Sign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${approveCount >= 1 || rejectCount == nrOfInstances}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToOrSign\" sourceRef=\"applicantRework\" targetRef=\"orSignTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"orSignTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approveCount >= 1}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approveCount == 0}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('c2de4da7-21d7-11f1-8dda-a22975756b37',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-sequential.bpmn20.xml','c2de2695-21d7-11f1-8dda-a22975756b37','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalSequential\" name=\"Approval Sequential\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"sequentialTask\"/>\n\n    <userTask id=\"sequentialTask\" name=\"Sequential Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"true\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${rejectCount > 0 || (nrOfCompletedInstances == nrOfInstances)}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToSequential\" sourceRef=\"applicantRework\" targetRef=\"sequentialTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"sequentialTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${rejectCount == 0}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${rejectCount > 0}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('c2de4da8-21d7-11f1-8dda-a22975756b37',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-workflow.bpmn20.xml','c2de2695-21d7-11f1-8dda-a22975756b37','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalWorkflow\" name=\"Approval Workflow\" isExecutable=\"true\">\n\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"countersignTask\"/>\n\n    <userTask id=\"countersignTask\" name=\"Countersign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${countersignMode == \'ALL\' ? (rejectCount == 0 &amp;&amp; nrOfCompletedInstances == nrOfInstances)\n            : (approveCount >= requiredApprove || rejectCount > (nrOfInstances - requiredApprove))}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"countersignTask\" targetRef=\"decision\"/>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToCountersign\" sourceRef=\"applicantRework\" targetRef=\"countersignTask\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n\n  </process>\n</definitions>\n',0),
('c2de4da9-21d7-11f1-8dda-a22975756b37',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-single.bpmn20.xml','c2de2695-21d7-11f1-8dda-a22975756b37','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalSingle\" name=\"Approval Single\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"singleApprovalTask\"/>\n\n    <userTask id=\"singleApprovalTask\" name=\"Single Approval Task\" flowable:assignee=\"${approverId}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${singleApprovalTaskListener}\"/>\n      </extensionElements>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToApproval\" sourceRef=\"applicantRework\" targetRef=\"singleApprovalTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"singleApprovalTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approvalResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approvalResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('c2de4daa-21d7-11f1-8dda-a22975756b37',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-countersign.bpmn20.xml','c2de2695-21d7-11f1-8dda-a22975756b37','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalCountersign\" name=\"Approval Countersign\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"countersignTask\"/>\n\n    <userTask id=\"countersignTask\" name=\"Countersign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${countersignMode == \'ALL\' ? (rejectCount == 0 &amp;&amp; nrOfCompletedInstances == nrOfInstances)\n            : (approveCount >= requiredApprove || rejectCount > (nrOfInstances - requiredApprove))}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToCountersign\" sourceRef=\"applicantRework\" targetRef=\"countersignTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"countersignTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('cab8d20d-1064-11f1-917d-22842007978f',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-orsign.bpmn20.xml','cab8d20c-1064-11f1-917d-22842007978f','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalOrSign\" name=\"Approval Or-Sign\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"orSignTask\"/>\n\n    <userTask id=\"orSignTask\" name=\"Or-Sign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${approveCount >= 1 || rejectCount == nrOfInstances}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToOrSign\" sourceRef=\"applicantRework\" targetRef=\"orSignTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"orSignTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approveCount >= 1}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${approveCount == 0}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('cab8f91e-1064-11f1-917d-22842007978f',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-sequential.bpmn20.xml','cab8d20c-1064-11f1-917d-22842007978f','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalSequential\" name=\"Approval Sequential\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"sequentialTask\"/>\n\n    <userTask id=\"sequentialTask\" name=\"Sequential Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"true\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${rejectCount > 0 || (nrOfCompletedInstances == nrOfInstances)}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToSequential\" sourceRef=\"applicantRework\" targetRef=\"sequentialTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"sequentialTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${rejectCount == 0}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${rejectCount > 0}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('cab8f91f-1064-11f1-917d-22842007978f',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-workflow.bpmn20.xml','cab8d20c-1064-11f1-917d-22842007978f','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalWorkflow\" name=\"Approval Workflow\" isExecutable=\"true\">\n\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"countersignTask\"/>\n\n    <userTask id=\"countersignTask\" name=\"Countersign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${countersignMode == \'ALL\' ? (rejectCount == 0 &amp;&amp; nrOfCompletedInstances == nrOfInstances)\n            : (approveCount >= requiredApprove || rejectCount > (nrOfInstances - requiredApprove))}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"countersignTask\" targetRef=\"decision\"/>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToCountersign\" sourceRef=\"applicantRework\" targetRef=\"countersignTask\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n\n  </process>\n</definitions>\n',0),
('cab8f920-1064-11f1-917d-22842007978f',1,'/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-countersign.bpmn20.xml','cab8d20c-1064-11f1-917d-22842007978f','<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\"\n             xmlns:flowable=\"http://flowable.org/bpmn\"\n             xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n             targetNamespace=\"http://flowable.org/examples\">\n\n  <process id=\"approvalCountersign\" name=\"Approval Countersign\" isExecutable=\"true\">\n    <startEvent id=\"start\" name=\"Start\"/>\n    <sequenceFlow id=\"flow1\" sourceRef=\"start\" targetRef=\"countersignTask\"/>\n\n    <userTask id=\"countersignTask\" name=\"Countersign Task\" flowable:assignee=\"${countersignUser}\">\n      <extensionElements>\n        <flowable:taskListener event=\"complete\" delegateExpression=\"${countersignTaskListener}\"/>\n      </extensionElements>\n      <multiInstanceLoopCharacteristics isSequential=\"false\"\n                                        flowable:collection=\"countersignUsers\"\n                                        flowable:elementVariable=\"countersignUser\">\n        <completionCondition>\n          ${countersignMode == \'ALL\' ? (rejectCount == 0 &amp;&amp; nrOfCompletedInstances == nrOfInstances)\n            : (approveCount >= requiredApprove || rejectCount > (nrOfInstances - requiredApprove))}\n        </completionCondition>\n      </multiInstanceLoopCharacteristics>\n    </userTask>\n\n    <userTask id=\"applicantRework\" name=\"Applicant Rework\" flowable:assignee=\"${applicantId}\"/>\n    <sequenceFlow id=\"flowReworkToCountersign\" sourceRef=\"applicantRework\" targetRef=\"countersignTask\"/>\n\n    <sequenceFlow id=\"flow2\" sourceRef=\"countersignTask\" targetRef=\"decision\"/>\n\n    <exclusiveGateway id=\"decision\" name=\"Decision\"/>\n    <sequenceFlow id=\"flow3\" sourceRef=\"decision\" targetRef=\"approveEnd\" name=\"Approve\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'APPROVE\'}</conditionExpression>\n    </sequenceFlow>\n    <sequenceFlow id=\"flow4\" sourceRef=\"decision\" targetRef=\"rejectEnd\" name=\"Reject\">\n      <conditionExpression xsi:type=\"tFormalExpression\">${countersignResult == \'REJECT\'}</conditionExpression>\n    </sequenceFlow>\n\n    <endEvent id=\"approveEnd\" name=\"Approved\"/>\n    <endEvent id=\"rejectEnd\" name=\"Rejected\"/>\n  </process>\n</definitions>\n',0),
('de0c5498-1064-11f1-917d-22842007978f',1,'var-countersignUsers',NULL,'¨Ì\0sr\0java.util.ArrayListxÅ“ô«aù\0I\0sizexp\0\0\0w\0\0\0t\01x',NULL),
('de0c549a-1064-11f1-917d-22842007978f',1,'hist.var-countersignUsers',NULL,'¨Ì\0sr\0java.util.ArrayListxÅ“ô«aù\0I\0sizexp\0\0\0w\0\0\0t\01x',NULL),
('f1f1061c-2149-11f1-9281-9ace7c5eee11',1,'var-countersignUsers',NULL,'¨Ì\0sr\0java.util.CollSerWé´∂:®\0I\0tagxp\0\0\0w\0\0\0t\05x',NULL),
('f1f12d2e-2149-11f1-9281-9ace7c5eee11',1,'hist.var-countersignUsers',NULL,'¨Ì\0sr\0java.util.CollSerWé´∂:®\0I\0tagxp\0\0\0w\0\0\0t\05x',NULL),
('f20ca48e-2149-11f1-9281-9ace7c5eee11',1,'var-countersignUsers',NULL,'¨Ì\0sr\0java.util.CollSerWé´∂:®\0I\0tagxp\0\0\0w\0\0\0t\05x',NULL),
('f20ca490-2149-11f1-9281-9ace7c5eee11',1,'hist.var-countersignUsers',NULL,'¨Ì\0sr\0java.util.CollSerWé´∂:®\0I\0tagxp\0\0\0w\0\0\0t\05x',NULL);
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
('4439242e-1066-11f1-a1f8-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','443812b1-1066-11f1-a1f8-22842007978f','4439242d-1066-11f1-a1f8-22842007978f','start',NULL,NULL,'Start','startEvent',NULL,'2026-02-23 11:18:04.250','2026-02-23 11:18:04.252',1,2,NULL,''),
('4439724f-1066-11f1-a1f8-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','443812b1-1066-11f1-a1f8-22842007978f','4439242d-1066-11f1-a1f8-22842007978f','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-02-23 11:18:04.252','2026-02-23 11:18:04.252',2,0,NULL,''),
('443a0e97-1066-11f1-a1f8-22842007978f',2,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','443812b1-1066-11f1-a1f8-22842007978f','4439e784-1066-11f1-a1f8-22842007978f','countersignTask','443a35a8-1066-11f1-a1f8-22842007978f',NULL,'Countersign Task','userTask','2','2026-02-23 11:18:04.256','2026-02-23 11:18:04.396',3,140,NULL,''),
('4450caee-1066-11f1-a1f8-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','443812b1-1066-11f1-a1f8-22842007978f','4450caed-1066-11f1-a1f8-22842007978f','flow2',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-02-23 11:18:04.405','2026-02-23 11:18:04.405',1,0,NULL,''),
('4450caef-1066-11f1-a1f8-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','443812b1-1066-11f1-a1f8-22842007978f','4450caed-1066-11f1-a1f8-22842007978f','decision',NULL,NULL,'Decision','exclusiveGateway',NULL,'2026-02-23 11:18:04.405','2026-02-23 11:18:04.405',2,0,NULL,''),
('4450caf0-1066-11f1-a1f8-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','443812b1-1066-11f1-a1f8-22842007978f','4450caed-1066-11f1-a1f8-22842007978f','flow3',NULL,NULL,'Approve','sequenceFlow',NULL,'2026-02-23 11:18:04.405','2026-02-23 11:18:04.405',3,0,NULL,''),
('4450caf1-1066-11f1-a1f8-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','443812b1-1066-11f1-a1f8-22842007978f','4450caed-1066-11f1-a1f8-22842007978f','approveEnd',NULL,NULL,'Approved','endEvent',NULL,'2026-02-23 11:18:04.405','2026-02-23 11:18:04.406',4,1,NULL,''),
('4dfcbe0b-2147-11f1-8664-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfcbe0a-2147-11f1-8664-9ace7c5eee11','start',NULL,NULL,'Start','startEvent',NULL,'2026-03-16 22:49:16.000','2026-03-16 22:49:16.002',1,2,NULL,''),
('4dfd333c-2147-11f1-8664-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfcbe0a-2147-11f1-8664-9ace7c5eee11','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-03-16 22:49:16.003','2026-03-16 22:49:16.003',2,0,NULL,''),
('4dfd333d-2147-11f1-8664-9ace7c5eee11',2,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfcbe0a-2147-11f1-8664-9ace7c5eee11','singleApprovalTask','4dfdcf7e-2147-11f1-8664-9ace7c5eee11',NULL,'Single Approval Task','userTask','manager','2026-03-16 22:49:16.003','2026-03-16 23:05:36.094',3,980091,NULL,''),
('53eeea5f-2151-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11','53eeea5e-2151-11f1-9281-9ace7c5eee11','start',NULL,NULL,'Start','startEvent',NULL,'2026-03-17 00:01:00.943','2026-03-17 00:01:00.943',1,0,NULL,''),
('53eeea60-2151-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11','53eeea5e-2151-11f1-9281-9ace7c5eee11','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-03-17 00:01:00.943','2026-03-17 00:01:00.943',2,0,NULL,''),
('53eeea61-2151-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11','53eeea5e-2151-11f1-9281-9ace7c5eee11','singleApprovalTask','53eeea62-2151-11f1-9281-9ace7c5eee11',NULL,'Single Approval Task','userTask','manager','2026-03-17 00:01:00.943',NULL,3,NULL,NULL,''),
('929d804f-1066-11f1-a1f8-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','929d5932-1066-11f1-a1f8-22842007978f','929d804e-1066-11f1-a1f8-22842007978f','start',NULL,NULL,'Start','startEvent',NULL,'2026-02-23 11:20:15.770','2026-02-23 11:20:15.770',1,0,NULL,''),
('929d8050-1066-11f1-a1f8-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','929d5932-1066-11f1-a1f8-22842007978f','929d804e-1066-11f1-a1f8-22842007978f','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-02-23 11:20:15.770','2026-02-23 11:20:15.770',2,0,NULL,''),
('929da768-1066-11f1-a1f8-22842007978f',2,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','929d5932-1066-11f1-a1f8-22842007978f','929da765-1066-11f1-a1f8-22842007978f','countersignTask','929da769-1066-11f1-a1f8-22842007978f',NULL,'Countersign Task','userTask','2','2026-02-23 11:20:15.771','2026-02-23 11:20:29.691',3,13920,NULL,''),
('962b8623-2149-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfcbe0a-2147-11f1-8664-9ace7c5eee11','flow2',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-03-16 23:05:36.096','2026-03-16 23:05:36.096',1,0,NULL,''),
('962b8624-2149-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfcbe0a-2147-11f1-8664-9ace7c5eee11','decision',NULL,NULL,'Decision','exclusiveGateway',NULL,'2026-03-16 23:05:36.096','2026-03-16 23:05:36.098',2,2,NULL,''),
('962bd445-2149-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfcbe0a-2147-11f1-8664-9ace7c5eee11','flow3',NULL,NULL,'Approve','sequenceFlow',NULL,'2026-03-16 23:05:36.098','2026-03-16 23:05:36.098',3,0,NULL,''),
('962bd446-2149-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfcbe0a-2147-11f1-8664-9ace7c5eee11','approveEnd',NULL,NULL,'Approved','endEvent',NULL,'2026-03-16 23:05:36.098','2026-03-16 23:05:36.099',4,1,NULL,''),
('97844a58-2147-11f1-8664-9ace7c5eee11',1,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11','97844a57-2147-11f1-8664-9ace7c5eee11','start',NULL,NULL,'Start','startEvent',NULL,'2026-03-16 22:51:19.362','2026-03-16 22:51:19.362',1,0,NULL,''),
('97847169-2147-11f1-8664-9ace7c5eee11',1,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11','97844a57-2147-11f1-8664-9ace7c5eee11','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-03-16 22:51:19.363','2026-03-16 22:51:19.363',2,0,NULL,''),
('97849881-2147-11f1-8664-9ace7c5eee11',1,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11','9784716b-2147-11f1-8664-9ace7c5eee11','sequentialTask','97849882-2147-11f1-8664-9ace7c5eee11',NULL,'Sequential Task','userTask','5','2026-03-16 22:51:19.364',NULL,3,NULL,NULL,''),
('9aea70bf-1066-11f1-a1f8-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','929d5932-1066-11f1-a1f8-22842007978f','9aea70be-1066-11f1-a1f8-22842007978f','flow2',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-02-23 11:20:29.696','2026-02-23 11:20:29.696',1,0,NULL,''),
('9aea70c0-1066-11f1-a1f8-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','929d5932-1066-11f1-a1f8-22842007978f','9aea70be-1066-11f1-a1f8-22842007978f','decision',NULL,NULL,'Decision','exclusiveGateway',NULL,'2026-02-23 11:20:29.696','2026-02-23 11:20:29.696',2,0,NULL,''),
('9aea70c1-1066-11f1-a1f8-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','929d5932-1066-11f1-a1f8-22842007978f','9aea70be-1066-11f1-a1f8-22842007978f','flow3',NULL,NULL,'Approve','sequenceFlow',NULL,'2026-02-23 11:20:29.696','2026-02-23 11:20:29.696',3,0,NULL,''),
('9aea70c2-1066-11f1-a1f8-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','929d5932-1066-11f1-a1f8-22842007978f','9aea70be-1066-11f1-a1f8-22842007978f','approveEnd',NULL,NULL,'Approved','endEvent',NULL,'2026-02-23 11:20:29.696','2026-02-23 11:20:29.696',4,0,NULL,''),
('b7d01cf4-2147-11f1-8664-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01cf3-2147-11f1-8664-9ace7c5eee11','start',NULL,NULL,'Start','startEvent',NULL,'2026-03-16 22:52:13.546','2026-03-16 22:52:13.547',1,1,NULL,''),
('b7d04405-2147-11f1-8664-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01cf3-2147-11f1-8664-9ace7c5eee11','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-03-16 22:52:13.547','2026-03-16 22:52:13.547',2,0,NULL,''),
('b7d04406-2147-11f1-8664-9ace7c5eee11',2,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01cf3-2147-11f1-8664-9ace7c5eee11','singleApprovalTask','b7d04407-2147-11f1-8664-9ace7c5eee11',NULL,'Single Approval Task','userTask','manager','2026-03-16 22:52:13.547','2026-03-16 23:08:10.185',3,956638,NULL,''),
('b9b6104f-2146-11f1-82c2-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b6104e-2146-11f1-82c2-9ace7c5eee11','start',NULL,NULL,'Start','startEvent',NULL,'2026-03-16 22:45:07.234','2026-03-16 22:45:07.237',1,3,NULL,''),
('b9b68580-2146-11f1-82c2-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b6104e-2146-11f1-82c2-9ace7c5eee11','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-03-16 22:45:07.237','2026-03-16 22:45:07.237',2,0,NULL,''),
('b9b68581-2146-11f1-82c2-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b6104e-2146-11f1-82c2-9ace7c5eee11','singleApprovalTask','b9b721c2-2146-11f1-82c2-9ace7c5eee11',NULL,'Single Approval Task','userTask','manager','2026-03-16 22:45:07.237',NULL,3,NULL,NULL,''),
('de0c7bb2-1064-11f1-917d-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f','de0c7bb1-1064-11f1-917d-22842007978f','start',NULL,NULL,'Start','startEvent',NULL,'2026-02-23 11:08:03.333','2026-02-23 11:08:03.334',1,1,NULL,''),
('de0cc9d3-1064-11f1-917d-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f','de0c7bb1-1064-11f1-917d-22842007978f','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-02-23 11:08:03.335','2026-02-23 11:08:03.335',2,0,NULL,''),
('de0d17fb-1064-11f1-917d-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f','de0d17f8-1064-11f1-917d-22842007978f','countersignTask','de0d3f0c-1064-11f1-917d-22842007978f',NULL,'Countersign Task','userTask','1','2026-02-23 11:08:03.337',NULL,3,NULL,NULL,''),
('f1f15447-2149-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11','f1f15446-2149-11f1-9281-9ace7c5eee11','start',NULL,NULL,'Start','startEvent',NULL,'2026-03-16 23:08:10.065','2026-03-16 23:08:10.065',1,0,NULL,''),
('f1f15448-2149-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11','f1f15446-2149-11f1-9281-9ace7c5eee11','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-03-16 23:08:10.065','2026-03-16 23:08:10.065',2,0,NULL,''),
('f1f15449-2149-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11','f1f15446-2149-11f1-9281-9ace7c5eee11','singleApprovalTask','f1f17b5a-2149-11f1-9281-9ace7c5eee11',NULL,'Single Approval Task','userTask','manager','2026-03-16 23:08:10.065',NULL,3,NULL,NULL,''),
('f203a3cf-2149-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01cf3-2147-11f1-8664-9ace7c5eee11','flow2',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-03-16 23:08:10.185','2026-03-16 23:08:10.185',1,0,NULL,''),
('f203cae0-2149-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01cf3-2147-11f1-8664-9ace7c5eee11','decision',NULL,NULL,'Decision','exclusiveGateway',NULL,'2026-03-16 23:08:10.186','2026-03-16 23:08:10.186',2,0,NULL,''),
('f203cae1-2149-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01cf3-2147-11f1-8664-9ace7c5eee11','flow3',NULL,NULL,'Approve','sequenceFlow',NULL,'2026-03-16 23:08:10.186','2026-03-16 23:08:10.186',3,0,NULL,''),
('f203cae2-2149-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01cf3-2147-11f1-8664-9ace7c5eee11','approveEnd',NULL,NULL,'Approved','endEvent',NULL,'2026-03-16 23:08:10.186','2026-03-16 23:08:10.186',4,0,NULL,''),
('f20ca494-2149-11f1-9281-9ace7c5eee11',1,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20ca493-2149-11f1-9281-9ace7c5eee11','start',NULL,NULL,'Start','startEvent',NULL,'2026-03-16 23:08:10.244','2026-03-16 23:08:10.244',1,0,NULL,''),
('f20ca495-2149-11f1-9281-9ace7c5eee11',1,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20ca493-2149-11f1-9281-9ace7c5eee11','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-03-16 23:08:10.244','2026-03-16 23:08:10.244',2,0,NULL,''),
('f20ccbad-2149-11f1-9281-9ace7c5eee11',1,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20ccba7-2149-11f1-9281-9ace7c5eee11','sequentialTask','f20ccbae-2149-11f1-9281-9ace7c5eee11',NULL,'Sequential Task','userTask','5','2026-03-16 23:08:10.245',NULL,3,NULL,NULL,'');
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
('443a5cb9-1066-11f1-a1f8-22842007978f',NULL,'assignee','2','443a35a8-1066-11f1-a1f8-22842007978f','2026-02-23 11:18:04.258',NULL,NULL,NULL,NULL,NULL),
('443a5cba-1066-11f1-a1f8-22842007978f',NULL,'participant','2',NULL,'2026-02-23 11:18:04.258','443812b1-1066-11f1-a1f8-22842007978f',NULL,NULL,NULL,NULL),
('4dfdf68f-2147-11f1-8664-9ace7c5eee11',NULL,'assignee','manager','4dfdcf7e-2147-11f1-8664-9ace7c5eee11','2026-03-16 22:49:16.008',NULL,NULL,NULL,NULL,NULL),
('4dfdf690-2147-11f1-8664-9ace7c5eee11',NULL,'participant','manager',NULL,'2026-03-16 22:49:16.008','4dfb5f6d-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL),
('53eeea63-2151-11f1-9281-9ace7c5eee11',NULL,'assignee','manager','53eeea62-2151-11f1-9281-9ace7c5eee11','2026-03-17 00:01:00.943',NULL,NULL,NULL,NULL,NULL),
('53eeea64-2151-11f1-9281-9ace7c5eee11',NULL,'participant','manager',NULL,'2026-03-17 00:01:00.943','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL),
('929da76a-1066-11f1-a1f8-22842007978f',NULL,'assignee','2','929da769-1066-11f1-a1f8-22842007978f','2026-02-23 11:20:15.771',NULL,NULL,NULL,NULL,NULL),
('929dce7b-1066-11f1-a1f8-22842007978f',NULL,'participant','2',NULL,'2026-02-23 11:20:15.772','929d5932-1066-11f1-a1f8-22842007978f',NULL,NULL,NULL,NULL),
('97849883-2147-11f1-8664-9ace7c5eee11',NULL,'assignee','5','97849882-2147-11f1-8664-9ace7c5eee11','2026-03-16 22:51:19.364',NULL,NULL,NULL,NULL,NULL),
('97849884-2147-11f1-8664-9ace7c5eee11',NULL,'participant','5',NULL,'2026-03-16 22:51:19.364','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL),
('b7d04408-2147-11f1-8664-9ace7c5eee11',NULL,'assignee','manager','b7d04407-2147-11f1-8664-9ace7c5eee11','2026-03-16 22:52:13.547',NULL,NULL,NULL,NULL,NULL),
('b7d04409-2147-11f1-8664-9ace7c5eee11',NULL,'participant','manager',NULL,'2026-03-16 22:52:13.547','b7d01ce5-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL),
('b9b76fe3-2146-11f1-82c2-9ace7c5eee11',NULL,'assignee','manager','b9b721c2-2146-11f1-82c2-9ace7c5eee11','2026-03-16 22:45:07.243',NULL,NULL,NULL,NULL,NULL),
('b9b76fe4-2146-11f1-82c2-9ace7c5eee11',NULL,'participant','manager',NULL,'2026-03-16 22:45:07.243','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,NULL,NULL),
('de0d661d-1064-11f1-917d-22842007978f',NULL,'assignee','1','de0d3f0c-1064-11f1-917d-22842007978f','2026-02-23 11:08:03.339',NULL,NULL,NULL,NULL,NULL),
('de0d8d2e-1064-11f1-917d-22842007978f',NULL,'participant','1',NULL,'2026-02-23 11:08:03.340','de0b4325-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL),
('f1f1a26b-2149-11f1-9281-9ace7c5eee11',NULL,'assignee','manager','f1f17b5a-2149-11f1-9281-9ace7c5eee11','2026-03-16 23:08:10.067',NULL,NULL,NULL,NULL,NULL),
('f1f1a26c-2149-11f1-9281-9ace7c5eee11',NULL,'participant','manager',NULL,'2026-03-16 23:08:10.067','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL),
('f20cf2bf-2149-11f1-9281-9ace7c5eee11',NULL,'assignee','5','f20ccbae-2149-11f1-9281-9ace7c5eee11','2026-03-16 23:08:10.246',NULL,NULL,NULL,NULL,NULL),
('f20cf2c0-2149-11f1-9281-9ace7c5eee11',NULL,'participant','5',NULL,'2026-03-16 23:08:10.246','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL);
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
('443812b1-1066-11f1-a1f8-22842007978f',2,'443812b1-1066-11f1-a1f8-22842007978f','116b414f-6fc9-497f-8b80-36b108425341','approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','2026-02-23 11:18:04.243','2026-02-23 11:18:04.410',167,NULL,'start','approveEnd',NULL,NULL,'',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('4dfb5f6d-2147-11f1-8664-9ace7c5eee11',2,'4dfb5f6d-2147-11f1-8664-9ace7c5eee11','TEST-001','approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','2026-03-16 22:49:15.991','2026-03-16 23:05:36.105',980114,NULL,'start','approveEnd',NULL,NULL,'',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('53eec341-2151-11f1-9281-9ace7c5eee11',1,'53eec341-2151-11f1-9281-9ace7c5eee11','TEST-VALID-001','approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','2026-03-17 00:01:00.942',NULL,NULL,NULL,'start',NULL,NULL,NULL,'',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('929d5932-1066-11f1-a1f8-22842007978f',2,'929d5932-1066-11f1-a1f8-22842007978f','75bf1537-f6b7-4c65-963d-7a96531e07f6','approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','2026-02-23 11:20:15.769','2026-02-23 11:20:29.700',13931,NULL,'start','approveEnd',NULL,NULL,'',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('97844a47-2147-11f1-8664-9ace7c5eee11',1,'97844a47-2147-11f1-8664-9ace7c5eee11','TRAVEL-2026-001','approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11','2026-03-16 22:51:19.362',NULL,NULL,NULL,'start',NULL,NULL,NULL,'',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('b7d01ce5-2147-11f1-8664-9ace7c5eee11',2,'b7d01ce5-2147-11f1-8664-9ace7c5eee11','EXP-2026-002','approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','2026-03-16 22:52:13.546','2026-03-16 23:08:10.190',956644,NULL,'start','approveEnd',NULL,NULL,'',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('b9b4146f-2146-11f1-82c2-9ace7c5eee11',1,'b9b4146f-2146-11f1-82c2-9ace7c5eee11','EXP-2026-001','approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','2026-03-16 22:45:07.221',NULL,NULL,NULL,'start',NULL,NULL,NULL,'',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('de0b4325-1064-11f1-917d-22842007978f',1,'de0b4325-1064-11f1-917d-22842007978f','50d9a78c-6a3f-4fb7-a165-f2d336cc8d73','approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','2026-02-23 11:08:03.325',NULL,NULL,NULL,'start',NULL,NULL,NULL,'',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('f1efa687-2149-11f1-9281-9ace7c5eee11',1,'f1efa687-2149-11f1-9281-9ace7c5eee11','EXP-2026-FINAL','approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','2026-03-16 23:08:10.054',NULL,NULL,NULL,'start',NULL,NULL,NULL,'',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('f20c7d73-2149-11f1-9281-9ace7c5eee11',1,'f20c7d73-2149-11f1-9281-9ace7c5eee11','TRAVEL-2026-FINAL','approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11','2026-03-16 23:08:10.243',NULL,NULL,NULL,'start',NULL,NULL,NULL,'',NULL,NULL,NULL,NULL,NULL,NULL,NULL);
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
('443a35a8-1066-11f1-a1f8-22842007978f',2,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f',NULL,'countersignTask','443812b1-1066-11f1-a1f8-22842007978f','4439e784-1066-11f1-a1f8-22842007978f',NULL,NULL,NULL,NULL,NULL,'Countersign Task',NULL,NULL,NULL,'2','2026-02-23 11:18:04.256',NULL,'2026-02-23 11:18:04.390',134,NULL,50,NULL,NULL,NULL,'','2026-02-23 11:18:04.390'),
('4dfdcf7e-2147-11f1-8664-9ace7c5eee11',2,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11',NULL,'singleApprovalTask','4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfcbe0a-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,'Single Approval Task',NULL,NULL,NULL,'manager','2026-03-16 22:49:16.003',NULL,'2026-03-16 23:05:36.090',980087,NULL,50,NULL,NULL,NULL,'','2026-03-16 23:05:36.090'),
('53eeea62-2151-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11',NULL,'singleApprovalTask','53eec341-2151-11f1-9281-9ace7c5eee11','53eeea5e-2151-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,'Single Approval Task',NULL,NULL,NULL,'manager','2026-03-17 00:01:00.943',NULL,NULL,NULL,NULL,50,NULL,NULL,NULL,'','2026-03-17 00:01:00.943'),
('929da769-1066-11f1-a1f8-22842007978f',2,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f',NULL,'countersignTask','929d5932-1066-11f1-a1f8-22842007978f','929da765-1066-11f1-a1f8-22842007978f',NULL,NULL,NULL,NULL,NULL,'Countersign Task',NULL,NULL,NULL,'2','2026-02-23 11:20:15.771',NULL,'2026-02-23 11:20:29.683',13912,NULL,50,NULL,NULL,NULL,'','2026-02-23 11:20:29.683'),
('97849882-2147-11f1-8664-9ace7c5eee11',1,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11',NULL,'sequentialTask','97844a47-2147-11f1-8664-9ace7c5eee11','9784716b-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,'Sequential Task',NULL,NULL,NULL,'5','2026-03-16 22:51:19.364',NULL,NULL,NULL,NULL,50,NULL,NULL,NULL,'','2026-03-16 22:51:19.364'),
('b7d04407-2147-11f1-8664-9ace7c5eee11',2,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11',NULL,'singleApprovalTask','b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01cf3-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,'Single Approval Task',NULL,NULL,NULL,'manager','2026-03-16 22:52:13.547',NULL,'2026-03-16 23:08:10.184',956637,NULL,50,NULL,NULL,NULL,'','2026-03-16 23:08:10.184'),
('b9b721c2-2146-11f1-82c2-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11',NULL,'singleApprovalTask','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b6104e-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,'Single Approval Task',NULL,NULL,NULL,'manager','2026-03-16 22:45:07.238',NULL,NULL,NULL,NULL,50,NULL,NULL,NULL,'','2026-03-16 22:45:07.243'),
('de0d3f0c-1064-11f1-917d-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f',NULL,'countersignTask','de0b4325-1064-11f1-917d-22842007978f','de0d17f8-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL,'Countersign Task',NULL,NULL,NULL,'1','2026-02-23 11:08:03.337',NULL,NULL,NULL,NULL,50,NULL,NULL,NULL,'','2026-02-23 11:08:03.339'),
('f1f17b5a-2149-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11',NULL,'singleApprovalTask','f1efa687-2149-11f1-9281-9ace7c5eee11','f1f15446-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,'Single Approval Task',NULL,NULL,NULL,'manager','2026-03-16 23:08:10.065',NULL,NULL,NULL,NULL,50,NULL,NULL,NULL,'','2026-03-16 23:08:10.067'),
('f20ccbae-2149-11f1-9281-9ace7c5eee11',1,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11',NULL,'sequentialTask','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20ccba7-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,'Sequential Task',NULL,NULL,NULL,'5','2026-03-16 23:08:10.245',NULL,NULL,NULL,NULL,50,NULL,NULL,NULL,'','2026-03-16 23:08:10.246');
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
('443812b2-1066-11f1-a1f8-22842007978f',0,'443812b1-1066-11f1-a1f8-22842007978f','443812b1-1066-11f1-a1f8-22842007978f',NULL,'countersignMode','string',NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL,'2026-02-23 11:18:04.244','2026-02-23 11:18:04.244'),
('443839c3-1066-11f1-a1f8-22842007978f',0,'443812b1-1066-11f1-a1f8-22842007978f','443812b1-1066-11f1-a1f8-22842007978f',NULL,'businessKey','string',NULL,NULL,NULL,NULL,NULL,NULL,'116b414f-6fc9-497f-8b80-36b108425341',NULL,NULL,'2026-02-23 11:18:04.244','2026-02-23 11:18:04.244'),
('44392425-1066-11f1-a1f8-22842007978f',0,'443812b1-1066-11f1-a1f8-22842007978f','443812b1-1066-11f1-a1f8-22842007978f',NULL,'countersignUsers','serializable',NULL,NULL,NULL,'44392426-1066-11f1-a1f8-22842007978f',NULL,NULL,NULL,NULL,NULL,'2026-02-23 11:18:04.250','2026-02-23 11:18:04.250'),
('44392427-1066-11f1-a1f8-22842007978f',0,'443812b1-1066-11f1-a1f8-22842007978f','443812b1-1066-11f1-a1f8-22842007978f',NULL,'requiredApprove','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-02-23 11:18:04.250','2026-02-23 11:18:04.250'),
('44392428-1066-11f1-a1f8-22842007978f',1,'443812b1-1066-11f1-a1f8-22842007978f','443812b1-1066-11f1-a1f8-22842007978f',NULL,'approveCount','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-02-23 11:18:04.250','2026-02-23 11:18:04.388'),
('44392429-1066-11f1-a1f8-22842007978f',0,'443812b1-1066-11f1-a1f8-22842007978f','443812b1-1066-11f1-a1f8-22842007978f',NULL,'applicantId','long',NULL,NULL,NULL,NULL,NULL,2,'2',NULL,NULL,'2026-02-23 11:18:04.250','2026-02-23 11:18:04.250'),
('4439242a-1066-11f1-a1f8-22842007978f',0,'443812b1-1066-11f1-a1f8-22842007978f','443812b1-1066-11f1-a1f8-22842007978f',NULL,'title','string',NULL,NULL,NULL,NULL,NULL,NULL,'Test Request',NULL,NULL,'2026-02-23 11:18:04.250','2026-02-23 11:18:04.250'),
('4439242b-1066-11f1-a1f8-22842007978f',1,'443812b1-1066-11f1-a1f8-22842007978f','443812b1-1066-11f1-a1f8-22842007978f',NULL,'rejectCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-02-23 11:18:04.250','2026-02-23 11:18:04.389'),
('4439242c-1066-11f1-a1f8-22842007978f',1,'443812b1-1066-11f1-a1f8-22842007978f','443812b1-1066-11f1-a1f8-22842007978f',NULL,'countersignResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'APPROVE',NULL,NULL,'2026-02-23 11:18:04.250','2026-02-23 11:18:04.389'),
('4439e781-1066-11f1-a1f8-22842007978f',0,'443812b1-1066-11f1-a1f8-22842007978f','44399960-1066-11f1-a1f8-22842007978f',NULL,'nrOfInstances','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-02-23 11:18:04.255','2026-02-23 11:18:04.255'),
('4439e782-1066-11f1-a1f8-22842007978f',1,'443812b1-1066-11f1-a1f8-22842007978f','44399960-1066-11f1-a1f8-22842007978f',NULL,'nrOfCompletedInstances','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-02-23 11:18:04.255','2026-02-23 11:18:04.398'),
('4439e783-1066-11f1-a1f8-22842007978f',1,'443812b1-1066-11f1-a1f8-22842007978f','44399960-1066-11f1-a1f8-22842007978f',NULL,'nrOfActiveInstances','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-02-23 11:18:04.255','2026-02-23 11:18:04.399'),
('4439e785-1066-11f1-a1f8-22842007978f',0,'443812b1-1066-11f1-a1f8-22842007978f','4439e784-1066-11f1-a1f8-22842007978f',NULL,'countersignUser','string',NULL,NULL,NULL,NULL,NULL,NULL,'2',NULL,NULL,'2026-02-23 11:18:04.255','2026-02-23 11:18:04.255'),
('443a0e96-1066-11f1-a1f8-22842007978f',0,'443812b1-1066-11f1-a1f8-22842007978f','4439e784-1066-11f1-a1f8-22842007978f',NULL,'loopCounter','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-02-23 11:18:04.256','2026-02-23 11:18:04.256'),
('444de4bb-1066-11f1-a1f8-22842007978f',0,'443812b1-1066-11f1-a1f8-22842007978f','443812b1-1066-11f1-a1f8-22842007978f',NULL,'comments','string',NULL,NULL,NULL,NULL,NULL,NULL,'Approved',NULL,NULL,'2026-02-23 11:18:04.386','2026-02-23 11:18:04.386'),
('444de4bc-1066-11f1-a1f8-22842007978f',0,'443812b1-1066-11f1-a1f8-22842007978f','443812b1-1066-11f1-a1f8-22842007978f',NULL,'approvalResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'APPROVE',NULL,NULL,'2026-02-23 11:18:04.386','2026-02-23 11:18:04.386'),
('4dfb5f6e-2147-11f1-8664-9ace7c5eee11',0,'4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11',NULL,'approverId','string',NULL,NULL,NULL,NULL,NULL,NULL,'manager',NULL,NULL,'2026-03-16 22:49:15.992','2026-03-16 22:49:15.992'),
('4dfb867f-2147-11f1-8664-9ace7c5eee11',0,'4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11',NULL,'countersignMode','string',NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL,'2026-03-16 22:49:15.992','2026-03-16 22:49:15.992'),
('4dfb8680-2147-11f1-8664-9ace7c5eee11',0,'4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11',NULL,'businessKey','string',NULL,NULL,NULL,NULL,NULL,NULL,'TEST-001',NULL,NULL,'2026-03-16 22:49:15.992','2026-03-16 22:49:15.992'),
('4dfcbe02-2147-11f1-8664-9ace7c5eee11',0,'4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11',NULL,'countersignUsers','serializable',NULL,NULL,NULL,'4dfcbe03-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,'2026-03-16 22:49:16.000','2026-03-16 22:49:16.000'),
('4dfcbe04-2147-11f1-8664-9ace7c5eee11',0,'4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11',NULL,'requiredApprove','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-03-16 22:49:16.000','2026-03-16 22:49:16.000'),
('4dfcbe05-2147-11f1-8664-9ace7c5eee11',1,'4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11',NULL,'approveCount','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-03-16 22:49:16.000','2026-03-16 23:05:36.088'),
('4dfcbe06-2147-11f1-8664-9ace7c5eee11',0,'4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11',NULL,'applicantId','long',NULL,NULL,NULL,NULL,NULL,4,'4',NULL,NULL,'2026-03-16 22:49:16.000','2026-03-16 22:49:16.000'),
('4dfcbe07-2147-11f1-8664-9ace7c5eee11',0,'4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11',NULL,'title','string',NULL,NULL,NULL,NULL,NULL,NULL,'Test',NULL,NULL,'2026-03-16 22:49:16.000','2026-03-16 22:49:16.000'),
('4dfcbe08-2147-11f1-8664-9ace7c5eee11',1,'4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11',NULL,'rejectCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-16 22:49:16.000','2026-03-16 23:05:36.089'),
('4dfcbe09-2147-11f1-8664-9ace7c5eee11',1,'4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11',NULL,'countersignResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'PENDING',NULL,NULL,'2026-03-16 22:49:16.000','2026-03-16 23:05:36.089'),
('53eec342-2151-11f1-9281-9ace7c5eee11',0,'53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,'approverId','string',NULL,NULL,NULL,NULL,NULL,NULL,'manager',NULL,NULL,'2026-03-17 00:01:00.942','2026-03-17 00:01:00.942'),
('53eec343-2151-11f1-9281-9ace7c5eee11',0,'53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,'countersignMode','string',NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL,'2026-03-17 00:01:00.942','2026-03-17 00:01:00.942'),
('53eec344-2151-11f1-9281-9ace7c5eee11',0,'53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,'businessKey','string',NULL,NULL,NULL,NULL,NULL,NULL,'TEST-VALID-001',NULL,NULL,'2026-03-17 00:01:00.942','2026-03-17 00:01:00.942'),
('53eeea56-2151-11f1-9281-9ace7c5eee11',0,'53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,'countersignUsers','serializable',NULL,NULL,NULL,'53eeea57-2151-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,'2026-03-17 00:01:00.943','2026-03-17 00:01:00.943'),
('53eeea58-2151-11f1-9281-9ace7c5eee11',0,'53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,'requiredApprove','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-03-17 00:01:00.943','2026-03-17 00:01:00.943'),
('53eeea59-2151-11f1-9281-9ace7c5eee11',0,'53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,'approveCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-17 00:01:00.943','2026-03-17 00:01:00.943'),
('53eeea5a-2151-11f1-9281-9ace7c5eee11',0,'53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,'applicantId','long',NULL,NULL,NULL,NULL,NULL,5,'5',NULL,NULL,'2026-03-17 00:01:00.943','2026-03-17 00:01:00.943'),
('53eeea5b-2151-11f1-9281-9ace7c5eee11',0,'53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,'title','string',NULL,NULL,NULL,NULL,NULL,NULL,'Valid Test Request',NULL,NULL,'2026-03-17 00:01:00.943','2026-03-17 00:01:00.943'),
('53eeea5c-2151-11f1-9281-9ace7c5eee11',0,'53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,'rejectCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-17 00:01:00.943','2026-03-17 00:01:00.943'),
('53eeea5d-2151-11f1-9281-9ace7c5eee11',0,'53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,'countersignResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'PENDING',NULL,NULL,'2026-03-17 00:01:00.943','2026-03-17 00:01:00.943'),
('929d5933-1066-11f1-a1f8-22842007978f',0,'929d5932-1066-11f1-a1f8-22842007978f','929d5932-1066-11f1-a1f8-22842007978f',NULL,'countersignMode','string',NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL,'2026-02-23 11:20:15.769','2026-02-23 11:20:15.769'),
('929d5934-1066-11f1-a1f8-22842007978f',0,'929d5932-1066-11f1-a1f8-22842007978f','929d5932-1066-11f1-a1f8-22842007978f',NULL,'businessKey','string',NULL,NULL,NULL,NULL,NULL,NULL,'75bf1537-f6b7-4c65-963d-7a96531e07f6',NULL,NULL,'2026-02-23 11:20:15.769','2026-02-23 11:20:15.769'),
('929d5936-1066-11f1-a1f8-22842007978f',0,'929d5932-1066-11f1-a1f8-22842007978f','929d5932-1066-11f1-a1f8-22842007978f',NULL,'countersignUsers','serializable',NULL,NULL,NULL,'929d5937-1066-11f1-a1f8-22842007978f',NULL,NULL,NULL,NULL,NULL,'2026-02-23 11:20:15.769','2026-02-23 11:20:15.769'),
('929d5938-1066-11f1-a1f8-22842007978f',0,'929d5932-1066-11f1-a1f8-22842007978f','929d5932-1066-11f1-a1f8-22842007978f',NULL,'requiredApprove','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-02-23 11:20:15.770','2026-02-23 11:20:15.770'),
('929d8049-1066-11f1-a1f8-22842007978f',1,'929d5932-1066-11f1-a1f8-22842007978f','929d5932-1066-11f1-a1f8-22842007978f',NULL,'approveCount','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-02-23 11:20:15.770','2026-02-23 11:20:29.682'),
('929d804a-1066-11f1-a1f8-22842007978f',0,'929d5932-1066-11f1-a1f8-22842007978f','929d5932-1066-11f1-a1f8-22842007978f',NULL,'applicantId','long',NULL,NULL,NULL,NULL,NULL,2,'2',NULL,NULL,'2026-02-23 11:20:15.770','2026-02-23 11:20:15.770'),
('929d804b-1066-11f1-a1f8-22842007978f',0,'929d5932-1066-11f1-a1f8-22842007978f','929d5932-1066-11f1-a1f8-22842007978f',NULL,'title','string',NULL,NULL,NULL,NULL,NULL,NULL,'Test Request',NULL,NULL,'2026-02-23 11:20:15.770','2026-02-23 11:20:15.770'),
('929d804c-1066-11f1-a1f8-22842007978f',1,'929d5932-1066-11f1-a1f8-22842007978f','929d5932-1066-11f1-a1f8-22842007978f',NULL,'rejectCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-02-23 11:20:15.770','2026-02-23 11:20:29.682'),
('929d804d-1066-11f1-a1f8-22842007978f',1,'929d5932-1066-11f1-a1f8-22842007978f','929d5932-1066-11f1-a1f8-22842007978f',NULL,'countersignResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'APPROVE',NULL,NULL,'2026-02-23 11:20:15.770','2026-02-23 11:20:29.683'),
('929da762-1066-11f1-a1f8-22842007978f',0,'929d5932-1066-11f1-a1f8-22842007978f','929da761-1066-11f1-a1f8-22842007978f',NULL,'nrOfInstances','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-02-23 11:20:15.771','2026-02-23 11:20:15.771'),
('929da763-1066-11f1-a1f8-22842007978f',1,'929d5932-1066-11f1-a1f8-22842007978f','929da761-1066-11f1-a1f8-22842007978f',NULL,'nrOfCompletedInstances','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-02-23 11:20:15.771','2026-02-23 11:20:29.691'),
('929da764-1066-11f1-a1f8-22842007978f',1,'929d5932-1066-11f1-a1f8-22842007978f','929da761-1066-11f1-a1f8-22842007978f',NULL,'nrOfActiveInstances','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-02-23 11:20:15.771','2026-02-23 11:20:29.692'),
('929da766-1066-11f1-a1f8-22842007978f',0,'929d5932-1066-11f1-a1f8-22842007978f','929da765-1066-11f1-a1f8-22842007978f',NULL,'countersignUser','string',NULL,NULL,NULL,NULL,NULL,NULL,'2',NULL,NULL,'2026-02-23 11:20:15.771','2026-02-23 11:20:15.771'),
('929da767-1066-11f1-a1f8-22842007978f',0,'929d5932-1066-11f1-a1f8-22842007978f','929da765-1066-11f1-a1f8-22842007978f',NULL,'loopCounter','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-02-23 11:20:15.771','2026-02-23 11:20:15.771'),
('96296341-2149-11f1-9281-9ace7c5eee11',0,'4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11',NULL,'comments','string',NULL,NULL,NULL,NULL,NULL,NULL,'Approved - necessary office supplies',NULL,NULL,'2026-03-16 23:05:36.083','2026-03-16 23:05:36.083'),
('96298a52-2149-11f1-9281-9ace7c5eee11',0,'4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11',NULL,'approvalResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'APPROVE',NULL,NULL,'2026-03-16 23:05:36.083','2026-03-16 23:05:36.083'),
('97844a48-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,'amount','integer',NULL,NULL,NULL,NULL,NULL,2500,'2500',NULL,NULL,'2026-03-16 22:51:19.362','2026-03-16 22:51:19.362'),
('97844a49-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,'level1Approver','string',NULL,NULL,NULL,NULL,NULL,NULL,'manager',NULL,NULL,'2026-03-16 22:51:19.362','2026-03-16 22:51:19.362'),
('97844a4a-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,'countersignMode','string',NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL,'2026-03-16 22:51:19.362','2026-03-16 22:51:19.362'),
('97844a4b-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,'destination','string',NULL,NULL,NULL,NULL,NULL,NULL,'Beijing',NULL,NULL,'2026-03-16 22:51:19.362','2026-03-16 22:51:19.362'),
('97844a4c-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,'requiredApprove','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-03-16 22:51:19.362','2026-03-16 22:51:19.362'),
('97844a4d-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,'level2Approver','string',NULL,NULL,NULL,NULL,NULL,NULL,'admin',NULL,NULL,'2026-03-16 22:51:19.362','2026-03-16 22:51:19.362'),
('97844a4e-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,'title','string',NULL,NULL,NULL,NULL,NULL,NULL,'Business Travel Reimbursement',NULL,NULL,'2026-03-16 22:51:19.362','2026-03-16 22:51:19.362'),
('97844a4f-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,'rejectCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-16 22:51:19.362','2026-03-16 22:51:19.362'),
('97844a50-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,'countersignResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'PENDING',NULL,NULL,'2026-03-16 22:51:19.362','2026-03-16 22:51:19.362'),
('97844a51-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,'businessKey','string',NULL,NULL,NULL,NULL,NULL,NULL,'TRAVEL-2026-001',NULL,NULL,'2026-03-16 22:51:19.362','2026-03-16 22:51:19.362'),
('97844a53-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,'countersignUsers','serializable',NULL,NULL,NULL,'97844a54-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,'2026-03-16 22:51:19.362','2026-03-16 22:51:19.362'),
('97844a55-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,'approveCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-16 22:51:19.362','2026-03-16 22:51:19.362'),
('97844a56-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,'applicantId','long',NULL,NULL,NULL,NULL,NULL,5,'5',NULL,NULL,'2026-03-16 22:51:19.362','2026-03-16 22:51:19.362'),
('9784716c-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','9784716a-2147-11f1-8664-9ace7c5eee11',NULL,'nrOfInstances','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-03-16 22:51:19.363','2026-03-16 22:51:19.363'),
('9784716d-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','9784716a-2147-11f1-8664-9ace7c5eee11',NULL,'nrOfCompletedInstances','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-16 22:51:19.363','2026-03-16 22:51:19.363'),
('9784716e-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','9784716a-2147-11f1-8664-9ace7c5eee11',NULL,'nrOfActiveInstances','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-03-16 22:51:19.363','2026-03-16 22:51:19.363'),
('9784716f-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','9784716b-2147-11f1-8664-9ace7c5eee11',NULL,'countersignUser','string',NULL,NULL,NULL,NULL,NULL,NULL,'5',NULL,NULL,'2026-03-16 22:51:19.363','2026-03-16 22:51:19.363'),
('97849880-2147-11f1-8664-9ace7c5eee11',0,'97844a47-2147-11f1-8664-9ace7c5eee11','9784716b-2147-11f1-8664-9ace7c5eee11',NULL,'loopCounter','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-16 22:51:19.364','2026-03-16 22:51:19.364'),
('9ae826cc-1066-11f1-a1f8-22842007978f',0,'929d5932-1066-11f1-a1f8-22842007978f','929d5932-1066-11f1-a1f8-22842007978f',NULL,'comments','string',NULL,NULL,NULL,NULL,NULL,NULL,'Approved',NULL,NULL,'2026-02-23 11:20:29.681','2026-02-23 11:20:29.681'),
('9ae826cd-1066-11f1-a1f8-22842007978f',0,'929d5932-1066-11f1-a1f8-22842007978f','929d5932-1066-11f1-a1f8-22842007978f',NULL,'approvalResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'APPROVE',NULL,NULL,'2026-02-23 11:20:29.681','2026-02-23 11:20:29.681'),
('b7d01ce6-2147-11f1-8664-9ace7c5eee11',0,'b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11',NULL,'amount','integer',NULL,NULL,NULL,NULL,NULL,500,'500',NULL,NULL,'2026-03-16 22:52:13.546','2026-03-16 22:52:13.546'),
('b7d01ce7-2147-11f1-8664-9ace7c5eee11',0,'b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11',NULL,'approverId','string',NULL,NULL,NULL,NULL,NULL,NULL,'manager',NULL,NULL,'2026-03-16 22:52:13.546','2026-03-16 22:52:13.546'),
('b7d01ce8-2147-11f1-8664-9ace7c5eee11',0,'b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11',NULL,'countersignMode','string',NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL,'2026-03-16 22:52:13.546','2026-03-16 22:52:13.546'),
('b7d01ce9-2147-11f1-8664-9ace7c5eee11',0,'b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11',NULL,'businessKey','string',NULL,NULL,NULL,NULL,NULL,NULL,'EXP-2026-002',NULL,NULL,'2026-03-16 22:52:13.546','2026-03-16 22:52:13.546'),
('b7d01ceb-2147-11f1-8664-9ace7c5eee11',0,'b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11',NULL,'countersignUsers','serializable',NULL,NULL,NULL,'b7d01cec-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,'2026-03-16 22:52:13.546','2026-03-16 22:52:13.546'),
('b7d01ced-2147-11f1-8664-9ace7c5eee11',0,'b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11',NULL,'requiredApprove','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-03-16 22:52:13.546','2026-03-16 22:52:13.546'),
('b7d01cee-2147-11f1-8664-9ace7c5eee11',1,'b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11',NULL,'approveCount','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-03-16 22:52:13.546','2026-03-16 23:08:10.183'),
('b7d01cef-2147-11f1-8664-9ace7c5eee11',0,'b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11',NULL,'applicantId','long',NULL,NULL,NULL,NULL,NULL,5,'5',NULL,NULL,'2026-03-16 22:52:13.546','2026-03-16 22:52:13.546'),
('b7d01cf0-2147-11f1-8664-9ace7c5eee11',0,'b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11',NULL,'title','string',NULL,NULL,NULL,NULL,NULL,NULL,'Office Supplies',NULL,NULL,'2026-03-16 22:52:13.546','2026-03-16 22:52:13.546'),
('b7d01cf1-2147-11f1-8664-9ace7c5eee11',1,'b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11',NULL,'rejectCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-16 22:52:13.546','2026-03-16 23:08:10.183'),
('b7d01cf2-2147-11f1-8664-9ace7c5eee11',1,'b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11',NULL,'countersignResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'PENDING',NULL,NULL,'2026-03-16 22:52:13.546','2026-03-16 23:08:10.184'),
('b9b43b80-2146-11f1-82c2-9ace7c5eee11',0,'b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,'amount','integer',NULL,NULL,NULL,NULL,NULL,500,'500',NULL,NULL,'2026-03-16 22:45:07.223','2026-03-16 22:45:07.223'),
('b9b46291-2146-11f1-82c2-9ace7c5eee11',0,'b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,'approverId','string',NULL,NULL,NULL,NULL,NULL,NULL,'manager',NULL,NULL,'2026-03-16 22:45:07.223','2026-03-16 22:45:07.223'),
('b9b46292-2146-11f1-82c2-9ace7c5eee11',0,'b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,'countersignMode','string',NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL,'2026-03-16 22:45:07.223','2026-03-16 22:45:07.223'),
('b9b46293-2146-11f1-82c2-9ace7c5eee11',0,'b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,'businessKey','string',NULL,NULL,NULL,NULL,NULL,NULL,'EXP-2026-001',NULL,NULL,'2026-03-16 22:45:07.223','2026-03-16 22:45:07.223'),
('b9b5e935-2146-11f1-82c2-9ace7c5eee11',0,'b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,'countersignUsers','serializable',NULL,NULL,NULL,'b9b5e936-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,'2026-03-16 22:45:07.233','2026-03-16 22:45:07.233'),
('b9b5e937-2146-11f1-82c2-9ace7c5eee11',0,'b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,'requiredApprove','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-03-16 22:45:07.233','2026-03-16 22:45:07.233'),
('b9b5e938-2146-11f1-82c2-9ace7c5eee11',0,'b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,'description','string',NULL,NULL,NULL,NULL,NULL,NULL,'Office supplies',NULL,NULL,'2026-03-16 22:45:07.233','2026-03-16 22:45:07.233'),
('b9b5e939-2146-11f1-82c2-9ace7c5eee11',0,'b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,'approveCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-16 22:45:07.233','2026-03-16 22:45:07.233'),
('b9b5e93a-2146-11f1-82c2-9ace7c5eee11',0,'b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,'applicantId','long',NULL,NULL,NULL,NULL,NULL,4,'4',NULL,NULL,'2026-03-16 22:45:07.233','2026-03-16 22:45:07.233'),
('b9b5e93b-2146-11f1-82c2-9ace7c5eee11',0,'b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,'title','string',NULL,NULL,NULL,NULL,NULL,NULL,'Expense Reimbursement',NULL,NULL,'2026-03-16 22:45:07.233','2026-03-16 22:45:07.233'),
('b9b6104c-2146-11f1-82c2-9ace7c5eee11',0,'b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,'rejectCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-16 22:45:07.234','2026-03-16 22:45:07.234'),
('b9b6104d-2146-11f1-82c2-9ace7c5eee11',0,'b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,'countersignResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'PENDING',NULL,NULL,'2026-03-16 22:45:07.234','2026-03-16 22:45:07.234'),
('de0b4326-1064-11f1-917d-22842007978f',0,'de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,'countersignMode','string',NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL,'2026-02-23 11:08:03.326','2026-02-23 11:08:03.326'),
('de0b6a37-1064-11f1-917d-22842007978f',0,'de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,'businessKey','string',NULL,NULL,NULL,NULL,NULL,NULL,'50d9a78c-6a3f-4fb7-a165-f2d336cc8d73',NULL,NULL,'2026-02-23 11:08:03.326','2026-02-23 11:08:03.326'),
('de0c5499-1064-11f1-917d-22842007978f',0,'de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,'countersignUsers','serializable',NULL,NULL,NULL,'de0c549a-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL,'2026-02-23 11:08:03.332','2026-02-23 11:08:03.332'),
('de0c549b-1064-11f1-917d-22842007978f',0,'de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,'requiredApprove','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-02-23 11:08:03.332','2026-02-23 11:08:03.332'),
('de0c549c-1064-11f1-917d-22842007978f',0,'de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,'approveCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-02-23 11:08:03.332','2026-02-23 11:08:03.332'),
('de0c549d-1064-11f1-917d-22842007978f',0,'de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,'applicantId','long',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-02-23 11:08:03.332','2026-02-23 11:08:03.332'),
('de0c549e-1064-11f1-917d-22842007978f',0,'de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,'title','string',NULL,NULL,NULL,NULL,NULL,NULL,'Test Request',NULL,NULL,'2026-02-23 11:08:03.332','2026-02-23 11:08:03.332'),
('de0c549f-1064-11f1-917d-22842007978f',0,'de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,'rejectCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-02-23 11:08:03.332','2026-02-23 11:08:03.332'),
('de0c54a0-1064-11f1-917d-22842007978f',0,'de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,'countersignResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'PENDING',NULL,NULL,'2026-02-23 11:08:03.332','2026-02-23 11:08:03.332'),
('de0cf0e5-1064-11f1-917d-22842007978f',0,'de0b4325-1064-11f1-917d-22842007978f','de0cc9d4-1064-11f1-917d-22842007978f',NULL,'nrOfInstances','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-02-23 11:08:03.336','2026-02-23 11:08:03.336'),
('de0cf0e6-1064-11f1-917d-22842007978f',0,'de0b4325-1064-11f1-917d-22842007978f','de0cc9d4-1064-11f1-917d-22842007978f',NULL,'nrOfCompletedInstances','bpmnParallelMultiInstanceCompleted',NULL,NULL,NULL,NULL,NULL,NULL,'de0cc9d4-1064-11f1-917d-22842007978f','completed',NULL,'2026-02-23 11:08:03.337','2026-02-23 11:08:03.337'),
('de0d17f7-1064-11f1-917d-22842007978f',0,'de0b4325-1064-11f1-917d-22842007978f','de0cc9d4-1064-11f1-917d-22842007978f',NULL,'nrOfActiveInstances','bpmnParallelMultiInstanceCompleted',NULL,NULL,NULL,NULL,NULL,NULL,'de0cc9d4-1064-11f1-917d-22842007978f','active',NULL,'2026-02-23 11:08:03.337','2026-02-23 11:08:03.337'),
('de0d17f9-1064-11f1-917d-22842007978f',0,'de0b4325-1064-11f1-917d-22842007978f','de0d17f8-1064-11f1-917d-22842007978f',NULL,'countersignUser','string',NULL,NULL,NULL,NULL,NULL,NULL,'1',NULL,NULL,'2026-02-23 11:08:03.337','2026-02-23 11:08:03.337'),
('de0d17fa-1064-11f1-917d-22842007978f',0,'de0b4325-1064-11f1-917d-22842007978f','de0d17f8-1064-11f1-917d-22842007978f',NULL,'loopCounter','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-02-23 11:08:03.337','2026-02-23 11:08:03.337'),
('f1efa688-2149-11f1-9281-9ace7c5eee11',0,'f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,'amount','integer',NULL,NULL,NULL,NULL,NULL,500,'500',NULL,NULL,'2026-03-16 23:08:10.054','2026-03-16 23:08:10.054'),
('f1efcd99-2149-11f1-9281-9ace7c5eee11',0,'f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,'approverId','string',NULL,NULL,NULL,NULL,NULL,NULL,'manager',NULL,NULL,'2026-03-16 23:08:10.055','2026-03-16 23:08:10.055'),
('f1efcd9a-2149-11f1-9281-9ace7c5eee11',0,'f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,'countersignMode','string',NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL,'2026-03-16 23:08:10.055','2026-03-16 23:08:10.055'),
('f1efcd9b-2149-11f1-9281-9ace7c5eee11',0,'f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,'businessKey','string',NULL,NULL,NULL,NULL,NULL,NULL,'EXP-2026-FINAL',NULL,NULL,'2026-03-16 23:08:10.055','2026-03-16 23:08:10.055'),
('f1f12d2d-2149-11f1-9281-9ace7c5eee11',0,'f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,'countersignUsers','serializable',NULL,NULL,NULL,'f1f12d2e-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,'2026-03-16 23:08:10.064','2026-03-16 23:08:10.064'),
('f1f12d2f-2149-11f1-9281-9ace7c5eee11',0,'f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,'requiredApprove','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-03-16 23:08:10.064','2026-03-16 23:08:10.064'),
('f1f12d30-2149-11f1-9281-9ace7c5eee11',0,'f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,'description','string',NULL,NULL,NULL,NULL,NULL,NULL,'Final test - office supplies',NULL,NULL,'2026-03-16 23:08:10.064','2026-03-16 23:08:10.064'),
('f1f12d31-2149-11f1-9281-9ace7c5eee11',0,'f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,'approveCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-16 23:08:10.064','2026-03-16 23:08:10.064'),
('f1f12d32-2149-11f1-9281-9ace7c5eee11',0,'f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,'applicantId','long',NULL,NULL,NULL,NULL,NULL,5,'5',NULL,NULL,'2026-03-16 23:08:10.064','2026-03-16 23:08:10.064'),
('f1f15443-2149-11f1-9281-9ace7c5eee11',0,'f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,'title','string',NULL,NULL,NULL,NULL,NULL,NULL,'Final Test - Office Supplies',NULL,NULL,'2026-03-16 23:08:10.065','2026-03-16 23:08:10.065'),
('f1f15444-2149-11f1-9281-9ace7c5eee11',0,'f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,'rejectCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-16 23:08:10.065','2026-03-16 23:08:10.065'),
('f1f15445-2149-11f1-9281-9ace7c5eee11',0,'f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,'countersignResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'PENDING',NULL,NULL,'2026-03-16 23:08:10.065','2026-03-16 23:08:10.065'),
('f2032e9d-2149-11f1-9281-9ace7c5eee11',0,'b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11',NULL,'comments','string',NULL,NULL,NULL,NULL,NULL,NULL,'Approved - office supplies are necessary for the team',NULL,NULL,'2026-03-16 23:08:10.182','2026-03-16 23:08:10.182'),
('f2032e9e-2149-11f1-9281-9ace7c5eee11',0,'b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11',NULL,'approvalResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'APPROVE',NULL,NULL,'2026-03-16 23:08:10.182','2026-03-16 23:08:10.182'),
('f20c7d74-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,'amount','integer',NULL,NULL,NULL,NULL,NULL,2500,'2500',NULL,NULL,'2026-03-16 23:08:10.243','2026-03-16 23:08:10.243'),
('f20c7d75-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,'level1Approver','string',NULL,NULL,NULL,NULL,NULL,NULL,'manager',NULL,NULL,'2026-03-16 23:08:10.243','2026-03-16 23:08:10.243'),
('f20c7d76-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,'countersignMode','string',NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL,'2026-03-16 23:08:10.243','2026-03-16 23:08:10.243'),
('f20c7d77-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,'destination','string',NULL,NULL,NULL,NULL,NULL,NULL,'Beijing',NULL,NULL,'2026-03-16 23:08:10.243','2026-03-16 23:08:10.243'),
('f20c7d78-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,'requiredApprove','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-03-16 23:08:10.243','2026-03-16 23:08:10.243'),
('f20c7d79-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,'level2Approver','string',NULL,NULL,NULL,NULL,NULL,NULL,'admin',NULL,NULL,'2026-03-16 23:08:10.243','2026-03-16 23:08:10.243'),
('f20c7d7a-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,'title','string',NULL,NULL,NULL,NULL,NULL,NULL,'Business Trip to Beijing',NULL,NULL,'2026-03-16 23:08:10.243','2026-03-16 23:08:10.243'),
('f20c7d7b-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,'rejectCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-16 23:08:10.243','2026-03-16 23:08:10.243'),
('f20c7d7c-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,'countersignResult','string',NULL,NULL,NULL,NULL,NULL,NULL,'PENDING',NULL,NULL,'2026-03-16 23:08:10.244','2026-03-16 23:08:10.244'),
('f20ca48d-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,'businessKey','string',NULL,NULL,NULL,NULL,NULL,NULL,'TRAVEL-2026-FINAL',NULL,NULL,'2026-03-16 23:08:10.244','2026-03-16 23:08:10.244'),
('f20ca48f-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,'countersignUsers','serializable',NULL,NULL,NULL,'f20ca490-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,'2026-03-16 23:08:10.244','2026-03-16 23:08:10.244'),
('f20ca491-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,'approveCount','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-16 23:08:10.244','2026-03-16 23:08:10.244'),
('f20ca492-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,'applicantId','long',NULL,NULL,NULL,NULL,NULL,5,'5',NULL,NULL,'2026-03-16 23:08:10.244','2026-03-16 23:08:10.244'),
('f20ccba8-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20ca496-2149-11f1-9281-9ace7c5eee11',NULL,'nrOfInstances','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-03-16 23:08:10.245','2026-03-16 23:08:10.245'),
('f20ccba9-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20ca496-2149-11f1-9281-9ace7c5eee11',NULL,'nrOfCompletedInstances','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-16 23:08:10.245','2026-03-16 23:08:10.245'),
('f20ccbaa-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20ca496-2149-11f1-9281-9ace7c5eee11',NULL,'nrOfActiveInstances','integer',NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL,'2026-03-16 23:08:10.245','2026-03-16 23:08:10.245'),
('f20ccbab-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20ccba7-2149-11f1-9281-9ace7c5eee11',NULL,'countersignUser','string',NULL,NULL,NULL,NULL,NULL,NULL,'5',NULL,NULL,'2026-03-16 23:08:10.245','2026-03-16 23:08:10.245'),
('f20ccbac-2149-11f1-9281-9ace7c5eee11',0,'f20c7d73-2149-11f1-9281-9ace7c5eee11','f20ccba7-2149-11f1-9281-9ace7c5eee11',NULL,'loopCounter','integer',NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL,'2026-03-16 23:08:10.245','2026-03-16 23:08:10.245');
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
('3c5fde83-2142-11f1-9715-9ace7c5eee11','SpringBootAutoDeployment',NULL,NULL,'','2026-03-16 14:12:58.965',NULL,NULL,'3c5fde83-2142-11f1-9715-9ace7c5eee11',NULL),
('c2de2695-21d7-11f1-8dda-a22975756b37','SpringBootAutoDeployment',NULL,NULL,'','2026-03-17 08:03:19.614',NULL,NULL,'c2de2695-21d7-11f1-8dda-a22975756b37',NULL),
('cab8d20c-1064-11f1-917d-22842007978f','SpringBootAutoDeployment',NULL,NULL,'','2026-02-23 03:07:30.908',NULL,NULL,'cab8d20c-1064-11f1-917d-22842007978f',NULL);
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
('approvalCountersign:1:cac729f4-1064-11f1-917d-22842007978f',1,'http://flowable.org/examples','Approval Countersign','approvalCountersign',1,'cab8d20c-1064-11f1-917d-22842007978f','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-countersign.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalCountersign:2:3c6dc13d-2142-11f1-9715-9ace7c5eee11',1,'http://flowable.org/examples','Approval Countersign','approvalCountersign',2,'3c5fde83-2142-11f1-9715-9ace7c5eee11','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-countersign.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalCountersign:3:c2f1ae9f-21d7-11f1-8dda-a22975756b37',1,'http://flowable.org/examples','Approval Countersign','approvalCountersign',3,'c2de2695-21d7-11f1-8dda-a22975756b37','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-countersign.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalOrSign:1:cac6dbd1-1064-11f1-917d-22842007978f',1,'http://flowable.org/examples','Approval Or-Sign','approvalOrSign',1,'cab8d20c-1064-11f1-917d-22842007978f','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-orsign.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalOrSign:2:3c6d7319-2142-11f1-9715-9ace7c5eee11',1,'http://flowable.org/examples','Approval Or-Sign','approvalOrSign',2,'3c5fde83-2142-11f1-9715-9ace7c5eee11','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-orsign.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalOrSign:3:c2f1607b-21d7-11f1-8dda-a22975756b37',1,'http://flowable.org/examples','Approval Or-Sign','approvalOrSign',3,'c2de2695-21d7-11f1-8dda-a22975756b37','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-orsign.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalSequential:1:cac729f2-1064-11f1-917d-22842007978f',1,'http://flowable.org/examples','Approval Sequential','approvalSequential',1,'cab8d20c-1064-11f1-917d-22842007978f','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-sequential.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11',1,'http://flowable.org/examples','Approval Sequential','approvalSequential',2,'3c5fde83-2142-11f1-9715-9ace7c5eee11','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-sequential.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalSequential:3:c2f1ae9c-21d7-11f1-8dda-a22975756b37',1,'http://flowable.org/examples','Approval Sequential','approvalSequential',3,'c2de2695-21d7-11f1-8dda-a22975756b37','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-sequential.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11',1,'http://flowable.org/examples','Approval Single','approvalSingle',1,'3c5fde83-2142-11f1-9715-9ace7c5eee11','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-single.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalSingle:2:c2f1ae9e-21d7-11f1-8dda-a22975756b37',1,'http://flowable.org/examples','Approval Single','approvalSingle',2,'c2de2695-21d7-11f1-8dda-a22975756b37','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-single.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f',1,'http://flowable.org/examples','Approval Workflow','approvalWorkflow',1,'cab8d20c-1064-11f1-917d-22842007978f','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-workflow.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalWorkflow:2:3c6dc13b-2142-11f1-9715-9ace7c5eee11',1,'http://flowable.org/examples','Approval Workflow','approvalWorkflow',2,'3c5fde83-2142-11f1-9715-9ace7c5eee11','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-workflow.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0),
('approvalWorkflow:3:c2f1ae9d-21d7-11f1-8dda-a22975756b37',1,'http://flowable.org/examples','Approval Workflow','approvalWorkflow',3,'c2de2695-21d7-11f1-8dda-a22975756b37','/home/cao/workspace/graduation_project/approval-system/target/classes/processes/approval-workflow.bpmn20.xml',NULL,NULL,0,0,1,'',NULL,NULL,NULL,0);
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
INSERT INTO `ACT_RU_ACTINST` VALUES
('53eeea5f-2151-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11','53eeea5e-2151-11f1-9281-9ace7c5eee11','start',NULL,NULL,'Start','startEvent',NULL,'2026-03-17 00:01:00.943','2026-03-17 00:01:00.943',0,1,NULL,''),
('53eeea60-2151-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11','53eeea5e-2151-11f1-9281-9ace7c5eee11','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-03-17 00:01:00.943','2026-03-17 00:01:00.943',0,2,NULL,''),
('53eeea61-2151-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11','53eeea5e-2151-11f1-9281-9ace7c5eee11','singleApprovalTask','53eeea62-2151-11f1-9281-9ace7c5eee11',NULL,'Single Approval Task','userTask','manager','2026-03-17 00:01:00.943',NULL,NULL,3,NULL,''),
('97844a58-2147-11f1-8664-9ace7c5eee11',1,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11','97844a57-2147-11f1-8664-9ace7c5eee11','start',NULL,NULL,'Start','startEvent',NULL,'2026-03-16 22:51:19.362','2026-03-16 22:51:19.362',0,1,NULL,''),
('97847169-2147-11f1-8664-9ace7c5eee11',1,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11','97844a57-2147-11f1-8664-9ace7c5eee11','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-03-16 22:51:19.363','2026-03-16 22:51:19.363',0,2,NULL,''),
('97849881-2147-11f1-8664-9ace7c5eee11',1,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11','9784716b-2147-11f1-8664-9ace7c5eee11','sequentialTask','97849882-2147-11f1-8664-9ace7c5eee11',NULL,'Sequential Task','userTask','5','2026-03-16 22:51:19.364',NULL,NULL,3,NULL,''),
('b9b6104f-2146-11f1-82c2-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b6104e-2146-11f1-82c2-9ace7c5eee11','start',NULL,NULL,'Start','startEvent',NULL,'2026-03-16 22:45:07.234','2026-03-16 22:45:07.237',3,1,NULL,''),
('b9b68580-2146-11f1-82c2-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b6104e-2146-11f1-82c2-9ace7c5eee11','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-03-16 22:45:07.237','2026-03-16 22:45:07.237',0,2,NULL,''),
('b9b68581-2146-11f1-82c2-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b6104e-2146-11f1-82c2-9ace7c5eee11','singleApprovalTask','b9b721c2-2146-11f1-82c2-9ace7c5eee11',NULL,'Single Approval Task','userTask','manager','2026-03-16 22:45:07.237',NULL,NULL,3,NULL,''),
('de0c7bb2-1064-11f1-917d-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f','de0c7bb1-1064-11f1-917d-22842007978f','start',NULL,NULL,'Start','startEvent',NULL,'2026-02-23 11:08:03.333','2026-02-23 11:08:03.334',1,1,NULL,''),
('de0cc9d3-1064-11f1-917d-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f','de0c7bb1-1064-11f1-917d-22842007978f','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-02-23 11:08:03.335','2026-02-23 11:08:03.335',0,2,NULL,''),
('de0d17fb-1064-11f1-917d-22842007978f',1,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f','de0d17f8-1064-11f1-917d-22842007978f','countersignTask','de0d3f0c-1064-11f1-917d-22842007978f',NULL,'Countersign Task','userTask','1','2026-02-23 11:08:03.337',NULL,NULL,3,NULL,''),
('f1f15447-2149-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11','f1f15446-2149-11f1-9281-9ace7c5eee11','start',NULL,NULL,'Start','startEvent',NULL,'2026-03-16 23:08:10.065','2026-03-16 23:08:10.065',0,1,NULL,''),
('f1f15448-2149-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11','f1f15446-2149-11f1-9281-9ace7c5eee11','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-03-16 23:08:10.065','2026-03-16 23:08:10.065',0,2,NULL,''),
('f1f15449-2149-11f1-9281-9ace7c5eee11',1,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11','f1f15446-2149-11f1-9281-9ace7c5eee11','singleApprovalTask','f1f17b5a-2149-11f1-9281-9ace7c5eee11',NULL,'Single Approval Task','userTask','manager','2026-03-16 23:08:10.065',NULL,NULL,3,NULL,''),
('f20ca494-2149-11f1-9281-9ace7c5eee11',1,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20ca493-2149-11f1-9281-9ace7c5eee11','start',NULL,NULL,'Start','startEvent',NULL,'2026-03-16 23:08:10.244','2026-03-16 23:08:10.244',0,1,NULL,''),
('f20ca495-2149-11f1-9281-9ace7c5eee11',1,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20ca493-2149-11f1-9281-9ace7c5eee11','flow1',NULL,NULL,NULL,'sequenceFlow',NULL,'2026-03-16 23:08:10.244','2026-03-16 23:08:10.244',0,2,NULL,''),
('f20ccbad-2149-11f1-9281-9ace7c5eee11',1,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20ccba7-2149-11f1-9281-9ace7c5eee11','sequentialTask','f20ccbae-2149-11f1-9281-9ace7c5eee11',NULL,'Sequential Task','userTask','5','2026-03-16 23:08:10.245',NULL,NULL,3,NULL,'');
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
INSERT INTO `ACT_RU_EXECUTION` VALUES
('53eec341-2151-11f1-9281-9ace7c5eee11',1,'53eec341-2151-11f1-9281-9ace7c5eee11','TEST-VALID-001',NULL,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11',NULL,'53eec341-2151-11f1-9281-9ace7c5eee11',NULL,1,0,1,0,0,1,NULL,'',NULL,'start','2026-03-17 00:01:00.942',NULL,NULL,NULL,1,0,0,0,0,0,0,0,0,0,NULL,NULL,NULL,NULL,NULL,NULL),
('53eeea5e-2151-11f1-9281-9ace7c5eee11',1,'53eec341-2151-11f1-9281-9ace7c5eee11',NULL,'53eec341-2151-11f1-9281-9ace7c5eee11','approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11',NULL,'53eec341-2151-11f1-9281-9ace7c5eee11','singleApprovalTask',1,0,0,0,0,1,NULL,'',NULL,NULL,'2026-03-17 00:01:00.943',NULL,NULL,NULL,1,0,1,0,0,0,0,0,0,0,NULL,NULL,NULL,NULL,NULL,NULL),
('97844a47-2147-11f1-8664-9ace7c5eee11',1,'97844a47-2147-11f1-8664-9ace7c5eee11','TRAVEL-2026-001',NULL,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11',NULL,'97844a47-2147-11f1-8664-9ace7c5eee11',NULL,1,0,1,0,0,1,NULL,'',NULL,'start','2026-03-16 22:51:19.362',NULL,NULL,NULL,1,0,0,0,0,0,0,0,0,0,NULL,NULL,NULL,NULL,NULL,NULL),
('9784716a-2147-11f1-8664-9ace7c5eee11',1,'97844a47-2147-11f1-8664-9ace7c5eee11',NULL,'97844a47-2147-11f1-8664-9ace7c5eee11','approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11',NULL,'97844a47-2147-11f1-8664-9ace7c5eee11','sequentialTask',0,0,0,0,1,1,NULL,'',NULL,NULL,'2026-03-16 22:51:19.363',NULL,NULL,NULL,1,0,0,0,0,0,0,0,3,0,NULL,NULL,NULL,NULL,NULL,NULL),
('9784716b-2147-11f1-8664-9ace7c5eee11',1,'97844a47-2147-11f1-8664-9ace7c5eee11',NULL,'9784716a-2147-11f1-8664-9ace7c5eee11','approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11',NULL,'97844a47-2147-11f1-8664-9ace7c5eee11','sequentialTask',1,0,0,0,0,1,NULL,'',NULL,NULL,'2026-03-16 22:51:19.363',NULL,NULL,NULL,1,0,1,0,0,0,0,0,2,0,NULL,NULL,NULL,NULL,NULL,NULL),
('b9b4146f-2146-11f1-82c2-9ace7c5eee11',1,'b9b4146f-2146-11f1-82c2-9ace7c5eee11','EXP-2026-001',NULL,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11',NULL,'b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,1,0,1,0,0,1,NULL,'',NULL,'start','2026-03-16 22:45:07.221',NULL,NULL,NULL,1,0,0,0,0,0,0,0,0,0,NULL,NULL,NULL,NULL,NULL,NULL),
('b9b6104e-2146-11f1-82c2-9ace7c5eee11',1,'b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,'b9b4146f-2146-11f1-82c2-9ace7c5eee11','approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11',NULL,'b9b4146f-2146-11f1-82c2-9ace7c5eee11','singleApprovalTask',1,0,0,0,0,1,NULL,'',NULL,NULL,'2026-03-16 22:45:07.234',NULL,NULL,NULL,1,0,1,0,0,0,0,0,0,0,NULL,NULL,NULL,NULL,NULL,NULL),
('de0b4325-1064-11f1-917d-22842007978f',1,'de0b4325-1064-11f1-917d-22842007978f','50d9a78c-6a3f-4fb7-a165-f2d336cc8d73',NULL,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f',NULL,'de0b4325-1064-11f1-917d-22842007978f',NULL,1,0,1,0,0,1,NULL,'',NULL,'start','2026-02-23 11:08:03.325',NULL,NULL,NULL,1,0,0,0,0,0,0,0,0,0,NULL,NULL,NULL,NULL,NULL,NULL),
('de0cc9d4-1064-11f1-917d-22842007978f',1,'de0b4325-1064-11f1-917d-22842007978f',NULL,'de0b4325-1064-11f1-917d-22842007978f','approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f',NULL,'de0b4325-1064-11f1-917d-22842007978f','countersignTask',0,0,0,0,1,1,NULL,'',NULL,NULL,'2026-02-23 11:08:03.335',NULL,NULL,NULL,1,0,0,0,0,0,0,0,3,0,NULL,NULL,NULL,NULL,NULL,NULL),
('de0d17f8-1064-11f1-917d-22842007978f',1,'de0b4325-1064-11f1-917d-22842007978f',NULL,'de0cc9d4-1064-11f1-917d-22842007978f','approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f',NULL,'de0b4325-1064-11f1-917d-22842007978f','countersignTask',1,0,0,0,0,1,NULL,'',NULL,NULL,'2026-02-23 11:08:03.337',NULL,NULL,NULL,1,0,1,0,0,0,0,0,2,0,NULL,NULL,NULL,NULL,NULL,NULL),
('f1efa687-2149-11f1-9281-9ace7c5eee11',1,'f1efa687-2149-11f1-9281-9ace7c5eee11','EXP-2026-FINAL',NULL,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11',NULL,'f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,1,0,1,0,0,1,NULL,'',NULL,'start','2026-03-16 23:08:10.054',NULL,NULL,NULL,1,0,0,0,0,0,0,0,0,0,NULL,NULL,NULL,NULL,NULL,NULL),
('f1f15446-2149-11f1-9281-9ace7c5eee11',1,'f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,'f1efa687-2149-11f1-9281-9ace7c5eee11','approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11',NULL,'f1efa687-2149-11f1-9281-9ace7c5eee11','singleApprovalTask',1,0,0,0,0,1,NULL,'',NULL,NULL,'2026-03-16 23:08:10.065',NULL,NULL,NULL,1,0,1,0,0,0,0,0,0,0,NULL,NULL,NULL,NULL,NULL,NULL),
('f20c7d73-2149-11f1-9281-9ace7c5eee11',1,'f20c7d73-2149-11f1-9281-9ace7c5eee11','TRAVEL-2026-FINAL',NULL,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11',NULL,'f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,1,0,1,0,0,1,NULL,'',NULL,'start','2026-03-16 23:08:10.243',NULL,NULL,NULL,1,0,0,0,0,0,0,0,0,0,NULL,NULL,NULL,NULL,NULL,NULL),
('f20ca496-2149-11f1-9281-9ace7c5eee11',1,'f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,'f20c7d73-2149-11f1-9281-9ace7c5eee11','approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11',NULL,'f20c7d73-2149-11f1-9281-9ace7c5eee11','sequentialTask',0,0,0,0,1,1,NULL,'',NULL,NULL,'2026-03-16 23:08:10.244',NULL,NULL,NULL,1,0,0,0,0,0,0,0,3,0,NULL,NULL,NULL,NULL,NULL,NULL),
('f20ccba7-2149-11f1-9281-9ace7c5eee11',1,'f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,'f20ca496-2149-11f1-9281-9ace7c5eee11','approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11',NULL,'f20c7d73-2149-11f1-9281-9ace7c5eee11','sequentialTask',1,0,0,0,0,1,NULL,'',NULL,NULL,'2026-03-16 23:08:10.245',NULL,NULL,NULL,1,0,1,0,0,0,0,0,2,0,NULL,NULL,NULL,NULL,NULL,NULL);
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
INSERT INTO `ACT_RU_IDENTITYLINK` VALUES
('53eeea64-2151-11f1-9281-9ace7c5eee11',1,NULL,'participant','manager',NULL,'53eec341-2151-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL),
('97849884-2147-11f1-8664-9ace7c5eee11',1,NULL,'participant','5',NULL,'97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL),
('b9b76fe4-2146-11f1-82c2-9ace7c5eee11',1,NULL,'participant','manager',NULL,'b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL),
('de0d8d2e-1064-11f1-917d-22842007978f',1,NULL,'participant','1',NULL,'de0b4325-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL),
('f1f1a26c-2149-11f1-9281-9ace7c5eee11',1,NULL,'participant','manager',NULL,'f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL),
('f20cf2c0-2149-11f1-9281-9ace7c5eee11',1,NULL,'participant','5',NULL,'f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL);
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
INSERT INTO `ACT_RU_TASK` VALUES
('53eeea62-2151-11f1-9281-9ace7c5eee11',1,'53eeea5e-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11','approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,'Single Approval Task',NULL,NULL,'singleApprovalTask',NULL,'manager',NULL,50,'2026-03-16 16:01:00.943',NULL,NULL,1,'',NULL,NULL,1,0,0,0),
('97849882-2147-11f1-8664-9ace7c5eee11',1,'9784716b-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11','approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,'Sequential Task',NULL,NULL,'sequentialTask',NULL,'5',NULL,50,'2026-03-16 14:51:19.364',NULL,NULL,1,'',NULL,NULL,1,0,0,0),
('b9b721c2-2146-11f1-82c2-9ace7c5eee11',1,'b9b6104e-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11','approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,'Single Approval Task',NULL,NULL,'singleApprovalTask',NULL,'manager',NULL,50,'2026-03-16 14:45:07.238',NULL,NULL,1,'',NULL,NULL,1,0,0,0),
('de0d3f0c-1064-11f1-917d-22842007978f',1,'de0d17f8-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f','approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL,NULL,'Countersign Task',NULL,NULL,'countersignTask',NULL,'1',NULL,50,'2026-02-23 03:08:03.337',NULL,NULL,1,'',NULL,NULL,1,0,0,0),
('f1f17b5a-2149-11f1-9281-9ace7c5eee11',1,'f1f15446-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11','approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,'Single Approval Task',NULL,NULL,'singleApprovalTask',NULL,'manager',NULL,50,'2026-03-16 15:08:10.065',NULL,NULL,1,'',NULL,NULL,1,0,0,0),
('f20ccbae-2149-11f1-9281-9ace7c5eee11',1,'f20ccba7-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11','approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,'Sequential Task',NULL,NULL,'sequentialTask',NULL,'5',NULL,50,'2026-03-16 15:08:10.245',NULL,NULL,1,'',NULL,NULL,1,0,0,0);
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
INSERT INTO `ACT_RU_VARIABLE` VALUES
('53eec342-2151-11f1-9281-9ace7c5eee11',1,'string','approverId','53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'manager',NULL,NULL),
('53eec343-2151-11f1-9281-9ace7c5eee11',1,'string','countersignMode','53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL),
('53eec344-2151-11f1-9281-9ace7c5eee11',1,'string','businessKey','53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TEST-VALID-001',NULL,NULL),
('53eeea56-2151-11f1-9281-9ace7c5eee11',1,'serializable','countersignUsers','53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,'53eeea55-2151-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL),
('53eeea58-2151-11f1-9281-9ace7c5eee11',1,'integer','requiredApprove','53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL),
('53eeea59-2151-11f1-9281-9ace7c5eee11',1,'integer','approveCount','53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL),
('53eeea5a-2151-11f1-9281-9ace7c5eee11',1,'long','applicantId','53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,5,'5',NULL,NULL),
('53eeea5b-2151-11f1-9281-9ace7c5eee11',1,'string','title','53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Valid Test Request',NULL,NULL),
('53eeea5c-2151-11f1-9281-9ace7c5eee11',1,'integer','rejectCount','53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL),
('53eeea5d-2151-11f1-9281-9ace7c5eee11',1,'string','countersignResult','53eec341-2151-11f1-9281-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'PENDING',NULL,NULL),
('97844a48-2147-11f1-8664-9ace7c5eee11',1,'integer','amount','97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,2500,'2500',NULL,NULL),
('97844a49-2147-11f1-8664-9ace7c5eee11',1,'string','level1Approver','97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'manager',NULL,NULL),
('97844a4a-2147-11f1-8664-9ace7c5eee11',1,'string','countersignMode','97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL),
('97844a4b-2147-11f1-8664-9ace7c5eee11',1,'string','destination','97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Beijing',NULL,NULL),
('97844a4c-2147-11f1-8664-9ace7c5eee11',1,'integer','requiredApprove','97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL),
('97844a4d-2147-11f1-8664-9ace7c5eee11',1,'string','level2Approver','97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'admin',NULL,NULL),
('97844a4e-2147-11f1-8664-9ace7c5eee11',1,'string','title','97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Business Travel Reimbursement',NULL,NULL),
('97844a4f-2147-11f1-8664-9ace7c5eee11',1,'integer','rejectCount','97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL),
('97844a50-2147-11f1-8664-9ace7c5eee11',1,'string','countersignResult','97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'PENDING',NULL,NULL),
('97844a51-2147-11f1-8664-9ace7c5eee11',1,'string','businessKey','97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TRAVEL-2026-001',NULL,NULL),
('97844a53-2147-11f1-8664-9ace7c5eee11',1,'serializable','countersignUsers','97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,'97844a52-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL),
('97844a55-2147-11f1-8664-9ace7c5eee11',1,'integer','approveCount','97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL),
('97844a56-2147-11f1-8664-9ace7c5eee11',1,'long','applicantId','97844a47-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,5,'5',NULL,NULL),
('9784716c-2147-11f1-8664-9ace7c5eee11',1,'integer','nrOfInstances','9784716a-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL),
('9784716d-2147-11f1-8664-9ace7c5eee11',1,'integer','nrOfCompletedInstances','9784716a-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL),
('9784716e-2147-11f1-8664-9ace7c5eee11',1,'integer','nrOfActiveInstances','9784716a-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL),
('9784716f-2147-11f1-8664-9ace7c5eee11',1,'string','countersignUser','9784716b-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'5',NULL,NULL),
('97849880-2147-11f1-8664-9ace7c5eee11',1,'integer','loopCounter','9784716b-2147-11f1-8664-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL),
('b9b43b80-2146-11f1-82c2-9ace7c5eee11',1,'integer','amount','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,500,'500',NULL,NULL),
('b9b46291-2146-11f1-82c2-9ace7c5eee11',1,'string','approverId','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'manager',NULL,NULL),
('b9b46292-2146-11f1-82c2-9ace7c5eee11',1,'string','countersignMode','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL),
('b9b46293-2146-11f1-82c2-9ace7c5eee11',1,'string','businessKey','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'EXP-2026-001',NULL,NULL),
('b9b5e935-2146-11f1-82c2-9ace7c5eee11',1,'serializable','countersignUsers','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,NULL,NULL,'b9b5e934-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL),
('b9b5e937-2146-11f1-82c2-9ace7c5eee11',1,'integer','requiredApprove','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL),
('b9b5e938-2146-11f1-82c2-9ace7c5eee11',1,'string','description','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Office supplies',NULL,NULL),
('b9b5e939-2146-11f1-82c2-9ace7c5eee11',1,'integer','approveCount','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL),
('b9b5e93a-2146-11f1-82c2-9ace7c5eee11',1,'long','applicantId','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,4,'4',NULL,NULL),
('b9b5e93b-2146-11f1-82c2-9ace7c5eee11',1,'string','title','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Expense Reimbursement',NULL,NULL),
('b9b6104c-2146-11f1-82c2-9ace7c5eee11',1,'integer','rejectCount','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL),
('b9b6104d-2146-11f1-82c2-9ace7c5eee11',1,'string','countersignResult','b9b4146f-2146-11f1-82c2-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'PENDING',NULL,NULL),
('de0b4326-1064-11f1-917d-22842007978f',1,'string','countersignMode','de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL),
('de0b6a37-1064-11f1-917d-22842007978f',1,'string','businessKey','de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'50d9a78c-6a3f-4fb7-a165-f2d336cc8d73',NULL,NULL),
('de0c5499-1064-11f1-917d-22842007978f',1,'serializable','countersignUsers','de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,'de0c5498-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL),
('de0c549b-1064-11f1-917d-22842007978f',1,'integer','requiredApprove','de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL),
('de0c549c-1064-11f1-917d-22842007978f',1,'integer','approveCount','de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL),
('de0c549d-1064-11f1-917d-22842007978f',1,'long','applicantId','de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL),
('de0c549e-1064-11f1-917d-22842007978f',1,'string','title','de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Test Request',NULL,NULL),
('de0c549f-1064-11f1-917d-22842007978f',1,'integer','rejectCount','de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL),
('de0c54a0-1064-11f1-917d-22842007978f',1,'string','countersignResult','de0b4325-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'PENDING',NULL,NULL),
('de0cf0e5-1064-11f1-917d-22842007978f',1,'integer','nrOfInstances','de0cc9d4-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL),
('de0cf0e6-1064-11f1-917d-22842007978f',1,'bpmnParallelMultiInstanceCompleted','nrOfCompletedInstances','de0cc9d4-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'de0cc9d4-1064-11f1-917d-22842007978f','completed',NULL),
('de0d17f7-1064-11f1-917d-22842007978f',1,'bpmnParallelMultiInstanceCompleted','nrOfActiveInstances','de0cc9d4-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'de0cc9d4-1064-11f1-917d-22842007978f','active',NULL),
('de0d17f9-1064-11f1-917d-22842007978f',1,'string','countersignUser','de0d17f8-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'1',NULL,NULL),
('de0d17fa-1064-11f1-917d-22842007978f',1,'integer','loopCounter','de0d17f8-1064-11f1-917d-22842007978f','de0b4325-1064-11f1-917d-22842007978f',NULL,NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL),
('f1efa688-2149-11f1-9281-9ace7c5eee11',1,'integer','amount','f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,500,'500',NULL,NULL),
('f1efcd99-2149-11f1-9281-9ace7c5eee11',1,'string','approverId','f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'manager',NULL,NULL),
('f1efcd9a-2149-11f1-9281-9ace7c5eee11',1,'string','countersignMode','f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL),
('f1efcd9b-2149-11f1-9281-9ace7c5eee11',1,'string','businessKey','f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'EXP-2026-FINAL',NULL,NULL),
('f1f12d2d-2149-11f1-9281-9ace7c5eee11',1,'serializable','countersignUsers','f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,'f1f1061c-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL),
('f1f12d2f-2149-11f1-9281-9ace7c5eee11',1,'integer','requiredApprove','f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL),
('f1f12d30-2149-11f1-9281-9ace7c5eee11',1,'string','description','f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Final test - office supplies',NULL,NULL),
('f1f12d31-2149-11f1-9281-9ace7c5eee11',1,'integer','approveCount','f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL),
('f1f12d32-2149-11f1-9281-9ace7c5eee11',1,'long','applicantId','f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,5,'5',NULL,NULL),
('f1f15443-2149-11f1-9281-9ace7c5eee11',1,'string','title','f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Final Test - Office Supplies',NULL,NULL),
('f1f15444-2149-11f1-9281-9ace7c5eee11',1,'integer','rejectCount','f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL),
('f1f15445-2149-11f1-9281-9ace7c5eee11',1,'string','countersignResult','f1efa687-2149-11f1-9281-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'PENDING',NULL,NULL),
('f20c7d74-2149-11f1-9281-9ace7c5eee11',1,'integer','amount','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,2500,'2500',NULL,NULL),
('f20c7d75-2149-11f1-9281-9ace7c5eee11',1,'string','level1Approver','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'manager',NULL,NULL),
('f20c7d76-2149-11f1-9281-9ace7c5eee11',1,'string','countersignMode','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'ALL',NULL,NULL),
('f20c7d77-2149-11f1-9281-9ace7c5eee11',1,'string','destination','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Beijing',NULL,NULL),
('f20c7d78-2149-11f1-9281-9ace7c5eee11',1,'integer','requiredApprove','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL),
('f20c7d79-2149-11f1-9281-9ace7c5eee11',1,'string','level2Approver','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'admin',NULL,NULL),
('f20c7d7a-2149-11f1-9281-9ace7c5eee11',1,'string','title','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Business Trip to Beijing',NULL,NULL),
('f20c7d7b-2149-11f1-9281-9ace7c5eee11',1,'integer','rejectCount','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL),
('f20c7d7c-2149-11f1-9281-9ace7c5eee11',1,'string','countersignResult','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'PENDING',NULL,NULL),
('f20ca48d-2149-11f1-9281-9ace7c5eee11',1,'string','businessKey','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TRAVEL-2026-FINAL',NULL,NULL),
('f20ca48f-2149-11f1-9281-9ace7c5eee11',1,'serializable','countersignUsers','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,'f20ca48e-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL),
('f20ca491-2149-11f1-9281-9ace7c5eee11',1,'integer','approveCount','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL),
('f20ca492-2149-11f1-9281-9ace7c5eee11',1,'long','applicantId','f20c7d73-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,5,'5',NULL,NULL),
('f20ccba8-2149-11f1-9281-9ace7c5eee11',1,'integer','nrOfInstances','f20ca496-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL),
('f20ccba9-2149-11f1-9281-9ace7c5eee11',1,'integer','nrOfCompletedInstances','f20ca496-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL),
('f20ccbaa-2149-11f1-9281-9ace7c5eee11',1,'integer','nrOfActiveInstances','f20ca496-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,1,'1',NULL,NULL),
('f20ccbab-2149-11f1-9281-9ace7c5eee11',1,'string','countersignUser','f20ccba7-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'5',NULL,NULL),
('f20ccbac-2149-11f1-9281-9ace7c5eee11',1,'integer','loopCounter','f20ccba7-2149-11f1-9281-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL,NULL,NULL,NULL,NULL,NULL,0,'0',NULL,NULL);
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
('1','flowable','org/flowable/eventregistry/db/liquibase/flowable-eventregistry-db-changelog.xml','2026-02-08 18:08:52',1,'EXECUTED','9:63268f536c469325acef35970312551b','createTable tableName=FLW_EVENT_DEPLOYMENT; createTable tableName=FLW_EVENT_RESOURCE; createTable tableName=FLW_EVENT_DEFINITION; createIndex indexName=ACT_IDX_EVENT_DEF_UNIQ, tableName=FLW_EVENT_DEFINITION; createTable tableName=FLW_CHANNEL_DEFIN...','',NULL,'4.31.1',NULL,NULL,'0545332071'),
('2','flowable','org/flowable/eventregistry/db/liquibase/flowable-eventregistry-db-changelog.xml','2026-02-08 18:08:52',2,'EXECUTED','9:dcb58b7dfd6dbda66939123a96985536','addColumn tableName=FLW_CHANNEL_DEFINITION; addColumn tableName=FLW_CHANNEL_DEFINITION','',NULL,'4.31.1',NULL,NULL,'0545332071'),
('3','flowable','org/flowable/eventregistry/db/liquibase/flowable-eventregistry-db-changelog.xml','2026-02-08 18:08:52',3,'EXECUTED','9:d0c05678d57af23ad93699991e3bf4f6','customChange','',NULL,'4.31.1',NULL,NULL,'0545332071');
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
-- Table structure for table `biz_request`
--

DROP TABLE IF EXISTS `biz_request`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `biz_request` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `applicant_dept_id` bigint(20) DEFAULT NULL,
  `applicant_id` bigint(20) NOT NULL,
  `applicant_post_id` bigint(20) DEFAULT NULL,
  `business_key` varchar(64) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `current_assignee_id` bigint(20) DEFAULT NULL,
  `current_task_id` varchar(64) DEFAULT NULL,
  `finish_time` datetime(6) DEFAULT NULL,
  `form_instance_id` bigint(20) DEFAULT NULL,
  `is_deleted` int(11) NOT NULL,
  `process_definition_id` varchar(64) NOT NULL,
  `process_instance_id` varchar(64) NOT NULL,
  `status` int(11) NOT NULL,
  `submit_time` datetime(6) DEFAULT NULL,
  `title` varchar(128) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKcqhjge0dnqeujqh4hr876h078` (`business_key`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `biz_request`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `biz_request` WRITE;
/*!40000 ALTER TABLE `biz_request` DISABLE KEYS */;
INSERT INTO `biz_request` VALUES
(1,NULL,2,NULL,'116b414f-6fc9-497f-8b80-36b108425341','2026-02-23 11:18:04.282955',NULL,NULL,'2026-02-23 11:18:04.440361',NULL,0,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','443812b1-1066-11f1-a1f8-22842007978f',3,'2026-02-23 11:18:04.282519','Test Request','2026-02-23 11:18:04.440925'),
(2,NULL,2,NULL,'75bf1537-f6b7-4c65-963d-7a96531e07f6','2026-02-23 11:20:15.802991',NULL,NULL,'2026-02-23 11:20:29.724656',NULL,0,'approvalWorkflow:1:cac729f3-1064-11f1-917d-22842007978f','929d5932-1066-11f1-a1f8-22842007978f',3,'2026-02-23 11:20:15.802693','Test Request','2026-02-23 11:20:29.724899'),
(3,NULL,4,NULL,'EXP-2026-001','2026-03-16 22:45:07.260046',NULL,'b9b721c2-2146-11f1-82c2-9ace7c5eee11',NULL,NULL,0,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','b9b4146f-2146-11f1-82c2-9ace7c5eee11',2,'2026-03-16 22:45:07.259471','Expense Reimbursement','2026-03-16 22:45:07.275114'),
(4,NULL,4,NULL,'TEST-001','2026-03-16 22:49:16.032911',NULL,NULL,'2026-03-16 23:05:36.140098',NULL,0,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','4dfb5f6d-2147-11f1-8664-9ace7c5eee11',2,'2026-03-16 22:49:16.032523','Test','2026-03-16 23:05:36.140475'),
(6,NULL,5,NULL,'TRAVEL-2026-001','2026-03-16 22:51:19.375919',5,'97849882-2147-11f1-8664-9ace7c5eee11',NULL,NULL,0,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11','97844a47-2147-11f1-8664-9ace7c5eee11',2,'2026-03-16 22:51:19.375749','Business Travel Reimbursement','2026-03-16 22:51:19.381554'),
(7,NULL,5,NULL,'EXP-2026-002','2026-03-16 22:52:13.562040',NULL,NULL,'2026-03-16 23:08:10.210543',NULL,0,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','b7d01ce5-2147-11f1-8664-9ace7c5eee11',2,'2026-03-16 22:52:13.561823','Office Supplies','2026-03-16 23:08:10.210863'),
(8,NULL,5,NULL,'EXP-2026-FINAL','2026-03-16 23:08:10.097785',6,'f1f17b5a-2149-11f1-9281-9ace7c5eee11',NULL,NULL,0,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','f1efa687-2149-11f1-9281-9ace7c5eee11',2,'2026-03-16 23:08:10.097415','Final Test - Office Supplies','2026-03-16 23:08:10.117683'),
(9,NULL,5,NULL,'TRAVEL-2026-FINAL','2026-03-16 23:08:10.264536',5,'f20ccbae-2149-11f1-9281-9ace7c5eee11',NULL,NULL,0,'approvalSequential:2:3c6dc13a-2142-11f1-9715-9ace7c5eee11','f20c7d73-2149-11f1-9281-9ace7c5eee11',2,'2026-03-16 23:08:10.264308','Business Trip to Beijing','2026-03-16 23:08:10.275350'),
(10,NULL,5,NULL,'TEST-VALID-001','2026-03-17 00:01:00.952881',6,'53eeea62-2151-11f1-9281-9ace7c5eee11',NULL,NULL,0,'approvalSingle:1:3c6dc13c-2142-11f1-9715-9ace7c5eee11','53eec341-2151-11f1-9281-9ace7c5eee11',2,'2026-03-17 00:01:00.952614','Valid Test Request','2026-03-17 00:01:00.965634');
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
  `action` varchar(32) NOT NULL,
  `business_key` varchar(64) NOT NULL,
  `comment` varchar(512) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `operator_id` bigint(20) NOT NULL,
  `process_instance_id` varchar(64) NOT NULL,
  `task_id` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `biz_request_log`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `biz_request_log` WRITE;
/*!40000 ALTER TABLE `biz_request_log` DISABLE KEYS */;
INSERT INTO `biz_request_log` VALUES
(1,'SUBMIT','116b414f-6fc9-497f-8b80-36b108425341','Êèê‰∫§Áî≥ËØ∑','2026-02-23 11:18:04.302178',2,'443812b1-1066-11f1-a1f8-22842007978f',NULL),
(2,'APPROVE','116b414f-6fc9-497f-8b80-36b108425341','Approved','2026-02-23 11:18:04.433195',2,'443812b1-1066-11f1-a1f8-22842007978f','443a35a8-1066-11f1-a1f8-22842007978f'),
(3,'SUBMIT','75bf1537-f6b7-4c65-963d-7a96531e07f6','Êèê‰∫§Áî≥ËØ∑','2026-02-23 11:20:15.818797',2,'929d5932-1066-11f1-a1f8-22842007978f',NULL),
(4,'APPROVE','75bf1537-f6b7-4c65-963d-7a96531e07f6','Approved','2026-02-23 11:20:29.721888',2,'929d5932-1066-11f1-a1f8-22842007978f','929da769-1066-11f1-a1f8-22842007978f'),
(5,'SUBMIT','EXP-2026-001','Êèê‰∫§Áî≥ËØ∑','2026-03-16 22:45:07.272793',4,'b9b4146f-2146-11f1-82c2-9ace7c5eee11',NULL),
(6,'SUBMIT','TEST-001','Êèê‰∫§Áî≥ËØ∑','2026-03-16 22:49:16.054764',4,'4dfb5f6d-2147-11f1-8664-9ace7c5eee11',NULL),
(7,'SUBMIT','TRAVEL-2026-001','Êèê‰∫§Áî≥ËØ∑','2026-03-16 22:51:19.380900',5,'97844a47-2147-11f1-8664-9ace7c5eee11',NULL),
(8,'SUBMIT','EXP-2026-002','Êèê‰∫§Áî≥ËØ∑','2026-03-16 22:52:13.568434',5,'b7d01ce5-2147-11f1-8664-9ace7c5eee11',NULL),
(9,'APPROVE','TEST-001','Approved - necessary office supplies','2026-03-16 23:05:36.135847',6,'4dfb5f6d-2147-11f1-8664-9ace7c5eee11','4dfdcf7e-2147-11f1-8664-9ace7c5eee11'),
(10,'SUBMIT','EXP-2026-FINAL','Êèê‰∫§Áî≥ËØ∑','2026-03-16 23:08:10.114790',5,'f1efa687-2149-11f1-9281-9ace7c5eee11',NULL),
(11,'APPROVE','EXP-2026-002','Approved - office supplies are necessary for the team','2026-03-16 23:08:10.207326',6,'b7d01ce5-2147-11f1-8664-9ace7c5eee11','b7d04407-2147-11f1-8664-9ace7c5eee11'),
(12,'SUBMIT','TRAVEL-2026-FINAL','Êèê‰∫§Áî≥ËØ∑','2026-03-16 23:08:10.274191',5,'f20c7d73-2149-11f1-9281-9ace7c5eee11',NULL),
(13,'SUBMIT','TEST-VALID-001','Êèê‰∫§Áî≥ËØ∑','2026-03-17 00:01:00.964008',5,'53eec341-2151-11f1-9281-9ace7c5eee11',NULL);
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
  `action` varchar(32) DEFAULT NULL,
  `assignee_id` bigint(20) DEFAULT NULL,
  `business_key` varchar(64) NOT NULL,
  `comment` varchar(512) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `end_time` datetime(6) DEFAULT NULL,
  `owner_id` bigint(20) DEFAULT NULL,
  `process_instance_id` varchar(64) NOT NULL,
  `start_time` datetime(6) DEFAULT NULL,
  `status` int(11) NOT NULL,
  `task_id` varchar(64) NOT NULL,
  `task_name` varchar(128) DEFAULT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK478fyq4qdrfcjikh1oru5iadu` (`task_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `biz_request_task`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `biz_request_task` WRITE;
/*!40000 ALTER TABLE `biz_request_task` DISABLE KEYS */;
INSERT INTO `biz_request_task` VALUES
(1,'APPROVE',2,'116b414f-6fc9-497f-8b80-36b108425341','Approved','2026-02-23 11:18:04.298309','2026-02-23 11:18:04.430094',NULL,'443812b1-1066-11f1-a1f8-22842007978f','2026-02-23 11:18:04.256000',3,'443a35a8-1066-11f1-a1f8-22842007978f','Countersign Task','2026-02-23 11:18:04.440827'),
(2,'APPROVE',2,'75bf1537-f6b7-4c65-963d-7a96531e07f6','Approved','2026-02-23 11:20:15.814344','2026-02-23 11:20:29.719794',NULL,'929d5932-1066-11f1-a1f8-22842007978f','2026-02-23 11:20:15.771000',3,'929da769-1066-11f1-a1f8-22842007978f','Countersign Task','2026-02-23 11:20:29.724843'),
(3,'CREATE',NULL,'EXP-2026-001',NULL,'2026-03-16 22:45:07.269054',NULL,NULL,'b9b4146f-2146-11f1-82c2-9ace7c5eee11','2026-03-16 22:45:07.238000',0,'b9b721c2-2146-11f1-82c2-9ace7c5eee11','Single Approval Task','2026-03-16 22:45:07.269054'),
(4,'APPROVE',6,'TEST-001','Approved - necessary office supplies','2026-03-16 22:49:16.051862','2026-03-16 23:05:36.132457',NULL,'4dfb5f6d-2147-11f1-8664-9ace7c5eee11','2026-03-16 22:49:16.003000',3,'4dfdcf7e-2147-11f1-8664-9ace7c5eee11','Single Approval Task','2026-03-16 23:05:36.140408'),
(5,'CREATE',5,'TRAVEL-2026-001',NULL,'2026-03-16 22:51:19.379317',NULL,NULL,'97844a47-2147-11f1-8664-9ace7c5eee11','2026-03-16 22:51:19.364000',0,'97849882-2147-11f1-8664-9ace7c5eee11','Sequential Task','2026-03-16 22:51:19.379317'),
(6,'APPROVE',6,'EXP-2026-002','Approved - office supplies are necessary for the team','2026-03-16 22:52:13.566801','2026-03-16 23:08:10.204338',NULL,'b7d01ce5-2147-11f1-8664-9ace7c5eee11','2026-03-16 22:52:13.547000',3,'b7d04407-2147-11f1-8664-9ace7c5eee11','Single Approval Task','2026-03-16 23:08:10.210820'),
(7,'CREATE',6,'EXP-2026-FINAL',NULL,'2026-03-16 23:08:10.107551',NULL,NULL,'f1efa687-2149-11f1-9281-9ace7c5eee11','2026-03-16 23:08:10.065000',0,'f1f17b5a-2149-11f1-9281-9ace7c5eee11','Single Approval Task','2026-03-16 23:08:10.107551'),
(8,'CREATE',5,'TRAVEL-2026-FINAL',NULL,'2026-03-16 23:08:10.271853',NULL,NULL,'f20c7d73-2149-11f1-9281-9ace7c5eee11','2026-03-16 23:08:10.245000',0,'f20ccbae-2149-11f1-9281-9ace7c5eee11','Sequential Task','2026-03-16 23:08:10.271853'),
(9,'CREATE',6,'TEST-VALID-001',NULL,'2026-03-17 00:01:00.960046',NULL,NULL,'53eec341-2151-11f1-9281-9ace7c5eee11','2026-03-17 00:01:00.943000',0,'53eeea62-2151-11f1-9281-9ace7c5eee11','Single Approval Task','2026-03-17 00:01:00.960046');
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
  `form_key` varchar(64) NOT NULL,
  `form_name` varchar(128) NOT NULL,
  `status` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKeerpb9vujaxtvpn1jqhq37jqg` (`form_key`)
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
  `field_key` varchar(64) NOT NULL,
  `field_type` varchar(32) NOT NULL,
  `form_version_id` bigint(20) NOT NULL,
  `label` varchar(128) DEFAULT NULL,
  `options_json` text DEFAULT NULL,
  `required` int(11) NOT NULL,
  `validate_rule` text DEFAULT NULL,
  `visible_rule` text DEFAULT NULL,
  PRIMARY KEY (`id`)
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
  `business_key` varchar(64) NOT NULL,
  `data_json` text NOT NULL,
  `form_version_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`)
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
  `schema_json` text NOT NULL,
  `version` int(11) NOT NULL,
  PRIMARY KEY (`id`)
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
  `dept_name` varchar(64) NOT NULL,
  `parent_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_dept`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_dept` WRITE;
/*!40000 ALTER TABLE `sys_dept` DISABLE KEYS */;
INSERT INTO `sys_dept` VALUES
(1,'HR Department',NULL),
(2,'IT Department',1),
(3,'Sales Department',NULL);
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
  `ip_address` varchar(64) DEFAULT NULL,
  `login_status` int(11) NOT NULL,
  `login_time` datetime(6) DEFAULT NULL,
  `message` varchar(512) DEFAULT NULL,
  `user_agent` varchar(512) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `username` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_login_log`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_login_log` WRITE;
/*!40000 ALTER TABLE `sys_login_log` DISABLE KEYS */;
INSERT INTO `sys_login_log` VALUES
(1,'127.0.0.1',1,'2026-03-16 22:16:01.081036','user not found','curl/8.19.0',NULL,'admin'),
(2,'127.0.0.1',1,'2026-03-16 22:16:01.299678','user not found','curl/8.19.0',NULL,'john'),
(3,'127.0.0.1',1,'2026-03-16 22:16:52.586634','invalid password','curl/8.19.0',NULL,'testuser1'),
(4,'127.0.0.1',1,'2026-03-16 22:16:52.608072','invalid password','curl/8.19.0',NULL,'testuser1'),
(5,'127.0.0.1',1,'2026-03-16 22:16:52.640274','invalid password','curl/8.19.0',NULL,'testuser1'),
(6,'127.0.0.1',1,'2026-03-16 22:16:52.668041','invalid password','curl/8.19.0',NULL,'testuser1'),
(7,'127.0.0.1',1,'2026-03-16 22:16:52.690914','invalid password','curl/8.19.0',NULL,'testuser1'),
(8,'127.0.0.1',1,'2026-03-16 22:21:25.158836','user not found','curl/8.19.0',NULL,'admin'),
(9,'127.0.0.1',1,'2026-03-16 22:21:25.368765','user not found','curl/8.19.0',NULL,'john'),
(10,'127.0.0.1',0,'2026-03-16 22:33:01.876307','login successful','curl/8.19.0',4,'admin'),
(11,'127.0.0.1',0,'2026-03-16 22:36:13.140303','login successful','curl/8.19.0',4,'admin'),
(12,'127.0.0.1',0,'2026-03-16 22:36:13.624667','login successful','curl/8.19.0',5,'john'),
(13,'127.0.0.1',0,'2026-03-16 22:38:08.137695','login successful','curl/8.19.0',4,'admin'),
(14,'127.0.0.1',0,'2026-03-16 22:38:08.229639','login successful','curl/8.19.0',5,'john'),
(15,'127.0.0.1',0,'2026-03-16 22:40:18.970311','login successful','curl/8.19.0',4,'admin'),
(16,'127.0.0.1',0,'2026-03-16 22:41:34.219743','login successful','curl/8.19.0',4,'admin'),
(17,'127.0.0.1',0,'2026-03-16 22:44:06.161182','login successful','curl/8.19.0',4,'admin'),
(18,'127.0.0.1',0,'2026-03-16 22:45:07.146735','login successful','curl/8.19.0',4,'admin'),
(19,'127.0.0.1',0,'2026-03-16 22:49:15.804478','login successful','curl/8.19.0',4,'admin'),
(20,'127.0.0.1',0,'2026-03-16 22:51:19.092295','login successful','curl/8.19.0',4,'admin'),
(21,'127.0.0.1',0,'2026-03-16 22:51:19.185384','login successful','curl/8.19.0',5,'john'),
(22,'127.0.0.1',0,'2026-03-16 22:52:13.518990','login successful','curl/8.19.0',5,'john'),
(23,'127.0.0.1',0,'2026-03-16 22:52:46.754344','login successful','curl/8.19.0',4,'admin'),
(24,'127.0.0.1',0,'2026-03-16 22:54:03.557609','login successful','curl/8.19.0',4,'admin'),
(25,'127.0.0.1',0,'2026-03-16 23:04:56.359917','login successful','curl/8.19.0',4,'admin'),
(26,'127.0.0.1',0,'2026-03-16 23:05:35.995691','login successful','curl/8.19.0',4,'admin'),
(27,'127.0.0.1',0,'2026-03-16 23:08:09.922844','login successful','curl/8.19.0',4,'admin'),
(28,'127.0.0.1',0,'2026-03-16 23:08:10.021098','login successful','curl/8.19.0',5,'john'),
(29,'127.0.0.1',0,'2026-03-17 00:00:12.666279','login successful','curl/8.19.0',5,'john'),
(30,'127.0.0.1',0,'2026-03-17 00:00:23.170032','login successful','curl/8.19.0',5,'john'),
(31,'127.0.0.1',0,'2026-03-17 00:01:00.895676','login successful','curl/8.19.0',5,'john'),
(42,'0:0:0:0:0:0:0:1',1,'2026-03-19 12:17:07.139419','invalid password','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36',NULL,'admin'),
(43,'0:0:0:0:0:0:0:1',1,'2026-03-19 12:17:11.139717','invalid password','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36',NULL,'admin'),
(44,'0:0:0:0:0:0:0:1',1,'2026-03-19 12:17:22.021434','invalid password','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36',NULL,'admin');
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
  UNIQUE KEY `UK2yyh4977y7ri5rdciukg2k6ij` (`post_code`)
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
  `status` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKjqdita2l45v2gglry7bp8kl1f` (`role_code`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_role`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_role` WRITE;
/*!40000 ALTER TABLE `sys_role` DISABLE KEYS */;
INSERT INTO `sys_role` VALUES
(1,'ADMIN','System Administrator',1),
(2,'MANAGER','Department Manager',1),
(3,'EMPLOYEE','Employee',1);
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
  `dept_id` bigint(20) DEFAULT NULL,
  `role_id` bigint(20) NOT NULL,
  `scope_type` varchar(32) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
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
  `dept_id` bigint(20) DEFAULT NULL,
  `password` varchar(128) DEFAULT NULL,
  `status` int(11) NOT NULL,
  `username` varchar(64) NOT NULL,
  `last_login_at` datetime(6) DEFAULT NULL,
  `locked_until` datetime(6) DEFAULT NULL,
  `login_failures` int(11) NOT NULL DEFAULT 0,
  `recovery_codes` varchar(512) DEFAULT NULL,
  `two_factor_enabled` int(11) NOT NULL DEFAULT 0,
  `two_factor_secret` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK51bvuyvihefoh4kp5syh2jpi4` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_user`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_user` WRITE;
/*!40000 ALTER TABLE `sys_user` DISABLE KEYS */;
INSERT INTO `sys_user` VALUES
(4,NULL,'$2a$10$sS1i.h95iK4zcsLRT6iXAe4pcyNs32V.WmrUg.xs00gNypXlixq/m',1,'admin','2026-03-16 23:08:09.919345',NULL,3,NULL,0,NULL),
(5,2,'$2a$10$hRxJy/QUVUpLWQlIeL8ud.6cIuxrJBjqEjczZ0QeoWe6JezLKZtMy',1,'john','2026-03-17 00:01:00.887620',NULL,0,NULL,0,NULL),
(6,2,'$2a$10$8zbcHMFfrpZ9caf6EmNKl.YaXdOZcTxT7RBeExZxiARLBbUh7rSv2',1,'manager',NULL,NULL,0,NULL,0,NULL);
/*!40000 ALTER TABLE `sys_user` ENABLE KEYS */;
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
  `post_id` bigint(20) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sys_user_post_user_post` (`user_id`,`post_id`)
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
  `role_id` bigint(20) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sys_user_role_user_role` (`user_id`,`role_id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_user_role`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sys_user_role` WRITE;
/*!40000 ALTER TABLE `sys_user_role` DISABLE KEYS */;
INSERT INTO `sys_user_role` VALUES
(2,1,4),
(4,3,4),
(5,3,5),
(3,2,6),
(6,3,6);
/*!40000 ALTER TABLE `sys_user_role` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Dumping events for database 'approval_system'
--

--
-- Dumping routines for database 'approval_system'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2026-03-22 20:32:37
