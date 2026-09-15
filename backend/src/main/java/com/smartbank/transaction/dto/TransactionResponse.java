/*TransactionResponse.java */ 
package com.smartbank.transaction.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.smartbank.transaction.enums.TransactionType;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder


@NoArgsConstructor
@AllArgsConstructor
public class TransactionResponse {

    private String transactionReference;

    private TransactionType transactionType;

    private BigDecimal amount;

    private String description;

    private LocalDateTime createdAt;
}