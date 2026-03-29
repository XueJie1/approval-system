package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.repository.rbac.SysRoleRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserRoleRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Integration tests for the /api/auth/bootstrap-status endpoint.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class BootstrapStatusIntegrationTests {

    @Autowired
    private MockMvc mockMvc;
    
    @Autowired
    private ObjectMapper objectMapper;
    
    @Autowired
    private SysUserRepository sysUserRepository;
    
    @Autowired
    private SysRoleRepository sysRoleRepository;
    
    @Autowired
    private SysUserRoleRepository sysUserRoleRepository;

    @Test
    @Transactional
    void testBootstrapStatus_whenNoAdminExists_shouldReturnTrue() throws Exception {
        // Ensure clean state
        sysUserRoleRepository.deleteAll();
        sysUserRepository.deleteAll();
        sysRoleRepository.deleteAll();
        
        // When: Access the bootstrap status endpoint
        MvcResult result = mockMvc.perform(get("/api/auth/bootstrap-status"))
                .andExpect(status().isOk())
                .andExpect(content().contentType("application/json"))
                .andReturn();

        // Then: Verify the response
        String responseBody = result.getResponse().getContentAsString();
        System.out.println("Response: " + responseBody);
        
        // Parse and verify
        var jsonNode = objectMapper.readTree(responseBody);
        boolean isBootstrapMode = jsonNode.get("isBootstrapMode").asBoolean();
        
        assert isBootstrapMode : "Expected isBootstrapMode to be true when no admin exists";
    }

    @Test
    @Transactional
    void testBootstrapStatus_afterAdminCreated_shouldReturnFalse() throws Exception {
        // Ensure clean state
        sysUserRoleRepository.deleteAll();
        sysUserRepository.deleteAll();
        sysRoleRepository.deleteAll();
        
        // Given: Create an admin user via bootstrap
        String bootstrapJson = """
            {
                "username": "testadmin",
                "password": "TestAdmin@123"
            }
            """;
        
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post("/api/auth/bootstrap")
                .contentType("application/json")
                .content(bootstrapJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").exists());

        // When: Check bootstrap status after admin creation
        MvcResult result = mockMvc.perform(get("/api/auth/bootstrap-status"))
                .andExpect(status().isOk())
                .andExpect(content().contentType("application/json"))
                .andReturn();

        // Then: Verify bootstrap mode is now false
        String responseBody = result.getResponse().getContentAsString();
        System.out.println("Response after bootstrap: " + responseBody);
        
        var jsonNode = objectMapper.readTree(responseBody);
        boolean isBootstrapMode = jsonNode.get("isBootstrapMode").asBoolean();
        
        assert !isBootstrapMode : "Expected isBootstrapMode to be false after admin creation";
    }

    @Test
    @Transactional
    void testBootstrapStatus_responseFormat() throws Exception {
        // Ensure clean state
        sysUserRoleRepository.deleteAll();
        sysUserRepository.deleteAll();
        sysRoleRepository.deleteAll();
        
        // When: Access the bootstrap status endpoint
        MvcResult result = mockMvc.perform(get("/api/auth/bootstrap-status"))
                .andExpect(status().isOk())
                .andExpect(content().contentType("application/json"))
                .andExpect(jsonPath("$.isBootstrapMode").exists())
                .andExpect(jsonPath("$.isBootstrapMode").isBoolean())
                .andReturn();

        // Then: Verify response structure
        String responseBody = result.getResponse().getContentAsString();
        System.out.println("Response format test: " + responseBody);
        
        var jsonNode = objectMapper.readTree(responseBody);
        assert jsonNode.has("isBootstrapMode") : "Response should contain 'isBootstrapMode' field";
        assert jsonNode.get("isBootstrapMode").isBoolean() : "'isBootstrapMode' should be a boolean";
    }
}
