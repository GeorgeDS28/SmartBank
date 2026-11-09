//PasswordResetServiceImplTest.java

package com.smartbank.passwordreset.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.LocalDateTime;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.smartbank.exception.InvalidCredentialsException;
import com.smartbank.passwordreset.dto.ForgotPasswordRequest;
import com.smartbank.passwordreset.dto.ResetPasswordRequest;
import com.smartbank.passwordreset.entity.PasswordResetToken;
import com.smartbank.passwordreset.repository.PasswordResetTokenRepository;
import com.smartbank.user.entity.User;
import com.smartbank.user.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class PasswordResetServiceImplTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordResetTokenRepository passwordResetTokenRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private ResetCodeMailer resetCodeMailer;

    @Mock
    private PasswordResetAttemptService passwordResetAttemptService;

    private PasswordResetServiceImpl passwordResetService;

    private User user;

    @BeforeEach
    void setUp() {

        passwordResetService = new PasswordResetServiceImpl(
                userRepository,
                passwordResetTokenRepository,
                passwordEncoder,
                resetCodeMailer,
                passwordResetAttemptService
        );

        user = new User();
        user.setId(1L);
        user.setEmail("george@example.com");
        user.setPassword("stored-login-hash");
    }

    private ForgotPasswordRequest forgotRequest() {

        ForgotPasswordRequest request = new ForgotPasswordRequest();
        request.setEmail("george@example.com");
        return request;
    }

    private ResetPasswordRequest resetRequest(String code) {

        ResetPasswordRequest request = new ResetPasswordRequest();
        request.setEmail("george@example.com");
        request.setCode(code);
        request.setNewPassword("Recovered!23");
        request.setConfirmPassword("Recovered!23");
        return request;
    }

    private PasswordResetToken pendingToken(String codeHash) {

        PasswordResetToken token = PasswordResetToken.builder()
                .user(user)
                .codeHash(codeHash)
                .expiresAt(LocalDateTime.now().plusMinutes(10))
                .used(false)
                .failedAttempts(0)
                .build();

        token.setId(7L);
        return token;
    }

    @Test
    void requestCode_shouldSendNothingForAnUnknownEmail() {

        when(userRepository.findByEmail("george@example.com"))
                .thenReturn(Optional.empty());

        passwordResetService.requestCode(forgotRequest());

        verify(passwordResetTokenRepository, never()).save(any());
        verify(resetCodeMailer, never())
                .send(anyString(), anyString(), anyInt());
    }

    @Test
    void requestCode_shouldStoreOnlyAHashAndEmailTheCodeItself() {

        when(userRepository.findByEmail("george@example.com"))
                .thenReturn(Optional.of(user));

        when(passwordResetTokenRepository.findTopByUserIdOrderByCreatedAtDescIdDesc(1L))
                .thenReturn(Optional.empty());

        when(passwordEncoder.encode(anyString()))
                .thenReturn("stored-code-hash");

        passwordResetService.requestCode(forgotRequest());

        ArgumentCaptor<PasswordResetToken> saved =
                ArgumentCaptor.forClass(PasswordResetToken.class);

        verify(passwordResetTokenRepository).save(saved.capture());

        PasswordResetToken token = saved.getValue();

        assertEquals("stored-code-hash", token.getCodeHash());
        assertTrue(token.getExpiresAt().isAfter(LocalDateTime.now()),
                "a fresh code has to still be usable");

        ArgumentCaptor<String> emailed = ArgumentCaptor.forClass(String.class);

        verify(resetCodeMailer).send(
                eq("george@example.com"), emailed.capture(), anyInt());

        String code = emailed.getValue();

        assertTrue(code.matches("^[0-9]{6}$"), "code was " + code);
        assertNotEquals(code, token.getCodeHash(),
                "the emailed code must never be what gets stored");
    }

    @Test
    void requestCode_shouldNotIssueTwiceInsideTheCooldown() {

        when(userRepository.findByEmail("george@example.com"))
                .thenReturn(Optional.of(user));

        PasswordResetToken justIssued = pendingToken("stored-code-hash");
        justIssued.setCreatedAt(LocalDateTime.now().minusSeconds(5));

        when(passwordResetTokenRepository.findTopByUserIdOrderByCreatedAtDescIdDesc(1L))
                .thenReturn(Optional.of(justIssued));

        passwordResetService.requestCode(forgotRequest());

        verify(passwordResetTokenRepository, never()).save(any());
        verify(resetCodeMailer, never())
                .send(anyString(), anyString(), anyInt());
    }

    @Test
    void resetPassword_shouldStoreTheNewHashAndRetireTheCode() {

        when(userRepository.findByEmail("george@example.com"))
                .thenReturn(Optional.of(user));

        PasswordResetToken token = pendingToken("stored-code-hash");

        when(passwordResetTokenRepository.findTopByUserIdOrderByCreatedAtDescIdDesc(1L))
                .thenReturn(Optional.of(token));

        when(passwordEncoder.matches("246813", "stored-code-hash"))
                .thenReturn(true);

        when(passwordEncoder.encode("Recovered!23"))
                .thenReturn("new-login-hash");

        passwordResetService.resetPassword(resetRequest("246813"));

        assertEquals("new-login-hash", user.getPassword());
        verify(userRepository).save(user);
        assertTrue(token.isUsed());
        verify(passwordResetTokenRepository).save(token);
    }

    @Test
    void resetPassword_shouldCountAFailedGuessAndStoreNothing() {

        when(userRepository.findByEmail("george@example.com"))
                .thenReturn(Optional.of(user));

        PasswordResetToken token = pendingToken("stored-code-hash");

        when(passwordResetTokenRepository.findTopByUserIdOrderByCreatedAtDescIdDesc(1L))
                .thenReturn(Optional.of(token));

        when(passwordEncoder.matches("111111", "stored-code-hash"))
                .thenReturn(false);

        assertThrows(
                InvalidCredentialsException.class,
                () -> passwordResetService.resetPassword(resetRequest("111111"))
        );

        // Recorded on its own transaction, because this one rolls back.
        verify(passwordResetAttemptService).recordFailedAttempt(7L);
        verify(userRepository, never()).save(any());
    }

    @Test
    void resetPassword_shouldRejectAnExpiredCode() {

        when(userRepository.findByEmail("george@example.com"))
                .thenReturn(Optional.of(user));

        PasswordResetToken expired = pendingToken("stored-code-hash");
        expired.setExpiresAt(LocalDateTime.now().minusMinutes(1));

        when(passwordResetTokenRepository.findTopByUserIdOrderByCreatedAtDescIdDesc(1L))
                .thenReturn(Optional.of(expired));

        assertThrows(
                IllegalArgumentException.class,
                () -> passwordResetService.resetPassword(resetRequest("246813"))
        );

        verify(userRepository, never()).save(any());
    }

    @Test
    void resetPassword_shouldRejectACodeThatWasAlreadyRedeemed() {

        when(userRepository.findByEmail("george@example.com"))
                .thenReturn(Optional.of(user));

        PasswordResetToken spent = pendingToken("stored-code-hash");
        spent.setUsed(true);

        when(passwordResetTokenRepository.findTopByUserIdOrderByCreatedAtDescIdDesc(1L))
                .thenReturn(Optional.of(spent));

        assertThrows(
                IllegalArgumentException.class,
                () -> passwordResetService.resetPassword(resetRequest("246813"))
        );

        verify(userRepository, never()).save(any());
    }

    @Test
    void resetPassword_shouldRejectMismatchedConfirmation() {

        when(userRepository.findByEmail("george@example.com"))
                .thenReturn(Optional.of(user));

        when(passwordResetTokenRepository.findTopByUserIdOrderByCreatedAtDescIdDesc(1L))
                .thenReturn(Optional.of(pendingToken("stored-code-hash")));

        when(passwordEncoder.matches("246813", "stored-code-hash"))
                .thenReturn(true);

        ResetPasswordRequest request = resetRequest("246813");
        request.setConfirmPassword("SomethingElse!23");

        assertThrows(
                IllegalArgumentException.class,
                () -> passwordResetService.resetPassword(request)
        );

        verify(userRepository, never()).save(any());
    }
}
