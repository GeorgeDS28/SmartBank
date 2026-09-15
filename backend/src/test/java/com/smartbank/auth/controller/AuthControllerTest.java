//AuthControllerTest.java
package com.smartbank.auth.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartbank.auth.dto.LoginRequest;
import com.smartbank.auth.dto.LoginResponse;
import com.smartbank.auth.dto.RegisterRequest;
import com.smartbank.auth.service.AuthService;
import com.smartbank.auth.jwt.JwtService;

import com.smartbank.security.CustomUserDetailsService;

@WebMvcTest(AuthController.class)
@AutoConfigureMockMvc(addFilters = false)
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AuthService authService;

    @MockBean
    private JwtService jwtService;

    @MockBean
   private CustomUserDetailsService customUserDetailsService;

    @Test
    void register_success() throws Exception {

        RegisterRequest request = new RegisterRequest();

        request.setFirstName("George");
        request.setLastName("Annamattathil");
        request.setEmail("george@gmail.com");
        request.setPassword("George@123");
        request.setPhone("9876543210");

        mockMvc.perform(
                post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isOk())
        .andExpect(content().string("User registered successfully"));

        verify(authService).register(any(RegisterRequest.class));
    }

    @Test
    void register_invalidRequest_returnsBadRequest() throws Exception {

        RegisterRequest request = new RegisterRequest();

        mockMvc.perform(
                post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isBadRequest());
    }

    @Test
    void login_success() throws Exception {

        LoginRequest request = new LoginRequest();

        request.setEmail("george@gmail.com");
        request.setPassword("George@123");

        LoginResponse loginResponse =
                new LoginResponse("mock-jwt-token");

        when(authService.login(any(LoginRequest.class)))
                .thenReturn(loginResponse);

        mockMvc.perform(
                post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.token")
                .value("mock-jwt-token"));

        verify(authService).login(any(LoginRequest.class));
    }

    @Test
    void login_invalidRequest_returnsBadRequest() throws Exception {

        LoginRequest request = new LoginRequest();

        mockMvc.perform(
                post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isBadRequest());
    }
}