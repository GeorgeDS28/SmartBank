//GoalControllerTest.java

package com.smartbank.goal.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartbank.auth.jwt.JwtService;
import com.smartbank.goal.dto.ContributeGoalRequest;
import com.smartbank.goal.dto.CreateGoalRequest;
import com.smartbank.goal.dto.GoalResponse;
import com.smartbank.goal.dto.UpdateGoalRequest;
import com.smartbank.goal.entity.GoalStatus;
import com.smartbank.goal.service.GoalService;
import com.smartbank.security.JwtAuthenticationFilter;

@WebMvcTest(GoalController.class)
@AutoConfigureMockMvc(addFilters = false)
class GoalControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private GoalService goalService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    // =========================================================
    // CREATE GOAL
    // =========================================================

    @Test
    void createGoal_success() throws Exception {

        CreateGoalRequest request = new CreateGoalRequest();
        request.setGoalName("Emergency Fund");
        request.setTargetAmount(new BigDecimal("50000.00"));
        request.setTargetDate(LocalDate.now().plusDays(30));

        GoalResponse response = new GoalResponse(
                1L,
                "Emergency Fund",
                new BigDecimal("50000.00"),
                new BigDecimal("10000.00"),
                20,
                GoalStatus.IN_PROGRESS,
                request.getTargetDate(),
                LocalDateTime.now()
        );

        when(goalService.createGoal(any(CreateGoalRequest.class)))
                .thenReturn(response);

        mockMvc.perform(
                post("/api/goals")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.id").value(1))
        .andExpect(jsonPath("$.goalName")
                .value("Emergency Fund"))
        .andExpect(jsonPath("$.targetAmount")
                .value(50000.00))
        .andExpect(jsonPath("$.currentAmount")
                .value(10000.00))
        .andExpect(jsonPath("$.progressPercentage")
                .value(20))
        .andExpect(jsonPath("$.status")
                .value("IN_PROGRESS"));

        verify(goalService)
                .createGoal(any(CreateGoalRequest.class));
    }

    @Test
    void createGoal_invalidRequest_returnsBadRequest()
            throws Exception {

        CreateGoalRequest request = new CreateGoalRequest();

        mockMvc.perform(
                post("/api/goals")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isBadRequest());

        verify(goalService, times(0))
                .createGoal(any(CreateGoalRequest.class));
    }

    // =========================================================
    // GET MY GOALS
    // =========================================================

    @Test
    void getMyGoals_success() throws Exception {

        GoalResponse response = new GoalResponse(
                1L,
                "Emergency Fund",
                new BigDecimal("50000.00"),
                new BigDecimal("10000.00"),
                20,
                GoalStatus.IN_PROGRESS,
                LocalDate.now().plusDays(30),
                LocalDateTime.now()
        );

        when(goalService.getMyGoals())
                .thenReturn(List.of(response));

        mockMvc.perform(
                get("/api/goals")
        )
        .andExpect(status().isOk())
        .andExpect(jsonPath("$[0].id").value(1))
        .andExpect(jsonPath("$[0].goalName")
                .value("Emergency Fund"))
        .andExpect(jsonPath("$[0].targetAmount")
                .value(50000.00))
        .andExpect(jsonPath("$[0].currentAmount")
                .value(10000.00))
        .andExpect(jsonPath("$[0].progressPercentage")
                .value(20))
        .andExpect(jsonPath("$[0].status")
                .value("IN_PROGRESS"));

        verify(goalService)
                .getMyGoals();
    }

    // =========================================================
    // GET GOAL BY ID
    // =========================================================

    @Test
    void getGoalById_success() throws Exception {

        GoalResponse response = new GoalResponse(
                1L,
                "Emergency Fund",
                new BigDecimal("50000.00"),
                new BigDecimal("10000.00"),
                20,
                GoalStatus.IN_PROGRESS,
                LocalDate.now().plusDays(30),
                LocalDateTime.now()
        );

        when(goalService.getGoalById(1L))
                .thenReturn(response);

        mockMvc.perform(
                get("/api/goals/{id}", 1L)
        )
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.id").value(1))
        .andExpect(jsonPath("$.goalName")
                .value("Emergency Fund"))
        .andExpect(jsonPath("$.progressPercentage")
                .value(20));

        verify(goalService)
                .getGoalById(1L);
    }

    // =========================================================
    // UPDATE GOAL
    // =========================================================

    @Test
    void updateGoal_success() throws Exception {

        UpdateGoalRequest request = new UpdateGoalRequest();
        request.setGoalName("New Car Fund");
        request.setTargetAmount(new BigDecimal("100000.00"));
        request.setTargetDate(LocalDate.now().plusDays(60));

        GoalResponse response = new GoalResponse(
                1L,
                "New Car Fund",
                new BigDecimal("100000.00"),
                new BigDecimal("25000.00"),
                25,
                GoalStatus.IN_PROGRESS,
                request.getTargetDate(),
                LocalDateTime.now()
        );

        when(goalService.updateGoal(
                eq(1L),
                any(UpdateGoalRequest.class)))
                .thenReturn(response);

        mockMvc.perform(
                put("/api/goals/{id}", 1L)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.id").value(1))
        .andExpect(jsonPath("$.goalName")
                .value("New Car Fund"))
        .andExpect(jsonPath("$.targetAmount")
                .value(100000.00))
        .andExpect(jsonPath("$.progressPercentage")
                .value(25));

        verify(goalService)
                .updateGoal(eq(1L), any(UpdateGoalRequest.class));
    }

    @Test
    void updateGoal_invalidRequest_returnsBadRequest()
            throws Exception {

        UpdateGoalRequest request = new UpdateGoalRequest();

        mockMvc.perform(
                put("/api/goals/{id}", 1L)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isBadRequest());

        verify(goalService, times(0))
                .updateGoal(eq(1L), any(UpdateGoalRequest.class));
    }

    // =========================================================
    // DELETE GOAL
    // =========================================================

    @Test
    void deleteGoal_success() throws Exception {

        mockMvc.perform(
                delete("/api/goals/{id}", 1L)
        )
        .andExpect(status().isNoContent());

        verify(goalService)
                .deleteGoal(1L);
    }

    // =========================================================
    // CONTRIBUTE TO GOAL
    // =========================================================

    @Test
    void contributeToGoal_success() throws Exception {

        ContributeGoalRequest request = new ContributeGoalRequest();
        request.setAmount(new BigDecimal("5000.00"));

        GoalResponse response = new GoalResponse(
                1L,
                "Emergency Fund",
                new BigDecimal("50000.00"),
                new BigDecimal("15000.00"),
                30,
                GoalStatus.IN_PROGRESS,
                LocalDate.now().plusDays(30),
                LocalDateTime.now()
        );

        when(goalService.contributeToGoal(
                eq(1L),
                any(ContributeGoalRequest.class)))
                .thenReturn(response);

        mockMvc.perform(
                post("/api/goals/{goalId}/contribute", 1L)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.id").value(1))
        .andExpect(jsonPath("$.goalName")
                .value("Emergency Fund"))
        .andExpect(jsonPath("$.currentAmount")
                .value(15000.00))
        .andExpect(jsonPath("$.progressPercentage")
                .value(30))
        .andExpect(jsonPath("$.status")
                .value("IN_PROGRESS"));

        verify(goalService)
                .contributeToGoal(
                        eq(1L),
                        any(ContributeGoalRequest.class));
    }

    @Test
    void contributeToGoal_invalidRequest_returnsBadRequest()
            throws Exception {

        ContributeGoalRequest request = new ContributeGoalRequest();
        request.setAmount(null);

        mockMvc.perform(
                post("/api/goals/{goalId}/contribute", 1L)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isBadRequest());

        verify(goalService, times(0))
                .contributeToGoal(
                        eq(1L),
                        any(ContributeGoalRequest.class));
    }

    @Test
    void contributeToGoal_amountBelowMinimum_returnsBadRequest()
            throws Exception {

        ContributeGoalRequest request = new ContributeGoalRequest();
        request.setAmount(new BigDecimal("0.00"));

        mockMvc.perform(
                post("/api/goals/{goalId}/contribute", 1L)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isBadRequest());

        verify(goalService, times(0))
                .contributeToGoal(
                        eq(1L),
                        any(ContributeGoalRequest.class));
    }
}

