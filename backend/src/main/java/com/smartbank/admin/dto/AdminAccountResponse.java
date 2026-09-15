package com.smartbank.admin.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.smartbank.account.entity.AccountStatus;
import com.smartbank.account.entity.AccountType;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@AllArgsConstructor
public class AdminAccountResponse {

    private Long id;
    private String accountNumber;
    private AccountType accountType;
    private BigDecimal balance;
    private AccountStatus status;

    private Long userId;
    private String userName;

    private LocalDateTime createdAt;
}