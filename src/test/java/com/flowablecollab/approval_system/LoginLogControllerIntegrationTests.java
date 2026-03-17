package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.entity.rbac.SysLoginLog;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class LoginLogControllerIntegrationTests extends AbstractIntegrationTestSupport {

    @Test
    void admin_canListAndFetchLoginLogs() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "ADMIN");
        String adminToken = accessToken(admin, "ADMIN");

        SysLoginLog log = new SysLoginLog();
        log.setUserId(admin.getId());
        log.setUsername(admin.getUsername());
        log.setLoginStatus(0);
        log.setMessage("login successful");
        log.setIpAddress("127.0.0.1");
        log.setUserAgent("JUnit");
        log.setLoginTime(LocalDateTime.now());
        log = sysLoginLogRepository.save(log);

        mockMvc.perform(get("/api/admin/login-logs")
                        .header("Authorization", authorization(adminToken))
                        .param("userId", String.valueOf(admin.getId())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].id").value(log.getId()));

        mockMvc.perform(get("/api/admin/login-logs/{id}", log.getId())
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value(admin.getUsername()))
                .andExpect(jsonPath("$.message").value("login successful"));
    }

    @Test
    void nonAdmin_cannotReadLoginLogs() throws Exception {
        SysUser employee = createUser("employee", "Password@123", null, "EMPLOYEE");
        String employeeToken = accessToken(employee, "EMPLOYEE");

        mockMvc.perform(get("/api/admin/login-logs")
                        .header("Authorization", authorization(employeeToken)))
                .andExpect(status().isForbidden());
    }
}
