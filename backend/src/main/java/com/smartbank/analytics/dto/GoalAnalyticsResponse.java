package com.smartbank.analytics.dto;

import java.math.BigDecimal;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GoalAnalyticsResponse {

    private long totalGoals;

    private long activeGoals;

    private long completedGoals;

    private BigDecimal totalTargetAmount;

    private BigDecimal totalSavedAmount;

    private BigDecimal overallProgress;
}