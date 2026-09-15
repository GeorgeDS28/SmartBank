/* GoalServiceImpl */

package com.smartbank.goal.service.impl;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.smartbank.goal.dto.CreateGoalRequest;
import com.smartbank.goal.dto.GoalResponse;
import com.smartbank.goal.dto.UpdateGoalRequest;
import com.smartbank.goal.entity.Goal;
import com.smartbank.goal.entity.GoalStatus;
import com.smartbank.goal.repository.GoalRepository;
import com.smartbank.goal.service.GoalHelperService;
import com.smartbank.goal.service.GoalService;
import com.smartbank.user.entity.User;
import com.smartbank.user.repository.UserRepository;

import lombok.RequiredArgsConstructor;


import com.smartbank.goal.dto.ContributeGoalRequest;

@Service
@RequiredArgsConstructor
public class GoalServiceImpl implements GoalService {

    private final GoalRepository goalRepository;
    private final UserRepository userRepository;
    private final GoalHelperService goalHelperService;

    @Override
public GoalResponse createGoal(CreateGoalRequest request) {

    String email = SecurityContextHolder.getContext()
            .getAuthentication()
            .getName();

    User user = userRepository.findByEmail(email)
            .orElseThrow(() ->
                    new RuntimeException("Authenticated user not found"));

    Goal goal = Goal.builder()
            .goalName(request.getGoalName())
            .targetAmount(request.getTargetAmount())
            .currentAmount(BigDecimal.ZERO)
            .targetDate(request.getTargetDate())
            .status(GoalStatus.IN_PROGRESS)
            .user(user)
            .build();

    Goal savedGoal = goalRepository.save(goal);

    return mapToResponse(savedGoal);
}

       private GoalResponse mapToResponse(Goal goal) {

    Integer progress = calculateProgress(
            goal.getCurrentAmount(),
            goal.getTargetAmount()
    );

    return new GoalResponse(
            goal.getId(),
            goal.getGoalName(),
            goal.getTargetAmount(),
            goal.getCurrentAmount(),
            progress,
            goal.getStatus(),
            goal.getTargetDate(),
            goal.getCreatedAt()
    );
}



private Integer calculateProgress(BigDecimal current, BigDecimal target) {

    if (target.compareTo(BigDecimal.ZERO) == 0) {
        return 0;
    }

    return current.multiply(BigDecimal.valueOf(100))
            .divide(target, 0, RoundingMode.DOWN)
            .intValue();
}


@Override
public List<GoalResponse> getMyGoals() {

    String email = SecurityContextHolder.getContext()
            .getAuthentication()
            .getName();

    User user = userRepository.findByEmail(email)
            .orElseThrow(() ->
                    new RuntimeException("Authenticated user not found"));

    return goalRepository.findByUserOrderByCreatedAtDesc(user)
            .stream()
            .map(this::mapToResponse)
            .toList();
}


@Override
public GoalResponse getGoalById(Long id) {

    Goal goal = goalHelperService.getUserGoal(id);

    return mapToResponse(goal);
}



@Override
public GoalResponse updateGoal(Long id, UpdateGoalRequest request) {

    Goal goal = goalHelperService.getUserGoal(id);

    goal.setGoalName(request.getGoalName());
    goal.setTargetAmount(request.getTargetAmount());
    goal.setTargetDate(request.getTargetDate());

    if (goal.getCurrentAmount().compareTo(goal.getTargetAmount()) >= 0) {
        goal.setStatus(GoalStatus.COMPLETED);
    } else {
        goal.setStatus(GoalStatus.IN_PROGRESS);
    }

    Goal updatedGoal = goalRepository.save(goal);

    return mapToResponse(updatedGoal);
}



@Override
public void deleteGoal(Long id) {

    Goal goal = goalHelperService.getUserGoal(id);

    goalRepository.delete(goal);
}



@Override
public GoalResponse contributeToGoal(Long goalId, ContributeGoalRequest request) {

    Goal goal = goalHelperService.getUserGoal(goalId);

    if (goal.getStatus() == GoalStatus.COMPLETED) {
        throw new RuntimeException("Goal is already completed.");
    }

    if (request.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
        throw new RuntimeException("Contribution amount must be greater than zero.");
    }

    BigDecimal updatedAmount = goal.getCurrentAmount().add(request.getAmount());

    // Don't allow current amount to exceed target amount
    if (updatedAmount.compareTo(goal.getTargetAmount()) >= 0) {
        updatedAmount = goal.getTargetAmount();
        goal.setStatus(GoalStatus.COMPLETED);
    }

    goal.setCurrentAmount(updatedAmount);

    Goal updatedGoal = goalRepository.save(goal);

    return mapToResponse(updatedGoal);
}






}