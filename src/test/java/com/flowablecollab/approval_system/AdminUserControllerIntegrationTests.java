package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.entity.rbac.SysDept;
import com.flowablecollab.approval_system.entity.rbac.SysPost;
import com.flowablecollab.approval_system.entity.rbac.SysRole;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import java.io.ByteArrayOutputStream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AdminUserControllerIntegrationTests extends AbstractIntegrationTestSupport {

    @Test
    void sysAdmin_canCreateAndManageUsers() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");
        String deptCode = unique("FIN").toUpperCase().replace('-', '_');
        SysDept finance = rbacService.createDept(deptCode, "Finance", null);
        SysRole employeeRole = ensureRole("EMPLOYEE");
        SysPost reviewerPost = rbacService.createPost(unique("FIN_REVIEW"), "Finance Reviewer");
        SysUser manager = createUser(unique("manager"), "Password@123", finance.getId(), "EMPLOYEE");

        String response = mockMvc.perform(post("/api/admin/users")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "%s",
                                  "password": "Password@123",
                                  "deptId": %d,
                                  "managerUserId": %d,
                                  "roleIds": [%d],
                                  "postIds": [%d],
                                  "status": 1
                                }
                                """.formatted(unique("employee"), finance.getId(), manager.getId(), employeeRole.getId(), reviewerPost.getId())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.department.deptCode").value(deptCode))
                .andExpect(jsonPath("$.managerUserId").value(manager.getId()))
                .andExpect(jsonPath("$.roles[0].roleCode").value("EMPLOYEE"))
                .andExpect(jsonPath("$.posts[0].postCode").value(reviewerPost.getPostCode()))
                .andReturn()
                .getResponse()
                .getContentAsString();

        Long userId = json(response).get("userId").asLong();

        mockMvc.perform(patch("/api/admin/users/{userId}/status", userId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "status": 0
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value(0));

        mockMvc.perform(post("/api/admin/users/{userId}/reset-password", userId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "newPassword": "Reset@123"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Password reset"));

        mockMvc.perform(get("/api/admin/users")
                        .header("Authorization", authorization(adminToken))
                        .param("keyword", "employee")
                        .param("status", "0")
                        .param("page", "0")
                        .param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].userId").value(userId))
                .andExpect(jsonPath("$.content[0].locked").value(false))
                .andExpect(jsonPath("$.total").value(1));
    }

    @Test
    void sysAdmin_canValidateAndExecuteCsvImport() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");
        String deptCode = unique("FIN").toUpperCase().replace('-', '_');
        rbacService.createDept(deptCode, "Finance", null);
        SysRole employeeRole = ensureRole("EMPLOYEE");
        SysPost reviewerPost = rbacService.createPost(unique("POST"), "Finance Reviewer");

        MockMultipartFile file = new MockMultipartFile(
                "file",
                "users.csv",
                "text/csv",
                ("""
                        username,password,dept_code,post_codes,role_codes,status
                        import-user-1,Password@123,%s,%s,%s,1
                        import-user-2,Password@123,%s,,%s,1
                        """.formatted(deptCode, reviewerPost.getPostCode(), employeeRole.getRoleCode(), deptCode, employeeRole.getRoleCode()))
                        .getBytes()
        );

        String validateResponse = mockMvc.perform(multipart("/api/admin/users/imports/validate")
                        .file(file)
                        .param("strategy", "CREATE_ONLY")
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalRows").value(2))
                .andExpect(jsonPath("$.failedRows").value(0))
                .andReturn()
                .getResponse()
                .getContentAsString();

        long jobId = json(validateResponse).get("jobId").asLong();

        mockMvc.perform(post("/api/admin/users/imports/{jobId}/execute", jobId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "skipErrorRows": true
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"))
                .andExpect(jsonPath("$.successRows").value(2))
                .andExpect(jsonPath("$.failedRows").value(0));

        assertThat(sysUserRepository.findByUsername("import-user-1")).isPresent();
        assertThat(sysUserRepository.findByUsername("import-user-2")).isPresent();

        mockMvc.perform(get("/api/admin/users/imports/{jobId}/items", jobId)
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].result").value("SUCCESS"));

        mockMvc.perform(get("/api/admin/users/imports")
                        .header("Authorization", authorization(adminToken))
                        .param("status", "COMPLETED")
                        .param("page", "0")
                        .param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].jobId").value(jobId));
    }

    @Test
    void sysAdmin_canValidateXlsxImportAndGetErrors() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");
        ensureRole("EMPLOYEE");

        byte[] workbookBytes = buildWorkbook(
                new String[]{"username", "password", "dept_code", "post_codes", "role_codes", "status"},
                new String[]{"bad-user", "short", "UNKNOWN", "", "EMPLOYEE", "1"}
        );
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "users.xlsx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                workbookBytes
        );

        String validateResponse = mockMvc.perform(multipart("/api/admin/users/imports/validate")
                        .file(file)
                        .param("strategy", "CREATE_ONLY")
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.failedRows").value(1))
                .andExpect(jsonPath("$.errors[0].rowNo").value(2))
                .andReturn()
                .getResponse()
                .getContentAsString();

        long jobId = json(validateResponse).get("jobId").asLong();

        mockMvc.perform(get("/api/admin/users/imports/{jobId}/failed-export", jobId)
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isOk());
    }

    @Test
    void failedExport_keepsValidationFailuresAfterExecute() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");
        SysRole employeeRole = ensureRole("EMPLOYEE");

        MockMultipartFile file = new MockMultipartFile(
                "file",
                "users.csv",
                "text/csv",
                ("""
                        username,password,dept_code,post_codes,role_codes,status
                        valid-import-user,Password@123,,,%s,1
                        invalid-import-user,short,,,%s,1
                        """.formatted(employeeRole.getRoleCode(), employeeRole.getRoleCode()))
                        .getBytes()
        );

        String validateResponse = mockMvc.perform(multipart("/api/admin/users/imports/validate")
                        .file(file)
                        .param("strategy", "CREATE_ONLY")
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.failedRows").value(1))
                .andReturn()
                .getResponse()
                .getContentAsString();

        long jobId = json(validateResponse).get("jobId").asLong();

        mockMvc.perform(post("/api/admin/users/imports/{jobId}/execute", jobId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "skipErrorRows": true
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.successRows").value(1))
                .andExpect(jsonPath("$.failedRows").value(1));

        mockMvc.perform(get("/api/admin/users/imports/{jobId}/failed-export", jobId)
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isOk())
                .andExpect(result -> assertThat(result.getResponse().getContentAsString()).contains("invalid-import-user"));
    }

    @Test
    void nonAdmin_cannotAccessAdminUserApis() throws Exception {
        SysUser employee = createUser("employee", "Password@123", null, "EMPLOYEE");

        mockMvc.perform(get("/api/admin/users")
                        .header("Authorization", authorization(accessToken(employee, "EMPLOYEE"))))
                .andExpect(status().isForbidden());
    }

    @Test
    void options_includeUsersForManagerSelection() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");
        SysUser manager = createUser(unique("leader"), "Password@123", null, "EMPLOYEE");

        mockMvc.perform(get("/api/admin/users/options")
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.users[?(@.id==%d)].username".formatted(manager.getId())).value(org.hamcrest.Matchers.hasItem(manager.getUsername())));
    }

    private byte[] buildWorkbook(String[] headers, String[] values) throws Exception {
        try (XSSFWorkbook workbook = new XSSFWorkbook(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            var sheet = workbook.createSheet("users");
            var headerRow = sheet.createRow(0);
            for (int i = 0; i < headers.length; i++) {
                headerRow.createCell(i).setCellValue(headers[i]);
            }
            var row = sheet.createRow(1);
            for (int i = 0; i < values.length; i++) {
                row.createCell(i).setCellValue(values[i]);
            }
            workbook.write(output);
            return output.toByteArray();
        }
    }
}
