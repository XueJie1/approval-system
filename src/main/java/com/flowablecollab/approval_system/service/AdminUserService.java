package com.flowablecollab.approval_system.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.flowablecollab.approval_system.entity.rbac.SysDept;
import com.flowablecollab.approval_system.entity.rbac.SysPost;
import com.flowablecollab.approval_system.entity.rbac.SysRole;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import com.flowablecollab.approval_system.entity.rbac.SysUserImportJob;
import com.flowablecollab.approval_system.entity.rbac.SysUserImportJobItem;
import com.flowablecollab.approval_system.entity.rbac.SysUserPost;
import com.flowablecollab.approval_system.entity.rbac.SysUserRole;
import com.flowablecollab.approval_system.exception.ResourceConflictException;
import com.flowablecollab.approval_system.repository.rbac.SysDeptRepository;
import com.flowablecollab.approval_system.repository.rbac.SysPostRepository;
import com.flowablecollab.approval_system.repository.rbac.SysRoleRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserImportJobItemRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserImportJobRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserPostRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserRoleRepository;
import lombok.RequiredArgsConstructor;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;
import org.apache.poi.ss.usermodel.*;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminUserService {

    private static final String STRATEGY_CREATE_ONLY = "CREATE_ONLY";
    private static final String STRATEGY_UPSERT = "UPSERT";
    private static final String JOB_STATUS_VALIDATED = "VALIDATED";
    private static final String JOB_STATUS_RUNNING = "RUNNING";
    private static final String JOB_STATUS_COMPLETED = "COMPLETED";
    private static final String ITEM_RESULT_PENDING = "PENDING";
    private static final String ITEM_RESULT_SUCCESS = "SUCCESS";
    private static final String ITEM_RESULT_FAILED = "FAILED";
    private static final DataFormatter DATA_FORMATTER = new DataFormatter();
    private static final List<String> TEMPLATE_HEADERS = List.of(
            "username",
            "password",
            "dept_code",
            "post_codes",
            "role_codes",
            "status"
    );

    private final SysUserRepository sysUserRepository;
    private final SysRoleRepository sysRoleRepository;
    private final SysUserRoleRepository sysUserRoleRepository;
    private final SysUserPostRepository sysUserPostRepository;
    private final SysPostRepository sysPostRepository;
    private final SysDeptRepository sysDeptRepository;
    private final SysUserImportJobRepository sysUserImportJobRepository;
    private final SysUserImportJobItemRepository sysUserImportJobItemRepository;
    private final RbacService rbacService;
    private final ObjectMapper objectMapper;

    public UserOptions loadOptions() {
        List<DeptOption> departments = sysDeptRepository.findAllByOrderByDeptNameAsc().stream()
                .map(dept -> new DeptOption(dept.getId(), dept.getDeptCode(), dept.getDeptName(), dept.getParentId()))
                .toList();
        List<RoleOption> roles = sysRoleRepository.findAllByOrderByRoleCodeAsc().stream()
                .map(role -> new RoleOption(role.getId(), role.getRoleCode(), role.getRoleName(), role.getStatus()))
                .toList();
        List<PostOption> posts = sysPostRepository.findAllByOrderByPostCodeAsc().stream()
                .map(post -> new PostOption(post.getId(), post.getPostCode(), post.getPostName()))
                .toList();
        List<UserOption> users = sysUserRepository.findAllByOrderByUsernameAsc().stream()
                .map(user -> new UserOption(user.getId(), user.getUsername()))
                .toList();
        return new UserOptions(departments, roles, posts, users);
    }

    public PageResult<UserListItem> listUsers(String keyword, Integer status, Long deptId, Long roleId, Integer page, Integer size) {
        List<UserListItem> filtered = rbacService.listUsers(keyword, status).stream()
                .filter(user -> deptId == null || Objects.equals(user.getDeptId(), deptId))
                .filter(user -> roleId == null || sysUserRoleRepository.findByUserId(user.getId()).stream()
                        .anyMatch(mapping -> Objects.equals(mapping.getRoleId(), roleId)))
                .map(this::toUserListItem)
                .toList();
        return paginate(filtered, page, size);
    }

    public UserDetail getUserDetail(Long userId) {
        SysUser user = getRequiredUser(userId);
        return toUserDetail(user);
    }

    @Transactional
    public UserDetail createUser(CreateUserCommand command) {
        validateRoleIds(command.roleIds());
        validatePostIds(command.postIds());
        validateManagerUserId(command.managerUserId(), null);
        SysUser user = rbacService.createUser(command.username(), command.password(), command.deptId(), command.status());
        user.setManagerUserId(command.managerUserId());
        sysUserRepository.save(user);
        replaceRoles(user.getId(), command.roleIds());
        replacePosts(user.getId(), command.postIds());
        return toUserDetail(getRequiredUser(user.getId()));
    }

    @Transactional
    public UserDetail updateUser(Long userId, UpdateUserCommand command) {
        SysUser user = getRequiredUser(userId);
        if (command.deptId() != null && !sysDeptRepository.existsById(command.deptId())) {
            throw new IllegalArgumentException("deptId does not exist: " + command.deptId());
        }
        validateRoleIds(command.roleIds());
        validatePostIds(command.postIds());
        validateManagerUserId(command.managerUserId(), userId);
        user.setDeptId(command.deptId());
        user.setManagerUserId(command.managerUserId());
        user.setStatus(command.status());
        sysUserRepository.save(user);
        replaceRoles(userId, command.roleIds());
        replacePosts(userId, command.postIds());
        return toUserDetail(getRequiredUser(userId));
    }

    @Transactional
    public UserDetail updateUserStatus(Long userId, Integer status) {
        if (status == null || (status != 0 && status != 1)) {
            throw new IllegalArgumentException("status must be 0 or 1");
        }
        SysUser user = getRequiredUser(userId);
        user.setStatus(status);
        sysUserRepository.save(user);
        return toUserDetail(user);
    }

    @Transactional
    public void resetPassword(Long userId, String newPassword) {
        if (newPassword == null || newPassword.length() < 8 || newPassword.length() > 128) {
            throw new IllegalArgumentException("password length must be between 8 and 128");
        }
        SysUser user = getRequiredUser(userId);
        user.setPassword(BCrypt.hashpw(newPassword, BCrypt.gensalt()));
        user.setLoginFailures(0);
        user.setLockedUntil(null);
        sysUserRepository.save(user);
    }

    @Transactional
    public ImportValidationResult validateImport(Long operatorId, String strategy, MultipartFile file) {
        String normalizedStrategy = normalizeStrategy(strategy);
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("file is required");
        }
        String fileName = Optional.ofNullable(file.getOriginalFilename()).orElse("users-import");
        String fileType = resolveFileType(fileName);
        List<ImportRowDraft> rows = parseFile(file, fileType);

        SysUserImportJob job = new SysUserImportJob();
        job.setFileName(fileName);
        job.setFileType(fileType);
        job.setFileChecksum(calculateChecksum(file));
        job.setStrategy(normalizedStrategy);
        job.setStatus(JOB_STATUS_VALIDATED);
        job.setOperatorId(operatorId);
        job.setCreatedAt(LocalDateTime.now());
        job.setFinishedAt(null);

        List<SysUserImportJobItem> items = buildValidationItems(rows, normalizedStrategy);
        job.setTotalRows(items.size());
        job.setSuccessRows((int) items.stream().filter(item -> ITEM_RESULT_PENDING.equals(item.getResult())).count());
        job.setFailedRows((int) items.stream().filter(item -> ITEM_RESULT_FAILED.equals(item.getResult())).count());
        SysUserImportJob savedJob = sysUserImportJobRepository.save(job);

        for (SysUserImportJobItem item : items) {
            item.setJobId(savedJob.getId());
        }
        sysUserImportJobItemRepository.saveAll(items);

        List<ImportItemResult> results = items.stream().map(this::toImportItemResult).toList();
        List<ImportPreviewRow> preview = results.stream()
                .map(item -> new ImportPreviewRow(
                        item.rowNo(),
                        item.username(),
                        item.deptCode(),
                        item.postCodes(),
                        item.roleCodes(),
                        item.status(),
                        ITEM_RESULT_PENDING.equals(item.result())
                ))
                .toList();
        List<ImportError> errors = results.stream()
                .filter(item -> ITEM_RESULT_FAILED.equals(item.result()))
                .map(item -> new ImportError(item.rowNo(), item.username(), item.errorMessage()))
                .toList();

        return new ImportValidationResult(
                savedJob.getId(),
                savedJob.getFileName(),
                savedJob.getStrategy(),
                savedJob.getTotalRows(),
                savedJob.getSuccessRows(),
                savedJob.getFailedRows(),
                errors,
                preview
        );
    }

    @Transactional
    public ImportJobSummary executeImport(Long operatorId, Long jobId, boolean skipErrorRows) {
        SysUserImportJob job = sysUserImportJobRepository.findById(jobId)
                .orElseThrow(() -> new IllegalArgumentException("import job not found: " + jobId));
        if (!Objects.equals(job.getOperatorId(), operatorId) && !rbacService.hasRole(operatorId, "ADMIN")
                && !rbacService.hasRole(operatorId, "SYS_ADMIN")) {
            throw new IllegalArgumentException("operator has no permission to execute this import job");
        }
        if (!JOB_STATUS_VALIDATED.equals(job.getStatus())) {
            throw new IllegalArgumentException("import job is not ready for execution");
        }

        List<SysUserImportJobItem> items = sysUserImportJobItemRepository.findByJobIdOrderByRowNoAsc(jobId);
        job.setStatus(JOB_STATUS_RUNNING);
        sysUserImportJobRepository.save(job);

        int successRows = 0;
        int failedRows = 0;
        for (SysUserImportJobItem item : items) {
            if (ITEM_RESULT_FAILED.equals(item.getResult())) {
                failedRows++;
                if (skipErrorRows) {
                    sysUserImportJobItemRepository.save(item);
                }
                continue;
            }
            try {
                ImportRowData row = objectMapper.readValue(item.getRawPayload(), ImportRowData.class);
                SysUser target = sysUserRepository.findByUsername(row.username()).orElse(null);
                String beforeSnapshot = target == null ? null : writeJson(summarizeUser(target));
                SysUser saved = applyImportRow(job.getStrategy(), row, target);
                item.setCreatedUserId(saved.getId());
                item.setBeforeSnapshot(beforeSnapshot);
                item.setAfterSnapshot(writeJson(summarizeUser(saved)));
                item.setErrorMessage(null);
                item.setResult(ITEM_RESULT_SUCCESS);
                successRows++;
            } catch (Exception ex) {
                item.setResult(ITEM_RESULT_FAILED);
                item.setErrorMessage(ex.getMessage());
                failedRows++;
            }
            sysUserImportJobItemRepository.save(item);
        }

        job.setStatus(JOB_STATUS_COMPLETED);
        job.setSuccessRows(successRows);
        job.setFailedRows(failedRows);
        job.setFinishedAt(LocalDateTime.now());
        sysUserImportJobRepository.save(job);
        return toImportJobSummary(job);
    }

    public PageResult<ImportJobSummary> listImportJobs(String status, Integer page, Integer size) {
        String normalizedStatus = status == null ? null : status.trim().toUpperCase(Locale.ROOT);
        List<ImportJobSummary> filtered = sysUserImportJobRepository.findAllByOrderByCreatedAtDesc().stream()
                .filter(job -> normalizedStatus == null || normalizedStatus.isBlank() || normalizedStatus.equals(job.getStatus()))
                .map(this::toImportJobSummary)
                .toList();
        return paginate(filtered, page, size);
    }

    public List<ImportItemResult> listImportItems(Long jobId) {
        if (!sysUserImportJobRepository.existsById(jobId)) {
            throw new IllegalArgumentException("import job not found: " + jobId);
        }
        return sysUserImportJobItemRepository.findByJobIdOrderByRowNoAsc(jobId).stream()
                .map(this::toImportItemResult)
                .toList();
    }

    public byte[] buildFailedItemsCsv(Long jobId) {
        List<ImportItemResult> failed = listImportItems(jobId).stream()
                .filter(item -> ITEM_RESULT_FAILED.equals(item.result()))
                .toList();
        StringBuilder builder = new StringBuilder("row_no,username,error_message\n");
        for (ImportItemResult item : failed) {
            builder.append(item.rowNo()).append(',')
                    .append(escapeCsv(item.username())).append(',')
                    .append(escapeCsv(item.errorMessage())).append('\n');
        }
        return builder.toString().getBytes(StandardCharsets.UTF_8);
    }

    public byte[] buildTemplateCsv() {
        return String.join(",", TEMPLATE_HEADERS).concat("\n").getBytes(StandardCharsets.UTF_8);
    }

    private SysUser applyImportRow(String strategy, ImportRowData row, SysUser existingUser) {
        if (STRATEGY_CREATE_ONLY.equals(strategy) && existingUser != null) {
            throw new ResourceConflictException("username already exists: " + row.username());
        }

        if (existingUser == null) {
            return createUser(new CreateUserCommand(
                    row.username(),
                    row.password(),
                    resolveDeptId(row.deptCode()),
                    null,
                    resolveRoleIds(row.roleCodes()),
                    resolvePostIds(row.postCodes()),
                    row.status()
            )).toUser();
        }

        existingUser.setPassword(BCrypt.hashpw(row.password(), BCrypt.gensalt()));
        existingUser.setDeptId(resolveDeptId(row.deptCode()));
        existingUser.setStatus(row.status());
        existingUser.setLoginFailures(0);
        existingUser.setLockedUntil(null);
        sysUserRepository.save(existingUser);
        replaceRoles(existingUser.getId(), resolveRoleIds(row.roleCodes()));
        replacePosts(existingUser.getId(), resolvePostIds(row.postCodes()));
        return getRequiredUser(existingUser.getId());
    }

    private List<SysUserImportJobItem> buildValidationItems(List<ImportRowDraft> rows, String strategy) {
        Set<String> seenUsernames = new HashSet<>();
        List<SysUserImportJobItem> items = new ArrayList<>();
        for (ImportRowDraft draft : rows) {
            List<String> errors = new ArrayList<>();
            String username = normalizeText(draft.username());
            if (username == null) {
                errors.add("username is required");
            } else {
                if (!seenUsernames.add(username)) {
                    errors.add("username is duplicated in file");
                }
                if (username.length() > 64) {
                    errors.add("username length must be <= 64");
                }
            }

            String password = normalizeText(draft.password());
            if (password == null || password.length() < 8 || password.length() > 128) {
                errors.add("password length must be between 8 and 128");
            }

            Integer status = normalizeStatus(draft.statusText(), errors);
            String deptCode = normalizeText(draft.deptCode());
            if (deptCode != null && sysDeptRepository.findByDeptCode(deptCode).isEmpty()) {
                errors.add("dept_code does not exist: " + deptCode);
            }

            List<String> roleCodes = splitCodes(draft.roleCodesText());
            if (roleCodes.isEmpty()) {
                errors.add("role_codes is required");
            } else {
                for (String roleCode : roleCodes) {
                    if (sysRoleRepository.findByRoleCode(roleCode).isEmpty()) {
                        errors.add("role_codes contains unknown role: " + roleCode);
                    }
                }
            }

            List<String> postCodes = splitCodes(draft.postCodesText());
            for (String postCode : postCodes) {
                if (sysPostRepository.findByPostCode(postCode).isEmpty()) {
                    errors.add("post_codes contains unknown post: " + postCode);
                }
            }

            if (username != null && STRATEGY_CREATE_ONLY.equals(strategy)
                    && sysUserRepository.findByUsername(username).isPresent()) {
                errors.add("username already exists: " + username);
            }

            ImportRowData row = new ImportRowData(
                    username,
                    password,
                    deptCode,
                    postCodes,
                    roleCodes,
                    status == null ? 1 : status
            );

            SysUserImportJobItem item = new SysUserImportJobItem();
            item.setRowNo(draft.rowNo());
            item.setUsername(username);
            item.setRawPayload(writeJson(row));
            item.setResult(errors.isEmpty() ? ITEM_RESULT_PENDING : ITEM_RESULT_FAILED);
            item.setErrorMessage(errors.isEmpty() ? null : String.join("; ", errors));
            items.add(item);
        }
        return items;
    }

    private List<ImportRowDraft> parseFile(MultipartFile file, String fileType) {
        try {
            return "CSV".equals(fileType) ? parseCsv(file) : parseXlsx(file);
        } catch (IOException ex) {
            throw new IllegalArgumentException("failed to parse import file");
        }
    }

    private List<ImportRowDraft> parseCsv(MultipartFile file) throws IOException {
        try (Reader reader = new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8);
             CSVParser parser = CSVFormat.DEFAULT.builder()
                     .setHeader()
                     .setSkipHeaderRecord(true)
                     .setTrim(true)
                     .build()
                     .parse(reader)) {
            validateHeaders(parser.getHeaderNames());
            List<ImportRowDraft> rows = new ArrayList<>();
            for (CSVRecord record : parser) {
                rows.add(new ImportRowDraft(
                        (int) record.getRecordNumber() + 1,
                        record.get("username"),
                        record.get("password"),
                        record.get("dept_code"),
                        record.get("post_codes"),
                        record.get("role_codes"),
                        record.get("status")
                ));
            }
            return rows;
        }
    }

    private List<ImportRowDraft> parseXlsx(MultipartFile file) throws IOException {
        try (Workbook workbook = WorkbookFactory.create(file.getInputStream())) {
            Sheet sheet = workbook.getSheetAt(0);
            if (sheet == null || sheet.getPhysicalNumberOfRows() == 0) {
                throw new IllegalArgumentException("import file is empty");
            }
            Row headerRow = sheet.getRow(sheet.getFirstRowNum());
            if (headerRow == null) {
                throw new IllegalArgumentException("import file is empty");
            }
            List<String> headers = new ArrayList<>();
            for (int i = 0; i < TEMPLATE_HEADERS.size(); i++) {
                headers.add(readCell(headerRow.getCell(i)));
            }
            validateHeaders(headers);
            List<ImportRowDraft> rows = new ArrayList<>();
            for (int rowIndex = sheet.getFirstRowNum() + 1; rowIndex <= sheet.getLastRowNum(); rowIndex++) {
                Row row = sheet.getRow(rowIndex);
                if (row == null || isRowBlank(row)) {
                    continue;
                }
                rows.add(new ImportRowDraft(
                        rowIndex + 1,
                        readCell(row.getCell(0)),
                        readCell(row.getCell(1)),
                        readCell(row.getCell(2)),
                        readCell(row.getCell(3)),
                        readCell(row.getCell(4)),
                        readCell(row.getCell(5))
                ));
            }
            return rows;
        }
    }

    private void validateHeaders(List<String> headers) {
        List<String> normalizedHeaders = headers.stream()
                .map(header -> header == null ? null : header.trim().toLowerCase(Locale.ROOT))
                .toList();
        if (!normalizedHeaders.equals(TEMPLATE_HEADERS)) {
            throw new IllegalArgumentException("invalid import headers");
        }
    }

    private boolean isRowBlank(Row row) {
        for (int i = 0; i < TEMPLATE_HEADERS.size(); i++) {
            if (!readCell(row.getCell(i)).isBlank()) {
                return false;
            }
        }
        return true;
    }

    private String readCell(Cell cell) {
        if (cell == null) {
            return "";
        }
        return switch (cell.getCellType()) {
            case STRING -> cell.getStringCellValue().trim();
            case NUMERIC -> DATA_FORMATTER.formatCellValue(cell).trim();
            case BOOLEAN -> String.valueOf(cell.getBooleanCellValue());
            case FORMULA -> DATA_FORMATTER.formatCellValue(cell).trim();
            case BLANK, _NONE, ERROR -> "";
        };
    }

    private String calculateChecksum(MultipartFile file) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(file.getBytes());
            StringBuilder hex = new StringBuilder();
            for (byte b : hash) {
                hex.append(String.format("%02x", b));
            }
            return hex.toString();
        } catch (NoSuchAlgorithmException | IOException ex) {
            throw new IllegalArgumentException("failed to calculate file checksum");
        }
    }

    private String resolveFileType(String fileName) {
        String lowerCase = fileName.toLowerCase(Locale.ROOT);
        if (lowerCase.endsWith(".csv")) {
            return "CSV";
        }
        if (lowerCase.endsWith(".xlsx")) {
            return "XLSX";
        }
        throw new IllegalArgumentException("only csv and xlsx files are supported");
    }

    private String normalizeStrategy(String strategy) {
        if (strategy == null || strategy.isBlank()) {
            return STRATEGY_CREATE_ONLY;
        }
        String normalized = strategy.trim().toUpperCase(Locale.ROOT);
        if (!Set.of(STRATEGY_CREATE_ONLY, STRATEGY_UPSERT).contains(normalized)) {
            throw new IllegalArgumentException("invalid import strategy");
        }
        return normalized;
    }

    private Integer normalizeStatus(String statusText, List<String> errors) {
        String normalized = normalizeText(statusText);
        if (normalized == null) {
            return 1;
        }
        if (!"0".equals(normalized) && !"1".equals(normalized)) {
            errors.add("status must be 0 or 1");
            return null;
        }
        return Integer.parseInt(normalized);
    }

    private String normalizeText(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private List<String> splitCodes(String text) {
        String normalized = normalizeText(text);
        if (normalized == null) {
            return List.of();
        }
        return Arrays.stream(normalized.split(","))
                .map(String::trim)
                .filter(code -> !code.isEmpty())
                .distinct()
                .toList();
    }

    private Long resolveDeptId(String deptCode) {
        if (deptCode == null || deptCode.isBlank()) {
            return null;
        }
        return sysDeptRepository.findByDeptCode(deptCode)
                .map(SysDept::getId)
                .orElseThrow(() -> new IllegalArgumentException("dept_code does not exist: " + deptCode));
    }

    private List<Long> resolveRoleIds(List<String> roleCodes) {
        List<Long> ids = new ArrayList<>();
        for (String roleCode : roleCodes) {
            ids.add(sysRoleRepository.findByRoleCode(roleCode)
                    .orElseThrow(() -> new IllegalArgumentException("role_codes contains unknown role: " + roleCode))
                    .getId());
        }
        return ids;
    }

    private List<Long> resolvePostIds(List<String> postCodes) {
        List<Long> ids = new ArrayList<>();
        for (String postCode : postCodes) {
            ids.add(sysPostRepository.findByPostCode(postCode)
                    .orElseThrow(() -> new IllegalArgumentException("post_codes contains unknown post: " + postCode))
                    .getId());
        }
        return ids;
    }

    private void validateRoleIds(List<Long> roleIds) {
        if (roleIds == null || roleIds.isEmpty()) {
            throw new IllegalArgumentException("roleIds is required");
        }
        Set<Long> uniqueIds = new LinkedHashSet<>(roleIds);
        List<SysRole> roles = sysRoleRepository.findByIdIn(uniqueIds);
        if (roles.size() != uniqueIds.size()) {
            throw new IllegalArgumentException("one or more roleIds do not exist");
        }
    }

    private void validatePostIds(List<Long> postIds) {
        if (postIds == null) {
            return;
        }
        Set<Long> uniqueIds = new LinkedHashSet<>(postIds);
        List<SysPost> posts = sysPostRepository.findByIdIn(uniqueIds);
        if (posts.size() != uniqueIds.size()) {
            throw new IllegalArgumentException("one or more postIds do not exist");
        }
    }

    private void replaceRoles(Long userId, List<Long> roleIds) {
        sysUserRoleRepository.deleteByUserId(userId);
        for (Long roleId : new LinkedHashSet<>(roleIds)) {
            SysUserRole mapping = new SysUserRole();
            mapping.setUserId(userId);
            mapping.setRoleId(roleId);
            sysUserRoleRepository.save(mapping);
        }
    }

    private void replacePosts(Long userId, List<Long> postIds) {
        sysUserPostRepository.deleteByUserId(userId);
        if (postIds == null) {
            return;
        }
        for (Long postId : new LinkedHashSet<>(postIds)) {
            SysUserPost mapping = new SysUserPost();
            mapping.setUserId(userId);
            mapping.setPostId(postId);
            sysUserPostRepository.save(mapping);
        }
    }

    private UserListItem toUserListItem(SysUser user) {
        List<RoleOption> roles = loadRoles(user.getId());
        List<PostOption> posts = loadPosts(user.getId());
        DeptOption dept = loadDept(user.getDeptId());
        boolean locked = user.getLockedUntil() != null && user.getLockedUntil().isAfter(LocalDateTime.now());
        return new UserListItem(
                user.getId(),
                user.getUsername(),
                dept,
                user.getManagerUserId(),
                roles,
                posts,
                user.getStatus(),
                user.getTwoFactorEnabled() != null && user.getTwoFactorEnabled() == 1,
                user.getLastLoginAt(),
                locked
        );
    }

    private UserDetail toUserDetail(SysUser user) {
        return new UserDetail(
                user.getId(),
                user.getUsername(),
                loadDept(user.getDeptId()),
                user.getManagerUserId(),
                loadRoles(user.getId()),
                loadPosts(user.getId()),
                user.getStatus(),
                user.getTwoFactorEnabled() != null && user.getTwoFactorEnabled() == 1,
                user.getLastLoginAt(),
                user.getLoginFailures(),
                user.getLockedUntil()
        );
    }

    private DeptOption loadDept(Long deptId) {
        if (deptId == null) {
            return null;
        }
        return sysDeptRepository.findById(deptId)
                .map(dept -> new DeptOption(dept.getId(), dept.getDeptCode(), dept.getDeptName(), dept.getParentId()))
                .orElse(null);
    }

    private List<RoleOption> loadRoles(Long userId) {
        List<Long> roleIds = sysUserRoleRepository.findByUserId(userId).stream()
                .map(SysUserRole::getRoleId)
                .toList();
        if (roleIds.isEmpty()) {
            return List.of();
        }
        return sysRoleRepository.findByIdIn(roleIds).stream()
                .sorted(Comparator.comparing(SysRole::getRoleCode, String.CASE_INSENSITIVE_ORDER))
                .map(role -> new RoleOption(role.getId(), role.getRoleCode(), role.getRoleName(), role.getStatus()))
                .toList();
    }

    private List<PostOption> loadPosts(Long userId) {
        List<Long> postIds = sysUserPostRepository.findByUserId(userId).stream()
                .map(SysUserPost::getPostId)
                .toList();
        if (postIds.isEmpty()) {
            return List.of();
        }
        return sysPostRepository.findByIdIn(postIds).stream()
                .sorted(Comparator.comparing(SysPost::getPostCode, String.CASE_INSENSITIVE_ORDER))
                .map(post -> new PostOption(post.getId(), post.getPostCode(), post.getPostName()))
                .toList();
    }

    private SysUser getRequiredUser(Long userId) {
        return sysUserRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("user not found: " + userId));
    }

    private void validateManagerUserId(Long managerUserId, Long userId) {
        if (managerUserId == null) {
            return;
        }
        if (userId != null && userId.equals(managerUserId)) {
            throw new IllegalArgumentException("managerUserId cannot be the same as userId");
        }
        if (!sysUserRepository.existsById(managerUserId)) {
            throw new IllegalArgumentException("managerUserId does not exist: " + managerUserId);
        }
    }

    private Map<String, Object> summarizeUser(SysUser user) {
        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("userId", user.getId());
        snapshot.put("username", user.getUsername());
        snapshot.put("dept", loadDept(user.getDeptId()));
        snapshot.put("managerUserId", user.getManagerUserId());
        snapshot.put("roles", loadRoles(user.getId()).stream().map(RoleOption::roleCode).toList());
        snapshot.put("posts", loadPosts(user.getId()).stream().map(PostOption::postCode).toList());
        snapshot.put("status", user.getStatus());
        return snapshot;
    }

    private String writeJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException ex) {
            throw new IllegalArgumentException("failed to serialize import data");
        }
    }

    private ImportJobSummary toImportJobSummary(SysUserImportJob job) {
        return new ImportJobSummary(
                job.getId(),
                job.getFileName(),
                job.getFileType(),
                job.getStrategy(),
                job.getStatus(),
                job.getTotalRows(),
                job.getSuccessRows(),
                job.getFailedRows(),
                job.getOperatorId(),
                job.getCreatedAt(),
                job.getFinishedAt()
        );
    }

    private ImportItemResult toImportItemResult(SysUserImportJobItem item) {
        ImportRowData row;
        try {
            row = objectMapper.readValue(item.getRawPayload(), ImportRowData.class);
        } catch (Exception ex) {
            row = new ImportRowData(item.getUsername(), null, null, List.of(), List.of(), 1);
        }
        return new ImportItemResult(
                item.getId(),
                item.getJobId(),
                item.getRowNo(),
                row.username(),
                row.deptCode(),
                row.postCodes(),
                row.roleCodes(),
                row.status(),
                item.getResult(),
                item.getErrorMessage(),
                item.getCreatedUserId(),
                item.getBeforeSnapshot(),
                item.getAfterSnapshot()
        );
    }

    private String escapeCsv(String value) {
        if (value == null) {
            return "";
        }
        String escaped = value.replace("\"", "\"\"");
        return '"' + escaped + '"';
    }

    private <T> PageResult<T> paginate(List<T> items, Integer page, Integer size) {
        int safeSize = size == null || size < 1 ? 10 : Math.min(size, 200);
        int safePage = page == null || page < 0 ? 0 : page;
        int total = items.size();
        int fromIndex = Math.min(safePage * safeSize, total);
        int toIndex = Math.min(fromIndex + safeSize, total);
        int totalPages = total == 0 ? 0 : (int) Math.ceil((double) total / safeSize);
        return new PageResult<>(items.subList(fromIndex, toIndex), total, safePage, safeSize, totalPages);
    }

    public record CreateUserCommand(
            String username,
            String password,
            Long deptId,
            Long managerUserId,
            List<Long> roleIds,
            List<Long> postIds,
            Integer status
    ) {
    }

    public record UpdateUserCommand(
            Long deptId,
            Long managerUserId,
            List<Long> roleIds,
            List<Long> postIds,
            Integer status
    ) {
    }

    public record UserOptions(List<DeptOption> departments, List<RoleOption> roles, List<PostOption> posts, List<UserOption> users) {
    }

    public record PageResult<T>(
            List<T> content,
            Integer total,
            Integer page,
            Integer size,
            Integer totalPages
    ) {
    }

    public record DeptOption(Long id, String deptCode, String deptName, Long parentId) {
    }

    public record RoleOption(Long id, String roleCode, String roleName, Integer status) {
    }

    public record PostOption(Long id, String postCode, String postName) {
    }

    public record UserOption(Long id, String username) {
    }

    public record UserListItem(
            Long userId,
            String username,
            DeptOption department,
            Long managerUserId,
            List<RoleOption> roles,
            List<PostOption> posts,
            Integer status,
            boolean twoFactorEnabled,
            LocalDateTime lastLoginAt,
            boolean locked
    ) {
    }

    public record UserDetail(
            Long userId,
            String username,
            DeptOption department,
            Long managerUserId,
            List<RoleOption> roles,
            List<PostOption> posts,
            Integer status,
            boolean twoFactorEnabled,
            LocalDateTime lastLoginAt,
            Integer loginFailures,
            LocalDateTime lockedUntil
    ) {
        public SysUser toUser() {
            SysUser user = new SysUser();
            user.setId(userId);
            user.setUsername(username);
            user.setDeptId(department == null ? null : department.id());
            user.setManagerUserId(managerUserId);
            user.setStatus(status);
            user.setTwoFactorEnabled(twoFactorEnabled ? 1 : 0);
            user.setLastLoginAt(lastLoginAt);
            user.setLoginFailures(loginFailures);
            user.setLockedUntil(lockedUntil);
            return user;
        }
    }

    public record ImportValidationResult(
            Long jobId,
            String fileName,
            String strategy,
            Integer totalRows,
            Integer successRows,
            Integer failedRows,
            List<ImportError> errors,
            List<ImportPreviewRow> preview
    ) {
    }

    public record ImportError(Integer rowNo, String username, String message) {
    }

    public record ImportPreviewRow(
            Integer rowNo,
            String username,
            String deptCode,
            List<String> postCodes,
            List<String> roleCodes,
            Integer status,
            boolean valid
    ) {
    }

    public record ImportJobSummary(
            Long jobId,
            String fileName,
            String fileType,
            String strategy,
            String status,
            Integer totalRows,
            Integer successRows,
            Integer failedRows,
            Long operatorId,
            LocalDateTime createdAt,
            LocalDateTime finishedAt
    ) {
    }

    public record ImportItemResult(
            Long id,
            Long jobId,
            Integer rowNo,
            String username,
            String deptCode,
            List<String> postCodes,
            List<String> roleCodes,
            Integer status,
            String result,
            String errorMessage,
            Long createdUserId,
            String beforeSnapshot,
            String afterSnapshot
    ) {
    }

    private record ImportRowDraft(
            Integer rowNo,
            String username,
            String password,
            String deptCode,
            String postCodesText,
            String roleCodesText,
            String statusText
    ) {
    }

    private record ImportRowData(
            String username,
            String password,
            String deptCode,
            List<String> postCodes,
            List<String> roleCodes,
            Integer status
    ) {
    }
}
