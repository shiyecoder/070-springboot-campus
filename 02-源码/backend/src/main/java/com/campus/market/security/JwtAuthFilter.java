package com.campus.market.security;

import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

/** 解析 Authorization: Bearer <token>，写入 SecurityContext 与 CurrentUser */
@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;

    public JwtAuthFilter(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String auth = request.getHeader("Authorization");
        if (auth != null && auth.startsWith("Bearer ")) {
            try {
                Claims claims = jwtUtil.parse(auth.substring(7));
                Long userId = Long.valueOf(claims.getSubject());
                String username = String.valueOf(claims.get("username"));
                String roles = String.valueOf(claims.getOrDefault("roles", ""));
                List<SimpleGrantedAuthority> authorities = Arrays.stream(roles.split(","))
                        .filter(s -> !s.isBlank())
                        .map(r -> new SimpleGrantedAuthority("ROLE_" + r.trim().toUpperCase()))
                        .toList();
                UsernamePasswordAuthenticationToken token =
                        new UsernamePasswordAuthenticationToken(userId, null, authorities);
                SecurityContextHolder.getContext().setAuthentication(token);
                CurrentUser.set(userId, username, roles);
            } catch (Exception ignored) {
                SecurityContextHolder.clearContext();
            }
        }
        try {
            chain.doFilter(request, response);
        } finally {
            CurrentUser.clear();
        }
    }
}
