/* AdminServiceImpl.java*/


package com.smartbank.admin.service.impl;

import java.math.BigDecimal;
import java.util.List;

import org.springframework.stereotype.Service;

import com.smartbank.account.entity.Account;
import com.smartbank.account.entity.AccountStatus;
import com.smartbank.account.repository.AccountRepository;

import com.smartbank.admin.dto.AdminAccountResponse;
import com.smartbank.admin.dto.AdminAccountStatisticsResponse;
import com.smartbank.admin.dto.AdminTransactionResponse;
import com.smartbank.admin.dto.AdminUserResponse;
import com.smartbank.admin.dto.AdminUserStatisticsResponse;
import com.smartbank.admin.service.AdminService;

import com.smartbank.transaction.entity.Transaction;
import com.smartbank.transaction.repository.TransactionRepository;

import com.smartbank.user.entity.User;
import com.smartbank.user.enums.Role;
import com.smartbank.user.repository.UserRepository;

import lombok.RequiredArgsConstructor;



@Service
@RequiredArgsConstructor
public class AdminServiceImpl implements AdminService {

    private final UserRepository userRepository;
    private final AccountRepository accountRepository;
    private final TransactionRepository transactionRepository;

    @Override
    public List<AdminUserResponse> getAllUsers() {

        return userRepository.findAll()
                .stream()
                .map(this::mapToUserResponse)
                .toList();
    }

    @Override
    public List<AdminAccountResponse> getAllAccounts() {

        return accountRepository.findAll()
                .stream()
                .map(this::mapToAccountResponse)
                .toList();
    }

    @Override
    public List<AdminTransactionResponse> getAllTransactions() {

        return transactionRepository.findAll()
                .stream()
                .map(this::mapToTransactionResponse)
                .toList();
    }

    private AdminUserResponse mapToUserResponse(User user) {

        return AdminUserResponse.builder()
                .id(user.getId())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .role(user.getRole())
                .build();
    }

    private AdminAccountResponse mapToAccountResponse(Account account) {

        User user = account.getUser();

        return AdminAccountResponse.builder()
                .id(account.getId())
                .accountNumber(account.getAccountNumber())
                .accountType(account.getAccountType())
                .balance(account.getBalance())
                .status(account.getStatus())
                .userId(user.getId())
                .userName(user.getFirstName() + " " + user.getLastName())
                .createdAt(account.getCreatedAt())
                .build();
    }

    private AdminTransactionResponse mapToTransactionResponse(Transaction transaction) {

        Account account = transaction.getAccount();

        return AdminTransactionResponse.builder()
                .id(transaction.getId())
                .transactionReference(transaction.getTransactionReference())
                .transactionType(transaction.getTransactionType())
                .amount(transaction.getAmount())
                .description(transaction.getDescription())
                .accountId(account.getId())
                .accountNumber(account.getAccountNumber())
                .createdAt(transaction.getCreatedAt())
                .build();
    }

   @Override
   public AdminUserStatisticsResponse getUserStatistics() {

    long totalUsers = userRepository.count();

    long totalAdmins = userRepository.countByRole(Role.ROLE_ADMIN);

    long totalNormalUsers = userRepository.countByRole(Role.ROLE_USER);

    return new AdminUserStatisticsResponse(
            totalUsers,
            totalAdmins,
            totalNormalUsers
    );
   }
   //@Override try removing the @Override annotation and see if it compiles. If it does, then the method signature in the interface might not match exactly with this implementation.
   public AdminAccountStatisticsResponse getAccountStatistics() {

    long totalAccounts = accountRepository.count();

    long activeAccounts = accountRepository.countByStatus(AccountStatus.ACTIVE);

    long inactiveAccounts = totalAccounts - activeAccounts;

    BigDecimal totalBalance = accountRepository.getTotalBalance();

    return new AdminAccountStatisticsResponse(
            totalAccounts,
            activeAccounts,
            inactiveAccounts,
            totalBalance
    );

   }


  






}




















