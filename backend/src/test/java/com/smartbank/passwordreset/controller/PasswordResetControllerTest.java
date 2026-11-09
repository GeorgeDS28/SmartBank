//PasswordResetControllerTest.java
package com.smartbank.passwordreset.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.doThrow;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

import com.smartbank.auth.jwt.JwtService;
import com.smartbank.passwordreset.dto.ForgotPasswordRequest;
import com.smartbank.passwordreset.dto.ResetPasswordRequest;
import com.smartbank.passwordreset.service.PasswordResetService;
import com.smartbank.security.CustomUserDetailsService;

@WebMvcTest(PasswordResetController.class)
@AutoConfigureMockMvc(addFilters = false)
class PasswordResetControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private PasswordResetService passwordResetService;

    // Pulled in by the slice because the JWT filter is a servlet filter;
    // they are not used by these tests.
    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void forgotPassword_repliesTheSameMessageRegardlessOfTheAccount()
            throws Exception {

        mockMvc.perform(
                post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"george@gmail.com\"}")
        )
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.message").value(
                "If that email belongs to an account, "
                        + "a reset code has been sent."));

        verify(passwordResetService).requestCode(any(ForgotPasswordRequest.class));
    }

    @Test
    void forgotPassword_withoutEmail_returnsBadRequest() throws Exception {

        mockMvc.perform(
                post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}")
        )
        .andExpect(status().isBadRequest());

        verify(passwordResetService, never()).requestCode(any());
    }

    @Test
    void forgotPassword_whenMailIsUnavailable_returnsServiceUnavailable()
            throws Exception {

        doThrow(new ResponseStatusException(
                HttpStatus.SERVICE_UNAVAILABLE,
                "Email delivery is not configured on this server"))
                .when(passwordResetService).requestCode(any());

        mockMvc.perform(
                post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"george@gmail.com\"}")
        )
        .andExpect(status().isServiceUnavailable());
    }

    @Test
    void resetPassword_success() throws Exception {

        mockMvc.perform(
                post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"george@gmail.com",
                                 "code":"246813",
                                 "newPassword":"Recovered!23",
                                 "confirmPassword":"Recovered!23"}
                                """)
        )
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.message").value("Password reset successfully"));

        verify(passwordResetService)
                .resetPassword(any(ResetPasswordRequest.class));
    }

    @Test
    void resetPassword_withACodeThatIsNotSixDigits_returnsBadRequest()
            throws Exception {

        mockMvc.perform(
                post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"george@gmail.com",
                                 "code":"12ab",
                                 "newPassword":"Recovered!23",
                                 "confirmPassword":"Recovered!23"}
                                """)
        )
        .andExpect(status().isBadRequest());

        verify(passwordResetService, never()).resetPassword(any());
    }

    @Test
    void resetPassword_withAShortNewPassword_returnsBadRequest()
            throws Exception {

        mockMvc.perform(
                post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"george@gmail.com",
                                 "code":"246813",
                                 "newPassword":"short",
                                 "confirmPassword":"short"}
                                """)
        )
        .andExpect(status().isBadRequest());

        verify(passwordResetService, never()).resetPassword(any());
    }
}
