//TransactionServiceImplTest.java
package com.smartbank.transaction.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.smartbank.account.entity.Account;
import com.smartbank.account.repository.AccountRepository;
import com.smartbank.account.service.AccountHelperService;
import com.smartbank.transaction.dto.TransactionResponse;
import com.smartbank.transaction.entity.Transaction;
import com.smartbank.transaction.enums.TransactionType;
import com.smartbank.transaction.repository.TransactionRepository;
import com.smartbank.user.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class TransactionServiceImplTest {

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private AccountHelperService accountHelperService;

    private TransactionServiceImpl transactionService;

    private Account account;

    @BeforeEach
    void setUp() {

        transactionService = new TransactionServiceImpl(
                transactionRepository,
                accountRepository,
                userRepository,
                accountHelperService
        );

        account = new Account();
        account.setAccountNumber("SB1234567890");
        account.setBalance(new BigDecimal("5000.00"));
    }

    @Test
    void recordTransaction_shouldCreateAndSaveTransaction() {

        BigDecimal amount = new BigDecimal("1000.00");

        Transaction savedTransaction = Transaction.builder()
                .transactionReference("TXN-ABC123456789")
                .transactionType(TransactionType.DEPOSIT)
                .amount(amount)
                .description("Cash deposit")
                .account(account)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        when(transactionRepository.save(any(Transaction.class)))
                .thenReturn(savedTransaction);

        Transaction result = transactionService.recordTransaction(
                account,
                TransactionType.DEPOSIT,
                amount,
                "Cash deposit"
        );

        assertNotNull(result);
        assertEquals(
                TransactionType.DEPOSIT,
                result.getTransactionType()
        );
        assertEquals(amount, result.getAmount());
        assertEquals("Cash deposit", result.getDescription());
        assertEquals(account, result.getAccount());

        assertNotNull(result.getTransactionReference());

        verify(transactionRepository).save(any(Transaction.class));
    }

    @Test
    void recordTransaction_shouldGenerateTransactionReference() {

        BigDecimal amount = new BigDecimal("500.00");

        Transaction savedTransaction = Transaction.builder()
                .transactionReference("TXN-ABC123456789")
                .transactionType(TransactionType.WITHDRAW)
                .amount(amount)
                .description("ATM withdrawal")
                .account(account)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        when(transactionRepository.save(any(Transaction.class)))
                .thenReturn(savedTransaction);

        Transaction result = transactionService.recordTransaction(
                account,
                TransactionType.WITHDRAW,
                amount,
                "ATM withdrawal"
        );

        assertNotNull(result.getTransactionReference());
        assertTrue(
                result.getTransactionReference().startsWith("TXN-")
        );

        verify(transactionRepository).save(any(Transaction.class));
    }

    @Test
    void getTransactions_shouldReturnTransactionResponses() {

        LocalDateTime time1 = LocalDateTime.now();
        LocalDateTime time2 = time1.minusMinutes(10);

        Transaction transaction1 = Transaction.builder()
                .transactionReference("TXN-AAA111BBB222")
                .transactionType(TransactionType.DEPOSIT)
                .amount(new BigDecimal("2000.00"))
                .description("Salary credit")
                .account(account)
                .createdAt(time1)
                .build();

        Transaction transaction2 = Transaction.builder()
                .transactionReference("TXN-CCC333DDD444")
                .transactionType(TransactionType.WITHDRAW)
                .amount(new BigDecimal("500.00"))
                .description("ATM withdrawal")
                .account(account)
                .createdAt(time2)
                .build();

        when(accountHelperService.getUserAccount(
                "SB1234567890"
        )).thenReturn(account);

        when(transactionRepository.findByAccountOrderByCreatedAtDesc(
                account
        )).thenReturn(List.of(transaction1, transaction2));

        List<TransactionResponse> result =
                transactionService.getTransactions("SB1234567890");

        assertNotNull(result);
        assertEquals(2, result.size());

        assertEquals(
                "TXN-AAA111BBB222",
                result.get(0).getTransactionReference()
        );

        assertEquals(
                TransactionType.DEPOSIT,
                result.get(0).getTransactionType()
        );

        assertEquals(
                new BigDecimal("2000.00"),
                result.get(0).getAmount()
        );

        assertEquals(
                "Salary credit",
                result.get(0).getDescription()
        );

        assertEquals(
                "TXN-CCC333DDD444",
                result.get(1).getTransactionReference()
        );

        verify(accountHelperService)
                .getUserAccount("SB1234567890");

        verify(transactionRepository)
                .findByAccountOrderByCreatedAtDesc(account);
    }

    @Test
    void getTransactions_shouldReturnEmptyListWhenNoTransactionsExist() {

        when(accountHelperService.getUserAccount(
                "SB1234567890"
        )).thenReturn(account);

        when(transactionRepository.findByAccountOrderByCreatedAtDesc(
                account
        )).thenReturn(List.of());

        List<TransactionResponse> result =
                transactionService.getTransactions("SB1234567890");

        assertNotNull(result);
        assertTrue(result.isEmpty());

        verify(accountHelperService)
                .getUserAccount("SB1234567890");

        verify(transactionRepository)
                .findByAccountOrderByCreatedAtDesc(account);
    }
}