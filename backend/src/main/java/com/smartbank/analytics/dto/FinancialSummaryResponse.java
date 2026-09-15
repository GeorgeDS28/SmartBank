package com.smartbank.analytics.dto;

import java.math.BigDecimal;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@AllArgsConstructor
public class FinancialSummaryResponse {

    private BigDecimal totalBalance;

    private BigDecimal totalDeposits;

    private BigDecimal totalWithdrawals;

    private BigDecimal totalTransferredIn;

    private BigDecimal totalTransferredOut;

    private BigDecimal netCashFlow;

    private BigDecimal totalGoalSavings;
}