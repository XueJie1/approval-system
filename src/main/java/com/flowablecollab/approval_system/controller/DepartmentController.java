package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.entity.rbac.SysDept;
import com.flowablecollab.approval_system.exception.ForbiddenOperationException;
import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.DepartmentService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/departments")
@RequiredArgsConstructor
public class DepartmentController {

    private final DepartmentService departmentService;

    @GetMapping
    public ResponseEntity<List<SysDept>> listDepartments() {
        Long currentUserId = SecurityUtils.currentUserId();
        if (currentUserId == null) {
            throw new ForbiddenOperationException("Unauthorized");
        }
        return ResponseEntity.ok(departmentService.listAllDepartments());
    }

    @GetMapping("/{id}")
    public ResponseEntity<SysDept> getDepartmentById(@PathVariable Long id) {
        Long currentUserId = SecurityUtils.currentUserId();
        if (currentUserId == null) {
            throw new ForbiddenOperationException("Unauthorized");
        }
        SysDept dept = departmentService.getDepartmentById(id);
        return ResponseEntity.ok(dept);
    }

    @PostMapping
    public ResponseEntity<SysDept> createDepartment(@Valid @RequestBody CreateDepartmentRequest request) {
        Long operatorId = resolveOperatorId(request.getOperatorId());
        departmentService.ensureRbacManagePermission(operatorId);
        SysDept dept = departmentService.createDepartment(
                request.getDeptCode(),
                request.getDeptName(),
                request.getParentId(),
                request.getLeaderUserId()
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(dept);
    }

    @PutMapping("/{id}")
    public ResponseEntity<SysDept> updateDepartment(
            @PathVariable Long id,
            @Valid @RequestBody UpdateDepartmentRequest request) {
        Long operatorId = resolveOperatorId(request.getOperatorId());
        departmentService.ensureRbacManagePermission(operatorId);
        SysDept dept = departmentService.updateDepartment(
                id,
                request.getDeptCode(),
                request.getDeptName(),
                request.getParentId(),
                request.getLeaderUserId()
        );
        return ResponseEntity.ok(dept);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteDepartment(@PathVariable Long id) {
        Long currentUserId = resolveOperatorId(null);
        departmentService.ensureRbacManagePermission(currentUserId);
        departmentService.deleteDepartment(id);
        return ResponseEntity.noContent().build();
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
    public static class CreateDepartmentRequest {
        private Long operatorId;

        @Size(max = 64, message = "deptCode length must be <= 64")
        private String deptCode;

        @NotBlank(message = "deptName is required")
        @Size(max = 64, message = "deptName length must be <= 64")
        private String deptName;

        private Long parentId;

        private Long leaderUserId;
    }

    @Data
    public static class UpdateDepartmentRequest {
        private Long operatorId;

        @Size(max = 64, message = "deptCode length must be <= 64")
        private String deptCode;

        @NotBlank(message = "deptName is required")
        @Size(max = 64, message = "deptName length must be <= 64")
        private String deptName;

        private Long parentId;

        private Long leaderUserId;
    }
}
