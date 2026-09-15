/*AnalyticsService.java
 */

package com.smartbank.analytics.service;
import java.util.List;
import com.smartbank.analytics.dto.TransferAnalyticsResponse;

import com.smartbank.analytics.dto.DashboardResponse;

import com.smartbank.analytics.dto.GoalAnalyticsResponse;

import com.smartbank.analytics.dto.MonthlyTransactionResponse;

import com.smartbank.analytics.dto.FinancialSummaryResponse;

public interface AnalyticsService {

    DashboardResponse getDashboard();

    GoalAnalyticsResponse getGoalAnalytics();
    
    List<MonthlyTransactionResponse> getMonthlyAnalytics();

    TransferAnalyticsResponse getTransferAnalytics();

   FinancialSummaryResponse getFinancialSummary();
}