package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.entity.form.FormDefinition;
import com.flowablecollab.approval_system.entity.form.FormField;
import com.flowablecollab.approval_system.entity.form.FormVersion;
import com.flowablecollab.approval_system.repository.form.FormDefinitionRepository;
import com.flowablecollab.approval_system.repository.form.FormFieldRepository;
import com.flowablecollab.approval_system.repository.form.FormVersionRepository;
import com.flowablecollab.approval_system.service.form.FormCatalogBootstrapService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;

class FormCatalogBootstrapIntegrationTests extends AbstractIntegrationTestSupport {

    @Autowired
    private FormCatalogBootstrapService formCatalogBootstrapService;

    @Autowired
    private FormDefinitionRepository formDefinitionRepository;

    @Autowired
    private FormVersionRepository formVersionRepository;

    @Autowired
    private FormFieldRepository formFieldRepository;

    @Test
    void startupBootstrapsBuiltInRequestForms() {
        formCatalogBootstrapService.bootstrapDefaults();

        FormDefinition definition = formDefinitionRepository.findByFormKey("leave_request").orElseThrow();
        FormVersion version = formVersionRepository.findTopByFormIdOrderByVersionDesc(definition.getId()).orElseThrow();

        assertThat(definition.getFormName()).isEqualTo("请假申请表");
        assertThat(version.getSchemaJson()).contains("leaveType");
        assertThat(formFieldRepository.findByFormVersionId(version.getId())).isNotEmpty();
    }

    @Test
    void bootstrapIsIdempotentForBuiltInRequestForms() {
        long beforeDefinitions = formDefinitionRepository.count();
        long beforeVersions = formVersionRepository.count();

        formCatalogBootstrapService.bootstrapDefaults();

        assertThat(formDefinitionRepository.count()).isEqualTo(beforeDefinitions);
        assertThat(formVersionRepository.count()).isEqualTo(beforeVersions);
    }

    @Test
    void startupBootstrapsBuiltInTemporalFieldsWithExplicitTypes() {
        formCatalogBootstrapService.bootstrapDefaults();

        FormDefinition leaveDefinition = formDefinitionRepository.findByFormKey("leave_request").orElseThrow();
        FormVersion leaveVersion = formVersionRepository.findTopByFormIdOrderByVersionDesc(leaveDefinition.getId()).orElseThrow();
        java.util.List<FormField> leaveFields = formFieldRepository.findByFormVersionId(leaveVersion.getId());

        assertThat(leaveFields)
                .anyMatch(field -> field.getFieldKey().equals("startDate") && field.getFieldType().equals("datetime"))
                .anyMatch(field -> field.getFieldKey().equals("endDate") && field.getFieldType().equals("datetime"));

        FormDefinition expenseDefinition = formDefinitionRepository.findByFormKey("expense_request").orElseThrow();
        FormVersion expenseVersion = formVersionRepository.findTopByFormIdOrderByVersionDesc(expenseDefinition.getId()).orElseThrow();
        java.util.List<FormField> expenseFields = formFieldRepository.findByFormVersionId(expenseVersion.getId());

        assertThat(expenseFields)
                .anyMatch(field -> field.getFieldKey().equals("occurredOn") && field.getFieldType().equals("date"));
    }
}
