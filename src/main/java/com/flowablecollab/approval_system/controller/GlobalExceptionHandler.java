package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.exception.ForbiddenOperationException;
import com.flowablecollab.approval_system.exception.ResourceConflictException;
import com.flowablecollab.approval_system.exception.ResourceNotFoundException;
import io.jsonwebtoken.JwtException;
import lombok.extern.slf4j.Slf4j;
import org.flowable.common.engine.api.FlowableException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> handleIllegalArgument(IllegalArgumentException ex) {
        return ResponseEntity.badRequest().body(Map.of("error", ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error -> errors.put(error.getField(), error.getDefaultMessage()));
        return ResponseEntity.badRequest().body(Map.of(
                "error", "Validation failed",
                "errors", errors
        ));
    }

    @ExceptionHandler(ForbiddenOperationException.class)
    public ResponseEntity<Map<String, String>> handleForbidden(ForbiddenOperationException ex) {
        return ResponseEntity.status(403).body(Map.of("error", ex.getMessage()));
    }

    @ExceptionHandler(ResourceConflictException.class)
    public ResponseEntity<Map<String, String>> handleConflict(ResourceConflictException ex) {
        return ResponseEntity.status(409).body(Map.of("error", ex.getMessage()));
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Map<String, String>> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(404).body(Map.of("error", ex.getMessage()));
    }

    @ExceptionHandler(JwtException.class)
    public ResponseEntity<Map<String, String>> handleJwt(JwtException ex) {
        return ResponseEntity.status(401).body(Map.of("error", "Invalid token"));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Map<String, String>> handleDataIntegrity(DataIntegrityViolationException ex) {
        return ResponseEntity.status(409).body(Map.of("error", "Data integrity violation"));
    }

    @ExceptionHandler(com.flowablecollab.approval_system.service.FormService.FormValidationException.class)
    public ResponseEntity<Map<String, Object>> handleFormValidation(
            com.flowablecollab.approval_system.service.FormService.FormValidationException ex) {
        List<com.flowablecollab.approval_system.service.FormService.FieldError> errors = ex.getErrors();
        return ResponseEntity.badRequest().body(Map.of(
                "error", "Form validation failed",
                "errors", errors
        ));
    }

    @ExceptionHandler(FlowableException.class)
    public ResponseEntity<Map<String, String>> handleFlowable(FlowableException ex) {
        log.error("Workflow engine error", ex);
        if (ex.getMessage() != null && ex.getMessage().contains("Unknown property used in expression")) {
            return ResponseEntity.badRequest().body(Map.of("error", "Workflow variables are incomplete"));
        }
        return ResponseEntity.status(500).body(Map.of("error", "Internal server error"));
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, String>> handleRuntime(RuntimeException ex) {
        log.error("Unhandled runtime exception", ex);
        if (ex.getMessage() != null && ex.getMessage().contains("not found")) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.status(500).body(Map.of("error", "Internal server error"));
    }
}
