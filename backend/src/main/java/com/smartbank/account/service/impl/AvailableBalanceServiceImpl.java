// AvailableBalanceServiceImpl.java

package com.smartbank.account.service.impl;

import java.math.BigDecimal;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.smartbank.account.entity.Account;
import com.smartbank.account.entity.AccountStatus;
import com.smartbank.account.repository.AccountRepository;
import com.smartbank.account.service.AvailableBalanceService;
import com.smartbank.exception.InsufficientBalanceException;
import com.smartbank.goal.entity.Goal;
import com.smartbank.goal.entity.GoalStatus;
import com.smartbank.goal.repository.GoalRepository;
import com.smartbank.user.entity.User;
import com.smartbank.user.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AvailableBalanceServiceImpl implements AvailableBalanceService {

    private final AccountRepository accountRepository;
    private final GoalRepository goalRepository;
    private final UserRepository userRepository;

    @Override
    public BigDecimal getAvailableBalance() {

        User user = getAuthenticatedUser();

        BigDecimal total = accountRepository.findByUser(user)
                .stream()
                .filter(account ->
                        account.getStatus() == AccountStatus.ACTIVE)
                .map(Account::getBalance)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal reserved = goalRepository.findByUser(user)
                .stream()
                .filter(goal -> goal.getStatus() != GoalStatus.CANCELLED)
                .map(Goal::getCurrentAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return total.subtract(reserved);
    }

    @Override
    public void assertSpendable(BigDecimal amount) {

        BigDecimal available = getAvailableBalance();

        if (available.compareTo(amount) < 0) {
            throw new InsufficientBalanceException(
                    "Insufficient available balance. Only "
                            + available.max(BigDecimal.ZERO).toPlainString()
                            + " is spendable after reserving your savings goals.");
        }
    }

    private User getAuthenticatedUser() {

        String email = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();

        return userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new RuntimeException("Authenticated user not found"));
    }
}
