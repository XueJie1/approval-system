package com.flowablecollab.approval_system;

import com.fasterxml.jackson.databind.JsonNode;
import com.flowablecollab.approval_system.entity.rbac.SysDept;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class DepartmentControllerIntegrationTests extends AbstractIntegrationTestSupport {

    @Test
    void sysAdmin_canCreateDepartment() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");
        SysUser leader = createUser(unique("dept-leader"), "Password@123", null, "EMPLOYEE");

        String response = mockMvc.perform(post("/api/departments")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "deptCode": "DEPT001",
                                  "deptName": "IT Department",
                                  "leaderUserId": %d
                                }
                                """.formatted(leader.getId())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.deptCode").value("DEPT001"))
                .andExpect(jsonPath("$.deptName").value("IT Department"))
                .andExpect(jsonPath("$.leaderUserId").value(leader.getId()))
                .andReturn()
                .getResponse()
                .getContentAsString();

        SysDept dept = sysDeptRepository.findByDeptCode("DEPT001").orElseThrow();
        assertThat(dept.getDeptName()).isEqualTo("IT Department");
        assertThat(dept.getLeaderUserId()).isEqualTo(leader.getId());
    }

    @Test
    void sysAdmin_canCreateSubDepartment() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        SysDept parentDept = createDept("PARENT001", "Parent Department");
        parentDept = sysDeptRepository.save(parentDept);

        String response = mockMvc.perform(post("/api/departments")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "deptCode": "CHILD001",
                                  "deptName": "Child Department",
                                  "parentId": %d
                                }
                                """.formatted(parentDept.getId())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.parentId").value(parentDept.getId()))
                .andReturn()
                .getResponse()
                .getContentAsString();

        SysDept childDept = sysDeptRepository.findByDeptCode("CHILD001").orElseThrow();
        assertThat(childDept.getParentId()).isEqualTo(parentDept.getId());
    }

    @Test
    void sysAdmin_canListAllDepartments() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        sysDeptRepository.deleteAll();
        sysDeptRepository.save(createDept("HR", "Human Resources"));
        sysDeptRepository.save(createDept("IT", "Information Technology"));

        mockMvc.perform(get("/api/departments")
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void sysAdmin_canGetDepartmentById() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        SysDept dept = sysDeptRepository.save(createDept("TEST", "Test Department"));

        mockMvc.perform(get("/api/departments/{id}", dept.getId())
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(dept.getId()))
                .andExpect(jsonPath("$.deptCode").value("TEST"))
                .andExpect(jsonPath("$.deptName").value("Test Department"));
    }

    @Test
    void sysAdmin_canUpdateDepartment() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        SysDept dept = sysDeptRepository.save(createDept("OLD", "Old Name"));

        mockMvc.perform(put("/api/departments/{id}", dept.getId())
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "deptCode": "NEW",
                                  "deptName": "New Name"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(dept.getId()))
                .andExpect(jsonPath("$.deptCode").value("NEW"))
                .andExpect(jsonPath("$.deptName").value("New Name"));

        SysDept updated = sysDeptRepository.findById(dept.getId()).orElseThrow();
        assertThat(updated.getDeptCode()).isEqualTo("NEW");
        assertThat(updated.getDeptName()).isEqualTo("New Name");
    }

    @Test
    void sysAdmin_canDeleteDepartment() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        SysDept dept = sysDeptRepository.save(createDept("TODELETE", "To Delete"));

        mockMvc.perform(delete("/api/departments/{id}", dept.getId())
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isNoContent());

        assertThat(sysDeptRepository.findById(dept.getId())).isEmpty();
    }

    @Test
    void cannotDeleteDepartmentWithChildren() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        SysDept parentDept = sysDeptRepository.save(createDept("PARENT", "Parent"));
        SysDept childDept = sysDeptRepository.save(createDept("CHILD", "Child"));
        childDept.setParentId(parentDept.getId());
        sysDeptRepository.save(childDept);

        mockMvc.perform(delete("/api/departments/{id}", parentDept.getId())
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("Cannot delete department with child departments"));
    }

    @Test
    void cannotDeleteDepartmentWithUsers() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        SysDept dept = sysDeptRepository.save(createDept("HASUSER", "Has User"));
        SysUser user = rbacService.createUser(unique("user"), "User@123", dept.getId(), 1);

        mockMvc.perform(delete("/api/departments/{id}", dept.getId())
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("Cannot delete department with assigned users"));
    }

    @Test
    void createDepartment_validatesDeptCodeUniqueness() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        sysDeptRepository.save(createDept("UNIQUE", "Unique Department"));

        mockMvc.perform(post("/api/departments")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "deptCode": "UNIQUE",
                                  "deptName": "Duplicate Department"
                                }
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("deptCode already exists: UNIQUE"));
    }

    @Test
    void nonAdmin_cannotManageDepartments() throws Exception {
        SysUser employee = createUser("employee", "Password@123", null, "EMPLOYEE");
        String employeeToken = accessToken(employee, "EMPLOYEE");

        mockMvc.perform(post("/api/departments")
                        .header("Authorization", authorization(employeeToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "deptCode": "TEST",
                                  "deptName": "Test"
                                }
                                """))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("Forbidden"));
    }

    @Test
    void getDepartmentNotFound_returns404() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        mockMvc.perform(get("/api/departments/99999")
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isNotFound());
    }

    @Test
    void updateDepartmentNotFound_returns404() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        mockMvc.perform(put("/api/departments/99999")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "deptCode": "NEW",
                                  "deptName": "New Name"
                                }
                                """))
                .andExpect(status().isNotFound());
    }

    @Test
    void updateDepartment_rejectsSelfAsParent() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");
        SysDept dept = sysDeptRepository.save(createDept("SELF", "Self Parent"));

        mockMvc.perform(put("/api/departments/{id}", dept.getId())
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "deptCode": "SELF",
                                  "deptName": "Self Parent",
                                  "parentId": %d
                                }
                                """.formatted(dept.getId())))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("parentId cannot be the same as department id"));
    }

    @Test
    void updateDepartment_rejectsCycleParent() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");
        SysDept grandParent = sysDeptRepository.save(createDept("ROOT", "Root"));
        SysDept parent = sysDeptRepository.save(createDept("PARENT2", "Parent2"));
        parent.setParentId(grandParent.getId());
        parent = sysDeptRepository.save(parent);
        SysDept child = sysDeptRepository.save(createDept("CHILD2", "Child2"));
        child.setParentId(parent.getId());
        child = sysDeptRepository.save(child);

        mockMvc.perform(put("/api/departments/{id}", grandParent.getId())
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "deptCode": "ROOT",
                                  "deptName": "Root",
                                  "parentId": %d
                                }
                                """.formatted(child.getId())))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("parentId would create a department cycle"));
    }

    @Test
    void deleteDepartmentNotFound_returns404() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        mockMvc.perform(delete("/api/departments/99999")
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isNotFound());
    }

    private SysDept createDept(String code, String name) {
        SysDept dept = new SysDept();
        dept.setDeptCode(code);
        dept.setDeptName(name);
        return dept;
    }
}
