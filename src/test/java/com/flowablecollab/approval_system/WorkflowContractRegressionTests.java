package com.flowablecollab.approval_system;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertTrue;

class WorkflowContractRegressionTests {

    @Test
    void singleApprovalShouldBeExposedInUiAndApiContract() throws IOException {
        String indexHtml = Files.readString(Path.of("src/main/resources/static/index.html"));
        String openapi = Files.readString(Path.of("docs/openapi.yaml"));

        assertTrue(indexHtml.contains("approvalSingle"),
                "start page should expose approvalSingle in the process type selector");
        assertTrue(openapi.contains("approvalSingle"),
                "OpenAPI should document approvalSingle as a supported processKey");
        assertTrue(openapi.contains("approverId"),
                "OpenAPI should document how single approval provides approverId");
    }
}
