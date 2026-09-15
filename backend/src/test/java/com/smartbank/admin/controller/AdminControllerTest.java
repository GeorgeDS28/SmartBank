package com.smartbank.admin.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;

import com.smartbank.admin.dto.AdminAccountResponse;
import com.smartbank.admin.dto.AdminAccountStatisticsResponse;
import com.smartbank.admin.dto.AdminTransactionResponse;
import com.smartbank.admin.dto.AdminUserResponse;
import com.smartbank.admin.dto.AdminUserStatisticsResponse;
import com.smartbank.admin.service.AdminService;

@ExtendWith(MockitoExtension.class)
class AdminControllerTest {

    @Mock
    private AdminService adminService;

    private AdminController adminController;

    @BeforeEach
    void setUp() {
        adminController = new AdminController(adminService);
    }

    @Test
    void getAllUsers_shouldReturnUsers() {

        List<AdminUserResponse> users =
                List.of(org.mockito.Mockito.mock(AdminUserResponse.class));

        when(adminService.getAllUsers()).thenReturn(users);

        List<AdminUserResponse> result =
                adminController.getAllUsers();

        assertSame(users, result);

        verify(adminService).getAllUsers();
    }

    @Test
    void getAllAccounts_shouldReturnAccounts() {

        List<AdminAccountResponse> accounts =
                List.of(org.mockito.Mockito.mock(AdminAccountResponse.class));

        when(adminService.getAllAccounts()).thenReturn(accounts);

        List<AdminAccountResponse> result =
                adminController.getAllAccounts();

        assertSame(accounts, result);

        verify(adminService).getAllAccounts();
    }

    @Test
    void getAllTransactions_shouldReturnTransactions() {

        List<AdminTransactionResponse> transactions =
                List.of(org.mockito.Mockito.mock(AdminTransactionResponse.class));

        when(adminService.getAllTransactions()).thenReturn(transactions);

        List<AdminTransactionResponse> result =
                adminController.getAllTransactions();

        assertSame(transactions, result);

        verify(adminService).getAllTransactions();
    }

    @Test
    void getUserStatistics_shouldReturnOkResponse() {

        AdminUserStatisticsResponse statistics =
                org.mockito.Mockito.mock(AdminUserStatisticsResponse.class);

        when(adminService.getUserStatistics()).thenReturn(statistics);

        ResponseEntity<AdminUserStatisticsResponse> response =
                adminController.getUserStatistics();

        assertEquals(200, response.getStatusCode().value());
        assertSame(statistics, response.getBody());

        verify(adminService).getUserStatistics();
    }

    @Test
    void getAccountStatistics_shouldReturnOkResponse() {

        AdminAccountStatisticsResponse statistics =
                org.mockito.Mockito.mock(AdminAccountStatisticsResponse.class);

        when(adminService.getAccountStatistics()).thenReturn(statistics);

        ResponseEntity<AdminAccountStatisticsResponse> response =
                adminController.getAccountStatistics();

        assertEquals(200, response.getStatusCode().value());
        assertSame(statistics, response.getBody());

        verify(adminService).getAccountStatistics();
    }
}