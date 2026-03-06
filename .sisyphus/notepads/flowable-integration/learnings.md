# Flowable Integration Learnings

## 2026-02-08 - Flowable Integration Complete

### Key Learnings

#### 1. Flowable Version Compatibility
- **Flowable 6.8.0** uses `javax.*` namespace (not compatible with Spring Boot 3.x)
- **Flowable 7.0.0.M2** uses `jakarta.*` namespace (required for Spring Boot 3.x)
- Always check namespace compatibility when integrating with Spring Boot 3+

#### 2. MySQL Configuration
- Password in YAML must be quoted if it contains only numbers: `password: "000001"`
- Flowable 7.x uses Liquibase for database schema management
- Database must exist before application starts: `CREATE DATABASE approval_system`

#### 3. BPMN Process Design
- Keep BPMN files simple - avoid unnecessary listeners
- ScriptTaskListener requires a script field which was causing errors
- Removed `<flowable:taskListener>` element to fix deployment issues
- Process ID must match the key used in `runtimeService.startProcessInstanceByKey()`

#### 4. Auto-Configuration
- Flowable Spring Boot starter auto-configures:
  - ProcessEngine bean
  - RuntimeService, TaskService, RepositoryService beans
  - Database schema creation (with `create-drop`)
  - Process deployment from `processes/` folder
- No manual bean configuration needed

#### 5. REST API Testing
- Application needs time to start (15-20 seconds with Flowable)
- Use `--noproxy localhost` with curl to avoid proxy issues
- All 5 verification scenarios passed successfully

### Successful Pattern
```java
@Service
@RequiredArgsConstructor
public class WorkflowService {
    private final RuntimeService runtimeService;
    private final TaskService taskService;
    
    public String startApprovalProcess(String requestId, String requester, BigDecimal amount) {
        Map<String, Object> variables = new HashMap<>();
        variables.put("requestId", requestId);
        variables.put("requester", requester);
        variables.put("amount", amount);
        
        ProcessInstance processInstance = runtimeService
            .startProcessInstanceByKey("approvalWorkflow", variables);
        
        return processInstance.getId();
    }
}
```

### API Endpoints
- POST `/api/workflow/start` - Returns processInstanceId
- GET `/api/workflow/tasks?assignee=reviewer` - Returns task list
- POST `/api/workflow/tasks/{taskId}/complete` - Completes task

### Commits
1. 05512e7 - chore(deps): add Flowable process engine dependency
2. 841a62b - feat(config): add Flowable database configuration
3. e87e510 - feat(process): add sample approval workflow BPMN
4. 1681c9a - feat(service): add workflow service layer
5. b299422 - feat(api): add workflow REST controller
6. 16ad071 - fix(bpmn): remove script listener from approval workflow

### Status: ✅ COMPLETE (43/43 tasks)
All tasks completed successfully. Flowable BPMN Process Engine integrated with Spring Boot 3.5.10 and MySQL.

**Completed on**: 2026-02-08
**Total Commits**: 6
**Verification Scenarios**: 5/5 passed
