package com.traxia.common.security;

import java.util.Collection;
import java.util.List;

public final class GlobalRolePolicy {

    private static final String ADMIN = "ADMIN";

    private GlobalRolePolicy() {
    }

    public static List<String> filter(Collection<String> roleCodes) {
        if (roleCodes == null || roleCodes.isEmpty()) {
            return List.of();
        }
        return roleCodes.stream()
                .filter(ADMIN::equals)
                .distinct()
                .toList();
    }
}
