package com.flowablecollab.approval_system;

import com.fasterxml.jackson.databind.JsonNode;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.http.MediaType.MULTIPART_FORM_DATA_VALUE;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class FormControllerIntegrationTests extends AbstractIntegrationTestSupport {

    @Test
    void designer_canCreateDefinitionVersionFields_andReadThemBack() throws Exception {
        SysUser designer = createUser("designer", "Password@123", null, "DESIGNER");
        String designerToken = accessToken(designer, "DESIGNER");
        String formKey = unique("travel-form");

        String definitionResponse = mockMvc.perform(post("/api/forms/definitions")
                        .header("Authorization", authorization(designerToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": %d,
                                  "formKey": "%s",
                                  "formName": "Travel Request"
                                }
                                """.formatted(designer.getId(), formKey)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        Long formId = json(definitionResponse).get("id").asLong();

        String versionResponse = mockMvc.perform(post("/api/forms/versions")
                        .header("Authorization", authorization(designerToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": %d,
                                  "formId": %d,
                                  "schemaJson": %s
                                }
                                """.formatted(
                                designer.getId(),
                                formId,
                                objectMapper.writeValueAsString("{\"fields\":[{\"key\":\"amount\",\"type\":\"number\",\"required\":true},{\"key\":\"reason\",\"type\":\"string\",\"required\":true}]}")
                        )))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.version").value(1))
                .andReturn()
                .getResponse()
                .getContentAsString();

        Long formVersionId = json(versionResponse).get("id").asLong();

        mockMvc.perform(post("/api/forms/fields")
                        .header("Authorization", authorization(designerToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": %d,
                                  "formVersionId": %d,
                                  "fields": [
                                    {
                                      "fieldKey": "amount",
                                      "fieldType": "number",
                                      "label": "Amount",
                                      "required": true
                                    },
                                    {
                                      "fieldKey": "reason",
                                      "fieldType": "string",
                                      "label": "Reason",
                                      "required": true
                                    }
                                  ]
                                }
                                """.formatted(designer.getId(), formVersionId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Fields updated"));

        mockMvc.perform(get("/api/forms/versions/latest")
                        .header("Authorization", authorization(designerToken))
                        .param("formKey", formKey))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(formVersionId));

        String fieldsResponse = mockMvc.perform(get("/api/forms/fields")
                        .header("Authorization", authorization(designerToken))
                        .param("formVersionId", String.valueOf(formVersionId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].fieldKey").value("amount"))
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode fields = json(fieldsResponse);
        assertThat(fields).hasSize(2);
    }

    @Test
    void employee_canValidateAndCreateFormInstance() throws Exception {
        SysUser designer = createUser("designer", "Password@123", null, "DESIGNER");
        SysUser employee = createUser("employee", "Password@123", null, "EMPLOYEE");
        String designerToken = accessToken(designer, "DESIGNER");
        String employeeToken = accessToken(employee, "EMPLOYEE");
        String formKey = unique("expense-form");

        Long formVersionId = createFormVersion(designer, designerToken, formKey,
                "{\"fields\":[{\"key\":\"amount\",\"type\":\"number\",\"required\":true,\"validateRule\":{\"min\":100}},{\"key\":\"reason\",\"type\":\"string\",\"required\":true,\"validateRule\":{\"minLength\":3}}]}");

        mockMvc.perform(post("/api/forms/validate")
                        .header("Authorization", authorization(employeeToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": %d,
                                  "formVersionId": %d,
                                  "data": {
                                    "amount": 300,
                                    "reason": "Taxi"
                                  }
                                }
                                """.formatted(employee.getId(), formVersionId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Validation passed"));

        mockMvc.perform(post("/api/forms/instances")
                        .header("Authorization", authorization(employeeToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": %d,
                                  "formVersionId": %d,
                                  "businessKey": "%s",
                                  "data": {
                                    "amount": 300,
                                    "reason": "Taxi"
                                  }
                                }
                                """.formatted(employee.getId(), formVersionId, unique("biz"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNumber());
    }

    @Test
    void latestVersion_returns404_whenFormDefinitionDoesNotExist() throws Exception {
        SysUser designer = createUser("designer", "Password@123", null, "DESIGNER");
        String designerToken = accessToken(designer, "DESIGNER");

        mockMvc.perform(get("/api/forms/versions/latest")
                        .header("Authorization", authorization(designerToken))
                        .param("formKey", unique("missing-form")))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("Form definition not found"));
    }

    @Test
    void employee_canUploadAttachment_andDownloadIt() throws Exception {
        SysUser designer = createUser("designer", "Password@123", null, "DESIGNER");
        SysUser employee = createUser("employee", "Password@123", null, "EMPLOYEE");
        String designerToken = accessToken(designer, "DESIGNER");
        String employeeToken = accessToken(employee, "EMPLOYEE");

        Long formVersionId = createFormVersion(designer, designerToken, unique("file-form"),
                "{\"fields\":[{\"key\":\"attachment\",\"type\":\"file\",\"required\":false}]}");

        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test-document.pdf",
                "application/pdf",
                "test content".getBytes());

        String uploadResponse = mockMvc.perform(multipart("/api/forms/attachments/upload")
                        .file(file)
                        .param("formVersionId", String.valueOf(formVersionId))
                        .param("fieldKey", "attachment")
                        .header("Authorization", authorization(employeeToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.fieldKey").value("attachment"))
                .andExpect(jsonPath("$.originalName").value("test-document.pdf"))
                .andExpect(jsonPath("$.contentType").value("application/pdf"))
                .andReturn()
                .getResponse()
                .getContentAsString();

        Long attachmentId = json(uploadResponse).get("id").asLong();

        mockMvc.perform(get("/api/forms/attachments/{attachmentId}", attachmentId)
                        .header("Authorization", authorization(employeeToken)))
                .andExpect(status().isOk());

        mockMvc.perform(delete("/api/forms/attachments/{attachmentId}", attachmentId)
                        .header("Authorization", authorization(employeeToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Attachment deleted"));
    }

    @Test
    void uploadAttachment_rejectsUnsupportedFileType() throws Exception {
        SysUser designer = createUser("designer", "Password@123", null, "DESIGNER");
        SysUser employee = createUser("employee", "Password@123", null, "EMPLOYEE");
        String designerToken = accessToken(designer, "DESIGNER");
        String employeeToken = accessToken(employee, "EMPLOYEE");

        Long formVersionId = createFormVersion(designer, designerToken, unique("file-form2"),
                "{\"fields\":[{\"key\":\"attachment\",\"type\":\"file\",\"required\":false}]}");

        MockMultipartFile file = new MockMultipartFile(
                "file",
                "script.exe",
                "application/octet-stream",
                "bad content".getBytes());

        mockMvc.perform(multipart("/api/forms/attachments/upload")
                        .file(file)
                        .param("formVersionId", String.valueOf(formVersionId))
                        .param("fieldKey", "attachment")
                        .header("Authorization", authorization(employeeToken)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void formInstance_linksAttachmentsOnCreation() throws Exception {
        SysUser designer = createUser("designer", "Password@123", null, "DESIGNER");
        SysUser employee = createUser("employee", "Password@123", null, "EMPLOYEE");
        String designerToken = accessToken(designer, "DESIGNER");
        String employeeToken = accessToken(employee, "EMPLOYEE");

        Long formVersionId = createFormVersion(designer, designerToken, unique("link-form"),
                "{\"fields\":[{\"key\":\"file1\",\"type\":\"file\",\"required\":false},{\"key\":\"name\",\"type\":\"string\",\"required\":true}]}");

        MockMultipartFile file = new MockMultipartFile(
                "file",
                "attachment.pdf",
                "application/pdf",
                "pdf content".getBytes());

        String uploadResponse = mockMvc.perform(multipart("/api/forms/attachments/upload")
                        .file(file)
                        .param("formVersionId", String.valueOf(formVersionId))
                        .param("fieldKey", "file1")
                        .header("Authorization", authorization(employeeToken)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        Long attachmentId = json(uploadResponse).get("id").asLong();

        String instanceResponse = mockMvc.perform(post("/api/forms/instances")
                        .header("Authorization", authorization(employeeToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": %d,
                                  "formVersionId": %d,
                                  "businessKey": "%s",
                                  "data": {
                                    "file1": [%d],
                                    "name": "Test"
                                  }
                                }
                                """.formatted(employee.getId(), formVersionId, unique("biz"), attachmentId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNumber())
                .andReturn()
                .getResponse()
                .getContentAsString();

        Long formInstanceId = json(instanceResponse).get("id").asLong();

        String attachmentsResponse = mockMvc.perform(get("/api/forms/instances/{formInstanceId}/attachments", formInstanceId)
                        .header("Authorization", authorization(employeeToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(attachmentId))
                .andExpect(jsonPath("$[0].formInstanceId").value(formInstanceId))
                .andReturn()
                .getResponse()
                .getContentAsString();

        assertThat(json(attachmentsResponse)).hasSize(1);
    }

    @Test
    void previewImageAttachment_returnsInlineContentType() throws Exception {
        SysUser designer = createUser("designer", "Password@123", null, "DESIGNER");
        SysUser employee = createUser("employee", "Password@123", null, "EMPLOYEE");
        String designerToken = accessToken(designer, "DESIGNER");
        String employeeToken = accessToken(employee, "EMPLOYEE");

        Long formVersionId = createFormVersion(designer, designerToken, unique("img-form"),
                "{\"fields\":[{\"key\":\"photo\",\"type\":\"file\",\"required\":false}]}");

        byte[] pngContent = new byte[]{(byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00};
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "photo.png",
                "image/png",
                pngContent);

        String uploadResponse = mockMvc.perform(multipart("/api/forms/attachments/upload")
                        .file(file)
                        .param("formVersionId", String.valueOf(formVersionId))
                        .param("fieldKey", "photo")
                        .header("Authorization", authorization(employeeToken)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        Long attachmentId = json(uploadResponse).get("id").asLong();

        mockMvc.perform(get("/api/forms/attachments/{attachmentId}/preview", attachmentId)
                        .header("Authorization", authorization(employeeToken)))
                .andExpect(status().isOk());
    }

    @Test
    void validate_returnsStructuredErrors_forInvalidFormData() throws Exception {
        SysUser designer = createUser("designer", "Password@123", null, "DESIGNER");
        SysUser employee = createUser("employee", "Password@123", null, "EMPLOYEE");
        String designerToken = accessToken(designer, "DESIGNER");
        String employeeToken = accessToken(employee, "EMPLOYEE");

        Long formVersionId = createFormVersion(designer, designerToken, unique("rule-form"),
                "{\"fields\":[{\"key\":\"amount\",\"type\":\"number\",\"required\":true,\"validateRule\":{\"min\":100}},{\"key\":\"reason\",\"type\":\"string\",\"required\":true,\"validateRule\":{\"pattern\":\"[A-Z].+\"}}]}");

        mockMvc.perform(post("/api/forms/validate")
                        .header("Authorization", authorization(employeeToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": %d,
                                  "formVersionId": %d,
                                  "data": {
                                    "amount": 10,
                                    "reason": "bad"
                                  }
                                }
                                """.formatted(employee.getId(), formVersionId)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Form validation failed"))
                .andExpect(jsonPath("$.errors[0].field").value("amount"));
    }

    private Long createFormVersion(SysUser designer, String designerToken, String formKey, String schemaJson) throws Exception {
        String definitionResponse = mockMvc.perform(post("/api/forms/definitions")
                        .header("Authorization", authorization(designerToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": %d,
                                  "formKey": "%s",
                                  "formName": "Generated Form"
                                }
                                """.formatted(designer.getId(), formKey)))
                .andReturn()
                .getResponse()
                .getContentAsString();
        Long formId = json(definitionResponse).get("id").asLong();

        String versionResponse = mockMvc.perform(post("/api/forms/versions")
                        .header("Authorization", authorization(designerToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": %d,
                                  "formId": %d,
                                  "schemaJson": %s
                                }
                                """.formatted(designer.getId(), formId, objectMapper.writeValueAsString(schemaJson))))
                .andReturn()
                .getResponse()
                .getContentAsString();
        return json(versionResponse).get("id").asLong();
    }
}
