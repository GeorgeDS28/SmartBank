//TransactionPinServiceImplTest.java

package com.smartbank.transactionpin.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.LocalDateTime;
import java.util.Optional;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.smartbank.exception.InvalidCredentialsException;
import com.smartbank.transactionpin.dto.ResetPinRequest;
import com.smartbank.transactionpin.entity.TransactionPin;
import com.smartbank.transactionpin.repository.TransactionPinRepository;
import com.smartbank.transactionpin.service.TransactionPinAttemptService;
import com.smartbank.user.entity.User;
import com.smartbank.user.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class TransactionPinServiceImplTest {

    @Mock
    private TransactionPinRepository transactionPinRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private TransactionPinAttemptService transactionPinAttemptService;

    private TransactionPinServiceImpl transactionPinService;

    private User user;

    @BeforeEach
    void setUp() {

        transactionPinService = new TransactionPinServiceImpl(
                transactionPinRepository,
                userRepository,
                passwordEncoder,
                transactionPinAttemptService
        );

        user = new User();
        user.setId(1L);
        user.setEmail("george@example.com");
        user.setPassword("stored-login-hash");

        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(
                        "george@example.com",
                        null,
                        java.util.List.of()
                )
        );

        when(userRepository.findByEmail("george@example.com"))
                .thenReturn(Optional.of(user));
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void resetPin_shouldRejectWhenLoginPasswordDoesNotMatch() {

        when(passwordEncoder.matches("wrong-password", "stored-login-hash"))
                .thenReturn(false);

        ResetPinRequest request = new ResetPinRequest();
        request.setPassword("wrong-password");
        request.setNewPin("246810");
        request.setConfirmNewPin("246810");

        assertThrows(
                InvalidCredentialsException.class,
                () -> transactionPinService.resetPin(request)
        );

        verify(transactionPinRepository, never())
                .save(any(TransactionPin.class));
    }

    @Test
    void resetPin_shouldStoreNewHashAndClearTheLock() {

        when(passwordEncoder.matches("Password123", "stored-login-hash"))
                .thenReturn(true);

        TransactionPin existing = TransactionPin.builder()
                .user(user)
                .pinHash("old-pin-hash")
                .failedAttempts(5)
                .lockedUntil(LocalDateTime.now().plusMinutes(10))
                .build();

        when(transactionPinRepository.findByUserId(1L))
                .thenReturn(Optional.of(existing));

        when(passwordEncoder.encode("246810"))
                .thenReturn("new-pin-hash");

        ResetPinRequest request = new ResetPinRequest();
        request.setPassword("Password123");
        request.setNewPin("246810");
        request.setConfirmNewPin("246810");

        transactionPinService.resetPin(request);

        assertEquals("new-pin-hash", existing.getPinHash());
        assertEquals(0, existing.getFailedAttempts());
        assertNull(existing.getLockedUntil());

        verify(transactionPinRepository).save(existing);
    }

    @Test
    void resetPin_shouldCreateAPinWhenNoneExistsYet() {

        when(passwordEncoder.matches("Password123", "stored-login-hash"))
                .thenReturn(true);

        when(transactionPinRepository.findByUserId(1L))
                .thenReturn(Optional.empty());

        when(passwordEncoder.encode("135790"))
                .thenReturn("fresh-pin-hash");

        ResetPinRequest request = new ResetPinRequest();
        request.setPassword("Password123");
        request.setNewPin("135790");
        request.setConfirmNewPin("135790");

        transactionPinService.resetPin(request);

        verify(transactionPinRepository).save(any(TransactionPin.class));
    }

    @Test
    void resetPin_shouldRejectMismatchedConfirmation() {

        when(passwordEncoder.matches("Password123", "stored-login-hash"))
                .thenReturn(true);

        ResetPinRequest request = new ResetPinRequest();
        request.setPassword("Password123");
        request.setNewPin("246810");
        request.setConfirmNewPin("013462");

        assertThrows(
                IllegalArgumentException.class,
                () -> transactionPinService.resetPin(request)
        );

        verify(transactionPinRepository, never())
                .save(any(TransactionPin.class));
    }
}
