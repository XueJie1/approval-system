package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.entity.rbac.SysUser;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class FormAdminControllerIntegrationTests extends AbstractIntegrationTestSupport {

    @Test
    void designer_canManageDefinitionVersionFields_andPublishVersion() throws Exception {
        SysUser designer = createUser("designer-admin-form", "Password@123", null, "DESIGNER");
        String token = accessToken(designer, "DESIGNER");

        String formKey = unique("travel_admin_form").replace('-', '_');
        String definitionResponse = mockMvc.perform(post("/api/admin/forms/definitions")
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "formKey": "%s",
                                  "formName": "出差申请（管理端）"
                                }
                                """.formatted(formKey)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.formKey").value(formKey))
                .andReturn().getResponse().getContentAsString();

        Long definitionId = json(definitionResponse).get("id").asLong();

        String versionResponse = mockMvc.perform(post("/api/admin/forms/definitions/{definitionId}/versions", definitionId)
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "schemaJson": "{\\"fields\\": []}"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("DRAFT"))
                .andReturn().getResponse().getContentAsString();

        Long versionId = json(versionResponse).get("id").asLong();

        mockMvc.perform(put("/api/admin/forms/versions/{versionId}/fields", versionId)
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "fields": [
                                    {
                                      "fieldKey": "destination",
                                      "variableKey": "travelDestination",
                                      "fieldType": "string",
                                      "label": "出差地点",
                                      "required": true,
                                      "sortOrder": 0
                                    },
                                    {
                                      "fieldKey": "budget",
                                      "fieldType": "number",
                                      "label": "预算金额",
                                      "required": true,
                                      "validateRule": "{\\"min\\": 100}",
                                      "sortOrder": 1
                                    }
                                  ]
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].fieldKey").value("destination"));

        mockMvc.perform(post("/api/admin/forms/versions/{versionId}/validate-sample", versionId)
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "data": {
                                    "destination": "上海",
                                    "budget": 3600
                                  }
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.valid").value(true));

        mockMvc.perform(post("/api/admin/forms/versions/{versionId}/publish", versionId)
                        .header("Authorization", authorization(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("PUBLISHED"));

        mockMvc.perform(get("/api/admin/forms/definitions")
                        .header("Authorization", authorization(token))
                        .param("keyword", formKey))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].publishedVersionId").value(versionId));

        mockMvc.perform(get("/api/admin/forms/versions/{versionId}/impacts", versionId)
                        .header("Authorization", authorization(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.requestTemplateCount").isNumber())
                .andExpect(jsonPath("$.workflowVersionCount").isNumber());

        mockMvc.perform(put("/api/admin/forms/versions/{versionId}/fields", versionId)
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "fields": []
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Only draft form version can update fields"));
    }

    @Test
    void employee_cannotAccessAdminFormManagementEndpoints() throws Exception {
        SysUser employee = createUser("employee-form-admin", "Password@123", null, "EMPLOYEE");
        String employeeToken = accessToken(employee, "EMPLOYEE");

        mockMvc.perform(get("/api/admin/forms/definitions")
                        .header("Authorization", authorization(employeeToken)))
                .andExpect(status().isForbidden())
                .andReturn();

        assertThat(formDefinitionRepository.findAll()).isNotNull();
    }
}
