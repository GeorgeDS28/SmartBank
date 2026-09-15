//JwtAuthenticationFilterTest.java

package com.smartbank.security;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.io.IOException;
import java.util.List;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;

import com.smartbank.auth.jwt.JwtService;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@ExtendWith(MockitoExtension.class)
class JwtAuthenticationFilterTest {

    @Mock
    private JwtService jwtService;

    @Mock
    private CustomUserDetailsService userDetailsService;

    @Mock
    private FilterChain filterChain;

    @Mock
    private HttpServletRequest request;

    @Mock
    private HttpServletResponse response;

    @Mock
    private UserDetails userDetails;

    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @BeforeEach
    void setUp() {

        jwtAuthenticationFilter =
                new JwtAuthenticationFilter(
                        jwtService,
                        userDetailsService
                );

        SecurityContextHolder.clearContext();
    }

    @AfterEach
    void tearDown() {

        SecurityContextHolder.clearContext();
    }

    private void executeFilter()
            throws ServletException, IOException {

        jwtAuthenticationFilter.doFilterInternal(
                request,
                response,
                filterChain
        );
    }

    @Test
    void doFilter_shouldContinueWhenAuthorizationHeaderIsMissing()
            throws ServletException, IOException {

        when(request.getHeader("Authorization"))
                .thenReturn(null);

        executeFilter();

        verify(filterChain)
                .doFilter(request, response);

        assertNull(
                SecurityContextHolder
                        .getContext()
                        .getAuthentication()
        );
    }

    @Test
    void doFilter_shouldContinueWhenAuthorizationHeaderIsNotBearer()
            throws ServletException, IOException {

        when(request.getHeader("Authorization"))
                .thenReturn("Basic some-token");

        executeFilter();

        verify(filterChain)
                .doFilter(request, response);

        assertNull(
                SecurityContextHolder
                        .getContext()
                        .getAuthentication()
        );
    }

    @Test
    void doFilter_shouldAuthenticateUserWithValidToken()
            throws ServletException, IOException {

        String token = "valid-jwt";
        String email = "george@example.com";

        when(request.getHeader("Authorization"))
                .thenReturn("Bearer " + token);

        when(jwtService.extractEmail(token))
                .thenReturn(email);

        when(userDetailsService.loadUserByUsername(email))
                .thenReturn(userDetails);

        when(userDetails.getUsername())
                .thenReturn(email);

        when(userDetails.getAuthorities())
                .thenReturn(List.of());

        when(jwtService.isTokenValid(token, email))
                .thenReturn(true);

        executeFilter();

        var authentication =
                SecurityContextHolder
                        .getContext()
                        .getAuthentication();

        assertEquals(
                email,
                authentication.getName()
        );

        verify(jwtService)
                .extractEmail(token);

        verify(userDetailsService)
                .loadUserByUsername(email);

        verify(jwtService)
                .isTokenValid(token, email);

        verify(filterChain)
                .doFilter(request, response);
    }

    @Test
    void doFilter_shouldNotAuthenticateWhenTokenIsInvalid()
            throws ServletException, IOException {

        String token = "invalid-jwt";
        String email = "george@example.com";

        when(request.getHeader("Authorization"))
                .thenReturn("Bearer " + token);

        when(jwtService.extractEmail(token))
                .thenReturn(email);

        when(userDetailsService.loadUserByUsername(email))
                .thenReturn(userDetails);

        when(userDetails.getUsername())
                .thenReturn(email);

        when(jwtService.isTokenValid(token, email))
                .thenReturn(false);

        executeFilter();

        assertNull(
                SecurityContextHolder
                        .getContext()
                        .getAuthentication()
        );

        verify(jwtService)
                .extractEmail(token);

        verify(userDetailsService)
                .loadUserByUsername(email);

        verify(jwtService)
                .isTokenValid(token, email);

        verify(filterChain)
                .doFilter(request, response);
    }

    @Test
    void doFilter_shouldNotReauthenticateExistingAuthentication()
            throws ServletException, IOException {

        String token = "valid-jwt";
        String email = "george@example.com";

        UsernamePasswordAuthenticationToken existingAuthentication =
                new UsernamePasswordAuthenticationToken(
                        "existing-user",
                        null,
                        List.of()
                );

        SecurityContextHolder
                .getContext()
                .setAuthentication(existingAuthentication);

        when(request.getHeader("Authorization"))
                .thenReturn("Bearer " + token);

        when(jwtService.extractEmail(token))
                .thenReturn(email);

        executeFilter();

        assertEquals(
                existingAuthentication,
                SecurityContextHolder
                        .getContext()
                        .getAuthentication()
        );

        verify(jwtService)
                .extractEmail(token);

        verify(filterChain)
                .doFilter(request, response);
    }
}