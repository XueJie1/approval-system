package com.flowablecollab.approval_system.security;

import lombok.Getter;

import java.util.Set;

@Getter
public class AuthUserPrincipal {

    private final Long userId;
    private final String username;
    private final Set<String> roles;

    public AuthUserPrincipal(Long userId, String username, Set<String> roles) {
        this.userId = userId;
        this.username = username;
        this.roles = roles;
    }
}
