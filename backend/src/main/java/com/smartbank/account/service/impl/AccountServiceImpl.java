/*

AccountServiceImpl.java
*/

package com.smartbank.account.service.impl;

import java.math.BigDecimal;
import java.security.SecureRandom;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.smartbank.account.dto.AccountResponse;
import com.smartbank.account.dto.CreateAccountRequest;
import com.smartbank.account.entity.Account;
import com.smartbank.account.entity.AccountStatus;
import com.smartbank.account.repository.AccountRepository;
import com.smartbank.account.service.AccountHelperService;
import com.smartbank.account.service.AccountService;
import com.smartbank.exception.InactiveAccountException;
import com.smartbank.exception.InsufficientBalanceException;
import com.smartbank.transaction.dto.DepositRequest;
import com.smartbank.transaction.dto.DepositResponse;
import com.smartbank.transaction.dto.WithdrawRequest;
import com.smartbank.transaction.dto.WithdrawResponse;
import com.smartbank.transaction.enums.TransactionType;
import com.smartbank.transaction.service.TransactionService;
import com.smartbank.user.entity.User;
import com.smartbank.user.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AccountServiceImpl implements AccountService {

    private static final Logger log =
            LoggerFactory.getLogger(AccountServiceImpl.class);

    private final AccountRepository accountRepository;
    private final UserRepository userRepository;
    private final TransactionService transactionService;
    private final AccountHelperService accountHelperService;

    private final SecureRandom secureRandom = new SecureRandom();

    @Override
    public AccountResponse createAccount(CreateAccountRequest request) {

        User user = getAuthenticatedUser();

        Account account = Account.builder()
                .accountNumber(generateAccountNumber())
                .accountType(request.getAccountType())
                .balance(BigDecimal.ZERO)
                .status(AccountStatus.ACTIVE)
                .user(user)
                .build();

        // Save the account to the database
        Account savedAccount = accountRepository.save(account);

        log.info("Account created successfully");

        // Convert Entity -> DTO
        return AccountResponse.builder()
                .accountNumber(savedAccount.getAccountNumber())
                .accountType(savedAccount.getAccountType())
                .balance(savedAccount.getBalance())
                .status(savedAccount.getStatus())
                .build();
    }

    @Override
    public List<AccountResponse> getMyAccounts() {

        User user = getAuthenticatedUser();

        List<Account> accounts = accountRepository.findByUser(user);

        return accounts.stream()
                .map(account -> AccountResponse.builder()
                        .accountNumber(account.getAccountNumber())
                        .accountType(account.getAccountType())
                        .balance(account.getBalance())
                        .status(account.getStatus())
                        .build())
                .toList();
    }

    @Override
    public DepositResponse deposit(
            String accountNumber,
            DepositRequest request) {

        Account account = accountHelperService.getUserAccount(accountNumber);

        if (account.getStatus() != AccountStatus.ACTIVE) {
            throw new InactiveAccountException("Account is not active");
        }

        account.setBalance(
                account.getBalance().add(request.getAmount())
        );

        Account updatedAccount = accountRepository.save(account);

        transactionService.recordTransaction(
                updatedAccount,
                TransactionType.DEPOSIT,
                request.getAmount(),
                "Cash Deposit"
        );

        log.info("Money deposited successfully");

        return DepositResponse.builder()
                .accountNumber(updatedAccount.getAccountNumber())
                .depositedAmount(request.getAmount())
                .currentBalance(updatedAccount.getBalance())
                .message("Deposit successful")
                .build();
    }

    @Override
    public WithdrawResponse withdraw(
            String accountNumber,
            WithdrawRequest request) {

        Account account = accountHelperService.getUserAccount(accountNumber);

        // Verify account is ACTIVE
        if (account.getStatus() != AccountStatus.ACTIVE) {
            throw new InactiveAccountException("Account is not active");
        }

        BigDecimal amount = request.getAmount();

        // Validate sufficient balance
        if (account.getBalance().compareTo(amount) < 0) {
            log.warn("Insufficient balance");
            throw new InsufficientBalanceException("Insufficient balance");
        }

        // Deduct balance
        account.setBalance(
                account.getBalance().subtract(amount)
        );

        // Save account
        accountRepository.save(account);

        // Record transaction
        transactionService.recordTransaction(
                account,
                TransactionType.WITHDRAW,
                amount,
                "Cash Withdrawal"
        );

        log.info("Money withdrawn successfully");

        // Return response
        return new WithdrawResponse(
                "Withdrawal successful",
                account.getAccountNumber(),
                amount,
                account.getBalance()
        );
    }

    @Override
    public AccountResponse getAccountByNumber(String accountNumber) {

        Account account = accountHelperService.getUserAccount(accountNumber);

        return AccountResponse.builder()
                .accountNumber(account.getAccountNumber())
                .accountType(account.getAccountType())
                .balance(account.getBalance())
                .status(account.getStatus())
                .build();
    }

    private User getAuthenticatedUser() {

        String email = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();

        return userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new RuntimeException("Authenticated user not found"));
    }

    private String generateAccountNumber() {

        String accountNumber;

        do {
            accountNumber = "SB"
                    + (10000000 + secureRandom.nextInt(90000000));
        } while (accountRepository.existsByAccountNumber(accountNumber));

        return accountNumber;
    }
}