package com.flowablecollab.approval_system.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Set;

@Service
public class JwtService {

    private SecretKey accessSigningKey;

    @Value("${security.jwt.secret}")
    private String secret;

    @Value("${security.jwt.issuer:approval-system}")
    private String issuer;

    @Value("${security.jwt.access-token-minutes:120}")
    private long accessTokenMinutes;

    @Value("${security.jwt.challenge-token-minutes:5}")
    private long challengeTokenMinutes;

    @PostConstruct
    public void init() {
        byte[] keyBytes;
        if (secret.startsWith("base64:")) {
            keyBytes = Decoders.BASE64.decode(secret.substring("base64:".length()));
        } else {
            keyBytes = secret.getBytes(StandardCharsets.UTF_8);
        }
        accessSigningKey = Keys.hmacShaKeyFor(keyBytes);
    }

    public String generateAccessToken(Long userId, String username, Set<String> roles) {
        Instant now = Instant.now();
        return Jwts.builder()
                .issuer(issuer)
                .subject(username)
                .claim("uid", userId)
                .claim("roles", new ArrayList<>(roles))
                .claim("type", "ACCESS")
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(accessTokenMinutes * 60)))
                .signWith(accessSigningKey)
                .compact();
    }

    public String generateTwoFactorChallengeToken(Long userId, String username) {
        Instant now = Instant.now();
        return Jwts.builder()
                .issuer(issuer)
                .subject(username)
                .claim("uid", userId)
                .claim("type", "2FA_CHALLENGE")
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(challengeTokenMinutes * 60)))
                .signWith(accessSigningKey)
                .compact();
    }

    public Claims parseAccessToken(String token) {
        Claims claims = parseToken(token);
        if (!"ACCESS".equals(claims.get("type", String.class))) {
            throw new JwtException("invalid token type");
        }
        return claims;
    }

    public Claims parseChallengeToken(String token) {
        Claims claims = parseToken(token);
        if (!"2FA_CHALLENGE".equals(claims.get("type", String.class))) {
            throw new JwtException("invalid challenge token type");
        }
        return claims;
    }

    @SuppressWarnings("unchecked")
    public Set<String> getRoles(Claims claims) {
        Object roles = claims.get("roles");
        if (roles instanceof List<?> list) {
            return list.stream().map(String::valueOf).collect(java.util.stream.Collectors.toSet());
        }
        return Set.of();
    }

    public Long getUserId(Claims claims) {
        Object uid = claims.get("uid");
        if (uid instanceof Number number) {
            return number.longValue();
        }
        if (uid == null) {
            return null;
        }
        try {
            return Long.parseLong(String.valueOf(uid));
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    public long getAccessTokenExpiresInSeconds() {
        return accessTokenMinutes * 60;
    }

    private Claims parseToken(String token) {
        return Jwts.parser()
                .verifyWith(accessSigningKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
