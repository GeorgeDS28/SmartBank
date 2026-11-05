/*TransactionPinServiceImpl.java
 */

package com.smartbank.transactionpin.service.impl;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.smartbank.transactionpin.dto.CreatePinRequest;
import com.smartbank.transactionpin.dto.PinStatusResponse;
import com.smartbank.transactionpin.dto.ChangePinRequest;
import com.smartbank.transactionpin.dto.ResetPinRequest;

import com.smartbank.transactionpin.entity.TransactionPin;
import com.smartbank.transactionpin.repository.TransactionPinRepository;
import com.smartbank.transactionpin.service.TransactionPinService;
import com.smartbank.user.entity.User;
import com.smartbank.user.repository.UserRepository;




import java.time.LocalDateTime;

import com.smartbank.exception.InvalidCredentialsException;
import com.smartbank.exception.InvalidTransactionPinException;
import com.smartbank.exception.TransactionPinLockedException;
import com.smartbank.exception.TransactionPinNotConfiguredException;

import com.smartbank.transactionpin.service.TransactionPinAttemptService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class TransactionPinServiceImpl implements TransactionPinService
{

    private final TransactionPinRepository transactionPinRepository;

    private final UserRepository userRepository;

    private final PasswordEncoder passwordEncoder;
   
    private final TransactionPinAttemptService transactionPinAttemptService;

    @Override
    @Transactional
    public void createPin(CreatePinRequest request)
    {

        // 1. Get authenticated user
        User user = getAuthenticatedUser();

        // 2. Check whether PIN already exists
        if (transactionPinRepository.existsByUserId(user.getId())) {

            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Transaction PIN is already configured"
            );
        }

        // 3. Check whether both PIN entries match
        if (!request.getPin().equals(request.getConfirmPin())) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "PIN and Confirm PIN do not match"
            );
        }

        // 4. Hash PIN using BCrypt
        String hashedPin = passwordEncoder.encode(request.getPin());

        // 5. Create TransactionPin entity
        TransactionPin transactionPin = TransactionPin.builder()
                .user(user)
                .pinHash(hashedPin)
                .failedAttempts(0)
                .build();

        // 6. Save to database
        transactionPinRepository.save(transactionPin);
    }

    @Override
    @Transactional(readOnly = true)
    public PinStatusResponse getPinStatus() 
    {

        User user = getAuthenticatedUser();

        boolean configured =
                transactionPinRepository.existsByUserId(user.getId());

        if (configured) {

            return new PinStatusResponse(
                    true,
                    "Transaction PIN already configured"
            );
        }

        return new PinStatusResponse(
                false,
                "Transaction PIN not configured"
        );
    }

    @Override
   @Transactional
   public void verifyPin(String enteredPin) 
   {

    User user = getAuthenticatedUser();

    TransactionPin transactionPin =
            transactionPinRepository.findByUserId(user.getId())
                    .orElseThrow(() ->
                            new TransactionPinNotConfiguredException(
                                    "Create your transaction PIN before making transactions"
                            ));

    // Check whether PIN is temporarily locked
    if (transactionPin.getLockedUntil() != null) {

        if (transactionPin.getLockedUntil().isAfter(LocalDateTime.now())) {

            throw new TransactionPinLockedException(
                    "Too many incorrect PIN attempts. Try again later."
            );
        }

        // Previous lock has expired
        transactionPinAttemptService.resetFailedAttempts(user.getId());
    }

    // Verify entered PIN against BCrypt hash
    boolean matches = passwordEncoder.matches(
            enteredPin,
            transactionPin.getPinHash()
    );

    if (!matches) {

        transactionPinAttemptService.recordFailedAttempt(user.getId());

        throw new InvalidTransactionPinException(
                "Incorrect transaction PIN"
        );
    }

    // Reset failed attempts after successful verification
    transactionPinAttemptService.resetFailedAttempts(user.getId());
  }


  @Override
@Transactional
public void changePin(ChangePinRequest request) {

    User user = getAuthenticatedUser();

    // Check whether the user has already configured a PIN
    TransactionPin transactionPin = transactionPinRepository
            .findByUserId(user.getId())
            .orElseThrow(() ->
                    new TransactionPinNotConfiguredException(
                            "Create your transaction PIN before changing it"));

    // Verify the current PIN
    verifyPin(request.getCurrentPin());

    // Check whether the new PIN and confirmation match
    if (!request.getNewPin().equals(request.getConfirmNewPin())) {
        throw new IllegalArgumentException("New PIN and confirmation do not match");
    }

    // Prevent setting the same PIN again
    if (passwordEncoder.matches(
            request.getNewPin(),
            transactionPin.getPinHash())) {
        throw new IllegalArgumentException(
                "New PIN must be different from the current PIN");
    }

    // Hash and save the new PIN
    transactionPin.setPinHash(
            passwordEncoder.encode(request.getNewPin()));

    transactionPin.setFailedAttempts(0);
    transactionPin.setLockedUntil(null);

    transactionPinRepository.save(transactionPin);
}

  @Override
  @Transactional
  public void resetPin(ResetPinRequest request) {

      User user = getAuthenticatedUser();

      // The login password is the proof of identity for a forgotten PIN, so it
      // is checked against the same BCrypt hash that login uses.
      if (!passwordEncoder.matches(
              request.getPassword(),
              user.getPassword())) {
          throw new InvalidCredentialsException(
                  "Account password does not match");
      }

      if (!request.getNewPin().equals(request.getConfirmNewPin())) {
          throw new IllegalArgumentException(
                  "New PIN and confirmation do not match");
      }

      TransactionPin transactionPin = transactionPinRepository
              .findByUserId(user.getId())
              .orElseGet(() -> TransactionPin.builder()
                      .user(user)
                      .failedAttempts(0)
                      .build());

      transactionPin.setPinHash(
              passwordEncoder.encode(request.getNewPin()));

      // A reset must also lift any lock left by failed attempts.
      transactionPin.setFailedAttempts(0);
      transactionPin.setLockedUntil(null);

      transactionPinRepository.save(transactionPin);
  }

    private User getAuthenticatedUser()
    {

        String email = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();

        return userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new ResponseStatusException(
                                HttpStatus.NOT_FOUND,
                                "Authenticated user not found"
                        )
                );
    }
}