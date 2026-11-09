/*PasswordResetServiceImpl.java
 */

package com.smartbank.passwordreset.service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.smartbank.exception.InvalidCredentialsException;
import com.smartbank.passwordreset.dto.ForgotPasswordRequest;
import com.smartbank.passwordreset.dto.ResetPasswordRequest;
import com.smartbank.passwordreset.entity.PasswordResetToken;
import com.smartbank.passwordreset.repository.PasswordResetTokenRepository;
import com.smartbank.user.entity.User;
import com.smartbank.user.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class PasswordResetServiceImpl implements PasswordResetService {

    private static final Logger log =
            LoggerFactory.getLogger(PasswordResetServiceImpl.class);

    private static final SecureRandom RANDOM = new SecureRandom();

    static final int CODE_VALID_MINUTES = 15;

    private static final int REQUEST_COOLDOWN_SECONDS = 60;

    private final UserRepository userRepository;

    private final PasswordResetTokenRepository passwordResetTokenRepository;

    private final PasswordEncoder passwordEncoder;

    private final ResetCodeMailer resetCodeMailer;

    private final PasswordResetAttemptService passwordResetAttemptService;

    @Override
    @Transactional
    public void requestCode(ForgotPasswordRequest request) {

        // The reply is identical whether or not the address has an account, so
        // this endpoint cannot be used to discover registered emails.
        Optional<User> maybeUser =
                userRepository.findByEmail(request.getEmail());

        if (maybeUser.isEmpty()) {
            log.warn("Password reset requested for an unknown account");
            return;
        }

        User user = maybeUser.get();

        Optional<PasswordResetToken> newest = passwordResetTokenRepository
                .findTopByUserIdOrderByCreatedAtDescIdDesc(user.getId());

        if (newest.isPresent() && newest.get().getCreatedAt()
                .isAfter(LocalDateTime.now()
                        .minusSeconds(REQUEST_COOLDOWN_SECONDS))) {

            log.info("Password reset requested again inside the cooldown");
            return;
        }

        // Only the most recently issued code can be redeemed.
        passwordResetTokenRepository.retireOutstanding(user.getId());

        String code = newCode();

        PasswordResetToken token = PasswordResetToken.builder()
                .user(user)
                .codeHash(passwordEncoder.encode(code))
                .expiresAt(LocalDateTime.now().plusMinutes(CODE_VALID_MINUTES))
                .used(false)
                .failedAttempts(0)
                .build();

        passwordResetTokenRepository.save(token);

        // An unconfigured or failing mail server throws out of here, and the
        // rolled-back transaction leaves no undelivered code behind.
        resetCodeMailer.send(user.getEmail(), code, CODE_VALID_MINUTES);

        log.info("Password reset code issued");
    }

    @Override
    @Transactional
    public void resetPassword(ResetPasswordRequest request) {

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException(
                        "Reset code is not valid. Request a new one."));

        PasswordResetToken token = passwordResetTokenRepository
                .findTopByUserIdOrderByCreatedAtDescIdDesc(user.getId())
                .filter(candidate -> !candidate.isUsed())
                .orElseThrow(() -> new IllegalArgumentException(
                        "Reset code is not valid. Request a new one."));

        if (token.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new IllegalArgumentException(
                    "Reset code has expired. Request a new one.");
        }

        if (!passwordEncoder.matches(request.getCode(), token.getCodeHash())) {
            log.warn("Failed reset code attempt");

            // Counted in its own transaction; this one is about to roll back.
            passwordResetAttemptService.recordFailedAttempt(token.getId());

            throw new InvalidCredentialsException("Reset code does not match");
        }

        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new IllegalArgumentException(
                    "New password and confirmation do not match");
        }

        token.setUsed(true);
        passwordResetTokenRepository.save(token);

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        log.info("Password reset using a one-time code");
    }

    // 100000-999999, so the code is always six digits and never loses a
    // leading zero between the email and the form.
    private String newCode() {

        return String.valueOf(RANDOM.nextInt(900_000) + 100_000);
    }
}
