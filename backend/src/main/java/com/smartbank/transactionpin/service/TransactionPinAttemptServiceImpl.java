/*TransactionPinAttemptServiceImpl.java
 * This class is responsible for handling the transaction pin attempts.
 * It provides methods to record failed attempts and reset failed attempts.
 * It also handles locking the transaction pin after a certain number of failed attempts.
 */

package com.smartbank.transactionpin.service.impl;

import java.time.LocalDateTime;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import com.smartbank.exception.TransactionPinLockedException;
import com.smartbank.transactionpin.entity.TransactionPin;
import com.smartbank.transactionpin.repository.TransactionPinRepository;
import com.smartbank.transactionpin.service.TransactionPinAttemptService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class TransactionPinAttemptServiceImpl
        implements TransactionPinAttemptService {

    private final TransactionPinRepository transactionPinRepository;

    private static final int MAX_ATTEMPTS = 5;

    private static final int LOCK_DURATION_MINUTES = 15;

    @Override
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void recordFailedAttempt(Long userId) {

        TransactionPin transactionPin =
                transactionPinRepository.findByUserId(userId)
                        .orElseThrow(() ->
                                new IllegalStateException("Transaction PIN not found"));

        transactionPin.setFailedAttempts(
                transactionPin.getFailedAttempts() + 1
        );

        if (transactionPin.getFailedAttempts() >= MAX_ATTEMPTS) {

            transactionPin.setLockedUntil(
                    LocalDateTime.now().plusMinutes(LOCK_DURATION_MINUTES)
            );
        }

        transactionPinRepository.save(transactionPin);
    }

    @Override
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void resetFailedAttempts(Long userId) {

        TransactionPin transactionPin =
                transactionPinRepository.findByUserId(userId)
                        .orElseThrow(() ->
                                new IllegalStateException("Transaction PIN not found"));

        transactionPin.setFailedAttempts(0);
        transactionPin.setLockedUntil(null);

        transactionPinRepository.save(transactionPin);
    }
}