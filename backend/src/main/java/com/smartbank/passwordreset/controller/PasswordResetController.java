/*PasswordResetController.java
 */

package com.smartbank.passwordreset.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.smartbank.passwordreset.dto.ForgotPasswordRequest;
import com.smartbank.passwordreset.dto.ResetPasswordRequest;
import com.smartbank.passwordreset.service.PasswordResetService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

// Both endpoints sit under /api/auth because a locked-out user has no
// session to authenticate with.
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Tag(
    name = "Password reset",
    description = "One-time code delivery and password recovery APIs"
)
public class PasswordResetController {

    private final PasswordResetService passwordResetService;

    @Operation(
        summary = "Request a password reset code",
        description = "Emails a six-digit one-time code to the address on the account. "
                + "The reply is the same whether or not the address is registered."
    )
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Request accepted"),
        @ApiResponse(responseCode = "503",
                description = "Email delivery is not available")
    })
    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, String>> forgotPassword(
            @Valid @RequestBody ForgotPasswordRequest request) {

        passwordResetService.requestCode(request);

        return ResponseEntity.ok(Map.of(
                "message",
                "If that email belongs to an account, a reset code has been sent."));
    }

    @Operation(
        summary = "Set a new password with a reset code",
        description = "Exchanges a valid, unused, unexpired code for a new password."
    )
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Password reset successfully"),
        @ApiResponse(responseCode = "400", description = "Invalid reset request"),
        @ApiResponse(responseCode = "401", description = "Reset code does not match")
    })
    @PostMapping("/reset-password")
    public ResponseEntity<Map<String, String>> resetPassword(
            @Valid @RequestBody ResetPasswordRequest request) {

        passwordResetService.resetPassword(request);

        return ResponseEntity.ok(
                Map.of("message", "Password reset successfully"));
    }
}
