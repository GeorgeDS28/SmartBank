//GoalServiceImplTest.java

package com.smartbank.goal.service.impl;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import com.smartbank.goal.dto.ContributeGoalRequest;
import com.smartbank.goal.dto.CreateGoalRequest;
import com.smartbank.goal.dto.GoalResponse;
import com.smartbank.goal.dto.UpdateGoalRequest;
import com.smartbank.goal.entity.Goal;
import com.smartbank.goal.entity.GoalStatus;
import com.smartbank.goal.repository.GoalRepository;
import com.smartbank.goal.service.GoalHelperService;
import com.smartbank.user.entity.User;
import com.smartbank.user.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class GoalServiceImplTest {

    @Mock
    private GoalRepository goalRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private GoalHelperService goalHelperService;

    @InjectMocks
    private GoalServiceImpl goalService;

    private User user;
    private Goal goal;

    @BeforeEach
    void setUp() {

        user = new User();
        user.setId(1L);
        user.setEmail("george@gmail.com");

        goal = Goal.builder()
                .id(1L)
                .goalName("New Laptop")
                .targetAmount(new BigDecimal("100000.00"))
                .currentAmount(new BigDecimal("20000.00"))
                .targetDate(LocalDate.now().plusMonths(6))
                .status(GoalStatus.IN_PROGRESS)
                .user(user)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(
                        "george@gmail.com",
                        null
                )
        );
    }

    // ---------------------------------------------------------
    // CREATE GOAL
    // ---------------------------------------------------------

    @Test
    void createGoal_success() {

        CreateGoalRequest request = new CreateGoalRequest();
        request.setGoalName("New Laptop");
        request.setTargetAmount(new BigDecimal("100000.00"));
        request.setTargetDate(LocalDate.now().plusMonths(6));

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.of(user));

        when(goalRepository.save(any(Goal.class)))
                .thenAnswer(invocation -> {

                    Goal savedGoal = invocation.getArgument(0);
                    savedGoal.setId(1L);
                    savedGoal.setCreatedAt(LocalDateTime.now());

                    return savedGoal;
                });

        GoalResponse response = goalService.createGoal(request);

        assertNotNull(response);
        assertEquals(1L, response.getId());
        assertEquals("New Laptop", response.getGoalName());
        assertEquals(
                0,
                response.getCurrentAmount().compareTo(BigDecimal.ZERO)
        );
        assertEquals(
                0,
                response.getTargetAmount()
                        .compareTo(new BigDecimal("100000.00"))
        );
        assertEquals(GoalStatus.IN_PROGRESS, response.getStatus());
        assertEquals(0, response.getProgressPercentage());

        verify(userRepository).findByEmail("george@gmail.com");
        verify(goalRepository).save(any(Goal.class));
    }

    @Test
    void createGoal_authenticatedUserNotFound_throwsException() {

        CreateGoalRequest request = new CreateGoalRequest();
        request.setGoalName("New Laptop");
        request.setTargetAmount(new BigDecimal("100000.00"));
        request.setTargetDate(LocalDate.now().plusMonths(6));

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.empty());

        RuntimeException exception = assertThrows(
                RuntimeException.class,
                () -> goalService.createGoal(request)
        );

        assertEquals(
                "Authenticated user not found",
                exception.getMessage()
        );

        verify(goalRepository, never()).save(any(Goal.class));
    }

    // ---------------------------------------------------------
    // GET MY GOALS
    // ---------------------------------------------------------

    @Test
    void getMyGoals_success() {

        Goal secondGoal = Goal.builder()
                .id(2L)
                .goalName("Emergency Fund")
                .targetAmount(new BigDecimal("50000.00"))
                .currentAmount(new BigDecimal("25000.00"))
                .targetDate(LocalDate.now().plusMonths(3))
                .status(GoalStatus.IN_PROGRESS)
                .user(user)
                .createdAt(LocalDateTime.now())
                .build();

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.of(user));

        when(goalRepository.findByUserOrderByCreatedAtDesc(user))
                .thenReturn(List.of(goal, secondGoal));

        List<GoalResponse> responses = goalService.getMyGoals();

        assertNotNull(responses);
        assertEquals(2, responses.size());

        assertEquals("New Laptop", responses.get(0).getGoalName());
        assertEquals("Emergency Fund", responses.get(1).getGoalName());

        assertEquals(20, responses.get(0).getProgressPercentage());
        assertEquals(50, responses.get(1).getProgressPercentage());

        verify(userRepository).findByEmail("george@gmail.com");
        verify(goalRepository).findByUserOrderByCreatedAtDesc(user);
    }

    @Test
    void getMyGoals_noGoals_returnsEmptyList() {

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.of(user));

        when(goalRepository.findByUserOrderByCreatedAtDesc(user))
                .thenReturn(List.of());

        List<GoalResponse> responses = goalService.getMyGoals();

        assertNotNull(responses);
        assertTrue(responses.isEmpty());

        verify(goalRepository).findByUserOrderByCreatedAtDesc(user);
    }

    @Test
    void getMyGoals_authenticatedUserNotFound_throwsException() {

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.empty());

        RuntimeException exception = assertThrows(
                RuntimeException.class,
                () -> goalService.getMyGoals()
        );

        assertEquals(
                "Authenticated user not found",
                exception.getMessage()
        );

        verify(goalRepository, never())
                .findByUserOrderByCreatedAtDesc(any(User.class));
    }

    // ---------------------------------------------------------
    // GET GOAL BY ID
    // ---------------------------------------------------------

    @Test
    void getGoalById_success() {

        when(goalHelperService.getUserGoal(1L))
                .thenReturn(goal);

        GoalResponse response = goalService.getGoalById(1L);

        assertNotNull(response);
        assertEquals(1L, response.getId());
        assertEquals("New Laptop", response.getGoalName());

        assertEquals(
                0,
                response.getTargetAmount()
                        .compareTo(new BigDecimal("100000.00"))
        );

        assertEquals(
                0,
                response.getCurrentAmount()
                        .compareTo(new BigDecimal("20000.00"))
        );

        assertEquals(20, response.getProgressPercentage());
        assertEquals(GoalStatus.IN_PROGRESS, response.getStatus());

        verify(goalHelperService).getUserGoal(1L);
    }

    // ---------------------------------------------------------
    // UPDATE GOAL
    // ---------------------------------------------------------

    @Test
    void updateGoal_success_inProgress() {

        UpdateGoalRequest request = new UpdateGoalRequest();
        request.setGoalName("Gaming Laptop");
        request.setTargetAmount(new BigDecimal("100000.00"));
        request.setTargetDate(LocalDate.now().plusMonths(8));

        when(goalHelperService.getUserGoal(1L))
                .thenReturn(goal);

        when(goalRepository.save(goal))
                .thenReturn(goal);

        GoalResponse response = goalService.updateGoal(1L, request);

        assertNotNull(response);
        assertEquals("Gaming Laptop", response.getGoalName());

        assertEquals(
                0,
                response.getTargetAmount()
                        .compareTo(new BigDecimal("100000.00"))
        );

        assertEquals(20, response.getProgressPercentage());
        assertEquals(GoalStatus.IN_PROGRESS, response.getStatus());

        verify(goalHelperService).getUserGoal(1L);
        verify(goalRepository).save(goal);
    }

    @Test
    void updateGoal_targetReached_setsCompleted() {

        UpdateGoalRequest request = new UpdateGoalRequest();
        request.setGoalName("New Laptop");
        request.setTargetAmount(new BigDecimal("20000.00"));
        request.setTargetDate(LocalDate.now().plusMonths(2));

        when(goalHelperService.getUserGoal(1L))
                .thenReturn(goal);

        when(goalRepository.save(goal))
                .thenReturn(goal);

        GoalResponse response = goalService.updateGoal(1L, request);

        assertNotNull(response);

        assertEquals(
                GoalStatus.COMPLETED,
                response.getStatus()
        );

        assertEquals(100, response.getProgressPercentage());

        verify(goalRepository).save(goal);
    }

    // ---------------------------------------------------------
    // DELETE GOAL
    // ---------------------------------------------------------

    @Test
    void deleteGoal_success() {

        when(goalHelperService.getUserGoal(1L))
                .thenReturn(goal);

        goalService.deleteGoal(1L);

        verify(goalHelperService).getUserGoal(1L);
        verify(goalRepository).delete(goal);
    }

    // ---------------------------------------------------------
    // CONTRIBUTE TO GOAL
    // ---------------------------------------------------------

    @Test
    void contributeToGoal_success() {

        ContributeGoalRequest request = new ContributeGoalRequest();
        request.setAmount(new BigDecimal("30000.00"));

        when(goalHelperService.getUserGoal(1L))
                .thenReturn(goal);

        when(goalRepository.save(goal))
                .thenReturn(goal);

        GoalResponse response =
                goalService.contributeToGoal(1L, request);

        assertNotNull(response);

        assertEquals(
                0,
                response.getCurrentAmount()
                        .compareTo(new BigDecimal("50000.00"))
        );

        assertEquals(50, response.getProgressPercentage());

        assertEquals(
                GoalStatus.IN_PROGRESS,
                response.getStatus()
        );

        verify(goalRepository).save(goal);
    }

    @Test
    void contributeToGoal_completesGoal() {

        ContributeGoalRequest request = new ContributeGoalRequest();
        request.setAmount(new BigDecimal("80000.00"));

        when(goalHelperService.getUserGoal(1L))
                .thenReturn(goal);

        when(goalRepository.save(goal))
                .thenReturn(goal);

        GoalResponse response =
                goalService.contributeToGoal(1L, request);

        assertNotNull(response);

        assertEquals(
                0,
                response.getCurrentAmount()
                        .compareTo(new BigDecimal("100000.00"))
        );

        assertEquals(100, response.getProgressPercentage());

        assertEquals(
                GoalStatus.COMPLETED,
                response.getStatus()
        );

        verify(goalRepository).save(goal);
    }

    @Test
    void contributeToGoal_exceedingTarget_capsAtTarget() {

        ContributeGoalRequest request = new ContributeGoalRequest();
        request.setAmount(new BigDecimal("150000.00"));

        when(goalHelperService.getUserGoal(1L))
                .thenReturn(goal);

        when(goalRepository.save(goal))
                .thenReturn(goal);

        GoalResponse response =
                goalService.contributeToGoal(1L, request);

        assertNotNull(response);

        // Amount must never exceed target amount.
        assertEquals(
                0,
                response.getCurrentAmount()
                        .compareTo(new BigDecimal("100000.00"))
        );

        assertEquals(100, response.getProgressPercentage());

        assertEquals(
                GoalStatus.COMPLETED,
                response.getStatus()
        );

        verify(goalRepository).save(goal);
    }

    @Test
    void contributeToGoal_completedGoal_throwsException() {

        goal.setStatus(GoalStatus.COMPLETED);

        ContributeGoalRequest request = new ContributeGoalRequest();
        request.setAmount(new BigDecimal("10000.00"));

        when(goalHelperService.getUserGoal(1L))
                .thenReturn(goal);

        RuntimeException exception = assertThrows(
                RuntimeException.class,
                () -> goalService.contributeToGoal(1L, request)
        );

        assertEquals(
                "Goal is already completed.",
                exception.getMessage()
        );

        verify(goalRepository, never()).save(any(Goal.class));
    }

    @Test
    void contributeToGoal_zeroAmount_throwsException() {

        ContributeGoalRequest request = new ContributeGoalRequest();
        request.setAmount(BigDecimal.ZERO);

        when(goalHelperService.getUserGoal(1L))
                .thenReturn(goal);

        RuntimeException exception = assertThrows(
                RuntimeException.class,
                () -> goalService.contributeToGoal(1L, request)
        );

        assertEquals(
                "Contribution amount must be greater than zero.",
                exception.getMessage()
        );

        verify(goalRepository, never()).save(any(Goal.class));
    }

    @Test
    void contributeToGoal_negativeAmount_throwsException() {

        ContributeGoalRequest request = new ContributeGoalRequest();
        request.setAmount(new BigDecimal("-1000.00"));

        when(goalHelperService.getUserGoal(1L))
                .thenReturn(goal);

        RuntimeException exception = assertThrows(
                RuntimeException.class,
                () -> goalService.contributeToGoal(1L, request)
        );

        assertEquals(
                "Contribution amount must be greater than zero.",
                exception.getMessage()
        );

        verify(goalRepository, never()).save(any(Goal.class));
    }

    // ---------------------------------------------------------
    // PROGRESS CALCULATION
    // ---------------------------------------------------------

    @Test
    void getGoalById_progressCalculation_roundsDown() {

        goal.setCurrentAmount(new BigDecimal("3333.00"));
        goal.setTargetAmount(new BigDecimal("10000.00"));

        when(goalHelperService.getUserGoal(1L))
                .thenReturn(goal);

        GoalResponse response = goalService.getGoalById(1L);

        // 3333 / 10000 * 100 = 33.33%, RoundingMode.DOWN -> 33%
        assertEquals(33, response.getProgressPercentage());
    }

    @Test
    void getGoalById_zeroTarget_returnsZeroProgress() {

        goal.setTargetAmount(BigDecimal.ZERO);
        goal.setCurrentAmount(BigDecimal.ZERO);

        when(goalHelperService.getUserGoal(1L))
                .thenReturn(goal);

        GoalResponse response = goalService.getGoalById(1L);

        assertEquals(0, response.getProgressPercentage());
    }
}