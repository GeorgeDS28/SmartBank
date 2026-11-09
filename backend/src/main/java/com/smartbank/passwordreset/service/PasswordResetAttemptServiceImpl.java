/*PasswordResetAttemptServiceImpl.java
 */

package com.smartbank.passwordreset.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import com.smartbank.passwordreset.entity.PasswordResetToken;
import com.smartbank.passwordreset.repository.PasswordResetTokenRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class PasswordResetAttemptServiceImpl
        implements PasswordResetAttemptService {

    private final PasswordResetTokenRepository passwordResetTokenRepository;

    private static final int MAX_ATTEMPTS = 5;

    // REQUIRES_NEW: the redeeming transaction rolls back when the code is
    // wrong, and the counter has to survive that rollback.
    @Override
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void recordFailedAttempt(Long tokenId) {

        PasswordResetToken token = passwordResetTokenRepository
                .findById(tokenId)
                .orElseThrow(() -> new IllegalStateException("Reset code not found"));

        token.setFailedAttempts(token.getFailedAttempts() + 1);

        // Retiring the row rather than locking it keeps one rule:
        // a code that has been guessed at too often is simply dead.
        if (token.getFailedAttempts() >= MAX_ATTEMPTS) {
            token.setUsed(true);
        }

        passwordResetTokenRepository.save(token);
    }
}
