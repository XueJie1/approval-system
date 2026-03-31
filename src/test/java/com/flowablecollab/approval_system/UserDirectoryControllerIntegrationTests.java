package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.entity.rbac.SysUser;
import org.junit.jupiter.api.Test;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class UserDirectoryControllerIntegrationTests extends AbstractIntegrationTestSupport {

    @Test
    void authenticatedUser_canListActiveUsersWithKeywordFilter() throws Exception {
        SysUser employee = createUser("picker-viewer", "Password@123", null, "EMPLOYEE");
        SysUser alpha = createUser("alpha-reviewer", "Password@123", null, "EMPLOYEE");
        SysUser beta = createUser("beta-reviewer", "Password@123", null, "EMPLOYEE");
        beta.setStatus(0);
        sysUserRepository.save(beta);

        mockMvc.perform(get("/api/users")
                        .header("Authorization", authorization(accessToken(employee, "EMPLOYEE")))
                        .param("keyword", alpha.getUsername())
                        .param("status", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].username").value(alpha.getUsername()))
                .andExpect(jsonPath("$[0].status").value(1));
    }

    @Test
    void authenticatedUser_cannotSeeAdminAccountsInUserDirectory() throws Exception {
        SysUser employee = createUser("picker-viewer-2", "Password@123", null, "EMPLOYEE");
        createUser("directory-admin", "Password@123", null, "ADMIN");
        SysUser reviewer = createUser("directory-reviewer", "Password@123", null, "EMPLOYEE");

        mockMvc.perform(get("/api/users")
                        .header("Authorization", authorization(accessToken(employee, "EMPLOYEE"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].username").isArray())
                .andExpect(jsonPath("$[*].username").value(org.hamcrest.Matchers.hasItem(reviewer.getUsername())))
                .andExpect(jsonPath("$[*].username").value(org.hamcrest.Matchers.not(org.hamcrest.Matchers.hasItem("directory-admin"))));
    }

    @Test
    void anonymousUser_cannotListUsers() throws Exception {
        mockMvc.perform(get("/api/users"))
                .andExpect(status().isUnauthorized());
    }
}
