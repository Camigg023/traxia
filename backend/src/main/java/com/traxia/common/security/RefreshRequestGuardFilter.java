package com.traxia.common.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Set;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class RefreshRequestGuardFilter extends OncePerRequestFilter {

    private static final String REFRESH_PATH = "/api/v1/auth/refresh";
    private static final String LOGOUT_PATH = "/api/v1/auth/logout";
    private static final String REQUEST_HEADER = "X-TRAXIA-Refresh-Request";

    private final Set<String> allowedOrigins;
    private final ObjectMapper objectMapper;

    public RefreshRequestGuardFilter(
            @Value("${traxia.web.allowed-origins}") String origins,
            ObjectMapper objectMapper) {
        this.allowedOrigins = Set.of(origins.split(",")).stream()
                .map(String::trim)
                .filter(origin -> !origin.isEmpty())
                .collect(java.util.stream.Collectors.toUnmodifiableSet());
        this.objectMapper = objectMapper;
        if (this.allowedOrigins.isEmpty()) {
            throw new IllegalStateException("Debe configurarse al menos un origen web permitido.");
        }
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getServletPath();
        return !("POST".equals(request.getMethod())
                && (REFRESH_PATH.equals(path) || LOGOUT_PATH.equals(path)));
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {
        String origin = request.getHeader("Origin");
        String requestHeader = request.getHeader(REQUEST_HEADER);

        if (origin == null || !allowedOrigins.contains(origin) || !"true".equals(requestHeader)) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
            response.setCharacterEncoding(java.nio.charset.StandardCharsets.UTF_8.name());
            objectMapper.writeValue(response.getOutputStream(), new ApiProblem(
                    "Solicitud no válida",
                    HttpServletResponse.SC_FORBIDDEN,
                    "Actualiza la página e inténtalo de nuevo."));
            return;
        }

        filterChain.doFilter(request, response);
    }

    private record ApiProblem(String title, int status, String detail) {
    }
}
