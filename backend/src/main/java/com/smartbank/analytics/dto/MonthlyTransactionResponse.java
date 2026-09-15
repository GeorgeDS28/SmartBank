/* MonthlyTransactionResponse.java */

package com.smartbank.analytics.dto;

import java.math.BigDecimal;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class MonthlyTransactionResponse {

    private String month;

    private BigDecimal deposits;

    private BigDecimal withdrawals;

    private BigDecimal transfersIn;

    private BigDecimal transfersOut;
}