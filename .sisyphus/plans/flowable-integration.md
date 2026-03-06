# Flowable Integration for Spring Boot

## TL;DR

> **Quick Summary**: Integrate Flowable BPMN Process Engine into the Spring Boot 3.5.10 approval-system project with MySQL database. Includes a working sample approval workflow.
> 
> **Deliverables**:
> - Flowable dependencies configured in pom.xml
> - MySQL database schema configured for Flowable tables
> - Sample BPMN approval workflow (submit → review → approve/reject)
> - Service layer for process operations (start, query tasks, complete)
> - REST controller demonstrating workflow usage
> - Verification that Flowable engine starts and processes deploy
> 
> **Estimated Effort**: Medium (2-3 hours)
> **Parallel Execution**: NO - Sequential (dependencies between tasks)
> **Critical Path**: Dependencies → Configuration → BPMN → Service → Controller → Verification

---

## Context

### Original Request
Add Flowable support to a new Spring Boot project for workflow management.

### Interview Summary
**Key Discussions**:
- **Engine Type**: Process Engine only (BPMN workflows), excluding DMN/CMMN/IDM
- **API Style**: Java API only, no Flowable REST endpoints needed
- **Database**: MySQL (already configured in project)
- **Sample Content**: Simple approval workflow as a working example
- **Project Stack**: Spring Boot 3.5.10, Java 17, Maven, MySQL connector present

### Technical Decisions
- **Dependency**: `flowable-spring-boot-starter-process` (lightweight, process-only)
- **Version**: Flowable 6.8.0 (compatible with Spring Boot 3.x)
- **Schema Management**: `create-drop` for development, auto-creates Flowable tables
- **Process Location**: `src/main/resources/processes/` (Flowable convention)

---

## Work Objectives

### Core Objective
Integrate Flowable BPMN Process Engine into the existing Spring Boot project with proper MySQL configuration and a working approval workflow sample.

### Concrete Deliverables
1. `pom.xml` - Flowable dependency added
2. `src/main/resources/application.yml` - Flowable datasource configuration
3. `src/main/resources/processes/approval-workflow.bpmn20.xml` - Sample BPMN process
4. `src/main/java/com/flowablecollab/approvalsystem/service/WorkflowService.java` - Process operations service
5. `src/main/java/com/flowablecollab/approvalsystem/controller/WorkflowController.java` - REST endpoints

### Definition of Done
- [x] Application starts without errors
- [x] Flowable tables created in MySQL database
- [x] Sample BPMN process auto-deploys on startup
- [x] Can start a process instance via API
- [x] Can query and complete tasks via API

### Must Have
- Flowable Process Engine configured with MySQL
- Working BPMN approval workflow (2-3 steps)
- Service layer exposing: startProcess, getTasks, completeTask
- REST controller with endpoints for workflow operations

### Must NOT Have (Guardrails)
- Flowable REST API endpoints (disabled)
- DMN/CMMN/IDM engines (not needed)
- Flowable UI components
- Complex workflow features (timers, signals, messages)
- Production-grade schema management (staying with create-drop)

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: YES - `spring-boot-starter-test` present in pom.xml
- **Automated tests**: NO - No unit tests included (focus on integration verification)
- **Verification Method**: Agent-Executed QA Scenarios via curl and log inspection

### Agent-Executed QA Scenarios

**Scenario 1: Verify Flowable Engine Starts Successfully**
```
Tool: Bash (log inspection)
Preconditions: MySQL running, application.yml configured
Steps:
  1. Start Spring Boot application: ./mvnw spring-boot:run
  2. Wait for startup (timeout: 60s)
  3. Check logs for: "ProcessEngine default created"
  4. Check logs for: "deployed process definition 'approvalWorkflow'"
  5. Query MySQL: SHOW TABLES LIKE 'act_%' → Should return 20+ Flowable tables
Expected Result: Application starts, Flowable engine initialized, process deployed
Evidence: Application logs saved to .sisyphus/evidence/flowable-startup.log
```

**Scenario 2: Start Approval Process via API**
```
Tool: Bash (curl)
Preconditions: Application running on port 8080
Steps:
  1. POST http://localhost:8080/api/workflow/start \
     -H "Content-Type: application/json" \
     -d '{"requestId":"REQ-001","requester":"john.doe","amount":5000}'
  2. Assert: HTTP status 200
  3. Assert: Response contains "processInstanceId" field
  4. Capture: processInstanceId value for next scenario
Expected Result: Process started successfully, returns process instance ID
Evidence: Response body saved to .sisyphus/evidence/start-process-response.json
```

**Scenario 3: Query Pending Tasks**
```
Tool: Bash (curl)
Preconditions: Process instance created in Scenario 2
Steps:
  1. GET http://localhost:8080/api/workflow/tasks?assignee=reviewer
  2. Assert: HTTP status 200
  3. Assert: Response array has 1 task
  4. Assert: Task name contains "Review" or "审批"
  5. Capture: taskId value for next scenario
Expected Result: Returns list with one pending review task
Evidence: Response saved to .sisyphus/evidence/tasks-response.json
```

**Scenario 4: Complete Review Task (Approve)**
```
Tool: Bash (curl)
Preconditions: Task ID from Scenario 3
Steps:
  1. POST http://localhost:8080/api/workflow/tasks/{taskId}/complete \
     -H "Content-Type: application/json" \
     -d '{"approved":true,"comments":"Approved by manager"}'
  2. Assert: HTTP status 200
  3. Assert: Response contains "completed":true
Expected Result: Task completed, process moves to next step or ends
Evidence: Response saved to .sisyphus/evidence/complete-task-response.json
```

**Scenario 5: Query Tasks After Completion**
```
Tool: Bash (curl)
Preconditions: Task completed in Scenario 4
Steps:
  1. GET http://localhost:8080/api/workflow/tasks?assignee=reviewer
  2. Assert: HTTP status 200
  3. Assert: Response array is empty (or has next task if multi-step)
Expected Result: No pending tasks for reviewer (process completed or moved forward)
Evidence: Response saved to .sisyphus/evidence/tasks-after-completion.json
```

---

## Execution Strategy

### Sequential Execution (No Parallel Tasks)
All tasks have dependencies and must run sequentially:

```
Task 1: Add Dependencies
    ↓
Task 2: Configure Database
    ↓
Task 3: Create BPMN Process
    ↓
Task 4: Create Service Layer
    ↓
Task 5: Create Controller
    ↓
Task 6: Verification & QA
```

### Dependency Matrix
| Task | Depends On | Blocks | Can Parallelize With |
|------|------------|--------|---------------------|
| 1 | None | 2 | None |
| 2 | 1 | 3 | None |
| 3 | 2 | 4 | None |
| 4 | 3 | 5 | None |
| 5 | 4 | 6 | None |
| 6 | 5 | None | None |

---

## TODOs

### Task 1: Add Flowable Dependencies to pom.xml

**What to do**:
- Add `flowable-spring-boot-starter-process` dependency (version 6.8.0)
- Add MySQL connector (if not already scoped correctly)
- Verify no version conflicts with Spring Boot 3.5.10

**Must NOT do**:
- Do NOT add `flowable-spring-boot-starter` (includes all engines, too heavy)
- Do NOT add `flowable-spring-boot-starter-rest` (REST API not needed)

**Recommended Agent Profile**:
- **Category**: `quick`
- **Skills**: `git-master`
- **Reason**: Simple dependency addition, low complexity

**Parallelization**:
- **Can Run In Parallel**: NO
- **Blocks**: Task 2
- **Blocked By**: None

**References**:
- `pom.xml:32-57` - Current dependencies section
- Flowable docs: https://www.flowable.com/open-source/docs/bpmn/ch05a-Spring-Boot
- Pattern: Add dependency in `<dependencies>` section

**Acceptance Criteria**:
- [x] `flowable-spring-boot-starter-process:6.8.0` added to pom.xml
- [x] `mvn dependency:tree | grep flowable` shows Flowable dependencies
- [x] No dependency conflicts in build

**Agent-Executed QA**:
```
Scenario: Verify Flowable dependencies resolved
  Tool: Bash
  Steps:
    1. Run: mvn dependency:resolve
    2. Run: mvn dependency:tree | grep flowable
    3. Assert: Output contains "flowable-spring-boot-starter-process"
    4. Assert: No ERROR lines in output
  Expected Result: Dependencies resolved successfully
```

**Commit**: YES
- Message: `chore(deps): add Flowable process engine dependency`
- Files: `pom.xml`
- Pre-commit: `mvn dependency:resolve` must pass

---

### Task 2: Configure Flowable Database in application.yml

**What to do**:
- Add Flowable-specific datasource configuration (reuse existing MySQL)
- Configure schema update strategy: `create-drop` for development
- Disable REST API (not needed)
- Set process definition location

**Must NOT do**:
- Do NOT create separate datasource (use existing)
- Do NOT use `true` for schema update in production (security risk)

**Recommended Agent Profile**:
- **Category**: `quick`
- **Skills**: None needed
- **Reason**: Configuration file editing only

**Parallelization**:
- **Can Run In Parallel**: NO
- **Blocks**: Task 3
- **Blocked By**: Task 1

**References**:
- `src/main/resources/application.yml` - Current configuration
- Flowable property reference: https://www.flowable.com/open-source/docs/bpmn/ch05a-Spring-Boot
- Key properties:
  - `flowable.database-schema-update: create-drop`
  - `flowable.process.definition-location-prefix: classpath:/processes/`
  - `flowable.rest.api.enabled: false`

**Acceptance Criteria**:
- [x] Flowable configuration added to application.yml
- [x] Database URL points to existing MySQL instance
- [x] Schema update set to `create-drop` (development only)
- [x] REST API explicitly disabled

**Agent-Executed QA**:
```
Scenario: Verify Flowable configuration loaded
  Tool: Bash
  Steps:
    1. Start application: ./mvnw spring-boot:run &
    2. Wait for startup (timeout: 30s)
    3. Check logs: grep "ProcessEngine" logs
    4. Assert: Log contains "ProcessEngine default created"
    5. Query MySQL: SHOW TABLES LIKE 'act_%' | wc -l
    6. Assert: Table count > 20
  Expected Result: Flowable engine initialized with MySQL tables
  Evidence: .sisyphus/evidence/flowable-tables.log
```

**Commit**: YES
- Message: `feat(config): add Flowable database configuration`
- Files: `src/main/resources/application.yml`
- Pre-commit: Application starts without errors

---

### Task 3: Create Sample Approval BPMN Process

**What to do**:
- Create `src/main/resources/processes/` directory
- Create `approval-workflow.bpmn20.xml` with simple approval flow:
  - Start → Submit Request → Review Task → Gateway (Approve/Reject) → End
- Use BPMN 2.0 standard elements only
- Include task assignee: "reviewer"
- Include process variables: requestId, requester, amount

**Must NOT do**:
- Do NOT use advanced BPMN features (signals, events, timers)
- Do NOT make process too complex (keep it simple for demo)

**Recommended Agent Profile**:
- **Category**: `unspecified-medium`
- **Skills**: None needed
- **Reason**: XML file creation following BPMN 2.0 spec

**Parallelization**:
- **Can Run In Parallel**: NO
- **Blocks**: Task 4
- **Blocked By**: Task 2

**References**:
- BPMN 2.0 specification elements
- Flowable docs: Process definition deployment
- Example structure:
  ```xml
  <definitions>
    <process id="approvalWorkflow" name="Approval Workflow">
      <startEvent id="start" />
      <sequenceFlow sourceRef="start" targetRef="submitTask" />
      <userTask id="submitTask" name="Submit Request" />
      <sequenceFlow sourceRef="submitTask" targetRef="reviewTask" />
      <userTask id="reviewTask" name="Review Request" flowable:assignee="reviewer" />
      <exclusiveGateway id="decision" />
      <sequenceFlow sourceRef="reviewTask" targetRef="decision" />
      <sequenceFlow sourceRef="decision" targetRef="approveEnd" name="Approve">
        <conditionExpression>${approved == true}</conditionExpression>
      </sequenceFlow>
      <sequenceFlow sourceRef="decision" targetRef="rejectEnd" name="Reject">
        <conditionExpression>${approved == false}</conditionExpression>
      </sequenceFlow>
      <endEvent id="approveEnd" name="Approved" />
      <endEvent id="rejectEnd" name="Rejected" />
    </process>
  </definitions>
  ```

**Acceptance Criteria**:
- [x] BPMN file created at `src/main/resources/processes/approval-workflow.bpmn20.xml`
- [x] Valid BPMN 2.0 XML structure
- [x] Process ID: `approvalWorkflow`
- [x] Contains: start, user tasks, gateway, end events
- [x] Task assignee set to "reviewer"

**Agent-Executed QA**:
```
Scenario: Verify BPMN process deploys
  Tool: Bash
  Steps:
    1. Start application
    2. Check logs for: grep -i "approvalWorkflow" logs
    3. Assert: Log contains "deployed process definition 'approvalWorkflow'"
    4. Query MySQL: SELECT * FROM act_re_procdef WHERE KEY_ = 'approvalWorkflow'
    5. Assert: Query returns 1 row
  Expected Result: Process definition deployed and stored in database
  Evidence: Deployment log saved
```

**Commit**: YES
- Message: `feat(process): add sample approval workflow BPMN`
- Files: `src/main/resources/processes/approval-workflow.bpmn20.xml`
- Pre-commit: Valid XML structure, application starts

---

### Task 4: Create Workflow Service Layer

**What to do**:
- Create `WorkflowService.java` with methods:
  - `startApprovalProcess(String requestId, String requester, BigDecimal amount)` → returns processInstanceId
  - `getTasksForAssignee(String assignee)` → returns List<Task>
  - `completeTask(String taskId, Map<String, Object> variables)` → void
- Inject Flowable services: RuntimeService, TaskService
- Handle exceptions gracefully
- Add logging

**Must NOT do**:
- Do NOT expose Flowable internals in method signatures
- Do NOT create business logic here (just workflow orchestration)

**Recommended Agent Profile**:
- **Category**: `unspecified-medium`
- **Skills**: None needed
- **Reason**: Standard Spring service implementation

**Parallelization**:
- **Can Run In Parallel**: NO
- **Blocks**: Task 5
- **Blocked By**: Task 3

**References**:
- Flowable services API: RuntimeService, TaskService
- Pattern: Service layer in `com.flowablecollab.approvalsystem.service` package
- Example method signatures:
  ```java
  public String startApprovalProcess(String requestId, String requester, BigDecimal amount)
  public List<TaskInfo> getTasksForAssignee(String assignee)
  public void completeTask(String taskId, boolean approved, String comments)
  ```

**Acceptance Criteria**:
- [x] `WorkflowService.java` created in `service` package
- [x] `RuntimeService` and `TaskService` injected via constructor
- [x] `startApprovalProcess` method implemented
- [x] `getTasksForAssignee` method implemented
- [x] `completeTask` method implemented
- [x] All methods have proper logging

**Agent-Executed QA**:
```
Scenario: Verify service methods work
  Tool: Bash (curl via controller - depends on Task 5)
  Note: Full verification in Task 6
  Steps:
    1. Verify service class compiles: mvn compile
    2. Verify no compilation errors
  Expected Result: Service compiles successfully
```

**Commit**: YES
- Message: `feat(service): add workflow service layer`
- Files: `src/main/java/com/flowablecollab/approvalsystem/service/WorkflowService.java`
- Pre-commit: `mvn compile` passes

---

### Task 5: Create REST Controller for Workflow

**What to do**:
- Create `WorkflowController.java` with endpoints:
  - `POST /api/workflow/start` - Start approval process
  - `GET /api/workflow/tasks` - Get tasks for assignee (query param: assignee)
  - `POST /api/workflow/tasks/{taskId}/complete` - Complete a task
- Use `WorkflowService` for business logic
- Return proper HTTP status codes
- Include error handling

**Must NOT do**:
- Do NOT expose Flowable API directly (use service layer)
- Do NOT skip input validation

**Recommended Agent Profile**:
- **Category**: `unspecified-medium`
- **Skills**: None needed
- **Reason**: Standard Spring REST controller

**Parallelization**:
- **Can Run In Parallel**: NO
- **Blocks**: Task 6
- **Blocked By**: Task 4

**References**:
- Spring Boot @RestController pattern
- Existing controller structure in project (if any)
- Endpoint design:
  ```java
  @PostMapping("/api/workflow/start")
  public ResponseEntity<StartProcessResponse> startProcess(@RequestBody StartProcessRequest request)
  
  @GetMapping("/api/workflow/tasks")
  public ResponseEntity<List<TaskInfo>> getTasks(@RequestParam String assignee)
  
  @PostMapping("/api/workflow/tasks/{taskId}/complete")
  public ResponseEntity<Void> completeTask(@PathVariable String taskId, @RequestBody CompleteTaskRequest request)
  ```

**Acceptance Criteria**:
- [x] `WorkflowController.java` created in `controller` package
- [x] All three endpoints implemented
- [x] Uses `WorkflowService` for operations
- [x] Returns proper HTTP codes (200, 400, 404, 500)
- [x] Request/Response DTOs created

**Agent-Executed QA**:
```
Scenario: Verify controller endpoints accessible
  Tool: Bash (curl)
  Steps:
    1. Start application
    2. GET http://localhost:8080/actuator/health
    3. Assert: Status UP
    4. Test POST /api/workflow/start with sample data
    5. Assert: Returns 200 with processInstanceId
  Expected Result: Controller endpoints working
  Evidence: Curl responses saved
```

**Commit**: YES
- Message: `feat(api): add workflow REST controller`
- Files: `src/main/java/com/flowablecollab/approvalsystem/controller/WorkflowController.java`
- Pre-commit: `mvn test-compile` passes

---

### Task 6: End-to-End Verification

**What to do**:
- Run complete workflow test scenario:
  1. Start application
  2. Start a process via API
  3. Query tasks for reviewer
  4. Complete the review task (approve)
  5. Verify process completed
- Capture all evidence
- Document any issues

**Must NOT do**:
- Do NOT skip verification steps
- Do NOT ignore errors in logs

**Recommended Agent Profile**:
- **Category**: `unspecified-medium`
- **Skills**: None needed
- **Reason**: Integration testing and verification

**Parallelization**:
- **Can Run In Parallel**: NO
- **Blocks**: None (final task)
- **Blocked By**: Task 5

**References**:
- All previous tasks
- Test scenarios defined in Verification Strategy section

**Acceptance Criteria**:
- [x] Application starts successfully
- [x] Flowable tables created in MySQL
- [x] BPMN process auto-deployed
- [x] Can start process via POST /api/workflow/start
- [x] Can query tasks via GET /api/workflow/tasks
- [x] Can complete task via POST /api/workflow/tasks/{id}/complete
- [x] All evidence captured in .sisyphus/evidence/

**Agent-Executed QA** (execute all scenarios from Verification Strategy):
```
Execute ALL 5 scenarios defined in Verification Strategy section:
- Scenario 1: Verify Flowable Engine Starts Successfully
- Scenario 2: Start Approval Process via API
- Scenario 3: Query Pending Tasks
- Scenario 4: Complete Review Task (Approve)
- Scenario 5: Query Tasks After Completion

All scenarios must PASS for task completion.
```

**Commit**: YES
- Message: `feat(verification): complete Flowable integration verification`
- Files: None (verification only)
- Pre-commit: All verification scenarios pass

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 1 | `chore(deps): add Flowable process engine dependency` | pom.xml | mvn dependency:resolve |
| 2 | `feat(config): add Flowable database configuration` | application.yml | Application starts |
| 3 | `feat(process): add sample approval workflow BPMN` | approval-workflow.bpmn20.xml | BPMN valid, deploys |
| 4 | `feat(service): add workflow service layer` | WorkflowService.java | mvn compile |
| 5 | `feat(api): add workflow REST controller` | WorkflowController.java | mvn test-compile |
| 6 | `feat(verification): complete Flowable integration verification` | - | All scenarios pass |

---

## Success Criteria

### Verification Commands
```bash
# 1. Verify dependencies
mvn dependency:tree | grep flowable

# 2. Build the project
mvn clean package -DskipTests

# 3. Start application
./mvnw spring-boot:run

# 4. Test endpoints (in another terminal)
curl -X POST http://localhost:8080/api/workflow/start \
  -H "Content-Type: application/json" \
  -d '{"requestId":"TEST-001","requester":"test.user","amount":1000}'

# 5. Check database
mysql -u root -p -e "USE approval_system; SHOW TABLES LIKE 'act_%';"
```

### Final Checklist
- [x] All dependencies resolved (Task 1)
- [x] Database configured correctly (Task 2)
- [x] BPMN process deployed (Task 3)
- [x] Service layer functional (Task 4)
- [x] Controller endpoints working (Task 5)
- [x] End-to-end workflow verified (Task 6)
- [x] All commits follow conventional format
- [x] Evidence captured in .sisyphus/evidence/

---

## Additional Notes

### Database Schema
Flowable will auto-create these table categories:
- `act_ge_*` - General data (resources, properties)
- `act_re_*` - Repository data (deployments, process definitions)
- `act_ru_*` - Runtime data (executions, tasks, variables)
- `act_hi_*` - History data (completed processes, tasks)

### Useful Queries
```sql
-- List all Flowable tables
SHOW TABLES LIKE 'act_%';

-- Check deployed processes
SELECT ID_, KEY_, NAME_, VERSION_ FROM act_re_procdef;

-- Check running process instances
SELECT ID_, PROC_DEF_ID_, START_TIME_ FROM act_ru_execution;

-- Check pending tasks
SELECT ID_, NAME_, ASSIGNEE_, CREATE_TIME_ FROM act_ru_task;
```

### Troubleshooting
- **Tables not created**: Check `flowable.database-schema-update` property
- **Process not deployed**: Verify BPMN file is in `processes/` folder
- **Connection errors**: Verify MySQL is running and credentials correct
