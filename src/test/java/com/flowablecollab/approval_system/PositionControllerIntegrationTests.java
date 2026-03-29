package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.entity.rbac.SysPost;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class PositionControllerIntegrationTests extends AbstractIntegrationTestSupport {

    @Test
    void admin_canCreatePosition() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "ADMIN");
        String adminToken = accessToken(admin, "ADMIN");

        String response = mockMvc.perform(post("/api/positions")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "postCode": "MANAGER",
                                  "postName": "Manager"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.postCode").value("MANAGER"))
                .andExpect(jsonPath("$.postName").value("Manager"))
                .andReturn()
                .getResponse()
                .getContentAsString();

        SysPost post = sysPostRepository.findByPostCode("MANAGER").orElseThrow();
        assertThat(post.getPostName()).isEqualTo("Manager");
    }

    @Test
    void admin_canListAllPositions() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "ADMIN");
        String adminToken = accessToken(admin, "ADMIN");

        sysPostRepository.deleteAll();
        sysPostRepository.save(createPost("DEV", "Developer"));
        sysPostRepository.save(createPost("PM", "Project Manager"));

        mockMvc.perform(get("/api/positions")
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void admin_canGetPositionById() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "ADMIN");
        String adminToken = accessToken(admin, "ADMIN");

        SysPost post = sysPostRepository.save(createPost("TEST", "Test Position"));

        mockMvc.perform(get("/api/positions/{id}", post.getId())
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(post.getId()))
                .andExpect(jsonPath("$.postCode").value("TEST"))
                .andExpect(jsonPath("$.postName").value("Test Position"));
    }

    @Test
    void admin_canUpdatePosition() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "ADMIN");
        String adminToken = accessToken(admin, "ADMIN");

        SysPost post = sysPostRepository.save(createPost("OLD", "Old Position"));

        mockMvc.perform(put("/api/positions/{id}", post.getId())
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "postCode": "NEW",
                                  "postName": "New Position"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(post.getId()))
                .andExpect(jsonPath("$.postCode").value("NEW"))
                .andExpect(jsonPath("$.postName").value("New Position"));

        SysPost updated = sysPostRepository.findById(post.getId()).orElseThrow();
        assertThat(updated.getPostCode()).isEqualTo("NEW");
        assertThat(updated.getPostName()).isEqualTo("New Position");
    }

    @Test
    void admin_canDeletePosition() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "ADMIN");
        String adminToken = accessToken(admin, "ADMIN");

        SysPost post = sysPostRepository.save(createPost("TODELETE", "To Delete"));

        mockMvc.perform(delete("/api/positions/{id}", post.getId())
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isNoContent());

        assertThat(sysPostRepository.findById(post.getId())).isEmpty();
    }

    @Test
    void cannotDeletePositionWithUsers() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "ADMIN");
        String adminToken = accessToken(admin, "ADMIN");

        SysPost post = sysPostRepository.save(createPost("HASUSER", "Has User"));
        SysUser user = rbacService.createUser(unique("user"), "User@123", null, 1);
        rbacService.assignPost(user.getId(), post.getId());

        mockMvc.perform(delete("/api/positions/{id}", post.getId())
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("Cannot delete position with assigned users"));
    }

    @Test
    void createPosition_validatesPostCodeUniqueness() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "ADMIN");
        String adminToken = accessToken(admin, "ADMIN");

        sysPostRepository.save(createPost("UNIQUE", "Unique Position"));

        mockMvc.perform(post("/api/positions")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "postCode": "UNIQUE",
                                  "postName": "Duplicate Position"
                                }
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("postCode already exists: UNIQUE"));
    }

    @Test
    void nonAdmin_cannotManagePositions() throws Exception {
        SysUser employee = createUser("employee", "Password@123", null, "EMPLOYEE");
        String employeeToken = accessToken(employee, "EMPLOYEE");

        mockMvc.perform(post("/api/positions")
                        .header("Authorization", authorization(employeeToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "postCode": "TEST",
                                  "postName": "Test"
                                }
                                """))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("operator has no RBAC management permission"));
    }

    @Test
    void getPositionNotFound_returns404() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "ADMIN");
        String adminToken = accessToken(admin, "ADMIN");

        mockMvc.perform(get("/api/positions/99999")
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isNotFound());
    }

    @Test
    void updatePositionNotFound_returns404() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "ADMIN");
        String adminToken = accessToken(admin, "ADMIN");

        mockMvc.perform(put("/api/positions/99999")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "postCode": "NEW",
                                  "postName": "New Name"
                                }
                                """))
                .andExpect(status().isNotFound());
    }

    @Test
    void deletePositionNotFound_returns404() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "ADMIN");
        String adminToken = accessToken(admin, "ADMIN");

        mockMvc.perform(delete("/api/positions/99999")
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isNotFound());
    }

    @Test
    void createPosition_requiresPostCode() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "ADMIN");
        String adminToken = accessToken(admin, "ADMIN");

        mockMvc.perform(post("/api/positions")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "postName": "No Code Position"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Validation failed"))
                .andExpect(jsonPath("$.errors.postCode").value("postCode is required"));
    }

    @Test
    void createPosition_requiresPostName() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "ADMIN");
        String adminToken = accessToken(admin, "ADMIN");

        mockMvc.perform(post("/api/positions")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "postCode": "NOCODE"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Validation failed"))
                .andExpect(jsonPath("$.errors.postName").value("postName is required"));
    }

    private SysPost createPost(String code, String name) {
        SysPost post = new SysPost();
        post.setPostCode(code);
        post.setPostName(name);
        return post;
    }
}
