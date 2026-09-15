//AnalyticsControllerTest.java
package com.smartbank.analytics.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;

import com.smartbank.analytics.dto.DashboardResponse;
import com.smartbank.analytics.dto.FinancialSummaryResponse;
import com.smartbank.analytics.dto.GoalAnalyticsResponse;
import com.smartbank.analytics.dto.MonthlyTransactionResponse;
import com.smartbank.analytics.dto.TransferAnalyticsResponse;
import com.smartbank.analytics.service.AnalyticsService;

@ExtendWith(MockitoExtension.class)
class AnalyticsControllerTest {

    @Mock
    private AnalyticsService analyticsService;

    private AnalyticsController analyticsController;

    @BeforeEach
    void setUp() {
        analyticsController = new AnalyticsController(analyticsService);
    }

    @Test
    void getDashboard_shouldReturnDashboardResponse() {

        DashboardResponse dashboardResponse =
                Mockito.mock(DashboardResponse.class);

        when(analyticsService.getDashboard())
                .thenReturn(dashboardResponse);

        ResponseEntity<DashboardResponse> response =
                analyticsController.getDashboard();

        assertEquals(200, response.getStatusCode().value());
        assertSame(dashboardResponse, response.getBody());

        verify(analyticsService).getDashboard();
    }

    @Test
    void getMonthlyAnalytics_shouldReturnMonthlyAnalytics() {

        List<MonthlyTransactionResponse> monthlyAnalytics =
                List.of(Mockito.mock(MonthlyTransactionResponse.class));

        when(analyticsService.getMonthlyAnalytics())
                .thenReturn(monthlyAnalytics);

        ResponseEntity<List<MonthlyTransactionResponse>> response =
                analyticsController.getMonthlyAnalytics();

        assertEquals(200, response.getStatusCode().value());
        assertSame(monthlyAnalytics, response.getBody());

        verify(analyticsService).getMonthlyAnalytics();
    }

    @Test
    void getGoalAnalytics_shouldReturnGoalAnalytics() {

        GoalAnalyticsResponse goalAnalytics =
                Mockito.mock(GoalAnalyticsResponse.class);

        when(analyticsService.getGoalAnalytics())
                .thenReturn(goalAnalytics);

        ResponseEntity<GoalAnalyticsResponse> response =
                analyticsController.getGoalAnalytics();

        assertEquals(200, response.getStatusCode().value());
        assertSame(goalAnalytics, response.getBody());

        verify(analyticsService).getGoalAnalytics();
    }

    @Test
    void getTransferAnalytics_shouldReturnTransferAnalytics() {

        TransferAnalyticsResponse transferAnalytics =
                Mockito.mock(TransferAnalyticsResponse.class);

        when(analyticsService.getTransferAnalytics())
                .thenReturn(transferAnalytics);

        ResponseEntity<TransferAnalyticsResponse> response =
                analyticsController.getTransferAnalytics();

        assertEquals(200, response.getStatusCode().value());
        assertSame(transferAnalytics, response.getBody());

        verify(analyticsService).getTransferAnalytics();
    }

    @Test
    void getFinancialSummary_shouldReturnFinancialSummary() {

        FinancialSummaryResponse financialSummary =
                Mockito.mock(FinancialSummaryResponse.class);

        when(analyticsService.getFinancialSummary())
                .thenReturn(financialSummary);

        ResponseEntity<FinancialSummaryResponse> response =
                analyticsController.getFinancialSummary();

        assertEquals(200, response.getStatusCode().value());
        assertSame(financialSummary, response.getBody());

        verify(analyticsService).getFinancialSummary();
    }
}