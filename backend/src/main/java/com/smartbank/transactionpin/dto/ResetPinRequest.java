/*ResetPinRequest.java */

package com.smartbank.transactionpin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ResetPinRequest {

    @NotBlank(message = "Account password is required")
    private String password;

    @NotBlank(message = "New PIN is required")
    @Pattern(regexp = "^[0-9]{6}$", message = "New PIN must contain exactly 6 digits")
    private String newPin;

    @NotBlank(message = "PIN confirmation is required")
    @Pattern(regexp = "^[0-9]{6}$", message = "Confirm PIN must contain exactly 6 digits")
    private String confirmNewPin;
}
