package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.entity.rbac.SysLoginLog;
import com.flowablecollab.approval_system.repository.rbac.SysLoginLogRepository;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/login-logs")
@RequiredArgsConstructor
@PreAuthorize("hasRole('SYS_ADMIN')")
public class LoginLogController {

    private final SysLoginLogRepository loginLogRepository;

    @GetMapping
    public ResponseEntity<LoginPage> list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String username,
            @RequestParam(required = false) Integer loginStatus,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate) {

        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "loginTime"));
        
        Page<SysLoginLog> logs;
        if (userId != null) {
            logs = loginLogRepository.findByUserIdOrderByLoginTimeDesc(userId, pageable);
        } else if (username != null) {
            logs = loginLogRepository.findByUsernameOrderByLoginTimeDesc(username, pageable);
        } else if (loginStatus != null) {
            LocalDateTime start = startDate != null ? LocalDate.parse(startDate).atStartOfDay() : LocalDateTime.now().minusDays(30);
            LocalDateTime end = endDate != null ? LocalDate.parse(endDate).atTime(LocalTime.MAX) : LocalDateTime.now();
            logs = loginLogRepository.findByLoginTimeBetween(start, end, pageable);
        } else {
            logs = loginLogRepository.findAll(pageable);
        }

        LoginPage pageData = new LoginPage();
        pageData.setContent(logs.getContent().stream().map(this::toDto).collect(Collectors.toList()));
        pageData.setTotal(logs.getTotalElements());
        pageData.setPage(page);
        pageData.setSize(size);
        pageData.setTotalPages(logs.getTotalPages());

        return ResponseEntity.ok(pageData);
    }

    @GetMapping("/{id}")
    public ResponseEntity<LoginLogDto> get(@PathVariable Long id) {
        SysLoginLog log = loginLogRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("login log not found"));
        return ResponseEntity.ok(toDto(log));
    }

    private LoginLogDto toDto(SysLoginLog log) {
        LoginLogDto dto = new LoginLogDto();
        dto.setId(log.getId());
        dto.setUserId(log.getUserId());
        dto.setUsername(log.getUsername());
        dto.setLoginStatus(log.getLoginStatus());
        dto.setMessage(log.getMessage());
        dto.setIpAddress(log.getIpAddress());
        dto.setUserAgent(log.getUserAgent());
        dto.setLoginTime(log.getLoginTime());
        return dto;
    }

    @Data
    public static class LoginPage {
        private List<LoginLogDto> content;
        private long total;
        private int page;
        private int size;
        private int totalPages;
    }

    @Data
    public static class LoginLogDto {
        private Long id;
        private Long userId;
        private String username;
        private Integer loginStatus; // 0: success, 1: failed
        private String message;
        private String ipAddress;
        private String userAgent;
        private LocalDateTime loginTime;
    }
}