/* GoalService.java */


package com.smartbank.goal.service;

import java.util.List;

import com.smartbank.goal.dto.CreateGoalRequest;
import com.smartbank.goal.dto.GoalResponse;
import com.smartbank.goal.dto.UpdateGoalRequest;


import com.smartbank.goal.dto.ContributeGoalRequest;


public interface GoalService {

    GoalResponse createGoal(CreateGoalRequest request);

    List<GoalResponse> getMyGoals();

    GoalResponse getGoalById(Long id);

    GoalResponse updateGoal(Long id, UpdateGoalRequest request);
    

    void deleteGoal(Long id);


    //added this 
    GoalResponse contributeToGoal(Long goalId,
                              ContributeGoalRequest request);





}