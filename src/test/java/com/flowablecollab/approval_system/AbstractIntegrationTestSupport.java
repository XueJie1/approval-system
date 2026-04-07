package com.flowablecollab.approval_system;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.flowablecollab.approval_system.entity.rbac.SysRole;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import com.flowablecollab.approval_system.repository.BizRequestLogRepository;
import com.flowablecollab.approval_system.repository.BizRequestRepository;
import com.flowablecollab.approval_system.repository.BizRequestTaskRepository;
import com.flowablecollab.approval_system.repository.form.FormDefinitionRepository;
import com.flowablecollab.approval_system.repository.form.FormFieldRepository;
import com.flowablecollab.approval_system.repository.form.FormInstanceRepository;
import com.flowablecollab.approval_system.repository.form.FormVersionRepository;
import com.flowablecollab.approval_system.repository.rbac.SysDeptRepository;
import com.flowablecollab.approval_system.repository.rbac.SysLoginLogRepository;
import com.flowablecollab.approval_system.repository.rbac.SysPostRepository;
import com.flowablecollab.approval_system.repository.rbac.SysRoleDataScopeRepository;
import com.flowablecollab.approval_system.repository.rbac.SysRoleRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserRoleRepository;
import com.flowablecollab.approval_system.repository.workflow.RequestTemplateRepository;
import com.flowablecollab.approval_system.security.JwtService;
import com.flowablecollab.approval_system.service.RbacService;
import org.apache.commons.codec.binary.Base32;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.ByteBuffer;
import java.time.Instant;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.UUID;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
abstract class AbstractIntegrationTestSupport {

    @Autowired
    protected MockMvc mockMvc;

    @Autowired
    protected ObjectMapper objectMapper;

    @Autowired
    protected JwtService jwtService;

    @Autowired
    protected RbacService rbacService;

    @Autowired
    protected SysUserRepository sysUserRepository;

    @Autowired
    protected SysRoleRepository sysRoleRepository;

    @Autowired
    protected SysUserRoleRepository sysUserRoleRepository;

    @Autowired
    protected SysRoleDataScopeRepository sysRoleDataScopeRepository;

    @Autowired
    protected SysDeptRepository sysDeptRepository;

    @Autowired
    protected SysPostRepository sysPostRepository;

    @Autowired
    protected SysLoginLogRepository sysLoginLogRepository;

    @Autowired
    protected FormDefinitionRepository formDefinitionRepository;

    @Autowired
    protected FormVersionRepository formVersionRepository;

    @Autowired
    protected FormFieldRepository formFieldRepository;

    @Autowired
    protected FormInstanceRepository formInstanceRepository;

    @Autowired
    protected BizRequestRepository bizRequestRepository;

    @Autowired
    protected BizRequestTaskRepository bizRequestTaskRepository;

    @Autowired
    protected BizRequestLogRepository bizRequestLogRepository;

    @Autowired
    protected RequestTemplateRepository requestTemplateRepository;

    @BeforeEach
    void clearSecurityArtifacts() {
        // Keep tests isolated from previous method side effects without wiping the full database.
        org.springframework.security.core.context.SecurityContextHolder.clearContext();
    }

    protected SysUser createUser(String prefix, String rawPassword, Long deptId, String... roleCodes) {
        String username = unique(prefix);
        SysUser user = rbacService.createUser(username, rawPassword, deptId, 1);
        for (String roleCode : roleCodes) {
            SysRole role = ensureRole(roleCode);
            rbacService.assignRole(user.getId(), role.getId());
        }
        return user;
    }

    protected SysRole ensureRole(String roleCode) {
        return sysRoleRepository.findByRoleCode(roleCode)
                .orElseGet(() -> rbacService.createRole(roleCode, roleCode + " role"));
    }

    protected String accessToken(SysUser user, String... roleCodes) {
        Set<String> roles = new LinkedHashSet<>();
        roles.addAll(Arrays.asList(roleCodes));
        return jwtService.generateAccessToken(user.getId(), user.getUsername(), roles);
    }

    protected String authorization(String token) {
        return "Bearer " + token;
    }

    protected String unique(String prefix) {
        String suffix = UUID.randomUUID().toString();
        int maxPrefixLength = Math.max(1, 64 - 1 - suffix.length());
        String normalizedPrefix = prefix == null ? "t" : prefix;
        if (normalizedPrefix.length() > maxPrefixLength) {
            normalizedPrefix = normalizedPrefix.substring(0, maxPrefixLength);
        }
        return normalizedPrefix + "-" + suffix;
    }

    protected JsonNode json(String content) throws JsonProcessingException {
        return objectMapper.readTree(content);
    }

    protected String currentTotpCode(String secret) {
        try {
            long counter = Instant.now().getEpochSecond() / 30;
            byte[] key = new Base32().decode(secret);
            byte[] data = ByteBuffer.allocate(8).putLong(counter).array();
            Mac mac = Mac.getInstance("HmacSHA1");
            mac.init(new SecretKeySpec(key, "HmacSHA1"));
            byte[] hash = mac.doFinal(data);
            int offset = hash[hash.length - 1] & 0x0F;
            int binary = ((hash[offset] & 0x7F) << 24)
                    | ((hash[offset + 1] & 0xFF) << 16)
                    | ((hash[offset + 2] & 0xFF) << 8)
                    | (hash[offset + 3] & 0xFF);
            return String.format("%06d", binary % 1_000_000);
        } catch (Exception ex) {
            throw new IllegalStateException("failed to generate current TOTP code", ex);
        }
    }
}
