package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.entity.rbac.SysUser;
import com.flowablecollab.approval_system.service.RbacService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserDirectoryController {

    private final RbacService rbacService;

    @GetMapping
    public ResponseEntity<PageResult<UserListItem>> listUsers(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        List<SysUser> matchedUsers = rbacService.listUsers(keyword, status);
        Map<Long, List<String>> roleCodesByUserId = rbacService.getUserRoleCodes(
                matchedUsers.stream().map(SysUser::getId).toList());
        List<UserListItem> users = matchedUsers.stream()
                .map(user -> UserListItem.from(user, roleCodesByUserId.getOrDefault(user.getId(), List.of())))
                .filter(UserListItem::isApproverEligible)
                .toList();
        int safeSize = Math.max(1, Math.min(size, 200));
        int total = users.size();
        int fromIndex = Math.min(page * safeSize, total);
        int toIndex = Math.min(fromIndex + safeSize, total);
        int totalPages = total == 0 ? 0 : (int) Math.ceil((double) total / safeSize);
        return ResponseEntity.ok(new PageResult<>(users.subList(fromIndex, toIndex), total, page, safeSize, totalPages));
    }

    @Data
    public static class UserListItem {
        private Long userId;
        private String username;
        private Long deptId;
        private Integer status;
        private boolean twoFactorEnabled;
        private List<String> roleCodes;

        public boolean isApproverEligible() {
            return roleCodes == null || roleCodes.stream().noneMatch(role -> "ADMIN".equals(role) || "SYS_ADMIN".equals(role));
        }

        public static UserListItem from(SysUser user, List<String> roleCodes) {
            UserListItem item = new UserListItem();
            item.setUserId(user.getId());
            item.setUsername(user.getUsername());
            item.setDeptId(user.getDeptId());
            item.setStatus(user.getStatus());
            item.setTwoFactorEnabled(user.getTwoFactorEnabled() != null && user.getTwoFactorEnabled() == 1);
            item.setRoleCodes(roleCodes);
            return item;
        }
    }

    public record PageResult<T>(List<T> content, int total, int page, int size, int totalPages) {}
}
