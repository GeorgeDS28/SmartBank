/* GoalController.java */

package com.smartbank.goal.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.smartbank.goal.dto.CreateGoalRequest;
import com.smartbank.goal.dto.GoalResponse;
import com.smartbank.goal.dto.UpdateGoalRequest;
import com.smartbank.goal.service.GoalService;



import io.swagger.v3.oas.annotations.Operation; 
import io.swagger.v3.oas.annotations.Parameter; 
import io.swagger.v3.oas.annotations.responses.ApiResponse; 
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;








import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;


import com.smartbank.goal.dto.ContributeGoalRequest;

import org.springframework.http.ResponseEntity;
import com.smartbank.goal.service.GoalService;









@RestController
@RequestMapping("/api/goals")
@RequiredArgsConstructor
@Tag(
        name = "Goals",
        description = "Savings goal management and contribution APIs"
)
public class GoalController {

    private final GoalService goalService;

    @Operation(
            summary = "Create a savings goal",
            description = "Creates a new savings goal for the authenticated user."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "201",
                    description = "Goal created successfully"
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Invalid goal creation request"
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
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public GoalResponse createGoal(
            @Valid @RequestBody CreateGoalRequest request) {

        return goalService.createGoal(request);
    }

    @Operation(
            summary = "Get my savings goals",
            description = "Retrieves all savings goals belonging to the authenticated user."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Goals retrieved successfully"
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
    @GetMapping
    public List<GoalResponse> getMyGoals() {

        return goalService.getMyGoals();
    }

    @Operation(
            summary = "Get goal by ID",
            description = "Retrieves the details of a specific savings goal."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Goal retrieved successfully"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Access denied"
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Goal not found"
            )
    })
    @GetMapping("/{id}")
    public GoalResponse getGoalById(
            @Parameter(
                    description = "Unique ID of the savings goal",
                    required = true,
                    example = "1"
            )
            @PathVariable Long id) {

        return goalService.getGoalById(id);
    }

    @Operation(
            summary = "Update a savings goal",
            description = "Updates the details of an existing savings goal."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Goal updated successfully"
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Invalid goal update request"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Access denied"
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Goal not found"
            )
    })
    @PutMapping("/{id}")
    public GoalResponse updateGoal(
            @Parameter(
                    description = "Unique ID of the savings goal",
                    required = true,
                    example = "1"
            )
            @PathVariable Long id,
            @Valid @RequestBody UpdateGoalRequest request) {

        return goalService.updateGoal(id, request);
    }

    @Operation(
            summary = "Delete a savings goal",
            description = "Deletes an existing savings goal."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "204",
                    description = "Goal deleted successfully"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Access denied"
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Goal not found"
            )
    })
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteGoal(
            @Parameter(
                    description = "Unique ID of the savings goal",
                    required = true,
                    example = "1"
            )
            @PathVariable Long id) {

        goalService.deleteGoal(id);
    }

    @Operation(
            summary = "Contribute to a savings goal",
            description = "Adds a contribution amount to an existing savings goal."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Contribution added successfully"
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Invalid contribution request"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Access denied"
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Goal not found"
            )
    })
    @PostMapping("/{goalId}/contribute")
    public ResponseEntity<GoalResponse> contributeToGoal(
            @Parameter(
                    description = "Unique ID of the savings goal",
                    required = true,
                    example = "1"
            )
            @PathVariable Long goalId,
            @Valid @RequestBody ContributeGoalRequest request) {

        GoalResponse response = goalService.contributeToGoal(goalId, request);
        return ResponseEntity.ok(response);
    }
}

