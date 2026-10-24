package com.traxia.identity.application;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

public final class TraxiaUserDetails implements UserDetails {

    private final Long userId;
    private final UUID publicId;
    private final String normalizedEmail;
    private final String passwordHash;
    private final boolean enabled;
    private final List<String> roleCodes;

    public TraxiaUserDetails(
            Long userId,
            UUID publicId,
            String normalizedEmail,
            String passwordHash,
            boolean enabled,
            List<String> roleCodes) {
        this.userId = userId;
        this.publicId = publicId;
        this.normalizedEmail = normalizedEmail;
        this.passwordHash = passwordHash;
        this.enabled = enabled;
        this.roleCodes = List.copyOf(roleCodes);
    }

    public Long getUserId() {
        return userId;
    }

    public UUID getPublicId() {
        return publicId;
    }

    public List<String> getRoleCodes() {
        return roleCodes;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return roleCodes.stream()
                .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
                .toList();
    }

    @Override
    public String getPassword() {
        return passwordHash;
    }

    @Override
    public String getUsername() {
        return normalizedEmail;
    }

    @Override
    public boolean isEnabled() {
        return enabled;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return enabled;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }
}
