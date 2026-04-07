package com.flowablecollab.approval_system.service.workflow.manage;

import java.util.List;

public class RequestTemplateApprovalConfig {

    private List<ApprovalRule> rules;

    public List<ApprovalRule> getRules() {
        return rules;
    }

    public void setRules(List<ApprovalRule> rules) {
        this.rules = rules;
    }

    public static class ApprovalRule {
        private String name;
        private List<ApprovalCondition> conditions;
        private List<ApprovalStep> steps;

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public List<ApprovalCondition> getConditions() {
            return conditions;
        }

        public void setConditions(List<ApprovalCondition> conditions) {
            this.conditions = conditions;
        }

        public List<ApprovalStep> getSteps() {
            return steps;
        }

        public void setSteps(List<ApprovalStep> steps) {
            this.steps = steps;
        }
    }

    public static class ApprovalCondition {
        private String field;
        private String operator;
        private Double value;

        public String getField() {
            return field;
        }

        public void setField(String field) {
            this.field = field;
        }

        public String getOperator() {
            return operator;
        }

        public void setOperator(String operator) {
            this.operator = operator;
        }

        public Double getValue() {
            return value;
        }

        public void setValue(Double value) {
            this.value = value;
        }
    }

    public static class ApprovalStep {
        private String type;
        private Long userId;

        public String getType() {
            return type;
        }

        public void setType(String type) {
            this.type = type;
        }

        public Long getUserId() {
            return userId;
        }

        public void setUserId(Long userId) {
            this.userId = userId;
        }
    }
}
