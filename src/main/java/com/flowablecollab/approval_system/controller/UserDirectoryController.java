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
    public ResponseEntity<List<UserListItem>> listUsers(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer status) {
        List<SysUser> matchedUsers = rbacService.listUsers(keyword, status);
        Map<Long, List<String>> roleCodesByUserId = rbacService.getUserRoleCodes(
                matchedUsers.stream().map(SysUser::getId).toList());
        List<UserListItem> users = matchedUsers.stream()
                .map(user -> UserListItem.from(user, roleCodesByUserId.getOrDefault(user.getId(), List.of())))
                .filter(UserListItem::isApproverEligible)
                .toList();
        return ResponseEntity.ok(users);
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
}
