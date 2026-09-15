//AuthServiceImplTest.java
package com.smartbank.auth.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.smartbank.auth.dto.LoginRequest;
import com.smartbank.auth.dto.LoginResponse;
import com.smartbank.auth.dto.RegisterRequest;
import com.smartbank.auth.jwt.JwtService;
import com.smartbank.exception.EmailAlreadyExistsException;
import com.smartbank.exception.InvalidCredentialsException;
import com.smartbank.user.entity.User;
import com.smartbank.user.enums.Role;
import com.smartbank.user.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class AuthServiceImplTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    @InjectMocks
    private AuthServiceImpl authService;

    private RegisterRequest registerRequest;
    private LoginRequest loginRequest;
    private User user;

    @BeforeEach
    void setUp() {

        registerRequest = new RegisterRequest();

        registerRequest.setFirstName("George");
        registerRequest.setLastName("John");
        registerRequest.setEmail("george@test.com");
        registerRequest.setPassword("password123");
        registerRequest.setPhone("9876543210");

        loginRequest = new LoginRequest();

        loginRequest.setEmail("george@test.com");
        loginRequest.setPassword("password123");

        user = new User();

        user.setFirstName("George");
        user.setLastName("John");
        user.setEmail("george@test.com");
        user.setPassword("encodedPassword");
        user.setPhone("9876543210");
        user.setRole(Role.ROLE_USER);
    }

    @Test
    void register_success() {

        // Email does not already exist
        when(userRepository.existsByEmail("george@test.com"))
                .thenReturn(false);

        // Mock password encoding
        when(passwordEncoder.encode("password123"))
                .thenReturn("encodedPassword");

        authService.register(registerRequest);

        // Verify that user was saved
        verify(userRepository, times(1)).save(any(User.class));

        // Capture the User object passed to save()
        ArgumentCaptor<User> userCaptor =
                ArgumentCaptor.forClass(User.class);

        verify(userRepository).save(userCaptor.capture());

        User savedUser = userCaptor.getValue();

        // Verify user details
        assertEquals("George", savedUser.getFirstName());
        assertEquals("John", savedUser.getLastName());
        assertEquals("george@test.com", savedUser.getEmail());
        assertEquals("encodedPassword", savedUser.getPassword());
        assertEquals("9876543210", savedUser.getPhone());
        assertEquals(Role.ROLE_USER, savedUser.getRole());

        verify(passwordEncoder, times(1))
                .encode("password123");
    }

    @Test
    void register_duplicateEmail_throwsException() {

        when(userRepository.existsByEmail("george@test.com"))
                .thenReturn(true);

        assertThrows(
                EmailAlreadyExistsException.class,
                () -> authService.register(registerRequest)
        );

        // User should never be saved
        verify(userRepository, never()).save(any(User.class));

        // Password should not be encoded
        verify(passwordEncoder, never()).encode(anyString());
    }

    @Test
    void login_success() {

        when(userRepository.findByEmail("george@test.com"))
                .thenReturn(Optional.of(user));

        when(passwordEncoder.matches(
                "password123",
                "encodedPassword"
        )).thenReturn(true);

        when(jwtService.generateToken("george@test.com"))
                .thenReturn("test-jwt-token");

        LoginResponse response =
                authService.login(loginRequest);

        assertNotNull(response);
        assertEquals("test-jwt-token", response.getToken());

        verify(userRepository, times(1))
                .findByEmail("george@test.com");

        verify(passwordEncoder, times(1))
                .matches("password123", "encodedPassword");

        verify(jwtService, times(1))
                .generateToken("george@test.com");
    }

    @Test
    void login_invalidEmail_throwsException() {

        when(userRepository.findByEmail("george@test.com"))
                .thenReturn(Optional.empty());

        assertThrows(
                InvalidCredentialsException.class,
                () -> authService.login(loginRequest)
        );

        // Password and JWT should never be used
        verify(passwordEncoder, never())
                .matches(anyString(), anyString());

        verify(jwtService, never())
                .generateToken(anyString());
    }

    @Test
    void login_invalidPassword_throwsException() {

        when(userRepository.findByEmail("george@test.com"))
                .thenReturn(Optional.of(user));

        when(passwordEncoder.matches(
                "password123",
                "encodedPassword"
        )).thenReturn(false);

        assertThrows(
                InvalidCredentialsException.class,
                () -> authService.login(loginRequest)
        );

        // JWT should not be generated
        verify(jwtService, never())
                .generateToken(anyString());
    }
}

