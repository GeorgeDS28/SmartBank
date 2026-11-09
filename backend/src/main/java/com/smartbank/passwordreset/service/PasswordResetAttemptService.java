/*PasswordResetAttemptService.java
 */

package com.smartbank.passwordreset.service;

public interface PasswordResetAttemptService {

    void recordFailedAttempt(Long tokenId);
}
