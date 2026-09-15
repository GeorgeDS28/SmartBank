/*
GoalHelperServiceImpl*/


package com.smartbank.goal.service.impl;

import com.smartbank.exception.GoalNotFoundException;
import com.smartbank.goal.entity.Goal;
import com.smartbank.goal.repository.GoalRepository;
import com.smartbank.goal.service.GoalHelperService;
import com.smartbank.user.entity.User;
import com.smartbank.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;


import com.smartbank.goal.dto.ContributeGoalRequest;
import java.math.BigDecimal;
import com.smartbank.goal.dto.GoalResponse;


@Service
@RequiredArgsConstructor
public class GoalHelperServiceImpl implements GoalHelperService {

    private final GoalRepository goalRepository;
    private final UserRepository userRepository;

    @Override
    public Goal getUserGoal(Long goalId) {

        String email = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new RuntimeException("Authenticated user not found"));

        return goalRepository.findByUserAndId(user, goalId)
                .orElseThrow(() ->
                        new GoalNotFoundException("Goal not found"));
    }

   






}