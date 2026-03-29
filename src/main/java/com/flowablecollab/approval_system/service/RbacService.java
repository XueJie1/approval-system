package com.flowablecollab.approval_system.service;

import com.flowablecollab.approval_system.entity.rbac.SysRole;
import com.flowablecollab.approval_system.entity.rbac.SysRoleDataScope;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import com.flowablecollab.approval_system.entity.rbac.SysUserPost;
import com.flowablecollab.approval_system.entity.rbac.SysUserRole;
import com.flowablecollab.approval_system.entity.rbac.SysDept;
import com.flowablecollab.approval_system.entity.rbac.SysPost;
import com.flowablecollab.approval_system.exception.ForbiddenOperationException;
import com.flowablecollab.approval_system.exception.ResourceConflictException;
import com.flowablecollab.approval_system.repository.rbac.SysDeptRepository;
import com.flowablecollab.approval_system.repository.rbac.SysPostRepository;
import com.flowablecollab.approval_system.repository.rbac.SysRoleDataScopeRepository;
import com.flowablecollab.approval_system.repository.rbac.SysRoleRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserPostRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserRoleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RbacService {

    private final SysUserRepository sysUserRepository;
    private final SysRoleRepository sysRoleRepository;
    private final SysUserRoleRepository sysUserRoleRepository;
    private final SysRoleDataScopeRepository sysRoleDataScopeRepository;
    private final SysUserPostRepository sysUserPostRepository;
    private final SysDeptRepository sysDeptRepository;
    private final SysPostRepository sysPostRepository;

    public SysUser createUser(String username, String password, Long deptId, Integer status) {
        String normalizedUsername = username.trim();
        if (sysUserRepository.findByUsername(normalizedUsername).isPresent()) {
            throw new ResourceConflictException("username already exists: " + normalizedUsername);
        }
        if (deptId != null && !sysDeptRepository.existsById(deptId)) {
            throw new IllegalArgumentException("deptId does not exist: " + deptId);
        }
        SysUser user = new SysUser();
        user.setUsername(normalizedUsername);
        user.setPassword(encodePassword(password));
        user.setDeptId(deptId);
        user.setStatus(status == null ? 1 : status);
        user.setTwoFactorEnabled(0);
        user.setLoginFailures(0);
        return sysUserRepository.save(user);
    }

    public SysRole createRole(String code, String name) {
        String normalizedCode = code.trim();
        if (sysRoleRepository.findByRoleCode(normalizedCode).isPresent()) {
            throw new ResourceConflictException("roleCode already exists: " + normalizedCode);
        }
        SysRole role = new SysRole();
        role.setRoleCode(normalizedCode);
        role.setRoleName(name.trim());
        role.setStatus(1);
        return sysRoleRepository.save(role);
    }

    public SysDept createDept(String name, Long parentId) {
        return createDept(null, name, parentId);
    }

    public SysDept createDept(String code, String name, Long parentId) {
        if (parentId != null && !sysDeptRepository.existsById(parentId)) {
            throw new IllegalArgumentException("parentId does not exist: " + parentId);
        }
        String normalizedCode = code == null || code.isBlank() ? null : code.trim();
        if (normalizedCode != null && sysDeptRepository.findByDeptCode(normalizedCode).isPresent()) {
            throw new ResourceConflictException("deptCode already exists: " + normalizedCode);
        }
        SysDept dept = new SysDept();
        dept.setDeptCode(normalizedCode);
        dept.setDeptName(name.trim());
        dept.setParentId(parentId);
        return sysDeptRepository.save(dept);
    }

    public SysPost createPost(String code, String name) {
        String normalizedCode = code.trim();
        if (sysPostRepository.findByPostCode(normalizedCode).isPresent()) {
            throw new ResourceConflictException("postCode already exists: " + normalizedCode);
        }
        SysPost post = new SysPost();
        post.setPostCode(normalizedCode);
        post.setPostName(name.trim());
        return sysPostRepository.save(post);
    }

    public void assignRole(Long userId, Long roleId) {
        ensureUserAndRoleExist(userId, roleId);
        if (sysUserRoleRepository.existsByUserIdAndRoleId(userId, roleId)) {
            return;
        }
        SysUserRole mapping = new SysUserRole();
        mapping.setUserId(userId);
        mapping.setRoleId(roleId);
        sysUserRoleRepository.save(mapping);
    }

    public void assignPost(Long userId, Long postId) {
        if (!sysUserRepository.existsById(userId)) {
            throw new IllegalArgumentException("userId does not exist: " + userId);
        }
        if (!sysPostRepository.existsById(postId)) {
            throw new IllegalArgumentException("postId does not exist: " + postId);
        }
        if (sysUserPostRepository.existsByUserIdAndPostId(userId, postId)) {
            return;
        }
        SysUserPost mapping = new SysUserPost();
        mapping.setUserId(userId);
        mapping.setPostId(postId);
        sysUserPostRepository.save(mapping);
    }

    public void addRoleDataScope(Long roleId, String scopeType, Long deptId) {
        if (!sysRoleRepository.existsById(roleId)) {
            throw new IllegalArgumentException("roleId does not exist: " + roleId);
        }
        String normalizedScopeType = normalizeScopeType(scopeType);
        validateScopeDeptRelation(normalizedScopeType, deptId);
        SysRoleDataScope scope = new SysRoleDataScope();
        scope.setRoleId(roleId);
        scope.setScopeType(normalizedScopeType);
        scope.setDeptId(deptId);
        sysRoleDataScopeRepository.save(scope);
    }

    public void ensureRbacManagePermission(Long operatorId) {
        if (isBootstrapMode()) {
            return;
        }
        if (operatorId == null) {
            throw new ForbiddenOperationException("operatorId is required");
        }
        boolean isAdmin = hasRole(operatorId, "ADMIN") || hasRole(operatorId, "SYS_ADMIN");
        if (!isAdmin) {
            throw new ForbiddenOperationException("operator has no RBAC management permission");
        }
    }

    public boolean hasRole(Long userId, String roleCode) {
        if (userId == null || roleCode == null || roleCode.isBlank()) {
            return false;
        }
        SysRole role = sysRoleRepository.findByRoleCode(roleCode).orElse(null);
        if (role == null) {
            return false;
        }
        List<SysUserRole> mappings = sysUserRoleRepository.findByUserId(userId);
        return mappings.stream().anyMatch(m -> m.getRoleId().equals(role.getId()));
    }

    public Set<Long> getAccessibleDeptIds(Long userId) {
        List<SysUserRole> mappings = sysUserRoleRepository.findByUserId(userId);
        if (mappings.isEmpty()) {
            return Set.of();
        }
        Set<Long> roleIds = mappings.stream().map(SysUserRole::getRoleId).collect(Collectors.toSet());
        List<SysRoleDataScope> scopes = roleIds.stream()
                .flatMap(roleId -> sysRoleDataScopeRepository.findByRoleId(roleId).stream())
                .toList();
        if (scopes.stream().anyMatch(scope -> "ALL".equalsIgnoreCase(scope.getScopeType()))) {
            return null;
        }
        if (scopes.stream().anyMatch(scope -> "SELF".equalsIgnoreCase(scope.getScopeType()))) {
            return Set.of(-1L);
        }
        if (scopes.stream().anyMatch(scope -> "DEPT".equalsIgnoreCase(scope.getScopeType()))) {
            return sysUserRepository.findById(userId)
                    .map(SysUser::getDeptId)
                    .map(Set::of)
                    .orElse(Set.of());
        }
        if (scopes.stream().anyMatch(scope -> "DEPT_AND_CHILD".equalsIgnoreCase(scope.getScopeType()))) {
            return sysUserRepository.findById(userId)
                    .map(SysUser::getDeptId)
                    .map(this::expandDeptWithChildren)
                    .orElse(Set.of());
        }
        Set<Long> deptIds = scopes.stream()
                .filter(scope -> "CUSTOM".equalsIgnoreCase(scope.getScopeType()))
                .map(SysRoleDataScope::getDeptId)
                .filter(id -> id != null)
                .flatMap(id -> expandDeptWithChildren(id).stream())
                .collect(Collectors.toSet());
        if (!deptIds.isEmpty()) {
            return deptIds;
        }
        return sysUserRepository.findById(userId)
                .map(SysUser::getDeptId)
                .map(this::expandDeptWithChildren)
                .orElse(Set.of());
    }

    private Set<Long> expandDeptWithChildren(Long deptId) {
        if (deptId == null) {
            return Set.of();
        }
        List<SysDept> allDepts = sysDeptRepository.findAll();
        Set<Long> result = new java.util.HashSet<>();
        java.util.ArrayDeque<Long> queue = new java.util.ArrayDeque<>();
        queue.add(deptId);
        while (!queue.isEmpty()) {
            Long current = queue.poll();
            if (!result.add(current)) {
                continue;
            }
            for (SysDept dept : allDepts) {
                if (current.equals(dept.getParentId())) {
                    queue.add(dept.getId());
                }
            }
        }
        return result;
    }

    public Set<Long> getUserPostIds(Long userId) {
        List<SysUserPost> mappings = sysUserPostRepository.findByUserId(userId);
        return mappings.stream().map(SysUserPost::getPostId).collect(Collectors.toSet());
    }

    public List<SysUser> listUsers(String keyword, Integer status) {
        String normalizedKeyword = keyword == null ? "" : keyword.trim();
        if (!normalizedKeyword.isEmpty() && status != null) {
            return sysUserRepository.findByUsernameContainingIgnoreCaseAndStatusOrderByUsernameAsc(normalizedKeyword, status);
        }
        if (!normalizedKeyword.isEmpty()) {
            return sysUserRepository.findByUsernameContainingIgnoreCaseOrderByUsernameAsc(normalizedKeyword);
        }
        if (status != null) {
            return sysUserRepository.findByStatusOrderByUsernameAsc(status);
        }
        return sysUserRepository.findAll().stream()
                .sorted(java.util.Comparator.comparing(SysUser::getUsername, String.CASE_INSENSITIVE_ORDER))
                .toList();
    }

    private void ensureUserAndRoleExist(Long userId, Long roleId) {
        if (!sysUserRepository.existsById(userId)) {
            throw new IllegalArgumentException("userId does not exist: " + userId);
        }
        if (!sysRoleRepository.existsById(roleId)) {
            throw new IllegalArgumentException("roleId does not exist: " + roleId);
        }
    }

    private String encodePassword(String rawPassword) {
        if (rawPassword == null || rawPassword.isBlank()) {
            return null;
        }
        return BCrypt.hashpw(rawPassword, BCrypt.gensalt());
    }

    private String normalizeScopeType(String scopeType) {
        if (scopeType == null || scopeType.isBlank()) {
            throw new IllegalArgumentException("scopeType is required");
        }
        String normalized = scopeType.trim().toUpperCase(Locale.ROOT);
        if (!Set.of("ALL", "SELF", "DEPT", "DEPT_AND_CHILD", "CUSTOM").contains(normalized)) {
            throw new IllegalArgumentException("invalid scopeType: " + scopeType);
        }
        return normalized;
    }

    private void validateScopeDeptRelation(String scopeType, Long deptId) {
        if ("CUSTOM".equals(scopeType) && deptId == null) {
            throw new IllegalArgumentException("deptId is required when scopeType is CUSTOM");
        }
        if (deptId != null && !sysDeptRepository.existsById(deptId)) {
            throw new IllegalArgumentException("deptId does not exist: " + deptId);
        }
    }

    private boolean isBootstrapMode() {
        SysRole adminRole = sysRoleRepository.findByRoleCode("ADMIN").orElse(null);
        if (adminRole != null && sysUserRoleRepository.existsByRoleId(adminRole.getId())) {
            return false;
        }
        SysRole sysAdminRole = sysRoleRepository.findByRoleCode("SYS_ADMIN").orElse(null);
        return sysAdminRole == null || !sysUserRoleRepository.existsByRoleId(sysAdminRole.getId());
    }

    public boolean isBootstrapModeActive() {
        return isBootstrapMode();
    }
}
