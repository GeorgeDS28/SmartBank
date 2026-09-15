//WithdrawResponse.java
package com.smartbank.transaction.dto;

import java.math.BigDecimal;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class WithdrawResponse {

    private String message;
    private String accountNumber;
    private BigDecimal withdrawnAmount;
    private BigDecimal updatedBalance;

}