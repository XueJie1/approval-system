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
                        .param("keyword", "reviewer")
                        .param("status", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].username").value(alpha.getUsername()))
                .andExpect(jsonPath("$[0].status").value(1));
    }

    @Test
    void anonymousUser_cannotListUsers() throws Exception {
        mockMvc.perform(get("/api/users"))
                .andExpect(status().isUnauthorized());
    }
}
