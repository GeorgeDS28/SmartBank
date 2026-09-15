//AdminAccountStatisticsResponse.java

package com.smartbank.admin.dto;
import java.math.BigDecimal;

public class AdminAccountStatisticsResponse {

 private long totalAccounts;
    private long activeAccounts;
    private long inactiveAccounts;
    private BigDecimal totalBalance;

    public AdminAccountStatisticsResponse() {
    }

    public AdminAccountStatisticsResponse(long totalAccounts,
                                          long activeAccounts,
                                          long inactiveAccounts,
                                          BigDecimal totalBalance) {
        this.totalAccounts = totalAccounts;
        this.activeAccounts = activeAccounts;
        this.inactiveAccounts = inactiveAccounts;
        this.totalBalance = totalBalance;
    }

    public long getTotalAccounts() {
        return totalAccounts;
    }

    public void setTotalAccounts(long totalAccounts) {
        this.totalAccounts = totalAccounts;
    }

    public long getActiveAccounts() {
        return activeAccounts;
    }

    public void setActiveAccounts(long activeAccounts) {
        this.activeAccounts = activeAccounts;
    }

    public long getInactiveAccounts() {
        return inactiveAccounts;
    }

    public void setInactiveAccounts(long inactiveAccounts) {
        this.inactiveAccounts = inactiveAccounts;
    }

    public BigDecimal getTotalBalance() {
        return totalBalance;
    }

    public void setTotalBalance(BigDecimal totalBalance) {
        this.totalBalance = totalBalance;
    }

















}