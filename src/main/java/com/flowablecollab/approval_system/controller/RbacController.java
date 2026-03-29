package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.entity.rbac.SysDept;
import com.flowablecollab.approval_system.entity.rbac.SysPost;
import com.flowablecollab.approval_system.entity.rbac.SysRole;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import com.flowablecollab.approval_system.exception.ForbiddenOperationException;
import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.RbacService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/rbac")
@RequiredArgsConstructor
public class RbacController {

    private final RbacService rbacService;

    @PostMapping("/users")
    public ResponseEntity<UserResponse> createUser(@Valid @RequestBody CreateUserRequest request) {
        Long operatorId = resolveOperatorId(request.getOperatorId());
        rbacService.ensureRbacManagePermission(operatorId);
        SysUser user = rbacService.createUser(
                request.getUsername(),
                request.getPassword(),
                request.getDeptId(),
                request.getStatus()
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(UserResponse.from(user));
    }

    @PostMapping("/roles")
    public ResponseEntity<SysRole> createRole(@Valid @RequestBody CreateRoleRequest request) {
        Long operatorId = resolveOperatorId(request.getOperatorId());
        rbacService.ensureRbacManagePermission(operatorId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(rbacService.createRole(request.getRoleCode(), request.getRoleName()));
    }

    @PostMapping("/depts")
    public ResponseEntity<SysDept> createDept(@Valid @RequestBody CreateDeptRequest request) {
        Long operatorId = resolveOperatorId(request.getOperatorId());
        rbacService.ensureRbacManagePermission(operatorId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(rbacService.createDept(request.getDeptCode(), request.getDeptName(), request.getParentId()));
    }

    @PostMapping("/posts")
    public ResponseEntity<SysPost> createPost(@Valid @RequestBody CreatePostRequest request) {
        Long operatorId = resolveOperatorId(request.getOperatorId());
        rbacService.ensureRbacManagePermission(operatorId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(rbacService.createPost(request.getPostCode(), request.getPostName()));
    }

    @PostMapping("/assign")
    public ResponseEntity<ActionResponse> assignRole(@Valid @RequestBody AssignRoleRequest request) {
        Long operatorId = resolveOperatorId(request.getOperatorId());
        rbacService.ensureRbacManagePermission(operatorId);
        rbacService.assignRole(request.getUserId(), request.getRoleId());
        return ResponseEntity.ok(ActionResponse.ok("Role assigned"));
    }

    @PostMapping("/assign-post")
    public ResponseEntity<ActionResponse> assignPost(@Valid @RequestBody AssignPostRequest request) {
        Long operatorId = resolveOperatorId(request.getOperatorId());
        rbacService.ensureRbacManagePermission(operatorId);
        rbacService.assignPost(request.getUserId(), request.getPostId());
        return ResponseEntity.ok(ActionResponse.ok("Post assigned"));
    }

    @PostMapping("/role-data-scope")
    public ResponseEntity<ActionResponse> addRoleDataScope(@Valid @RequestBody AddRoleDataScopeRequest request) {
        Long operatorId = resolveOperatorId(request.getOperatorId());
        rbacService.ensureRbacManagePermission(operatorId);
        rbacService.addRoleDataScope(request.getRoleId(), request.getScopeType(), request.getDeptId());
        return ResponseEntity.ok(ActionResponse.ok("Role data scope added"));
    }

    private Long resolveOperatorId(Long requestedOperatorId) {
        Long currentUserId = SecurityUtils.currentUserId();
        if (currentUserId == null) {
            throw new ForbiddenOperationException("Unauthorized");
        }
        if (requestedOperatorId == null || requestedOperatorId.equals(currentUserId) || SecurityUtils.hasAnyRole("ADMIN", "SYS_ADMIN")) {
            return requestedOperatorId == null ? currentUserId : requestedOperatorId;
        }
        throw new ForbiddenOperationException("operatorId must match current login user");
    }

    @Data
    public static class CreateUserRequest {
        private Long operatorId;

        @NotBlank(message = "username is required")
        @Size(max = 64, message = "username length must be <= 64")
        private String username;

        @NotBlank(message = "password is required")
        @Size(min = 8, max = 128, message = "password length must be between 8 and 128")
        private String password;

        private Long deptId;

        @Min(value = 0, message = "status must be 0 or 1")
        @Max(value = 1, message = "status must be 0 or 1")
        private Integer status;
    }

    @Data
    public static class CreateRoleRequest {
        private Long operatorId;

        @NotBlank(message = "roleCode is required")
        @Size(max = 64, message = "roleCode length must be <= 64")
        private String roleCode;

        @NotBlank(message = "roleName is required")
        @Size(max = 64, message = "roleName length must be <= 64")
        private String roleName;
    }

    @Data
    public static class AssignRoleRequest {
        private Long operatorId;

        @NotNull(message = "userId is required")
        private Long userId;

        @NotNull(message = "roleId is required")
        private Long roleId;
    }

    @Data
    public static class CreateDeptRequest {
        private Long operatorId;

        @Size(max = 64, message = "deptCode length must be <= 64")
        private String deptCode;

        @NotBlank(message = "deptName is required")
        @Size(max = 64, message = "deptName length must be <= 64")
        private String deptName;

        private Long parentId;
    }

    @Data
    public static class CreatePostRequest {
        private Long operatorId;

        @NotBlank(message = "postCode is required")
        @Size(max = 64, message = "postCode length must be <= 64")
        private String postCode;

        @NotBlank(message = "postName is required")
        @Size(max = 64, message = "postName length must be <= 64")
        private String postName;
    }

    @Data
    public static class AssignPostRequest {
        private Long operatorId;

        @NotNull(message = "userId is required")
        private Long userId;

        @NotNull(message = "postId is required")
        private Long postId;
    }

    @Data
    public static class AddRoleDataScopeRequest {
        private Long operatorId;

        @NotNull(message = "roleId is required")
        private Long roleId;

        @NotBlank(message = "scopeType is required")
        @Size(max = 32, message = "scopeType length must be <= 32")
        private String scopeType;

        private Long deptId;
    }

    @Data
    public static class UserResponse {
        private Long id;
        private String username;
        private Long deptId;
        private Integer status;

        public static UserResponse from(SysUser user) {
            UserResponse response = new UserResponse();
            response.setId(user.getId());
            response.setUsername(user.getUsername());
            response.setDeptId(user.getDeptId());
            response.setStatus(user.getStatus());
            return response;
        }
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
