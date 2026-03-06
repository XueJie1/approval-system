package com.flowablecollab.approval_system.service;

import com.flowablecollab.approval_system.entity.rbac.SysLoginLog;
import com.flowablecollab.approval_system.repository.rbac.SysLoginLogRepository;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class LoginLogService {

    private final SysLoginLogRepository loginLogRepository;

    @Transactional
    public void logLoginSuccess(Long userId, String username, String ipAddress, String userAgent) {
        SysLoginLog log = new SysLoginLog();
        log.setUserId(userId);
        log.setUsername(username);
        log.setLoginStatus(0); // success
        log.setMessage("login successful");
        log.setIpAddress(ipAddress);
        log.setUserAgent(userAgent);
        log.setLoginTime(LocalDateTime.now());
        loginLogRepository.save(log);
    }

    @Transactional
    public void logLoginFailure(String username, String message, String ipAddress, String userAgent) {
        SysLoginLog log = new SysLoginLog();
        log.setUsername(username);
        log.setLoginStatus(1); // failed
        log.setMessage(message);
        log.setIpAddress(ipAddress);
        log.setUserAgent(userAgent);
        log.setLoginTime(LocalDateTime.now());
        loginLogRepository.save(log);
    }

    public String getIpAddress(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("X-Real-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getRemoteAddr();
        }
        return ip;
    }

    public String getUserAgent(HttpServletRequest request) {
        return request.getHeader("User-Agent");
    }
}