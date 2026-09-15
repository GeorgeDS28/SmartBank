//AnalyticsServiceImplTest.java
package com.smartbank.analytics.service.impl;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import com.smartbank.account.entity.Account;
import com.smartbank.account.repository.AccountRepository;
import com.smartbank.analytics.dto.DashboardResponse;
import com.smartbank.analytics.dto.FinancialSummaryResponse;
import com.smartbank.analytics.dto.GoalAnalyticsResponse;
import com.smartbank.analytics.dto.MonthlyTransactionResponse;
import com.smartbank.analytics.dto.RecentTransactionResponse;
import com.smartbank.analytics.dto.TransferAnalyticsResponse;
import com.smartbank.analytics.service.impl.AnalyticsServiceImpl;
import com.smartbank.goal.entity.Goal;
import com.smartbank.goal.entity.GoalStatus;
import com.smartbank.goal.repository.GoalRepository;
import com.smartbank.transaction.entity.Transaction;
import com.smartbank.transaction.enums.TransactionType;
import com.smartbank.transaction.repository.TransactionRepository;
import com.smartbank.user.entity.User;
import com.smartbank.user.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class AnalyticsServiceImplTest {

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private GoalRepository goalRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private AnalyticsServiceImpl analyticsService;

    private User user;
    private Account account1;
    private Account account2;

    @BeforeEach
    void setUp() {

        user = new User();
        user.setId(1L);
        user.setEmail("george@gmail.com");

        account1 = new Account();
        account1.setId(1L);
        account1.setAccountNumber("SB100001");
        account1.setBalance(new BigDecimal("50000.00"));
        account1.setUser(user);

        account2 = new Account();
        account2.setId(2L);
        account2.setAccountNumber("SB100002");
        account2.setBalance(new BigDecimal("25000.00"));
        account2.setUser(user);

        org.springframework.security.core.userdetails.User securityUser =
                new org.springframework.security.core.userdetails.User(
                        "george@gmail.com",
                        "password",
                        List.of()
                );

        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(
                        securityUser,
                        null,
                        securityUser.getAuthorities()
                )
        );
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    // ============================================================
    // getDashboard()
    // ============================================================

    @Test
    void getDashboard_success() {

        Transaction deposit = createTransaction(
                "TXN001",
                TransactionType.DEPOSIT,
                "10000.00",
                "Salary",
                account1,
                LocalDateTime.of(2026, 9, 10, 10, 0)
        );

        Transaction withdrawal = createTransaction(
                "TXN002",
                TransactionType.WITHDRAW,
                "2000.00",
                "Shopping",
                account1,
                LocalDateTime.of(2026, 9, 11, 10, 0)
        );

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.of(user));

        when(accountRepository.findByUser(user))
                .thenReturn(List.of(account1, account2));

        when(transactionRepository.findByAccount(account1))
                .thenReturn(List.of(deposit, withdrawal));

        when(transactionRepository.findByAccount(account2))
                .thenReturn(List.of());

        DashboardResponse response = analyticsService.getDashboard();

        assertNotNull(response);

        assertEquals(
                0,
                response.getTotalBalance()
                        .compareTo(new BigDecimal("75000.00"))
        );

        assertEquals(2, response.getNumberOfAccounts());
        assertEquals(2, response.getTotalTransactions());

        assertEquals(2, response.getRecentTransactions().size());

        assertEquals(
                "TXN002",
                response.getRecentTransactions()
                        .get(0)
                        .getTransactionReference()
        );

        assertEquals(
                "TXN001",
                response.getRecentTransactions()
                        .get(1)
                        .getTransactionReference()
        );
    }

    @Test
    void getDashboard_returnsOnlyLatestFiveTransactions() {

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.of(user));

        when(accountRepository.findByUser(user))
                .thenReturn(List.of(account1));

        List<Transaction> transactions = List.of(
                createTransaction(
                        "TXN001",
                        TransactionType.DEPOSIT,
                        "1000.00",
                        "T1",
                        account1,
                        LocalDateTime.of(2026, 9, 1, 10, 0)
                ),
                createTransaction(
                        "TXN002",
                        TransactionType.DEPOSIT,
                        "2000.00",
                        "T2",
                        account1,
                        LocalDateTime.of(2026, 9, 2, 10, 0)
                ),
                createTransaction(
                        "TXN003",
                        TransactionType.DEPOSIT,
                        "3000.00",
                        "T3",
                        account1,
                        LocalDateTime.of(2026, 9, 3, 10, 0)
                ),
                createTransaction(
                        "TXN004",
                        TransactionType.DEPOSIT,
                        "4000.00",
                        "T4",
                        account1,
                        LocalDateTime.of(2026, 9, 4, 10, 0)
                ),
                createTransaction(
                        "TXN005",
                        TransactionType.DEPOSIT,
                        "5000.00",
                        "T5",
                        account1,
                        LocalDateTime.of(2026, 9, 5, 10, 0)
                ),
                createTransaction(
                        "TXN006",
                        TransactionType.DEPOSIT,
                        "6000.00",
                        "T6",
                        account1,
                        LocalDateTime.of(2026, 9, 6, 10, 0)
                )
        );

        when(transactionRepository.findByAccount(account1))
                .thenReturn(transactions);

        DashboardResponse response = analyticsService.getDashboard();

        assertEquals(6, response.getTotalTransactions());
        assertEquals(5, response.getRecentTransactions().size());

        assertEquals(
                "TXN006",
                response.getRecentTransactions()
                        .get(0)
                        .getTransactionReference()
        );
    }

    @Test
    void getDashboard_userNotFound_throwsException() {

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.empty());

        RuntimeException exception = assertThrows(
                RuntimeException.class,
                () -> analyticsService.getDashboard()
        );

        assertEquals("User not found", exception.getMessage());
    }

    // ============================================================
    // getMonthlyAnalytics()
    // ============================================================

    @Test
    void getMonthlyAnalytics_groupsTransactionsByMonth() {

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.of(user));

        when(accountRepository.findByUser(user))
                .thenReturn(List.of(account1));

        Transaction januaryDeposit = createTransaction(
                "TXN001",
                TransactionType.DEPOSIT,
                "10000.00",
                "January deposit",
                account1,
                LocalDateTime.of(2026, 1, 10, 10, 0)
        );

        Transaction januaryWithdrawal = createTransaction(
                "TXN002",
                TransactionType.WITHDRAW,
                "2000.00",
                "January withdrawal",
                account1,
                LocalDateTime.of(2026, 1, 15, 10, 0)
        );

        Transaction februaryDeposit = createTransaction(
                "TXN003",
                TransactionType.DEPOSIT,
                "5000.00",
                "February deposit",
                account1,
                LocalDateTime.of(2026, 2, 10, 10, 0)
        );

        when(transactionRepository.findByAccount(account1))
                .thenReturn(
                        List.of(
                                januaryDeposit,
                                januaryWithdrawal,
                                februaryDeposit
                        )
                );

        List<MonthlyTransactionResponse> response =
                analyticsService.getMonthlyAnalytics();

        assertEquals(2, response.size());

        assertEquals("January", response.get(0).getMonth());
        assertEquals("February", response.get(1).getMonth());

        assertEquals(
                0,
                response.get(0)
                        .getDeposits()
                        .compareTo(new BigDecimal("10000.00"))
        );

        assertEquals(
                0,
                response.get(0)
                        .getWithdrawals()
                        .compareTo(new BigDecimal("2000.00"))
        );

        assertEquals(
                0,
                response.get(1)
                        .getDeposits()
                        .compareTo(new BigDecimal("5000.00"))
        );
    }

    @Test
    void getMonthlyAnalytics_calculatesTransferAmounts() {

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.of(user));

        when(accountRepository.findByUser(user))
                .thenReturn(List.of(account1));

        Transaction transferIn = createTransaction(
                "TXN001",
                TransactionType.TRANSFER_IN,
                "15000.00",
                "Transfer received",
                account1,
                LocalDateTime.of(2026, 3, 10, 10, 0)
        );

        Transaction transferOut = createTransaction(
                "TXN002",
                TransactionType.TRANSFER_OUT,
                "5000.00",
                "Transfer sent",
                account1,
                LocalDateTime.of(2026, 3, 15, 10, 0)
        );

        when(transactionRepository.findByAccount(account1))
                .thenReturn(List.of(transferIn, transferOut));

        List<MonthlyTransactionResponse> response =
                analyticsService.getMonthlyAnalytics();

        assertEquals(1, response.size());

        assertEquals(
                0,
                response.get(0)
                        .getTransfersIn()
                        .compareTo(new BigDecimal("15000.00"))
        );

        assertEquals(
                0,
                response.get(0)
                        .getTransfersOut()
                        .compareTo(new BigDecimal("5000.00"))
        );
    }

    @Test
    void getMonthlyAnalytics_noTransactions_returnsEmptyList() {

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.of(user));

        when(accountRepository.findByUser(user))
                .thenReturn(List.of(account1));

        when(transactionRepository.findByAccount(account1))
                .thenReturn(List.of());

        List<MonthlyTransactionResponse> response =
                analyticsService.getMonthlyAnalytics();

        assertNotNull(response);
        assertTrue(response.isEmpty());
    }

    // ============================================================
    // getGoalAnalytics()
    // ============================================================

    @Test
    void getGoalAnalytics_success() {

        Goal goal1 = createGoal(
                "New Laptop",
                "100000.00",
                "30000.00",
                GoalStatus.IN_PROGRESS
        );

        Goal goal2 = createGoal(
                "Vacation",
                "50000.00",
                "50000.00",
                GoalStatus.COMPLETED
        );

        Goal goal3 = createGoal(
                "Emergency Fund",
                "100000.00",
                "20000.00",
                GoalStatus.IN_PROGRESS
        );

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.of(user));

        when(goalRepository.findByUser(user))
                .thenReturn(List.of(goal1, goal2, goal3));

        GoalAnalyticsResponse response =
                analyticsService.getGoalAnalytics();

        assertNotNull(response);

        assertEquals(3, response.getTotalGoals());
        assertEquals(2, response.getActiveGoals());
        assertEquals(1, response.getCompletedGoals());

        assertEquals(
                0,
                response.getTotalTargetAmount()
                        .compareTo(new BigDecimal("250000.00"))
        );

        assertEquals(
                0,
                response.getTotalSavedAmount()
                        .compareTo(new BigDecimal("100000.00"))
        );

        assertEquals(
                0,
                response.getOverallProgress()
                        .compareTo(new BigDecimal("40.00"))
        );
    }

    @Test
    void getGoalAnalytics_noGoals_returnsZeroValues() {

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.of(user));

        when(goalRepository.findByUser(user))
                .thenReturn(List.of());

        GoalAnalyticsResponse response =
                analyticsService.getGoalAnalytics();

        assertEquals(0, response.getTotalGoals());
        assertEquals(0, response.getActiveGoals());
        assertEquals(0, response.getCompletedGoals());

        assertEquals(
                0,
                response.getTotalTargetAmount()
                        .compareTo(BigDecimal.ZERO)
        );

        assertEquals(
                0,
                response.getTotalSavedAmount()
                        .compareTo(BigDecimal.ZERO)
        );

        assertEquals(
                0,
                response.getOverallProgress()
                        .compareTo(BigDecimal.ZERO)
        );
    }

    @Test
    void getGoalAnalytics_userNotFound_throwsException() {

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.empty());

        RuntimeException exception = assertThrows(
                RuntimeException.class,
                () -> analyticsService.getGoalAnalytics()
        );

        assertEquals("User not found", exception.getMessage());
    }

    // ============================================================
    // getTransferAnalytics()
    // ============================================================

    @Test
    void getTransferAnalytics_success() {

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.of(user));

        when(accountRepository.findByUser(user))
                .thenReturn(List.of(account1, account2));

        Transaction transferIn = createTransaction(
                "TXN001",
                TransactionType.TRANSFER_IN,
                "15000.00",
                "Received",
                account1,
                LocalDateTime.of(2026, 9, 1, 10, 0)
        );

        Transaction transferOut = createTransaction(
                "TXN002",
                TransactionType.TRANSFER_OUT,
                "5000.00",
                "Sent",
                account1,
                LocalDateTime.of(2026, 9, 2, 10, 0)
        );

        Transaction deposit = createTransaction(
                "TXN003",
                TransactionType.DEPOSIT,
                "10000.00",
                "Salary",
                account2,
                LocalDateTime.of(2026, 9, 3, 10, 0)
        );

        when(transactionRepository.findByAccount(account1))
                .thenReturn(List.of(transferIn, transferOut));

        when(transactionRepository.findByAccount(account2))
                .thenReturn(List.of(deposit));

        TransferAnalyticsResponse response =
                analyticsService.getTransferAnalytics();

        assertEquals(2, response.getTotalTransfers());

        assertEquals(
                0,
                response.getTotalTransferredIn()
                        .compareTo(new BigDecimal("15000.00"))
        );

        assertEquals(
                0,
                response.getTotalTransferredOut()
                        .compareTo(new BigDecimal("5000.00"))
        );

        assertEquals(
                0,
                response.getNetTransferAmount()
                        .compareTo(new BigDecimal("10000.00"))
        );
    }

    @Test
    void getTransferAnalytics_noTransfers_returnsZeroValues() {

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.of(user));

        when(accountRepository.findByUser(user))
                .thenReturn(List.of(account1));

        Transaction deposit = createTransaction(
                "TXN001",
                TransactionType.DEPOSIT,
                "10000.00",
                "Salary",
                account1,
                LocalDateTime.of(2026, 9, 1, 10, 0)
        );

        when(transactionRepository.findByAccount(account1))
                .thenReturn(List.of(deposit));

        TransferAnalyticsResponse response =
                analyticsService.getTransferAnalytics();

        assertEquals(0, response.getTotalTransfers());

        assertEquals(
                0,
                response.getTotalTransferredIn()
                        .compareTo(BigDecimal.ZERO)
        );

        assertEquals(
                0,
                response.getTotalTransferredOut()
                        .compareTo(BigDecimal.ZERO)
        );

        assertEquals(
                0,
                response.getNetTransferAmount()
                        .compareTo(BigDecimal.ZERO)
        );
    }

    // ============================================================
    // getFinancialSummary()
    // ============================================================

    @Test
    void getFinancialSummary_success() {

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.of(user));

        when(accountRepository.findByUser(user))
                .thenReturn(List.of(account1, account2));

        Transaction deposit = createTransaction(
                "TXN001",
                TransactionType.DEPOSIT,
                "20000.00",
                "Salary",
                account1,
                LocalDateTime.of(2026, 9, 1, 10, 0)
        );

        Transaction withdrawal = createTransaction(
                "TXN002",
                TransactionType.WITHDRAW,
                "5000.00",
                "Shopping",
                account1,
                LocalDateTime.of(2026, 9, 2, 10, 0)
        );

        Transaction transferIn = createTransaction(
                "TXN003",
                TransactionType.TRANSFER_IN,
                "10000.00",
                "Received",
                account2,
                LocalDateTime.of(2026, 9, 3, 10, 0)
        );

        Transaction transferOut = createTransaction(
                "TXN004",
                TransactionType.TRANSFER_OUT,
                "3000.00",
                "Sent",
                account2,
                LocalDateTime.of(2026, 9, 4, 10, 0)
        );

        when(transactionRepository.findByAccount(account1))
                .thenReturn(List.of(deposit, withdrawal));

        when(transactionRepository.findByAccount(account2))
                .thenReturn(List.of(transferIn, transferOut));

        Goal goal1 = createGoal(
                "Laptop",
                "100000.00",
                "30000.00",
                GoalStatus.IN_PROGRESS
        );

        Goal goal2 = createGoal(
                "Vacation",
                "50000.00",
                "20000.00",
                GoalStatus.IN_PROGRESS
        );

        when(goalRepository.findByUser(user))
                .thenReturn(List.of(goal1, goal2));

        FinancialSummaryResponse response =
                analyticsService.getFinancialSummary();

        assertEquals(
                0,
                response.getTotalBalance()
                        .compareTo(new BigDecimal("75000.00"))
        );

        assertEquals(
                0,
                response.getTotalDeposits()
                        .compareTo(new BigDecimal("20000.00"))
        );

        assertEquals(
                0,
                response.getTotalWithdrawals()
                        .compareTo(new BigDecimal("5000.00"))
        );

        assertEquals(
                0,
                response.getTotalTransferredIn()
                        .compareTo(new BigDecimal("10000.00"))
        );

        assertEquals(
                0,
                response.getTotalTransferredOut()
                        .compareTo(new BigDecimal("3000.00"))
        );

        // 20000 + 10000 - 5000 - 3000 = 22000
        assertEquals(
                0,
                response.getNetCashFlow()
                        .compareTo(new BigDecimal("22000.00"))
        );

        assertEquals(
                0,
                response.getTotalGoalSavings()
                        .compareTo(new BigDecimal("50000.00"))
        );
    }

    @Test
    void getFinancialSummary_noTransactionsAndGoals_returnsZeroStatistics() {

        when(userRepository.findByEmail("george@gmail.com"))
                .thenReturn(Optional.of(user));

        when(accountRepository.findByUser(user))
                .thenReturn(List.of(account1));

        when(transactionRepository.findByAccount(account1))
                .thenReturn(List.of());

        when(goalRepository.findByUser(user))
                .thenReturn(List.of());

        FinancialSummaryResponse response =
                analyticsService.getFinancialSummary();

        assertEquals(
                0,
                response.getTotalBalance()
                        .compareTo(new BigDecimal("50000.00"))
        );

        assertEquals(
                0,
                response.getTotalDeposits()
                        .compareTo(BigDecimal.ZERO)
        );

        assertEquals(
                0,
                response.getTotalWithdrawals()
                        .compareTo(BigDecimal.ZERO)
        );

        assertEquals(
                0,
                response.getTotalTransferredIn()
                        .compareTo(BigDecimal.ZERO)
        );

        assertEquals(
                0,
                response.getTotalTransferredOut()
                        .compareTo(BigDecimal.ZERO)
        );

        assertEquals(
                0,
                response.getNetCashFlow()
                        .compareTo(BigDecimal.ZERO)
        );

        assertEquals(
                0,
                response.getTotalGoalSavings()
                        .compareTo(BigDecimal.ZERO)
        );
    }

    // ============================================================
    // Helper methods
    // ============================================================

    private Transaction createTransaction(
            String reference,
            TransactionType type,
            String amount,
            String description,
            Account account,
            LocalDateTime createdAt) {

        return Transaction.builder()
                .transactionReference(reference)
                .transactionType(type)
                .amount(new BigDecimal(amount))
                .description(description)
                .account(account)
                .createdAt(createdAt)
                .build();
    }

    private Goal createGoal(
            String goalName,
            String targetAmount,
            String currentAmount,
            GoalStatus status) {

        return Goal.builder()
                .id(System.nanoTime())
                .goalName(goalName)
                .targetAmount(new BigDecimal(targetAmount))
                .currentAmount(new BigDecimal(currentAmount))
                .targetDate(java.time.LocalDate.now().plusMonths(6))
                .status(status)
                .user(user)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
    }
}

