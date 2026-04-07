package com.flowablecollab.approval_system.service;

import com.flowablecollab.approval_system.entity.rbac.SysDept;
import com.flowablecollab.approval_system.exception.ForbiddenOperationException;
import com.flowablecollab.approval_system.exception.ResourceConflictException;
import com.flowablecollab.approval_system.exception.ResourceNotFoundException;
import com.flowablecollab.approval_system.repository.rbac.SysDeptRepository;
import com.flowablecollab.approval_system.repository.rbac.SysRoleDataScopeRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DepartmentService {

    private final SysDeptRepository sysDeptRepository;
    private final SysUserRepository sysUserRepository;
    private final SysRoleDataScopeRepository sysRoleDataScopeRepository;
    private final RbacService rbacService;

    public List<SysDept> listAllDepartments() {
        return sysDeptRepository.findAllByOrderByDeptNameAsc();
    }

    public SysDept getDepartmentById(Long id) {
        return sysDeptRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Department not found: " + id));
    }

    @Transactional
    public SysDept createDepartment(String code, String name, Long parentId) {
        return createDepartment(code, name, parentId, null);
    }

    @Transactional
    public SysDept createDepartment(String code, String name, Long parentId, Long leaderUserId) {
        validateParentDepartment(null, parentId);
        validateLeaderUserId(leaderUserId);
        String normalizedCode = code == null || code.isBlank() ? null : code.trim();
        if (normalizedCode != null && sysDeptRepository.findByDeptCode(normalizedCode).isPresent()) {
            throw new ResourceConflictException("deptCode already exists: " + normalizedCode);
        }
        SysDept dept = new SysDept();
        dept.setDeptCode(normalizedCode);
        dept.setDeptName(name.trim());
        dept.setParentId(parentId);
        dept.setLeaderUserId(leaderUserId);
        return sysDeptRepository.save(dept);
    }

    @Transactional
    public SysDept updateDepartment(Long id, String code, String name, Long parentId) {
        return updateDepartment(id, code, name, parentId, null);
    }

    @Transactional
    public SysDept updateDepartment(Long id, String code, String name, Long parentId, Long leaderUserId) {
        SysDept dept = sysDeptRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Department not found: " + id));

        validateParentDepartment(id, parentId);
        validateLeaderUserId(leaderUserId);

        String normalizedCode = code == null || code.isBlank() ? null : code.trim();
        if (normalizedCode != null) {
            Optional<SysDept> existingDept = sysDeptRepository.findByDeptCode(normalizedCode);
            if (existingDept.isPresent() && !existingDept.get().getId().equals(id)) {
                throw new ResourceConflictException("deptCode already exists: " + normalizedCode);
            }
        }

        dept.setDeptCode(normalizedCode);
        dept.setDeptName(name.trim());
        dept.setParentId(parentId);
        dept.setLeaderUserId(leaderUserId);
        return sysDeptRepository.save(dept);
    }

    @Transactional
    public void deleteDepartment(Long id) {
        SysDept dept = sysDeptRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Department not found: " + id));

        if (hasChildDepartments(id)) {
            throw new ForbiddenOperationException("Cannot delete department with child departments");
        }

        if (hasUsersInDepartment(id)) {
            throw new ForbiddenOperationException("Cannot delete department with assigned users");
        }

        sysDeptRepository.delete(dept);
    }

    public void ensureRbacManagePermission(Long operatorId) {
        rbacService.ensureRbacManagePermission(operatorId);
    }

    private boolean hasChildDepartments(Long parentId) {
        return sysDeptRepository.findAllByOrderByDeptNameAsc().stream()
                .anyMatch(dept -> parentId.equals(dept.getParentId()));
    }

    private boolean hasUsersInDepartment(Long deptId) {
        return sysUserRepository.findByDeptId(deptId).isPresent();
    }

    private void validateParentDepartment(Long deptId, Long parentId) {
        if (parentId == null) {
            return;
        }
        if (!sysDeptRepository.existsById(parentId)) {
            throw new IllegalArgumentException("parentId does not exist: " + parentId);
        }
        if (deptId != null && deptId.equals(parentId)) {
            throw new IllegalArgumentException("parentId cannot be the same as department id");
        }
        if (deptId != null && wouldCreateCycle(deptId, parentId)) {
            throw new IllegalArgumentException("parentId would create a department cycle");
        }
    }

    private boolean wouldCreateCycle(Long deptId, Long parentId) {
        Long currentId = parentId;
        while (currentId != null) {
            if (deptId.equals(currentId)) {
                return true;
            }
            SysDept current = sysDeptRepository.findById(currentId).orElse(null);
            if (current == null) {
                return false;
            }
            currentId = current.getParentId();
        }
        return false;
    }

    private void validateLeaderUserId(Long leaderUserId) {
        if (leaderUserId == null) {
            return;
        }
        if (!sysUserRepository.existsById(leaderUserId)) {
            throw new IllegalArgumentException("leaderUserId does not exist: " + leaderUserId);
        }
    }
}
