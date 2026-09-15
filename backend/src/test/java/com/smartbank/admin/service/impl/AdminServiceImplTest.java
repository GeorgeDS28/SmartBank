package com.smartbank.admin.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.smartbank.account.entity.Account;
import com.smartbank.account.entity.AccountStatus;
import com.smartbank.account.repository.AccountRepository;
import com.smartbank.admin.dto.AdminAccountResponse;
import com.smartbank.admin.dto.AdminAccountStatisticsResponse;
import com.smartbank.admin.dto.AdminTransactionResponse;
import com.smartbank.admin.dto.AdminUserResponse;
import com.smartbank.admin.dto.AdminUserStatisticsResponse;
import com.smartbank.transaction.entity.Transaction;




import com.smartbank.transaction.repository.TransactionRepository;
import com.smartbank.user.entity.User;
import com.smartbank.user.enums.Role;
import com.smartbank.user.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class AdminServiceImplTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private TransactionRepository transactionRepository;

    private AdminServiceImpl adminService;

    @BeforeEach
    void setUp() {
        adminService = new AdminServiceImpl(
                userRepository,
                accountRepository,
                transactionRepository
        );
    }

    @Test
    void getAllUsers_shouldMapUsersToResponses() {

        User user = new User();

        user.setId(1L);
        user.setFirstName("George");
        user.setLastName("Admin");
        user.setEmail("george@example.com");
        user.setPhone("9876543210");
        user.setRole(Role.ROLE_USER);

        when(userRepository.findAll()).thenReturn(List.of(user));

        List<AdminUserResponse> result =
                adminService.getAllUsers();

        assertNotNull(result);
        assertEquals(1, result.size());

        AdminUserResponse response = result.get(0);

        assertEquals(1L, response.getId());
        assertEquals("George", response.getFirstName());
        assertEquals("Admin", response.getLastName());
        assertEquals("george@example.com", response.getEmail());
        assertEquals("9876543210", response.getPhone());
        assertEquals(Role.ROLE_USER, response.getRole());

        verify(userRepository).findAll();
    }

    @Test
    void getAllAccounts_shouldMapAccountsToResponses() {

        User user = new User();

        user.setId(1L);
        user.setFirstName("George");
        user.setLastName("Admin");

        Account account = org.mockito.Mockito.mock(Account.class);

        when(account.getId()).thenReturn(10L);
        when(account.getAccountNumber()).thenReturn("SB123456789");
        when(account.getBalance()).thenReturn(new BigDecimal("5000.00"));
        when(account.getUser()).thenReturn(user);

        when(accountRepository.findAll()).thenReturn(List.of(account));

        List<AdminAccountResponse> result =
                adminService.getAllAccounts();

        assertNotNull(result);
        assertEquals(1, result.size());

        AdminAccountResponse response = result.get(0);

        assertEquals(10L, response.getId());
        assertEquals("SB123456789", response.getAccountNumber());
        assertEquals(new BigDecimal("5000.00"), response.getBalance());
        assertEquals(1L, response.getUserId());
        assertEquals("George Admin", response.getUserName());

        verify(accountRepository).findAll();
    }

    @Test
    void getAllTransactions_shouldMapTransactionsToResponses() {

        Account account = org.mockito.Mockito.mock(Account.class);

        when(account.getId()).thenReturn(10L);
        when(account.getAccountNumber()).thenReturn("SB123456789");

        Transaction transaction =
                org.mockito.Mockito.mock(Transaction.class);

        when(transaction.getId()).thenReturn(100L);
        when(transaction.getTransactionReference())
                .thenReturn("TXN-001");
        when(transaction.getAmount())
                .thenReturn(new BigDecimal("1000.00"));
        when(transaction.getDescription())
                .thenReturn("Test transaction");
        when(transaction.getAccount())
                .thenReturn(account);

        when(transactionRepository.findAll())
                .thenReturn(List.of(transaction));

        List<AdminTransactionResponse> result =
                adminService.getAllTransactions();

        assertNotNull(result);
        assertEquals(1, result.size());

        AdminTransactionResponse response = result.get(0);

        assertEquals(100L, response.getId());
        assertEquals("TXN-001", response.getTransactionReference());
        assertEquals(new BigDecimal("1000.00"), response.getAmount());
        assertEquals("Test transaction", response.getDescription());
        assertEquals(10L, response.getAccountId());
        assertEquals("SB123456789", response.getAccountNumber());

        verify(transactionRepository).findAll();
    }

    @Test
    void getUserStatistics_shouldReturnCorrectStatistics() {

        when(userRepository.count()).thenReturn(10L);
        when(userRepository.countByRole(Role.ROLE_ADMIN))
                .thenReturn(2L);
        when(userRepository.countByRole(Role.ROLE_USER))
                .thenReturn(8L);

        AdminUserStatisticsResponse result =
                adminService.getUserStatistics();

        assertNotNull(result);



       
        assertEquals(10L, result.getTotalUsers());
        assertEquals(2L, result.getTotalAdmins());
        assertEquals(8L, result.getTotalNormalUsers());




        verify(userRepository).count();
        verify(userRepository).countByRole(Role.ROLE_ADMIN);
        verify(userRepository).countByRole(Role.ROLE_USER);
    }

    @Test
    void getAccountStatistics_shouldReturnCorrectStatistics() {

        when(accountRepository.count()).thenReturn(10L);

        when(accountRepository.countByStatus(AccountStatus.ACTIVE))
                .thenReturn(7L);

        when(accountRepository.getTotalBalance())
                .thenReturn(new BigDecimal("50000.00"));

        AdminAccountStatisticsResponse result =
                adminService.getAccountStatistics();

        assertNotNull(result);

                
              assertEquals(10L, result.getTotalAccounts());
              assertEquals(7L, result.getActiveAccounts());
              assertEquals(3L, result.getInactiveAccounts());
              assertEquals(
                 new BigDecimal("50000.00"),
                  result.getTotalBalance()
                  ); 



        verify(accountRepository).count();
        verify(accountRepository)
                .countByStatus(AccountStatus.ACTIVE);
        verify(accountRepository).getTotalBalance();
    }
}