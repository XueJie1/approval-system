package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.entity.rbac.SysUser;
import org.junit.jupiter.api.Test;

import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class FormAdminQueryIntegrationTests extends AbstractIntegrationTestSupport {

    @Test
    void listFormDefinitionsAndVersions_returnsCreatedForms() throws Exception {
        SysUser designer = createUser("form-designer", "Password@123", null, "DESIGNER");
        String token = accessToken(designer, "DESIGNER");
        String formKey = unique("wf-form").replace('-', '_');

        Long formId = json(mockMvc.perform(post("/api/forms/definitions")
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": %d,
                                  "formKey": "%s",
                                  "formName": "Workflow Managed Form"
                                }
                                """.formatted(designer.getId(), formKey)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString()).get("id").asLong();

        mockMvc.perform(post("/api/forms/versions")
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": %d,
                                  "formId": %d,
                                  "schemaJson": %s
                                }
                                """.formatted(designer.getId(), formId, objectMapper.writeValueAsString("{\"fields\":[]}"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.version").value(1));

        mockMvc.perform(get("/api/forms/definitions")
                        .header("Authorization", authorization(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.id == %d)].formKey".formatted(formId)).value(formKey));

        mockMvc.perform(get("/api/forms/versions")
                        .header("Authorization", authorization(token))
                        .param("formId", String.valueOf(formId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].formId").value(formId))
                .andExpect(jsonPath("$[0].version").value(1));
    }
}
