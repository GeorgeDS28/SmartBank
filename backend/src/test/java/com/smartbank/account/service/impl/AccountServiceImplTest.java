//AccountServiceImplTest.java

package com.smartbank.account.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import com.smartbank.account.dto.AccountResponse;
import com.smartbank.account.dto.CreateAccountRequest;
import com.smartbank.account.entity.Account;
import com.smartbank.account.entity.AccountStatus;
import com.smartbank.account.entity.AccountType;
import com.smartbank.account.repository.AccountRepository;
import com.smartbank.account.service.AccountHelperService;
import com.smartbank.exception.InactiveAccountException;
import com.smartbank.exception.InsufficientBalanceException;
import com.smartbank.transaction.dto.DepositRequest;
import com.smartbank.transaction.dto.DepositResponse;
import com.smartbank.transaction.dto.WithdrawRequest;
import com.smartbank.transaction.dto.WithdrawResponse;
import com.smartbank.transaction.enums.TransactionType;
import com.smartbank.transaction.service.TransactionService;
import com.smartbank.user.entity.User;
import com.smartbank.user.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class AccountServiceImplTest {

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private TransactionService transactionService;

    @Mock
    private AccountHelperService accountHelperService;

    private AccountServiceImpl accountService;

    private User user;

    private Account account;

    @BeforeEach
    void setUp() {

        accountService = new AccountServiceImpl(
                accountRepository,
                userRepository,
                transactionService,
                accountHelperService
        );

        user = new User();
        user.setEmail("george@example.com");

        account = Account.builder()
                .accountNumber("SB12345678")
                .accountType(AccountType.SAVINGS)
                .balance(new BigDecimal("5000.00"))
                .status(AccountStatus.ACTIVE)
                .user(user)
                .build();

        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(
                        "george@example.com",
                        null,
                        List.of()
                )
        );
    }

    @org.junit.jupiter.api.AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void createAccount_shouldCreateAndReturnAccount() {

        CreateAccountRequest request = new CreateAccountRequest();

        request.setAccountType(AccountType.SAVINGS);

        when(userRepository.findByEmail("george@example.com"))
                .thenReturn(Optional.of(user));

        when(accountRepository.existsByAccountNumber(any(String.class)))
                .thenReturn(false);

        when(accountRepository.save(any(Account.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        AccountResponse response =
                accountService.createAccount(request);

        assertNotNull(response);

        assertNotNull(response.getAccountNumber());

        assertEquals(
                AccountType.SAVINGS,
                response.getAccountType()
        );

        assertEquals(
                BigDecimal.ZERO,
                response.getBalance()
        );

        assertEquals(
                AccountStatus.ACTIVE,
                response.getStatus()
        );

        verify(userRepository)
                .findByEmail("george@example.com");

        verify(accountRepository)
                .save(any(Account.class));
    }

    @Test
    void getMyAccounts_shouldReturnUserAccounts() {

        Account secondAccount = Account.builder()
                .accountNumber("SB87654321")
                .accountType(AccountType.CURRENT)
                .balance(new BigDecimal("2500.00"))
                .status(AccountStatus.ACTIVE)
                .user(user)
                .build();

        when(userRepository.findByEmail("george@example.com"))
                .thenReturn(Optional.of(user));

        when(accountRepository.findByUser(user))
                .thenReturn(List.of(account, secondAccount));

        List<AccountResponse> response =
                accountService.getMyAccounts();

        assertNotNull(response);

        assertEquals(2, response.size());

        assertEquals(
                "SB12345678",
                response.get(0).getAccountNumber()
        );

        assertEquals(
                "SB87654321",
                response.get(1).getAccountNumber()
        );

        verify(userRepository)
                .findByEmail("george@example.com");

        verify(accountRepository)
                .findByUser(user);
    }

    @Test
    void getMyAccounts_shouldReturnEmptyListWhenNoAccountsExist() {

        when(userRepository.findByEmail("george@example.com"))
                .thenReturn(Optional.of(user));

        when(accountRepository.findByUser(user))
                .thenReturn(List.of());

        List<AccountResponse> response =
                accountService.getMyAccounts();

        assertNotNull(response);

        assertEquals(0, response.size());

        verify(accountRepository)
                .findByUser(user);
    }

    @Test
    void deposit_shouldIncreaseBalanceAndRecordTransaction() {

        DepositRequest request = new DepositRequest();

        request.setAmount(new BigDecimal("1000.00"));

        when(accountHelperService.getUserAccount("SB12345678"))
                .thenReturn(account);

        when(accountRepository.save(account))
                .thenReturn(account);

        DepositResponse response =
                accountService.deposit(
                        "SB12345678",
                        request
                );

        assertNotNull(response);

        assertEquals(
                "SB12345678",
                response.getAccountNumber()
        );

        assertEquals(
                new BigDecimal("1000.00"),
                response.getDepositedAmount()
        );

        assertEquals(
                new BigDecimal("6000.00"),
                response.getCurrentBalance()
        );

        assertEquals(
                "Deposit successful",
                response.getMessage()
        );

        verify(accountRepository)
                .save(account);

        verify(transactionService)
                .recordTransaction(
                        account,
                        TransactionType.DEPOSIT,
                        new BigDecimal("1000.00"),
                        "Cash Deposit"
                );
    }

    @Test
    void deposit_shouldThrowExceptionWhenAccountIsInactive() {

        account.setStatus(AccountStatus.INACTIVE);

        DepositRequest request = new DepositRequest();

        request.setAmount(new BigDecimal("1000.00"));

        when(accountHelperService.getUserAccount("SB12345678"))
                .thenReturn(account);

        assertThrows(
                InactiveAccountException.class,
                () -> accountService.deposit(
                        "SB12345678",
                        request
                )
        );
    }

    @Test
    void withdraw_shouldDecreaseBalanceAndRecordTransaction() {

        WithdrawRequest request = new WithdrawRequest();

        request.setAmount(new BigDecimal("1000.00"));

        when(accountHelperService.getUserAccount("SB12345678"))
                .thenReturn(account);

        when(accountRepository.save(account))
                .thenReturn(account);

        WithdrawResponse response =
                accountService.withdraw(
                        "SB12345678",
                        request
                );

        assertNotNull(response);

        assertEquals(
                "Withdrawal successful",
                response.getMessage()
        );

        assertEquals(
                "SB12345678",
                response.getAccountNumber()
        );

        assertEquals(
                new BigDecimal("1000.00"),
                response.getWithdrawnAmount()
        );

        assertEquals(
                new BigDecimal("4000.00"),
                response.getUpdatedBalance()
        );

        verify(accountRepository)
                .save(account);

        verify(transactionService)
                .recordTransaction(
                        account,
                        TransactionType.WITHDRAW,
                        new BigDecimal("1000.00"),
                        "Cash Withdrawal"
                );
    }

    @Test
    void withdraw_shouldThrowExceptionWhenAccountIsInactive() {

        account.setStatus(AccountStatus.INACTIVE);

        WithdrawRequest request = new WithdrawRequest();

        request.setAmount(new BigDecimal("1000.00"));

        when(accountHelperService.getUserAccount("SB12345678"))
                .thenReturn(account);

        assertThrows(
                InactiveAccountException.class,
                () -> accountService.withdraw(
                        "SB12345678",
                        request
                )
        );
    }

    @Test
    void withdraw_shouldThrowExceptionWhenBalanceIsInsufficient() {

        WithdrawRequest request = new WithdrawRequest();

        request.setAmount(new BigDecimal("10000.00"));

        when(accountHelperService.getUserAccount("SB12345678"))
                .thenReturn(account);

        assertThrows(
                InsufficientBalanceException.class,
                () -> accountService.withdraw(
                        "SB12345678",
                        request
                )
        );
    }

    @Test
    void getAccountByNumber_shouldReturnAccountResponse() {

        when(accountHelperService.getUserAccount("SB12345678"))
                .thenReturn(account);

        AccountResponse response =
                accountService.getAccountByNumber(
                        "SB12345678"
                );

        assertNotNull(response);

        assertEquals(
                "SB12345678",
                response.getAccountNumber()
        );

        assertEquals(
                AccountType.SAVINGS,
                response.getAccountType()
        );

        assertEquals(
                new BigDecimal("5000.00"),
                response.getBalance()
        );

        assertEquals(
                AccountStatus.ACTIVE,
                response.getStatus()
        );

        verify(accountHelperService)
                .getUserAccount("SB12345678");
    }

    @Test
    void createAccount_shouldThrowExceptionWhenUserDoesNotExist() {

        CreateAccountRequest request = new CreateAccountRequest();

        request.setAccountType(AccountType.SAVINGS);

        when(userRepository.findByEmail("george@example.com"))
                .thenReturn(Optional.empty());

        assertThrows(
                RuntimeException.class,
                () -> accountService.createAccount(request)
        );

        verify(userRepository)
                .findByEmail("george@example.com");
    }
}