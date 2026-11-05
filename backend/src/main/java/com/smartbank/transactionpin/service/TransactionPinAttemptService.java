/* TransactionPinAttemptService.java*/


package com.smartbank.transactionpin.service;

public interface TransactionPinAttemptService {

    void recordFailedAttempt(Long userId);

    void resetFailedAttempts(Long userId);
}