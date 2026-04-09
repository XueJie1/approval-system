package com.flowablecollab.approval_system;

import com.fasterxml.jackson.databind.JsonNode;
import com.flowablecollab.approval_system.entity.rbac.SysRole;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import com.flowablecollab.approval_system.entity.rbac.SysUserRole;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 角色 CRUD 完整集成测试
 * 测试点：
 * 1. 查询角色列表（全部、按关键词、按状态、组合查询）
 * 2. 创建角色（正常、编码重复、参数验证）
 * 3. 更新角色（正常、编码冲突、不存在 ID、参数验证）
 * 4. 删除角色（正常、不存在 ID、已分配用户、权限）
 */
class RoleCrudIntegrationTests extends AbstractIntegrationTestSupport {

    private String createSysAdminToken() {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        return accessToken(admin, "SYS_ADMIN");
    }

    private SysRole createRole(String adminToken, String roleCode, String roleName) throws Exception {
        String response = mockMvc.perform(post("/api/rbac/roles")
                        .header("Authorization", authorization(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "%s",
                                  "roleName": "%s"
                                }
                                """.formatted(roleCode, roleName)))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return sysRoleRepository.findByRoleCode(roleCode).orElseThrow();
    }

    private List<String> extractRoleCodes(JsonNode arrayNode) {
        List<String> codes = new ArrayList<>();
        for (JsonNode element : arrayNode) {
            codes.add(element.get("roleCode").asText());
        }
        return codes;
    }

    // ==================== 查询角色列表测试 ====================

    @Test
    void listRoles_returnsAllRoles() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        // 创建测试角色
        String roleCode1 = unique("TEST_ROLE_1").toUpperCase().replace('-', '_');
        String roleCode2 = unique("TEST_ROLE_2").toUpperCase().replace('-', '_');
        createRole(adminToken, roleCode1, "Test Role 1");
        createRole(adminToken, roleCode2, "Test Role 2");

        // 查询所有角色
        String response = mockMvc.perform(get("/api/rbac/roles")
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode result = json(response);
        List<String> roleCodes = extractRoleCodes(result);
        assertThat(roleCodes).contains(roleCode1, roleCode2, "ADMIN");
    }

    @Test
    void listRoles_filterByKeyword_roleCode() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        String roleCode = unique("MANAGER").toUpperCase().replace('-', '_');
        createRole(adminToken, roleCode, "Manager Role");

        String response = mockMvc.perform(get("/api/rbac/roles")
                        .header("Authorization", authorization(adminToken))
                        .param("keyword", "MANAGER"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.[0].roleCode").value(roleCode))
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode result = json(response);
        assertThat(result.size()).isEqualTo(1);
        assertThat(result.get(0).get("roleCode").asText()).isEqualTo(roleCode);
    }

    @Test
    void listRoles_filterByKeyword_roleName() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        String roleCode = unique("EDITOR").toUpperCase().replace('-', '_');
        createRole(adminToken, roleCode, "Editor Role");

        String response = mockMvc.perform(get("/api/rbac/roles")
                        .header("Authorization", authorization(adminToken))
                        .param("keyword", "Editor"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.[0].roleName").value("Editor Role"))
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode result = json(response);
        assertThat(result.size()).isEqualTo(1);
    }

    @Test
    void listRoles_filterByStatus() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        // 创建启用和停用角色
        String activeRoleCode = unique("ACTIVE").toUpperCase().replace('-', '_');
        String inactiveRoleCode = unique("INACTIVE").toUpperCase().replace('-', '_');
        SysRole activeRole = createRole(adminToken, activeRoleCode, "Active Role");
        SysRole inactiveRole = createRole(adminToken, inactiveRoleCode, "Inactive Role");
        
        // 手动停用一个角色
        inactiveRole.setStatus(0);
        sysRoleRepository.save(inactiveRole);

        // 查询启用角色
        String response = mockMvc.perform(get("/api/rbac/roles")
                        .header("Authorization", authorization(adminToken))
                        .param("status", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode result = json(response);
        List<String> roleCodes = extractRoleCodes(result);
        assertThat(roleCodes).contains(activeRoleCode).doesNotContain(inactiveRoleCode);
    }

    @Test
    void listRoles_filterByKeywordAndStatus() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        // 创建多个角色
        String activeRoleCode = unique("MANAGER").toUpperCase().replace('-', '_');
        String inactiveRoleCode = unique("MANAGER_OLD").toUpperCase().replace('-', '_');
        SysRole activeRole = createRole(adminToken, activeRoleCode, "Manager Role");
        SysRole inactiveRole = createRole(adminToken, inactiveRoleCode, "Old Manager Role");
        
        // 手动停用一个角色
        inactiveRole.setStatus(0);
        sysRoleRepository.save(inactiveRole);

        // 查询包含 MANAGER 且状态为启用的角色
        String response = mockMvc.perform(get("/api/rbac/roles")
                        .header("Authorization", authorization(adminToken))
                        .param("keyword", "MANAGER")
                        .param("status", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode result = json(response);
        List<String> roleCodes = extractRoleCodes(result);
        assertThat(roleCodes).contains(activeRoleCode).doesNotContain(inactiveRoleCode);
    }

    @Test
    void listRoles_emptyResult_whenKeywordNotMatched() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        String response = mockMvc.perform(get("/api/rbac/roles")
                        .header("Authorization", authorization(adminToken))
                        .param("keyword", "NONEXISTENT_KEYWORD_12345"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$").isEmpty())
                .andReturn()
                .getResponse()
                .getContentAsString();

        assertThat(json(response).size()).isEqualTo(0);
    }

    // ==================== 创建角色测试 ====================

    @Test
    void createRole_success() throws Exception {
        String adminToken = createSysAdminToken();
        String roleCode = unique("NEW_ROLE").toUpperCase().replace('-', '_');
        String roleName = "New Test Role";

        mockMvc.perform(post("/api/rbac/roles")
                        .header("Authorization", authorization(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "%s",
                                  "roleName": "%s"
                                }
                                """.formatted(roleCode, roleName)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.roleCode").value(roleCode))
                .andExpect(jsonPath("$.roleName").value(roleName))
                .andExpect(jsonPath("$.status").value(1))
                .andExpect(jsonPath("$.id").isNumber());

        assertThat(sysRoleRepository.findByRoleCode(roleCode)).isPresent();
    }

    @Test
    void createRole_duplicateRoleCode_fails() throws Exception {
        String adminToken = createSysAdminToken();
        String roleCode = unique("DUPLICATE").toUpperCase().replace('-', '_');

        // 第一次创建成功
        createRole(adminToken, roleCode, "First Role");

        // 第二次创建失败
        mockMvc.perform(post("/api/rbac/roles")
                        .header("Authorization", authorization(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "%s",
                                  "roleName": "Duplicate Role"
                                }
                                """.formatted(roleCode)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("roleCode already exists: " + roleCode));
    }

    @Test
    void createRole_emptyRoleCode_fails() throws Exception {
        String adminToken = createSysAdminToken();

        mockMvc.perform(post("/api/rbac/roles")
                        .header("Authorization", authorization(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "",
                                  "roleName": "Empty Code Role"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Validation failed"))
                .andExpect(jsonPath("$.errors.roleCode").value("roleCode is required"));
    }

    @Test
    void createRole_emptyRoleName_fails() throws Exception {
        String adminToken = createSysAdminToken();
        String roleCode = unique("EMPTY_NAME").toUpperCase().replace('-', '_');

        mockMvc.perform(post("/api/rbac/roles")
                        .header("Authorization", authorization(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "%s",
                                  "roleName": ""
                                }
                                """.formatted(roleCode)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Validation failed"))
                .andExpect(jsonPath("$.errors.roleName").value("roleName is required"));
    }

    @Test
    void createRole_unauthorized_fails() throws Exception {
        SysUser employee = createUser("employee", "Password@123", null, "EMPLOYEE");
        String employeeToken = accessToken(employee, "EMPLOYEE");
        String roleCode = unique("UNAUTHORIZED").toUpperCase().replace('-', '_');

        // Spring Security 拦截请求，返回 403 Forbidden
        mockMvc.perform(post("/api/rbac/roles")
                        .header("Authorization", authorization(employeeToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "%s",
                                  "roleName": "Should Fail"
                                }
                                """.formatted(roleCode)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("Forbidden"));
    }

    // ==================== 更新角色测试 ====================

    @Test
    void updateRole_success() throws Exception {
        String adminToken = createSysAdminToken();
        String roleCode = unique("UPDATE_TEST").toUpperCase().replace('-', '_');
        SysRole role = createRole(adminToken, roleCode, "Original Name");

        mockMvc.perform(put("/api/rbac/roles/{roleId}", role.getId())
                        .header("Authorization", authorization(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "%s",
                                  "roleName": "Updated Name",
                                  "status": 0
                                }
                                """.formatted(unique("UPDATED").toUpperCase().replace('-', '_'))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.roleName").value("Updated Name"))
                .andExpect(jsonPath("$.status").value(0));

        SysRole updated = sysRoleRepository.findById(role.getId()).orElseThrow();
        assertThat(updated.getRoleName()).isEqualTo("Updated Name");
        assertThat(updated.getStatus()).isEqualTo(0);
    }

    @Test
    void updateRole_sameRoleCode_success() throws Exception {
        String adminToken = createSysAdminToken();
        String roleCode = unique("SAME_CODE").toUpperCase().replace('-', '_');
        SysRole role = createRole(adminToken, roleCode, "Original Name");

        mockMvc.perform(put("/api/rbac/roles/{roleId}", role.getId())
                        .header("Authorization", authorization(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "%s",
                                  "roleName": "Updated Name",
                                  "status": 1
                                }
                                """.formatted(roleCode)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.roleCode").value(roleCode))
                .andExpect(jsonPath("$.roleName").value("Updated Name"));
    }

    @Test
    void updateRole_conflictingRoleCode_fails() throws Exception {
        String adminToken = createSysAdminToken();
        String roleCode1 = unique("CONFLICT_1").toUpperCase().replace('-', '_');
        String roleCode2 = unique("CONFLICT_2").toUpperCase().replace('-', '_');
        
        SysRole role1 = createRole(adminToken, roleCode1, "Role 1");
        SysRole role2 = createRole(adminToken, roleCode2, "Role 2");

        // 尝试将 role2 的编码改为 role1 的编码
        mockMvc.perform(put("/api/rbac/roles/{roleId}", role2.getId())
                        .header("Authorization", authorization(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "%s",
                                  "roleName": "Conflict Name",
                                  "status": 1
                                }
                                """.formatted(roleCode1)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("roleCode already exists: " + roleCode1));
    }

    @Test
    void updateRole_nonExistentRoleId_fails() throws Exception {
        String adminToken = createSysAdminToken();

        mockMvc.perform(put("/api/rbac/roles/{roleId}", 99999L)
                        .header("Authorization", authorization(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "TEST",
                                  "roleName": "Test",
                                  "status": 1
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("roleId does not exist: 99999"));
    }

    @Test
    void updateRole_missingRequiredFields_fails() throws Exception {
        String adminToken = createSysAdminToken();
        SysRole role = createRole(adminToken, unique("UPDATE_MISSING").toUpperCase().replace('-', '_'), "Test");

        mockMvc.perform(put("/api/rbac/roles/{roleId}", role.getId())
                        .header("Authorization", authorization(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "",
                                  "roleName": "Test",
                                  "status": 1
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Validation failed"));
    }

    @Test
    void updateRole_unauthorized_fails() throws Exception {
        SysRole role = ensureRole("ADMIN");
        SysUser employee = createUser("employee", "Password@123", null, "EMPLOYEE");
        String employeeToken = accessToken(employee, "EMPLOYEE");

        mockMvc.perform(put("/api/rbac/roles/{roleId}", role.getId())
                        .header("Authorization", authorization(employeeToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "MODIFIED",
                                  "roleName": "Modified",
                                  "status": 1
                                }
                                """))
                .andExpect(status().isForbidden());
    }

    // ==================== 删除角色测试 ====================

    @Test
    void deleteRole_success() throws Exception {
        String adminToken = createSysAdminToken();
        String roleCode = unique("DELETE_TEST").toUpperCase().replace('-', '_');
        SysRole role = createRole(adminToken, roleCode, "To Be Deleted");

        mockMvc.perform(delete("/api/rbac/roles/{roleId}", role.getId())
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Role deleted"));

        assertThat(sysRoleRepository.findByRoleCode(roleCode)).isEmpty();
    }

    @Test
    void deleteRole_nonExistentRoleId_fails() throws Exception {
        String adminToken = createSysAdminToken();

        mockMvc.perform(delete("/api/rbac/roles/{roleId}", 99999L)
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("roleId does not exist: 99999"));
    }

    @Test
    void deleteRole_withUserAssignment_fails() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");
        String roleCode = unique("ASSIGNED_ROLE").toUpperCase().replace('-', '_');
        SysRole role = createRole(adminToken, roleCode, "Assigned Role");

        // 将角色分配给用户
        rbacService.assignRole(admin.getId(), role.getId());

        // 删除应该失败
        mockMvc.perform(delete("/api/rbac/roles/{roleId}", role.getId())
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("role is assigned to 1 user(s)"));

        // 角色应该还在
        assertThat(sysRoleRepository.findByRoleCode(roleCode)).isPresent();
    }

    @Test
    void deleteRole_unauthorized_fails() throws Exception {
        SysRole role = ensureRole("ADMIN");
        SysUser employee = createUser("employee", "Password@123", null, "EMPLOYEE");
        String employeeToken = accessToken(employee, "EMPLOYEE");

        mockMvc.perform(delete("/api/rbac/roles/{roleId}", role.getId())
                        .header("Authorization", authorization(employeeToken)))
                .andExpect(status().isForbidden());
    }

    // ==================== 边界条件测试 ====================

    @Test
    void createRole_specialCharactersInName_success() throws Exception {
        String adminToken = createSysAdminToken();
        String roleCode = unique("SPECIAL_CHARS").toUpperCase().replace('-', '_');
        String roleName = "Test Role (Special) 角色 @2024";

        mockMvc.perform(post("/api/rbac/roles")
                        .header("Authorization", authorization(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "%s",
                                  "roleName": "%s"
                                }
                                """.formatted(roleCode, roleName)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.roleName").value(roleName));
    }

    @Test
    void createRole_whitespaceInCode_trimmed() throws Exception {
        String adminToken = createSysAdminToken();
        String roleCode = unique("TRIMMED").toUpperCase().replace('-', '_');

        mockMvc.perform(post("/api/rbac/roles")
                        .header("Authorization", authorization(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "  %s  ",
                                  "roleName": "Trimmed Role"
                                }
                                """.formatted(roleCode)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.roleCode").value(roleCode));

        assertThat(sysRoleRepository.findByRoleCode(roleCode)).isPresent();
    }

    @Test
    void updateRole_statusBoundary_values() throws Exception {
        String adminToken = createSysAdminToken();
        SysRole role = createRole(adminToken, unique("STATUS_TEST").toUpperCase().replace('-', '_'), "Test");

        // 测试状态 0（停用）
        mockMvc.perform(put("/api/rbac/roles/{roleId}", role.getId())
                        .header("Authorization", authorization(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "%s",
                                  "roleName": "Test",
                                  "status": 0
                                }
                                """.formatted(role.getRoleCode())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value(0));

        // 测试状态 1（启用）
        mockMvc.perform(put("/api/rbac/roles/{roleId}", role.getId())
                        .header("Authorization", authorization(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roleCode": "%s",
                                  "roleName": "Test",
                                  "status": 1
                                }
                                """.formatted(role.getRoleCode())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value(1));
    }

    @Test
    void listRoles_sortedByRoleCode() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        // 创建多个角色（不按字母顺序）
        createRole(adminToken, unique("ZEBRA").toUpperCase().replace('-', '_'), "Zebra");
        createRole(adminToken, unique("APPLE").toUpperCase().replace('-', '_'), "Apple");
        createRole(adminToken, unique("MANGO").toUpperCase().replace('-', '_'), "Mango");

        String response = mockMvc.perform(get("/api/rbac/roles")
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode result = json(response);
        List<String> roleCodes = extractRoleCodes(result);
        
        // 验证按字母顺序排序
        assertThat(roleCodes).isSorted();
    }
}
