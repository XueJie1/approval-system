package com.flowablecollab.approval_system;

import com.fasterxml.jackson.databind.JsonNode;
import com.flowablecollab.approval_system.entity.rbac.SysRole;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class RbacControllerIntegrationTests extends AbstractIntegrationTestSupport {

    @Test
    void sysAdmin_canManageUsersRolesDepartmentsPosts_andDataScopes() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        String deptResponse = mockMvc.perform(post("/api/rbac/depts")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "deptName": "Finance"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andReturn()
                .getResponse()
                .getContentAsString();

        Long deptId = json(deptResponse).get("id").asLong();

        String postResponse = mockMvc.perform(post("/api/rbac/posts")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "postCode": "%s",
                                  "postName": "Reviewer"
                                }
                                """.formatted(unique("REVIEWER"))))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();

        Long postId = json(postResponse).get("id").asLong();

        String roleCode = unique("REVIEW_ROLE").toUpperCase().replace('-', '_');
        String roleResponse = mockMvc.perform(post("/api/rbac/roles")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "%s",
                                  "roleName": "Review Role"
                                }
                                """.formatted(roleCode)))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();

        Long roleId = json(roleResponse).get("id").asLong();

        String userResponse = mockMvc.perform(post("/api/rbac/users")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "%s",
                                  "password": "Password@123",
                                  "deptId": %d,
                                  "status": 1
                                }
                                """.formatted(unique("reviewer"), deptId)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.deptId").value(deptId))
                .andReturn()
                .getResponse()
                .getContentAsString();

        Long userId = json(userResponse).get("id").asLong();

        mockMvc.perform(post("/api/rbac/assign")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": %d,
                                  "roleId": %d
                                }
                                """.formatted(userId, roleId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Role assigned"));

        mockMvc.perform(post("/api/rbac/assign-post")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": %d,
                                  "postId": %d
                                }
                                """.formatted(userId, postId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Post assigned"));

        mockMvc.perform(post("/api/rbac/role-data-scope")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "roleId": %d,
                                  "scopeType": "CUSTOM",
                                  "deptId": %d
                                }
                                """.formatted(roleId, deptId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Role data scope added"));

        SysRole createdRole = sysRoleRepository.findById(roleId).orElseThrow();
        assertThat(createdRole.getRoleCode()).isEqualTo(roleCode);
        assertThat(sysUserRoleRepository.existsByUserIdAndRoleId(userId, roleId)).isTrue();
        assertThat(sysRoleDataScopeRepository.findByRoleId(roleId))
                .anyMatch(scope -> "CUSTOM".equals(scope.getScopeType()) && deptId.equals(scope.getDeptId()));
    }

    @Test
    void createUser_validatesPayload() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        mockMvc.perform(post("/api/rbac/users")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "bad-user",
                                  "password": "short"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Validation failed"))
                .andExpect(jsonPath("$.errors.password").value("password length must be between 8 and 128"));
    }

    @Test
    void nonAdmin_cannotManageRbac() throws Exception {
        SysUser employee = createUser("employee", "Password@123", null, "EMPLOYEE");
        String employeeToken = accessToken(employee, "EMPLOYEE");

        mockMvc.perform(post("/api/rbac/roles")
                        .header("Authorization", authorization(employeeToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "%s",
                                  "roleName": "Should Fail"
                                }
                                """.formatted(unique("FAIL_ROLE"))))
                .andExpect(status().isForbidden());
    }
}
