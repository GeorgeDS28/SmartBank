/*AnalyticsServiceImpl.java
 */

package com.smartbank.analytics.service.impl;
import java.util.*;

import com.smartbank.analytics.dto.MonthlyTransactionResponse;




import com.smartbank.analytics.dto.GoalAnalyticsResponse;
import com.smartbank.goal.entity.Goal;
import com.smartbank.goal.entity.GoalStatus;
import com.smartbank.goal.repository.GoalRepository;
import com.smartbank.analytics.dto.TransferAnalyticsResponse;



import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.smartbank.account.entity.Account;
import com.smartbank.account.repository.AccountRepository;
import com.smartbank.analytics.dto.DashboardResponse;
import com.smartbank.analytics.dto.RecentTransactionResponse;
import com.smartbank.transaction.entity.Transaction;
import com.smartbank.transaction.repository.TransactionRepository;

import com.smartbank.user.entity.User;
import com.smartbank.user.repository.UserRepository;

import com.smartbank.analytics.service.AnalyticsService;

import com.smartbank.analytics.dto.FinancialSummaryResponse;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AnalyticsServiceImpl implements AnalyticsService {

    private final AccountRepository accountRepository;
    private final TransactionRepository transactionRepository;
   
   
    private final GoalRepository goalRepository;
   
   
    private final UserRepository userRepository;

    @Override
    public DashboardResponse getDashboard() {

     // Get authenticated Spring Security user
        org.springframework.security.core.userdetails.User securityUser =
                (org.springframework.security.core.userdetails.User)
                        SecurityContextHolder
                                .getContext()
                                .getAuthentication()
                                .getPrincipal();

        // Get user's email
        String email = securityUser.getUsername();

        // Find actual SmartBank User entity from database
        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new RuntimeException("User not found")
                );

        // Get all accounts belonging to the user
        List<Account> accounts = accountRepository.findByUser(user);

        // Calculate total balance
        BigDecimal totalBalance = accounts.stream()
                .map(Account::getBalance)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Collect all transactions from user's accounts
        List<Transaction> allTransactions = new ArrayList<>();

        for (Account account : accounts) {

            List<Transaction> transactions =
                    transactionRepository.findByAccount(account);

            allTransactions.addAll(transactions);
        }

        // Sort transactions by newest first
        allTransactions.sort(
                Comparator.comparing(
                        Transaction::getCreatedAt
                ).reversed()
        );

        // Get latest 5 transactions
        List<RecentTransactionResponse> recentTransactions =
                allTransactions.stream()
                        .limit(5)
                        .map(transaction ->
                                RecentTransactionResponse.builder()
                                        .transactionReference(
                                                transaction.getTransactionReference()
                                        )
                                        .transactionType(
                                                transaction.getTransactionType()
                                        )
                                        .amount(
                                                transaction.getAmount()
                                        )
                                        .description(
                                                transaction.getDescription()
                                        )
                                        .accountNumber(
                                                transaction.getAccount()
                                                        .getAccountNumber()
                                        )
                                        .createdAt(
                                                transaction.getCreatedAt()
                                        )
                                        .build()
                        )
                        .toList();

        // Build dashboard response
        return DashboardResponse.builder()
                .totalBalance(totalBalance)
                .numberOfAccounts(accounts.size())
                .totalTransactions(allTransactions.size())
                .recentTransactions(recentTransactions)
                .build();



    }
    //added this 

 
        
@Override
public List<MonthlyTransactionResponse> getMonthlyAnalytics() {

    // Get authenticated Spring Security user
    org.springframework.security.core.userdetails.User securityUser =
            (org.springframework.security.core.userdetails.User)
                    SecurityContextHolder
                            .getContext()
                            .getAuthentication()
                            .getPrincipal();

    // Get user's email
    String email = securityUser.getUsername();

    // Find actual SmartBank User entity
    User user = userRepository.findByEmail(email)
            .orElseThrow(() ->
                    new RuntimeException("User not found")
            );

    // Get all accounts belonging to the user
    List<Account> accounts = accountRepository.findByUser(user);

    // Collect all transactions from user's accounts
    List<Transaction> allTransactions = new ArrayList<>();

    for (Account account : accounts) {

        List<Transaction> transactions =
                transactionRepository.findByAccount(account);

        allTransactions.addAll(transactions);
    }

    // Group transactions by Year + Month
    java.util.Map<java.time.YearMonth, List<Transaction>> monthlyTransactions =
            allTransactions.stream()
                    .collect(
                            java.util.stream.Collectors.groupingBy(
                                    transaction ->
                                            java.time.YearMonth.from(
                                                    transaction.getCreatedAt()
                                            )
                            )
                    );

    // Convert grouped transactions into response objects
    return monthlyTransactions.entrySet()
            .stream()

            // Sort oldest month -> newest month
            .sorted(
                    java.util.Map.Entry.comparingByKey()
            )

            .map(entry -> {

                java.time.YearMonth yearMonth = entry.getKey();

                List<Transaction> transactions = entry.getValue();

                BigDecimal deposits = BigDecimal.ZERO;
                BigDecimal withdrawals = BigDecimal.ZERO;
                BigDecimal transfersIn = BigDecimal.ZERO;
                BigDecimal transfersOut = BigDecimal.ZERO;

                for (Transaction transaction : transactions) {

                    BigDecimal amount = transaction.getAmount();

                    switch (transaction.getTransactionType()) {

                        case DEPOSIT:
                            deposits = deposits.add(amount);
                            break;

                        case WITHDRAW:
                            withdrawals = withdrawals.add(amount);
                            break;

                        case TRANSFER_IN:
                            transfersIn = transfersIn.add(amount);
                            break;

                        case TRANSFER_OUT:
                            transfersOut = transfersOut.add(amount);
                            break;
                    }
                }

                return new MonthlyTransactionResponse(
                        yearMonth.getMonth()
                                .getDisplayName(
                                        java.time.format.TextStyle.FULL,
                                        java.util.Locale.ENGLISH
                                ),
                        deposits,
                        withdrawals,
                        transfersIn,
                        transfersOut
                );
            })
            .toList();
}

   

@Override
public GoalAnalyticsResponse getGoalAnalytics() {

    // Get authenticated Spring Security user
    org.springframework.security.core.userdetails.User securityUser =
            (org.springframework.security.core.userdetails.User)
                    SecurityContextHolder
                            .getContext()
                            .getAuthentication()
                            .getPrincipal();

    // Get user's email
    String email = securityUser.getUsername();

    // Find actual SmartBank User entity
    User user = userRepository.findByEmail(email)
            .orElseThrow(() ->
                    new RuntimeException("User not found")
            );

    // Get all goals belonging to the user
    List<Goal> goals = goalRepository.findByUser(user);

    // Count total goals
    long totalGoals = goals.size();

    // Count active goals
    long activeGoals = goals.stream()
            .filter(goal -> goal.getStatus() == GoalStatus.IN_PROGRESS)
            .count();

    // Count completed goals
    long completedGoals = goals.stream()
            .filter(goal -> goal.getStatus() == GoalStatus.COMPLETED)
            .count();

    // Calculate total target amount
    BigDecimal totalTargetAmount = goals.stream()
            .map(Goal::getTargetAmount)
            .reduce(BigDecimal.ZERO, BigDecimal::add);

    // Calculate total saved amount
    BigDecimal totalSavedAmount = goals.stream()
            .map(Goal::getCurrentAmount)
            .reduce(BigDecimal.ZERO, BigDecimal::add);

    // Calculate overall progress
    BigDecimal overallProgress;

    if (totalTargetAmount.compareTo(BigDecimal.ZERO) == 0) {
        overallProgress = BigDecimal.ZERO;
    } else {
        overallProgress = totalSavedAmount
                .divide(totalTargetAmount, 4, java.math.RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
                .setScale(2, java.math.RoundingMode.HALF_UP);
    }

    // Build response
    return GoalAnalyticsResponse.builder()
            .totalGoals(totalGoals)
            .activeGoals(activeGoals)
            .completedGoals(completedGoals)
            .totalTargetAmount(totalTargetAmount)
            .totalSavedAmount(totalSavedAmount)
            .overallProgress(overallProgress)
            .build();
}



@Override
public TransferAnalyticsResponse getTransferAnalytics() {

    // Get authenticated Spring Security user
    org.springframework.security.core.userdetails.User securityUser =
            (org.springframework.security.core.userdetails.User)
                    SecurityContextHolder
                            .getContext()
                            .getAuthentication()
                            .getPrincipal();

    // Get user's email
    String email = securityUser.getUsername();

    // Find actual SmartBank User entity
    User user = userRepository.findByEmail(email)
            .orElseThrow(() ->
                    new RuntimeException("User not found")
            );

    // Get all accounts belonging to the user
    List<Account> accounts = accountRepository.findByUser(user);

    // Variables for transfer statistics
    long totalTransfers = 0;

    BigDecimal totalTransferredIn = BigDecimal.ZERO;

    BigDecimal totalTransferredOut = BigDecimal.ZERO;

    // Process transactions from all user's accounts
    for (Account account : accounts) {

        List<Transaction> transactions =
                transactionRepository.findByAccount(account);

        for (Transaction transaction : transactions) {

            BigDecimal amount = transaction.getAmount();

            switch (transaction.getTransactionType()) {

                case TRANSFER_IN:
                    totalTransfers++;
                    totalTransferredIn =
                            totalTransferredIn.add(amount);
                    break;

                case TRANSFER_OUT:
                    totalTransfers++;
                    totalTransferredOut =
                            totalTransferredOut.add(amount);
                    break;

                default:
                    break;
            }
        }
    }

    // Calculate net transfer amount
    BigDecimal netTransferAmount =
            totalTransferredIn.subtract(totalTransferredOut);

    // Build response
    return TransferAnalyticsResponse.builder()
            .totalTransfers(totalTransfers)
            .totalTransferredIn(totalTransferredIn)
            .totalTransferredOut(totalTransferredOut)
            .netTransferAmount(netTransferAmount)
            .build();
}



@Override
public FinancialSummaryResponse getFinancialSummary() {

    // Get authenticated Spring Security user
    org.springframework.security.core.userdetails.User securityUser =
            (org.springframework.security.core.userdetails.User)
                    SecurityContextHolder
                            .getContext()
                            .getAuthentication()
                            .getPrincipal();

    // Get user's email
    String email = securityUser.getUsername();

    // Find actual SmartBank User entity
    User user = userRepository.findByEmail(email)
            .orElseThrow(() ->
                    new RuntimeException("User not found")
            );

    // Get all accounts belonging to the user
    List<Account> accounts = accountRepository.findByUser(user);

    // Calculate total balance
    BigDecimal totalBalance = accounts.stream()
            .map(Account::getBalance)
            .reduce(BigDecimal.ZERO, BigDecimal::add);

    // Variables for financial statistics
    BigDecimal totalDeposits = BigDecimal.ZERO;
    BigDecimal totalWithdrawals = BigDecimal.ZERO;
    BigDecimal totalTransferredIn = BigDecimal.ZERO;
    BigDecimal totalTransferredOut = BigDecimal.ZERO;

    // Process transactions from all user's accounts
    for (Account account : accounts) {

        List<Transaction> transactions =
                transactionRepository.findByAccount(account);

        for (Transaction transaction : transactions) {

            BigDecimal amount = transaction.getAmount();

            switch (transaction.getTransactionType()) {

                case DEPOSIT:
                    totalDeposits = totalDeposits.add(amount);
                    break;

                case WITHDRAW:
                    totalWithdrawals = totalWithdrawals.add(amount);
                    break;

                case TRANSFER_IN:
                    totalTransferredIn =
                            totalTransferredIn.add(amount);
                    break;

                case TRANSFER_OUT:
                    totalTransferredOut =
                            totalTransferredOut.add(amount);
                    break;

                default:
                    break;
            }
        }
    }

    // Calculate net cash flow
    BigDecimal netCashFlow =
            totalDeposits
                    .add(totalTransferredIn)
                    .subtract(totalWithdrawals)
                    .subtract(totalTransferredOut);

    // Get all goals belonging to the user
    List<Goal> goals = goalRepository.findByUser(user);

    // Calculate total goal savings
    BigDecimal totalGoalSavings = goals.stream()
            .map(Goal::getCurrentAmount)
            .reduce(BigDecimal.ZERO, BigDecimal::add);

    // Build financial summary response
    return FinancialSummaryResponse.builder()
            .totalBalance(totalBalance)
            .totalDeposits(totalDeposits)
            .totalWithdrawals(totalWithdrawals)
            .totalTransferredIn(totalTransferredIn)
            .totalTransferredOut(totalTransferredOut)
            .netCashFlow(netCashFlow)
            .totalGoalSavings(totalGoalSavings)
            .build();
}






         }
