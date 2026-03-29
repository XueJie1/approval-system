package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.exception.ForbiddenOperationException;
import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.AdminUserService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
public class AdminUserController {

    private final AdminUserService adminUserService;

    @GetMapping("/options")
    public ResponseEntity<AdminUserService.UserOptions> options() {
        return ResponseEntity.ok(adminUserService.loadOptions());
    }

    @GetMapping
    public ResponseEntity<AdminUserService.PageResult<AdminUserService.UserListItem>> listUsers(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) Long deptId,
            @RequestParam(required = false) Long roleId,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "10") Integer size) {
        return ResponseEntity.ok(adminUserService.listUsers(keyword, status, deptId, roleId, page, size));
    }

    @GetMapping("/{userId}")
    public ResponseEntity<AdminUserService.UserDetail> getUser(@PathVariable Long userId) {
        return ResponseEntity.ok(adminUserService.getUserDetail(userId));
    }

    @PostMapping
    public ResponseEntity<AdminUserService.UserDetail> createUser(@Valid @RequestBody CreateAdminUserRequest request) {
        AdminUserService.UserDetail user = adminUserService.createUser(new AdminUserService.CreateUserCommand(
                request.getUsername(),
                request.getPassword(),
                request.getDeptId(),
                request.getRoleIds(),
                request.getPostIds(),
                request.getStatus()
        ));
        return ResponseEntity.status(201).body(user);
    }

    @PatchMapping("/{userId}")
    public ResponseEntity<AdminUserService.UserDetail> updateUser(
            @PathVariable Long userId,
            @Valid @RequestBody UpdateAdminUserRequest request) {
        return ResponseEntity.ok(adminUserService.updateUser(userId, new AdminUserService.UpdateUserCommand(
                request.getDeptId(),
                request.getRoleIds(),
                request.getPostIds(),
                request.getStatus()
        )));
    }

    @PatchMapping("/{userId}/status")
    public ResponseEntity<AdminUserService.UserDetail> updateStatus(
            @PathVariable Long userId,
            @Valid @RequestBody UpdateStatusRequest request) {
        return ResponseEntity.ok(adminUserService.updateUserStatus(userId, request.getStatus()));
    }

    @PostMapping("/{userId}/reset-password")
    public ResponseEntity<ActionResponse> resetPassword(
            @PathVariable Long userId,
            @Valid @RequestBody ResetPasswordRequest request) {
        adminUserService.resetPassword(userId, request.getNewPassword());
        return ResponseEntity.ok(ActionResponse.ok("Password reset"));
    }

    @GetMapping("/imports/template")
    public ResponseEntity<ByteArrayResource> downloadTemplate() {
        ByteArrayResource resource = new ByteArrayResource(adminUserService.buildTemplateCsv());
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=user-import-template.csv")
                .contentType(MediaType.parseMediaType("text/csv"))
                .body(resource);
    }

    @PostMapping(value = "/imports/validate", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<AdminUserService.ImportValidationResult> validateImport(
            @RequestPart("file") MultipartFile file,
            @RequestParam(defaultValue = "CREATE_ONLY") String strategy) {
        return ResponseEntity.ok(adminUserService.validateImport(requireCurrentUserId(), strategy, file));
    }

    @PostMapping("/imports/{jobId}/execute")
    public ResponseEntity<AdminUserService.ImportJobSummary> executeImport(
            @PathVariable Long jobId,
            @Valid @RequestBody ExecuteImportRequest request) {
        return ResponseEntity.ok(adminUserService.executeImport(requireCurrentUserId(), jobId, request.isSkipErrorRows()));
    }

    @GetMapping("/imports")
    public ResponseEntity<AdminUserService.PageResult<AdminUserService.ImportJobSummary>> listImports(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "10") Integer size) {
        return ResponseEntity.ok(adminUserService.listImportJobs(status, page, size));
    }

    @GetMapping("/imports/{jobId}/items")
    public ResponseEntity<List<AdminUserService.ImportItemResult>> listImportItems(@PathVariable Long jobId) {
        return ResponseEntity.ok(adminUserService.listImportItems(jobId));
    }

    @GetMapping("/imports/{jobId}/failed-export")
    public ResponseEntity<ByteArrayResource> exportFailedItems(@PathVariable Long jobId) {
        ByteArrayResource resource = new ByteArrayResource(adminUserService.buildFailedItemsCsv(jobId));
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=user-import-failed-" + jobId + ".csv")
                .contentType(MediaType.parseMediaType("text/csv"))
                .body(resource);
    }

    private Long requireCurrentUserId() {
        Long currentUserId = SecurityUtils.currentUserId();
        if (currentUserId == null) {
            throw new ForbiddenOperationException("Unauthorized");
        }
        return currentUserId;
    }

    @Data
    public static class CreateAdminUserRequest {
        @NotBlank(message = "username is required")
        @Size(max = 64, message = "username length must be <= 64")
        private String username;

        @NotBlank(message = "password is required")
        @Size(min = 8, max = 128, message = "password length must be between 8 and 128")
        private String password;

        private Long deptId;

        @NotEmpty(message = "roleIds is required")
        private List<Long> roleIds;

        private List<Long> postIds = List.of();

        @NotNull(message = "status is required")
        @Min(value = 0, message = "status must be 0 or 1")
        @Max(value = 1, message = "status must be 0 or 1")
        private Integer status;
    }

    @Data
    public static class UpdateAdminUserRequest {
        private Long deptId;

        @NotEmpty(message = "roleIds is required")
        private List<Long> roleIds;

        private List<Long> postIds = List.of();

        @NotNull(message = "status is required")
        @Min(value = 0, message = "status must be 0 or 1")
        @Max(value = 1, message = "status must be 0 or 1")
        private Integer status;
    }

    @Data
    public static class UpdateStatusRequest {
        @NotNull(message = "status is required")
        @Min(value = 0, message = "status must be 0 or 1")
        @Max(value = 1, message = "status must be 0 or 1")
        private Integer status;
    }

    @Data
    public static class ResetPasswordRequest {
        @NotBlank(message = "newPassword is required")
        @Size(min = 8, max = 128, message = "password length must be between 8 and 128")
        private String newPassword;
    }

    @Data
    public static class ExecuteImportRequest {
        private boolean skipErrorRows = true;
    }

    @Data
    public static class ActionResponse {
        private boolean success;
        private String message;

        public static ActionResponse ok(String message) {
            ActionResponse response = new ActionResponse();
            response.setSuccess(true);
            response.setMessage(message);
            return response;
        }
    }
}
