package com.flowablecollab.approval_system.exception;

import java.util.Map;

public class WorkflowValidationException extends RuntimeException {

    public static final String BPMN_KEY_MISMATCH = "BPMN_KEY_MISMATCH";
    public static final String BPMN_PROCESS_COUNT_INVALID = "BPMN_PROCESS_COUNT_INVALID";
    public static final String BPMN_XML_INVALID = "BPMN_XML_INVALID";
    public static final String NODE_CONFIG_MISMATCH = "NODE_CONFIG_MISMATCH";
    public static final String FORM_VERSION_REQUIRED = "FORM_VERSION_REQUIRED";

    private final String code;
    private final Map<String, Object> details;

    public WorkflowValidationException(String code, String message) {
        this(code, message, null);
    }

    public WorkflowValidationException(String code, String message, Map<String, Object> details) {
        super(message);
        this.code = code;
        this.details = details;
    }

    public String getCode() {
        return code;
    }

    public Map<String, Object> getDetails() {
        return details;
    }
}
