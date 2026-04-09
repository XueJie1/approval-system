package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.entity.rbac.SysPost;
import com.flowablecollab.approval_system.exception.ForbiddenOperationException;
import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.PositionService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/positions")
@RequiredArgsConstructor
@PreAuthorize("hasRole('SYS_ADMIN')")
public class PositionController {

    private final PositionService positionService;

    @GetMapping
    public ResponseEntity<List<SysPost>> listPositions() {
        Long currentUserId = SecurityUtils.currentUserId();
        if (currentUserId == null) {
            throw new ForbiddenOperationException("Unauthorized");
        }
        return ResponseEntity.ok(positionService.listAllPositions());
    }

    @GetMapping("/{id}")
    public ResponseEntity<SysPost> getPositionById(@PathVariable Long id) {
        Long currentUserId = SecurityUtils.currentUserId();
        if (currentUserId == null) {
            throw new ForbiddenOperationException("Unauthorized");
        }
        SysPost post = positionService.getPositionById(id);
        return ResponseEntity.ok(post);
    }

    @PostMapping
    public ResponseEntity<SysPost> createPosition(@Valid @RequestBody CreatePositionRequest request) {
        Long operatorId = resolveOperatorId(request.getOperatorId());
        positionService.ensureRbacManagePermission(operatorId);
        SysPost post = positionService.createPosition(
                request.getPostCode(),
                request.getPostName()
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(post);
    }

    @PutMapping("/{id}")
    public ResponseEntity<SysPost> updatePosition(
            @PathVariable Long id,
            @Valid @RequestBody UpdatePositionRequest request) {
        Long operatorId = resolveOperatorId(request.getOperatorId());
        positionService.ensureRbacManagePermission(operatorId);
        SysPost post = positionService.updatePosition(
                id,
                request.getPostCode(),
                request.getPostName()
        );
        return ResponseEntity.ok(post);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePosition(@PathVariable Long id) {
        Long currentUserId = resolveOperatorId(null);
        positionService.ensureRbacManagePermission(currentUserId);
        positionService.deletePosition(id);
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
    public static class CreatePositionRequest {
        private Long operatorId;

        @NotBlank(message = "postCode is required")
        @Size(max = 64, message = "postCode length must be <= 64")
        private String postCode;

        @NotBlank(message = "postName is required")
        @Size(max = 64, message = "postName length must be <= 64")
        private String postName;
    }

    @Data
    public static class UpdatePositionRequest {
        private Long operatorId;

        @NotBlank(message = "postCode is required")
        @Size(max = 64, message = "postCode length must be <= 64")
        private String postCode;

        @NotBlank(message = "postName is required")
        @Size(max = 64, message = "postName length must be <= 64")
        private String postName;
    }
}
