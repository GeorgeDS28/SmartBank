/* TransactionPinController.java
 */

package com.smartbank.transactionpin.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.smartbank.transactionpin.dto.CreatePinRequest;
import com.smartbank.transactionpin.dto.PinStatusResponse;
import com.smartbank.transactionpin.service.TransactionPinService;
import com.smartbank.transactionpin.dto.ChangePinRequest;
import com.smartbank.transactionpin.dto.ResetPinRequest;


import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/transaction-pin")
@RequiredArgsConstructor
@Tag(
    name = "Transaction PIN",
    description = "Transaction PIN creation and management APIs"
)
public class TransactionPinController {

    private final TransactionPinService transactionPinService;

    @Operation(
        summary = "Create transaction PIN",
        description = "Creates a six-digit transaction PIN for the authenticated user."
    )
    @PostMapping("/setup")
    public ResponseEntity<String> createPin(
            @Valid @RequestBody CreatePinRequest request) {

        transactionPinService.createPin(request);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body("Transaction PIN created successfully");
    }

    @Operation(
        summary = "Check transaction PIN status",
        description = "Checks whether the authenticated user has configured a transaction PIN."
    )
    @GetMapping("/status")
    public ResponseEntity<PinStatusResponse> getPinStatus() {

        return ResponseEntity.ok(
                transactionPinService.getPinStatus()
        );
    }

    @PutMapping("/change")
public ResponseEntity<String> changePin(
        @Valid @RequestBody ChangePinRequest request) {

    transactionPinService.changePin(request);

    return ResponseEntity.ok("Transaction PIN changed successfully");
}

    @Operation(
        summary = "Reset a forgotten transaction PIN",
        description = "Sets a new transaction PIN after verifying the account login password. Clears any PIN lock."
    )
    @PutMapping("/reset")
    public ResponseEntity<String> resetPin(
            @Valid @RequestBody ResetPinRequest request) {

        transactionPinService.resetPin(request);

        return ResponseEntity.ok("Transaction PIN reset successfully");
    }

}