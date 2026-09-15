/*AdminController.java  */


package com.smartbank.admin.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.smartbank.admin.dto.AdminAccountResponse;
import com.smartbank.admin.dto.AdminAccountStatisticsResponse;
import com.smartbank.admin.dto.AdminTransactionResponse;
import com.smartbank.admin.dto.AdminUserResponse;
import com.smartbank.admin.dto.AdminUserStatisticsResponse;
import com.smartbank.admin.service.AdminService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@Tag(
        name = "Admin",
        description = "Administrative APIs for managing users, accounts and transactions"
)
public class AdminController {

    private final AdminService adminService;

    @Operation(
            summary = "Get all users",
            description = "Retrieves a list of all registered users. Accessible only to administrators."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Users retrieved successfully"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Admin access required"
            )
    })
    @GetMapping("/users")
    public List<AdminUserResponse> getAllUsers() {

        return adminService.getAllUsers();
    }

    @Operation(
            summary = "Get all accounts",
            description = "Retrieves a list of all bank accounts in the system. Accessible only to administrators."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Accounts retrieved successfully"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Admin access required"
            )
    })
    @GetMapping("/accounts")
    public List<AdminAccountResponse> getAllAccounts() {

        return adminService.getAllAccounts();
    }

    @Operation(
            summary = "Get all transactions",
            description = "Retrieves a list of all transactions in the system. Accessible only to administrators."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Transactions retrieved successfully"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Admin access required"
            )
    })
    @GetMapping("/transactions")
    public List<AdminTransactionResponse> getAllTransactions() {

        return adminService.getAllTransactions();
    }

    @Operation(
            summary = "Get user statistics",
            description = "Retrieves statistical information about users in the SmartBank system."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "User statistics retrieved successfully"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Admin access required"
            )
    })
    @GetMapping("/statistics/users")
    public ResponseEntity<AdminUserStatisticsResponse> getUserStatistics() {

        return ResponseEntity.ok(adminService.getUserStatistics());
    }

    @Operation(
            summary = "Get account statistics",
            description = "Retrieves statistical information about bank accounts in the SmartBank system."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Account statistics retrieved successfully"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Admin access required"
            )
    })
    @GetMapping("/statistics/accounts")
    public ResponseEntity<AdminAccountStatisticsResponse> getAccountStatistics() {

        return ResponseEntity.ok(adminService.getAccountStatistics());
    }
}

