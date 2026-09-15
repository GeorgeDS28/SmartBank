/*AdminTransactionResponse.java */

package com.smartbank.admin.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.smartbank.transaction.enums.TransactionType;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@AllArgsConstructor
public class AdminTransactionResponse {

    private Long id;
    private String transactionReference;
    private TransactionType transactionType;
    private BigDecimal amount;
    private String description;

    private Long accountId;
    private String accountNumber;

    private LocalDateTime createdAt;
}