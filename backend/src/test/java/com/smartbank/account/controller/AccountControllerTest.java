//AccountControllerTest.java
package com.smartbank.account.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
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
import com.smartbank.account.dto.AccountResponse;
import com.smartbank.account.dto.CreateAccountRequest;
import com.smartbank.account.entity.AccountStatus;
import com.smartbank.account.entity.AccountType;
import com.smartbank.account.service.AccountService;
import com.smartbank.transaction.dto.DepositRequest;
import com.smartbank.transaction.dto.DepositResponse;
import com.smartbank.transaction.dto.TransactionResponse;
import com.smartbank.transaction.dto.WithdrawRequest;
import com.smartbank.transaction.dto.WithdrawResponse;
import com.smartbank.transaction.enums.TransactionType;
import com.smartbank.transaction.service.TransactionService;

import com.smartbank.auth.jwt.JwtService;
import com.smartbank.security.JwtAuthenticationFilter;

@WebMvcTest(AccountController.class)
@AutoConfigureMockMvc(addFilters = false)
class AccountControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AccountService accountService;

    @MockBean
    private TransactionService transactionService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    // =========================================================
    // CREATE ACCOUNT
    // =========================================================

    @Test
    void createAccount_success() throws Exception {

        CreateAccountRequest request = new CreateAccountRequest();
        request.setAccountType(AccountType.SAVINGS);

        AccountResponse response = AccountResponse.builder()
                .accountNumber("SB1234567890")
                .accountType(AccountType.SAVINGS)
                .balance(new BigDecimal("0.00"))
                .status(AccountStatus.ACTIVE)
                .build();

        when(accountService.createAccount(any(CreateAccountRequest.class)))
                .thenReturn(response);

        mockMvc.perform(
                post("/api/accounts")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.accountNumber")
                .value("SB1234567890"))
        .andExpect(jsonPath("$.accountType")
                .value("SAVINGS"))
        .andExpect(jsonPath("$.balance")
                .value(0.00))
        .andExpect(jsonPath("$.status")
                .value("ACTIVE"));

        verify(accountService)
                .createAccount(any(CreateAccountRequest.class));
    }

    @Test
    void createAccount_invalidRequest_returnsBadRequest() throws Exception {

        CreateAccountRequest request = new CreateAccountRequest();

        mockMvc.perform(
                post("/api/accounts")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isBadRequest());
    }

    // =========================================================
    // GET MY ACCOUNTS
    // =========================================================

    @Test
    void getMyAccounts_success() throws Exception {

        AccountResponse response = AccountResponse.builder()
                .accountNumber("SB1234567890")
                .accountType(AccountType.SAVINGS)
                .balance(new BigDecimal("5000.00"))
                .status(AccountStatus.ACTIVE)
                .build();

        when(accountService.getMyAccounts())
                .thenReturn(List.of(response));

        mockMvc.perform(
                get("/api/accounts")
        )
        .andExpect(status().isOk())
        .andExpect(jsonPath("$[0].accountNumber")
                .value("SB1234567890"))
        .andExpect(jsonPath("$[0].accountType")
                .value("SAVINGS"))
        .andExpect(jsonPath("$[0].balance")
                .value(5000.00))
        .andExpect(jsonPath("$[0].status")
                .value("ACTIVE"));

        verify(accountService).getMyAccounts();
    }

    // =========================================================
    // GET ACCOUNT BY NUMBER
    // =========================================================

    @Test
    void getAccountByNumber_success() throws Exception {

        AccountResponse response = AccountResponse.builder()
                .accountNumber("SB1234567890")
                .accountType(AccountType.SAVINGS)
                .balance(new BigDecimal("5000.00"))
                .status(AccountStatus.ACTIVE)
                .build();

        when(accountService.getAccountByNumber("SB1234567890"))
                .thenReturn(response);

        mockMvc.perform(
                get("/api/accounts/{accountNumber}", "SB1234567890")
        )
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.accountNumber")
                .value("SB1234567890"))
        .andExpect(jsonPath("$.balance")
                .value(5000.00));

        verify(accountService)
                .getAccountByNumber("SB1234567890");
    }

    // =========================================================
    // DEPOSIT
    // =========================================================

    @Test
    void deposit_success() throws Exception {

        DepositRequest request =
                new DepositRequest(new BigDecimal("1000.00"));

        DepositResponse response = new DepositResponse(
                "SB1234567890",
                new BigDecimal("1000.00"),
                new BigDecimal("6000.00"),
                "Deposit successful"
        );

        when(accountService.deposit(
                eq("SB1234567890"),
                any(DepositRequest.class)))
                .thenReturn(response);

        mockMvc.perform(
                post("/api/accounts/{accountNumber}/deposit",
                        "SB1234567890")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.accountNumber")
                .value("SB1234567890"))
        .andExpect(jsonPath("$.depositedAmount")
                .value(1000.00))
        .andExpect(jsonPath("$.currentBalance")
                .value(6000.00))
        .andExpect(jsonPath("$.message")
                .value("Deposit successful"));

        verify(accountService).deposit(
                eq("SB1234567890"),
                any(DepositRequest.class));
    }

    @Test
    void deposit_invalidRequest_returnsBadRequest() throws Exception {

        DepositRequest request = new DepositRequest();

        mockMvc.perform(
                post("/api/accounts/{accountNumber}/deposit",
                        "SB1234567890")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isBadRequest());
    }

    // =========================================================
    // WITHDRAW
    // =========================================================

    @Test
    void withdraw_success() throws Exception {

        WithdrawRequest request =
                new WithdrawRequest(new BigDecimal("500.00"));

        WithdrawResponse response = new WithdrawResponse(
                "Withdrawal successful",
                "SB1234567890",
                new BigDecimal("500.00"),
                new BigDecimal("4500.00")
        );

        when(accountService.withdraw(
                eq("SB1234567890"),
                any(WithdrawRequest.class)))
                .thenReturn(response);

        mockMvc.perform(
                post("/api/accounts/{accountNumber}/withdraw",
                        "SB1234567890")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.message")
                .value("Withdrawal successful"))
        .andExpect(jsonPath("$.accountNumber")
                .value("SB1234567890"))
        .andExpect(jsonPath("$.withdrawnAmount")
                .value(500.00))
        .andExpect(jsonPath("$.updatedBalance")
                .value(4500.00));

        verify(accountService).withdraw(
                eq("SB1234567890"),
                any(WithdrawRequest.class));
    }

    @Test
    void withdraw_invalidRequest_returnsBadRequest() throws Exception {

        WithdrawRequest request = new WithdrawRequest();

        mockMvc.perform(
                post("/api/accounts/{accountNumber}/withdraw",
                        "SB1234567890")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isBadRequest());
    }

    // =========================================================
    // GET TRANSACTIONS
    // =========================================================

    @Test
    void getTransactions_success() throws Exception {

        TransactionResponse transaction = new TransactionResponse(
                "TXN123",
                TransactionType.DEPOSIT,
                new BigDecimal("1000.00"),
                "Initial deposit",
                LocalDateTime.now()
        );

        when(transactionService.getTransactions("SB1234567890"))
                .thenReturn(List.of(transaction));

        mockMvc.perform(
                get("/api/accounts/{accountNumber}/transactions",
                        "SB1234567890")
        )
        .andExpect(status().isOk())
        .andExpect(jsonPath("$[0].transactionReference")
                .value("TXN123"))
        .andExpect(jsonPath("$[0].transactionType")
                .value("DEPOSIT"))
        .andExpect(jsonPath("$[0].amount")
                .value(1000.00))
        .andExpect(jsonPath("$[0].description")
                .value("Initial deposit"));

        verify(transactionService)
                .getTransactions("SB1234567890");
    }
}