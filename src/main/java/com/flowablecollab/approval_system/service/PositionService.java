package com.flowablecollab.approval_system.service;

import com.flowablecollab.approval_system.entity.rbac.SysPost;
import com.flowablecollab.approval_system.exception.ForbiddenOperationException;
import com.flowablecollab.approval_system.exception.ResourceConflictException;
import com.flowablecollab.approval_system.repository.rbac.SysPostRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserPostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class PositionService {

    private final SysPostRepository sysPostRepository;
    private final SysUserPostRepository sysUserPostRepository;
    private final RbacService rbacService;

    public List<SysPost> listAllPositions() {
        return sysPostRepository.findAllByOrderByPostCodeAsc();
    }

    public SysPost getPositionById(Long id) {
        return sysPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Position not found: " + id));
    }

    @Transactional
    public SysPost createPosition(String code, String name) {
        String normalizedCode = code.trim();
        if (sysPostRepository.findByPostCode(normalizedCode).isPresent()) {
            throw new ResourceConflictException("postCode already exists: " + normalizedCode);
        }
        SysPost post = new SysPost();
        post.setPostCode(normalizedCode);
        post.setPostName(name.trim());
        return sysPostRepository.save(post);
    }

    @Transactional
    public SysPost updatePosition(Long id, String code, String name) {
        SysPost post = sysPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Position not found: " + id));

        String normalizedCode = code.trim();
        Optional<SysPost> existingPost = sysPostRepository.findByPostCode(normalizedCode);
        if (existingPost.isPresent() && !existingPost.get().getId().equals(id)) {
            throw new ResourceConflictException("postCode already exists: " + normalizedCode);
        }

        post.setPostCode(normalizedCode);
        post.setPostName(name.trim());
        return sysPostRepository.save(post);
    }

    @Transactional
    public void deletePosition(Long id) {
        SysPost post = sysPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Position not found: " + id));

        if (hasUsersWithPosition(id)) {
            throw new ForbiddenOperationException("Cannot delete position with assigned users");
        }

        sysPostRepository.delete(post);
    }

    public void ensureRbacManagePermission(Long operatorId) {
        rbacService.ensureRbacManagePermission(operatorId);
    }

    private boolean hasUsersWithPosition(Long postId) {
        return sysUserPostRepository.findByPostId(postId).isPresent();
    }
}
