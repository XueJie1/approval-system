package com.flowablecollab.approval_system.service.form;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.flowablecollab.approval_system.entity.form.FormDefinition;
import com.flowablecollab.approval_system.entity.form.FormField;
import com.flowablecollab.approval_system.entity.form.FormVersion;
import com.flowablecollab.approval_system.repository.form.FormDefinitionRepository;
import com.flowablecollab.approval_system.repository.form.FormFieldRepository;
import com.flowablecollab.approval_system.repository.form.FormVersionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
public class FormCatalogBootstrapService {

    private final FormDefinitionRepository formDefinitionRepository;
    private final FormVersionRepository formVersionRepository;
    private final FormFieldRepository formFieldRepository;
    private final ObjectMapper objectMapper;

    public FormCatalogBootstrapService(FormDefinitionRepository formDefinitionRepository,
                                      FormVersionRepository formVersionRepository,
                                      FormFieldRepository formFieldRepository,
                                      ObjectMapper objectMapper) {
        this.formDefinitionRepository = formDefinitionRepository;
        this.formVersionRepository = formVersionRepository;
        this.formFieldRepository = formFieldRepository;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public void bootstrapDefaults() {
        for (BuiltInFormSeed seed : builtInSeeds()) {
            FormDefinition definition = formDefinitionRepository.findByFormKey(seed.formKey())
                    .orElseGet(FormDefinition::new);
            definition.setFormKey(seed.formKey());
            definition.setFormName(seed.formName());
            definition.setStatus(1);
            definition = formDefinitionRepository.save(definition);

            FormVersion version = formVersionRepository.findTopByFormIdOrderByVersionDesc(definition.getId())
                    .orElseGet(FormVersion::new);
            boolean creatingVersion = version.getId() == null;
            version.setFormId(definition.getId());
            version.setVersion(creatingVersion ? 1 : version.getVersion());
            version.setSchemaJson(seed.schemaJson());
            version.setStatus(FormVersion.STATUS_PUBLISHED);
            version.setPublishedBy(0L);
            version.setPublishedAt(java.time.LocalDateTime.now());
            version = formVersionRepository.save(version);

            formFieldRepository.deleteByFormVersionId(version.getId());
            int orderNo = 0;
            for (BuiltInFieldSeed fieldSeed : seed.fields()) {
                FormField field = new FormField();
                field.setFormVersionId(version.getId());
                field.setFieldKey(fieldSeed.fieldKey());
                field.setVariableKey(fieldSeed.fieldKey());
                field.setFieldType(fieldSeed.fieldType());
                field.setLabel(fieldSeed.label());
                field.setRequired(fieldSeed.required() ? 1 : 0);
                field.setVisibleRule(null);
                field.setValidateRule(null);
                field.setOptionsJson(fieldSeed.optionsJson());
                field.setDefaultValue(null);
                field.setSortOrder(orderNo++);
                formFieldRepository.save(field);
            }
        }
    }

    private List<BuiltInFormSeed> builtInSeeds() {
        return List.of(
                new BuiltInFormSeed("leave_request", "请假申请表", schema(List.of(
                        fieldSchema("leaveType", "select", "请假类型", true, List.of("事假", "病假", "年假")),
                        fieldSchema("startDate", "datetime", "开始时间", true, null),
                        fieldSchema("endDate", "datetime", "结束时间", true, null),
                        fieldSchema("days", "number", "请假天数", true, null),
                        fieldSchema("reason", "string", "请假原因", true, null)
                )), List.of(
                        new BuiltInFieldSeed("leaveType", "select", "请假类型", true, optionsJson(List.of("事假", "病假", "年假"))),
                        new BuiltInFieldSeed("startDate", "datetime", "开始时间", true, null),
                        new BuiltInFieldSeed("endDate", "datetime", "结束时间", true, null),
                        new BuiltInFieldSeed("days", "number", "请假天数", true, null),
                        new BuiltInFieldSeed("reason", "string", "请假原因", true, null)
                )),
                new BuiltInFormSeed("expense_request", "报销申请表", schema(List.of(
                        fieldSchema("expenseType", "select", "费用类型", true, List.of("差旅", "餐饮", "办公")),
                        fieldSchema("amount", "number", "报销金额", true, null),
                        fieldSchema("occurredOn", "date", "发生日期", true, null),
                        fieldSchema("reason", "string", "报销事由", true, null)
                )), List.of(
                        new BuiltInFieldSeed("expenseType", "select", "费用类型", true, optionsJson(List.of("差旅", "餐饮", "办公"))),
                        new BuiltInFieldSeed("amount", "number", "报销金额", true, null),
                        new BuiltInFieldSeed("occurredOn", "date", "发生日期", true, null),
                        new BuiltInFieldSeed("reason", "string", "报销事由", true, null)
                )),
                new BuiltInFormSeed("travel_request", "出差申请表", schema(List.of(
                        fieldSchema("destination", "string", "出差地点", true, null),
                        fieldSchema("startDate", "datetime", "出差开始时间", true, null),
                        fieldSchema("endDate", "datetime", "出差结束时间", true, null),
                        fieldSchema("budget", "number", "预计预算", false, null),
                        fieldSchema("reason", "string", "出差事由", true, null)
                )), List.of(
                        new BuiltInFieldSeed("destination", "string", "出差地点", true, null),
                        new BuiltInFieldSeed("startDate", "datetime", "出差开始时间", true, null),
                        new BuiltInFieldSeed("endDate", "datetime", "出差结束时间", true, null),
                        new BuiltInFieldSeed("budget", "number", "预计预算", false, null),
                        new BuiltInFieldSeed("reason", "string", "出差事由", true, null)
                )),
                new BuiltInFormSeed("purchase_request", "采购申请表", schema(List.of(
                        fieldSchema("itemName", "string", "采购物品", true, null),
                        fieldSchema("quantity", "number", "数量", true, null),
                        fieldSchema("amount", "number", "预算金额", true, null),
                        fieldSchema("reason", "string", "采购原因", true, null)
                )), List.of(
                        new BuiltInFieldSeed("itemName", "string", "采购物品", true, null),
                        new BuiltInFieldSeed("quantity", "number", "数量", true, null),
                        new BuiltInFieldSeed("amount", "number", "预算金额", true, null),
                        new BuiltInFieldSeed("reason", "string", "采购原因", true, null)
                )),
                new BuiltInFormSeed("seal_request", "用章申请表", schema(List.of(
                        fieldSchema("sealType", "select", "用章类型", true, List.of("公章", "合同章", "财务章")),
                        fieldSchema("documentName", "string", "文件名称", true, null),
                        fieldSchema("copies", "number", "份数", true, null),
                        fieldSchema("reason", "string", "用章事由", true, null)
                )), List.of(
                        new BuiltInFieldSeed("sealType", "select", "用章类型", true, optionsJson(List.of("公章", "合同章", "财务章"))),
                        new BuiltInFieldSeed("documentName", "string", "文件名称", true, null),
                        new BuiltInFieldSeed("copies", "number", "份数", true, null),
                        new BuiltInFieldSeed("reason", "string", "用章事由", true, null)
                )),
                new BuiltInFormSeed("contract_request", "合同审批表", schema(List.of(
                        fieldSchema("contractName", "string", "合同名称", true, null),
                        fieldSchema("counterparty", "string", "合同对方", true, null),
                        fieldSchema("amount", "number", "合同金额", true, null),
                        fieldSchema("riskNote", "string", "风险说明", false, null)
                )), List.of(
                        new BuiltInFieldSeed("contractName", "string", "合同名称", true, null),
                        new BuiltInFieldSeed("counterparty", "string", "合同对方", true, null),
                        new BuiltInFieldSeed("amount", "number", "合同金额", true, null),
                        new BuiltInFieldSeed("riskNote", "string", "风险说明", false, null)
                ))
        );
    }

    private String schema(List<Map<String, Object>> fields) {
        try {
            return objectMapper.writeValueAsString(Map.of("fields", fields));
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Failed to build form schema", e);
        }
    }

    private Map<String, Object> fieldSchema(String key, String type, String label, boolean required, List<String> options) {
        java.util.LinkedHashMap<String, Object> field = new java.util.LinkedHashMap<>();
        field.put("key", key);
        field.put("type", type);
        field.put("label", label);
        field.put("required", required);
        if (options != null && !options.isEmpty()) {
            field.put("options", options);
        }
        return field;
    }

    private String optionsJson(List<String> options) {
        try {
            return objectMapper.writeValueAsString(options);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Failed to build field options", e);
        }
    }

    private record BuiltInFormSeed(String formKey, String formName, String schemaJson, List<BuiltInFieldSeed> fields) {
    }

    private record BuiltInFieldSeed(String fieldKey, String fieldType, String label, boolean required, String optionsJson) {
    }
}
