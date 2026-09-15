/*AnalyticsController.java */


package com.smartbank.analytics.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.smartbank.analytics.dto.DashboardResponse;
import com.smartbank.analytics.dto.FinancialSummaryResponse;
import com.smartbank.analytics.dto.GoalAnalyticsResponse;
import com.smartbank.analytics.dto.MonthlyTransactionResponse;
import com.smartbank.analytics.dto.TransferAnalyticsResponse;
import com.smartbank.analytics.service.AnalyticsService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/analytics")
@RequiredArgsConstructor
@Tag(
        name = "Analytics",
        description = "Financial analytics, dashboard and transaction insights APIs"
)
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    @Operation(
            summary = "Get financial dashboard",
            description = "Retrieves an overview of the authenticated user's financial information."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Dashboard data retrieved successfully"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Access denied"
            )
    })
    @GetMapping("/dashboard")
    public ResponseEntity<DashboardResponse> getDashboard() {

        DashboardResponse response =
                analyticsService.getDashboard();

        return ResponseEntity.ok(response);
    }

    @Operation(
            summary = "Get monthly transaction analytics",
            description = "Retrieves monthly transaction statistics for the authenticated user."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Monthly analytics retrieved successfully"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Access denied"
            )
    })
    @GetMapping("/monthly")
    public ResponseEntity<List<MonthlyTransactionResponse>> getMonthlyAnalytics() {

        List<MonthlyTransactionResponse> response =
                analyticsService.getMonthlyAnalytics();

        return ResponseEntity.ok(response);
    }

    @Operation(
            summary = "Get goal analytics",
            description = "Retrieves savings goal statistics and progress for the authenticated user."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Goal analytics retrieved successfully"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Access denied"
            )
    })
    @GetMapping("/goals")
    public ResponseEntity<GoalAnalyticsResponse> getGoalAnalytics() {

        GoalAnalyticsResponse response =
                analyticsService.getGoalAnalytics();

        return ResponseEntity.ok(response);
    }

    @Operation(
            summary = "Get transfer analytics",
            description = "Retrieves statistics about money transferred between accounts."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Transfer analytics retrieved successfully"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Access denied"
            )
    })
    @GetMapping("/transfers")
    public ResponseEntity<TransferAnalyticsResponse> getTransferAnalytics() {

        TransferAnalyticsResponse response =
                analyticsService.getTransferAnalytics();

        return ResponseEntity.ok(response);
    }

    @Operation(
            summary = "Get financial summary",
            description = "Retrieves a comprehensive financial summary including balances, deposits, withdrawals, transfers and goal savings."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Financial summary retrieved successfully"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Access denied"
            )
    })
    @GetMapping("/financial-summary")
    public ResponseEntity<FinancialSummaryResponse> getFinancialSummary() {

        FinancialSummaryResponse response =
                analyticsService.getFinancialSummary();

        return ResponseEntity.ok(response);
    }
}

