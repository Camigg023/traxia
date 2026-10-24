package com.traxia.identity.application;

import com.traxia.identity.domain.AuthMethodEntity;
import com.traxia.identity.domain.UserEntity;
import com.traxia.identity.persistence.UserRepository;
import com.traxia.common.security.GlobalRolePolicy;
import java.util.List;
import java.util.Locale;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TraxiaUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    public TraxiaUserDetailsService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        String normalizedEmail = normalizeEmail(email);
        UserEntity user = userRepository.findByEmailNormalized(normalizedEmail)
                .orElseThrow(() -> new UsernameNotFoundException("Credenciales no válidas."));
        return toUserDetails(user);
    }

    @Transactional(readOnly = true)
    public TraxiaUserDetails loadEnabledUserById(Long userId) {
        UserEntity user = userRepository.findWithAuthenticationDataById(userId)
                .orElseThrow(() -> new UsernameNotFoundException("La sesión ya no está disponible."));
        TraxiaUserDetails details = toUserDetails(user);
        if (!details.isEnabled()) {
            throw new UsernameNotFoundException("La sesión ya no está disponible.");
        }
        return details;
    }

    private static TraxiaUserDetails toUserDetails(UserEntity user) {
        String passwordHash = user.getAuthMethods().stream()
                .filter(method -> "EMAIL".equals(method.getProviderCode()))
                .filter(method -> "ACTIVE".equals(method.getStatus()))
                .map(AuthMethodEntity::getCredentialHash)
                .filter(hash -> hash != null && !hash.isBlank())
                .findFirst()
                .orElse("");

        List<String> assignedRoleCodes = user.getUserRoles().stream()
                .filter(userRole -> userRole.getRevokedAtUtc() == null)
                .map(userRole -> userRole.getRole().getCode())
                .distinct()
                .toList();
        List<String> roles = GlobalRolePolicy.filter(assignedRoleCodes);

        boolean enabled = "ACTIVE".equals(user.getStatus())
                && user.getEmailVerifiedAtUtc() != null
                && !passwordHash.isBlank();
        return new TraxiaUserDetails(
                user.getId(),
                user.getPublicId(),
                user.getEmailNormalized(),
                passwordHash,
                enabled,
                roles);
    }

    public static String normalizeEmail(String email) {
        if (email == null) {
            return "";
        }
        return email.trim().toLowerCase(Locale.ROOT);
    }
}
