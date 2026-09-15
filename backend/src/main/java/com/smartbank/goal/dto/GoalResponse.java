/* GoalResponse.java */

package com.smartbank.goal.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import com.smartbank.goal.entity.GoalStatus;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class GoalResponse {

    private Long id;
    private String goalName;
    private BigDecimal targetAmount;
    private BigDecimal currentAmount;
    private Integer progressPercentage;
    private GoalStatus status;
    private LocalDate targetDate;
    private LocalDateTime createdAt;
}