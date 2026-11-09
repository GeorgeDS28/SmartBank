/*PasswordResetService.java
 */

package com.smartbank.passwordreset.service;

import com.smartbank.passwordreset.dto.ForgotPasswordRequest;
import com.smartbank.passwordreset.dto.ResetPasswordRequest;

public interface PasswordResetService {

    void requestCode(ForgotPasswordRequest request);

    void resetPassword(ResetPasswordRequest request);
}
