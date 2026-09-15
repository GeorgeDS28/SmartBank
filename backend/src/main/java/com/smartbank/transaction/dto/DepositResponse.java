//DepositResponse.java
package com.smartbank.transaction.dto;

import lombok.*;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DepositResponse {

    private String accountNumber;

    private BigDecimal depositedAmount;

    private BigDecimal currentBalance;

    private String message;
}