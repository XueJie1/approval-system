package com.flowablecollab.approval_system.security;

import com.flowablecollab.approval_system.entity.rbac.SysUser;
import com.flowablecollab.approval_system.repository.rbac.SysUserRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final SysUserRepository sysUserRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String authorization = request.getHeader("Authorization");
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = authorization.substring(7);
        try {
            Claims claims = jwtService.parseAccessToken(token);
            Long userId = jwtService.getUserId(claims);
            String username = claims.getSubject();
            Set<String> roles = jwtService.getRoles(claims);

            // Check if user is locked
            SysUser user = sysUserRepository.findById(userId)
                    .orElse(null);
            if (user != null && !isActive(user)) {
                SecurityContextHolder.clearContext();
                response.setStatus(403);
                response.setContentType("application/json");
                response.getWriter().write("{\"error\":\"User disabled\"}");
                return;
            }
            if (user != null && isAccountLocked(user)) {
                SecurityContextHolder.clearContext();
                response.setStatus(423); // Locked
                response.setContentType("application/json");
                response.getWriter().write("{\"error\":\"Account locked\"}");
                return;
            }

            List<GrantedAuthority> authorities = roles.stream()
                    .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
                    .map(GrantedAuthority.class::cast)
                    .toList();

            AuthUserPrincipal principal = new AuthUserPrincipal(userId, username, roles);
            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(principal, null, authorities);
            SecurityContextHolder.getContext().setAuthentication(authentication);
        } catch (JwtException ex) {
            SecurityContextHolder.clearContext();
        }

        filterChain.doFilter(request, response);
    }

    private boolean isAccountLocked(SysUser user) {
        if (user.getLoginFailures() == null || user.getLoginFailures() == 0) {
            return false;
        }
        if (user.getLockedUntil() == null) {
            return false;
        }
        return user.getLockedUntil().isAfter(LocalDateTime.now());
    }

    private boolean isActive(SysUser user) {
        return user.getStatus() != null && user.getStatus() == 1;
    }
}
