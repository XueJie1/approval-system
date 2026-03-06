# Draft: Flowable Integration Planning

## Research Findings

### Flowable Spring Boot Integration Options

Based on research, there are several starter options for Flowable:

1. **flowable-spring-boot-starter** - Adds ALL engines (Process, CMMN, DMN, IDM)
2. **flowable-spring-boot-starter-process** - BPMN process engine only
3. **flowable-spring-boot-starter-rest** - Includes REST API endpoints
4. **flowable-spring-boot-starter-integration** - Integration-focused starter

### Key Technical Details
- Flowable supports Spring Boot 3.x (latest versions)
- Requires database (H2 for dev, or PostgreSQL/MySQL for production)
- BPMN 2.0 process definitions go in `src/main/resources/processes/` folder
- Auto-deployment of .bpmn20.xml files
- Core services: ProcessEngine, RepositoryService, RuntimeService, TaskService

### Common Dependencies
```xml
<dependency>
    <groupId>org.flowable</groupId>
    <artifactId>flowable-spring-boot-starter</artifactId>
    <version>6.8.0</version>
</dependency>
```

## Requirements - CONFIRMED

### Flowable Configuration
- **Engine Type**: Process Engine Only (BPMN)
- **API Style**: Java API (no REST endpoints)
- **Database**: MySQL (already configured in project)

### Sample Content
- **Sample Process**: YES - Simple approval workflow (submit → review → approve/reject)

### Project Context
- Spring Boot 3.5.10
- Java 17
- Maven build
- MySQL connector already present
- Web starter already present
- No existing tests

## Technical Decisions
- Use `flowable-spring-boot-starter-process` dependency (lightweight, process-only)
- Flowable version: 6.8.0 (compatible with Spring Boot 3.x)
- Schema initialization: auto-create on startup for development
- Process definitions location: `src/main/resources/processes/`

## Scope
- **INCLUDE**: 
  - Flowable dependency configuration
  - Database configuration for Flowable
  - Sample approval BPMN process
  - Service layer for process operations
  - Basic controller to demonstrate usage
  - Verification that Flowable starts correctly
- **EXCLUDE**: 
  - REST API endpoints (Flowable's built-in REST)
  - DMN/CMMN/IDM engines
  - Flowable UI components
  - Advanced Flowable features (async, timers, etc.)
