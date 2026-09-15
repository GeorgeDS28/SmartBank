/*
TransactionServiceImpl.java
*/

package com.smartbank.transaction.service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.smartbank.account.entity.Account;
import com.smartbank.account.repository.AccountRepository;
import com.smartbank.account.service.AccountHelperService;
import com.smartbank.transaction.dto.TransactionResponse;
import com.smartbank.transaction.entity.Transaction;
import com.smartbank.transaction.enums.TransactionType;
import com.smartbank.transaction.repository.TransactionRepository;
import com.smartbank.user.entity.User;
import com.smartbank.user.repository.UserRepository;

import lombok.RequiredArgsConstructor;
@Service
@RequiredArgsConstructor
public class TransactionServiceImpl implements TransactionService {

    private final TransactionRepository transactionRepository;
    private final AccountRepository accountRepository;
    private final UserRepository userRepository;
    private final AccountHelperService accountHelperService;



    @Override
    public Transaction recordTransaction(
            Account account,
            TransactionType transactionType,
            BigDecimal amount,
            String description) {

        Transaction transaction = Transaction.builder()
                .transactionReference(generateTransactionReference())
                .transactionType(transactionType)
                .amount(amount)
                .description(description)
                .account(account)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        return transactionRepository.save(transaction);
    }

    @Override
    public List<TransactionResponse> getTransactions(String accountNumber) {
     

        Account account = accountHelperService.getUserAccount(accountNumber);


        List<Transaction> transactions =
                transactionRepository.findByAccountOrderByCreatedAtDesc(account);

        return transactions.stream()
                .map(transaction -> TransactionResponse.builder()
                        .transactionReference(transaction.getTransactionReference())
                        .transactionType(transaction.getTransactionType())
                        .amount(transaction.getAmount())
                        .description(transaction.getDescription())
                        .createdAt(transaction.getCreatedAt())
                        .build())
                .toList();
    }

    private User getAuthenticatedUser() {

        String email = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();

        return userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new RuntimeException("Authenticated user not found"));
    }

    private String generateTransactionReference() {

        return "TXN-" + UUID.randomUUID()
                .toString()
                .replace("-", "")
                .substring(0, 12)
                .toUpperCase();
    }
}