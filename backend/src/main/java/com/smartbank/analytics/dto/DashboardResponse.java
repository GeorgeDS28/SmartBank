
/* DashboardResponse.java */
package com.smartbank.analytics.dto;

import java.math.BigDecimal;
import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@AllArgsConstructor
public class DashboardResponse {

    private BigDecimal totalBalance;
    private int numberOfAccounts;
    private long totalTransactions;
    private List<RecentTransactionResponse> recentTransactions;
}