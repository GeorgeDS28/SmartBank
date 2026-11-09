/*
Purpose: receive the three password entries needed to replace a password.
ChangePasswordRequest.java
*/
package com.smartbank.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ChangePasswordRequest {

    @NotBlank(message = "Current password is required")
    private String currentPassword;

    // Same rule as registration, so a user is never allowed to weaken their own
    // password below the bar they had to clear to sign up.
    @NotBlank(message = "New password is required")
    @Size(min = 8, message = "Password must contain at least 8 characters")
    private String newPassword;

    @NotBlank(message = "Confirm password is required")
    private String confirmPassword;
}
