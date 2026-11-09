//AuthEndpointSecurityTest.java
package com.smartbank.security;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import com.smartbank.auth.service.AuthService;
import com.smartbank.passwordreset.service.PasswordResetService;

/**
 * Runs against the real security filter chain, unlike the @WebMvcTest slices
 * that switch it off, so it can prove which endpoints stay anonymous.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthEndpointSecurityTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private AuthService authService;

    @MockBean
    private PasswordResetService passwordResetService;

    private static final String BODY =
            "{\"currentPassword\":\"old12345\",\"newPassword\":\"brandNew9\","
                    + "\"confirmPassword\":\"brandNew9\"}";

    @Test
    void changePassword_withoutAnyToken_isRejected() throws Exception {

        int status = mockMvc.perform(
                put("/api/auth/change-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(BODY)
        ).andReturn().getResponse().getStatus();

        assertTrue(
                status == 401 || status == 403,
                "an anonymous caller must be rejected, got " + status
        );

        verify(authService, never()).changePassword(any());
    }

    @Test
    void login_isStillAnonymousReachable() throws Exception {

        // Validation rejects the empty body, which is only possible if the
        // request passed the security filter and reached the controller.
        int status = mockMvc.perform(
                post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}")
        ).andReturn().getResponse().getStatus();

        assertEquals(400, status);
    }

    @Test
    void recoveryEndpoints_areAnonymousReachable() throws Exception {

        // A locked-out user has no token, so both of these have to get through
        // the filter chain. 400 comes from Bean Validation on the empty body,
        // which the filter cannot produce.
        int forgot = mockMvc.perform(
                post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}")
        ).andReturn().getResponse().getStatus();

        assertEquals(400, forgot);

        int reset = mockMvc.perform(
                post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}")
        ).andReturn().getResponse().getStatus();

        assertEquals(400, reset);

        verify(passwordResetService, never()).requestCode(any());
        verify(passwordResetService, never()).resetPassword(any());
    }
}
