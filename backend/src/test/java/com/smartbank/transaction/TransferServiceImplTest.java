//TransferServiceImplTest.java
package com.smartbank.transaction.service.impl;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.math.BigDecimal;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.smartbank.account.entity.Account;
import com.smartbank.account.entity.AccountStatus;
import com.smartbank.account.entity.AccountType;
import com.smartbank.account.repository.AccountRepository;
import com.smartbank.account.service.AccountHelperService;

import com.smartbank.exception.AccountNotFoundException;
import com.smartbank.exception.InactiveAccountException;
import com.smartbank.exception.InsufficientBalanceException;

import com.smartbank.transaction.dto.TransferRequest;
import com.smartbank.transaction.dto.TransferResponse;
import com.smartbank.transaction.entity.Transaction;
import com.smartbank.transaction.enums.TransactionType;
import com.smartbank.transaction.repository.TransactionRepository;


@ExtendWith(MockitoExtension.class)
class TransferServiceImplTest {

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private AccountHelperService accountHelperService;

    @InjectMocks
    private TransferServiceImpl transferService;

    private Account sender;
    private Account receiver;

    @BeforeEach
    void setUp() {

        sender = Account.builder()
                .id(1L)
                .accountNumber("SB11111111")
                .accountType(AccountType.SAVINGS)
                .balance(new BigDecimal("10000.00"))
                .status(AccountStatus.ACTIVE)
                .build();

        receiver = Account.builder()
                .id(2L)
                .accountNumber("SB22222222")
                .accountType(AccountType.SAVINGS)
                .balance(new BigDecimal("5000.00"))
                .status(AccountStatus.ACTIVE)
                .build();
    }


    @Test
    void transfer_success() {

        TransferRequest request = new TransferRequest();

        request.setFromAccountNumber("SB11111111");
        request.setToAccountNumber("SB22222222");
        request.setAmount(new BigDecimal("3000.00"));
        request.setDescription("Rent payment");


        when(accountHelperService.getUserAccount("SB11111111"))
                .thenReturn(sender);

        when(accountRepository.findByAccountNumber("SB22222222"))
                .thenReturn(Optional.of(receiver));


        TransferResponse response =
                transferService.transfer(request);


        assertNotNull(response);

        assertEquals(
                "Transfer successful",
                response.getMessage()
        );

        assertEquals(
                "SB11111111",
                response.getFromAccountNumber()
        );

        assertEquals(
                "SB22222222",
                response.getToAccountNumber()
        );

        assertEquals(
                new BigDecimal("3000.00"),
                response.getAmount()
        );


        // Verify balances
        assertEquals(
                new BigDecimal("7000.00"),
                sender.getBalance()
        );

        assertEquals(
                new BigDecimal("8000.00"),
                receiver.getBalance()
        );


        // Verify account saves
        verify(accountRepository, times(1))
                .save(sender);

        verify(accountRepository, times(1))
                .save(receiver);


        // Verify two transaction records were created
        verify(transactionRepository, times(2))
                .save(any(Transaction.class));
    }


    @Test
    void transfer_createsCorrectTransactionRecords() {

        TransferRequest request = new TransferRequest();

        request.setFromAccountNumber("SB11111111");
        request.setToAccountNumber("SB22222222");
        request.setAmount(new BigDecimal("2000.00"));
        request.setDescription("Shopping");


        when(accountHelperService.getUserAccount("SB11111111"))
                .thenReturn(sender);

        when(accountRepository.findByAccountNumber("SB22222222"))
                .thenReturn(Optional.of(receiver));


        transferService.transfer(request);


        ArgumentCaptor<Transaction> transactionCaptor =
                ArgumentCaptor.forClass(Transaction.class);

        verify(transactionRepository, times(2))
                .save(transactionCaptor.capture());


        Transaction senderTransaction =
                transactionCaptor.getAllValues().get(0);

        Transaction receiverTransaction =
                transactionCaptor.getAllValues().get(1);


        // Sender transaction
        assertEquals(
                TransactionType.TRANSFER_OUT,
                senderTransaction.getTransactionType()
        );

        assertEquals(
                new BigDecimal("2000.00"),
                senderTransaction.getAmount()
        );

        assertEquals(
                "Shopping",
                senderTransaction.getDescription()
        );

        assertEquals(
                sender,
                senderTransaction.getAccount()
        );


        // Receiver transaction
        assertEquals(
                TransactionType.TRANSFER_IN,
                receiverTransaction.getTransactionType()
        );

        assertEquals(
                new BigDecimal("2000.00"),
                receiverTransaction.getAmount()
        );

        assertEquals(
                "Shopping",
                receiverTransaction.getDescription()
        );

        assertEquals(
                receiver,
                receiverTransaction.getAccount()
        );


        // Transaction references should be generated
        assertNotNull(
                senderTransaction.getTransactionReference()
        );

        assertNotNull(
                receiverTransaction.getTransactionReference()
        );
    }


    @Test
    void transfer_receiverAccountNotFound_throwsException() {

        TransferRequest request = new TransferRequest();

        request.setFromAccountNumber("SB11111111");
        request.setToAccountNumber("SB99999999");
        request.setAmount(new BigDecimal("1000.00"));


        when(accountHelperService.getUserAccount("SB11111111"))
                .thenReturn(sender);

        when(accountRepository.findByAccountNumber("SB99999999"))
                .thenReturn(Optional.empty());


        assertThrows(
                AccountNotFoundException.class,
                () -> transferService.transfer(request)
        );


        verify(accountRepository, never())
                .save(any(Account.class));

        verify(transactionRepository, never())
                .save(any(Transaction.class));
    }


    @Test
    void transfer_selfTransfer_throwsException() {

        TransferRequest request = new TransferRequest();

        request.setFromAccountNumber("SB11111111");
        request.setToAccountNumber("SB11111111");
        request.setAmount(new BigDecimal("1000.00"));


        when(accountHelperService.getUserAccount("SB11111111"))
                .thenReturn(sender);

        when(accountRepository.findByAccountNumber("SB11111111"))
                .thenReturn(Optional.of(sender));


        assertThrows(
                IllegalArgumentException.class,
                () -> transferService.transfer(request)
        );


        verify(accountRepository, never())
                .save(any(Account.class));

        verify(transactionRepository, never())
                .save(any(Transaction.class));
    }


    @Test
    void transfer_senderInactive_throwsException() {

        sender.setStatus(AccountStatus.INACTIVE);

        TransferRequest request = new TransferRequest();

        request.setFromAccountNumber("SB11111111");
        request.setToAccountNumber("SB22222222");
        request.setAmount(new BigDecimal("1000.00"));


        when(accountHelperService.getUserAccount("SB11111111"))
                .thenReturn(sender);

        when(accountRepository.findByAccountNumber("SB22222222"))
                .thenReturn(Optional.of(receiver));


        assertThrows(
                InactiveAccountException.class,
                () -> transferService.transfer(request)
        );


        verify(accountRepository, never())
                .save(any(Account.class));

        verify(transactionRepository, never())
                .save(any(Transaction.class));
    }


    @Test
    void transfer_receiverInactive_throwsException() {

        receiver.setStatus(AccountStatus.INACTIVE);

        TransferRequest request = new TransferRequest();

        request.setFromAccountNumber("SB11111111");
        request.setToAccountNumber("SB22222222");
        request.setAmount(new BigDecimal("1000.00"));


        when(accountHelperService.getUserAccount("SB11111111"))
                .thenReturn(sender);

        when(accountRepository.findByAccountNumber("SB22222222"))
                .thenReturn(Optional.of(receiver));


        assertThrows(
                InactiveAccountException.class,
                () -> transferService.transfer(request)
        );


        verify(accountRepository, never())
                .save(any(Account.class));

        verify(transactionRepository, never())
                .save(any(Transaction.class));
    }


    @Test
    void transfer_zeroAmount_throwsException() {

        TransferRequest request = new TransferRequest();

        request.setFromAccountNumber("SB11111111");
        request.setToAccountNumber("SB22222222");
        request.setAmount(BigDecimal.ZERO);


        when(accountHelperService.getUserAccount("SB11111111"))
                .thenReturn(sender);

        when(accountRepository.findByAccountNumber("SB22222222"))
                .thenReturn(Optional.of(receiver));


        assertThrows(
                IllegalArgumentException.class,
                () -> transferService.transfer(request)
        );


        verify(accountRepository, never())
                .save(any(Account.class));

        verify(transactionRepository, never())
                .save(any(Transaction.class));
    }


    @Test
    void transfer_negativeAmount_throwsException() {

        TransferRequest request = new TransferRequest();

        request.setFromAccountNumber("SB11111111");
        request.setToAccountNumber("SB22222222");
        request.setAmount(new BigDecimal("-500.00"));


        when(accountHelperService.getUserAccount("SB11111111"))
                .thenReturn(sender);

        when(accountRepository.findByAccountNumber("SB22222222"))
                .thenReturn(Optional.of(receiver));


        assertThrows(
                IllegalArgumentException.class,
                () -> transferService.transfer(request)
        );


        verify(accountRepository, never())
                .save(any(Account.class));

        verify(transactionRepository, never())
                .save(any(Transaction.class));
    }


    @Test
    void transfer_insufficientBalance_throwsException() {

        TransferRequest request = new TransferRequest();

        request.setFromAccountNumber("SB11111111");
        request.setToAccountNumber("SB22222222");
        request.setAmount(new BigDecimal("15000.00"));


        when(accountHelperService.getUserAccount("SB11111111"))
                .thenReturn(sender);

        when(accountRepository.findByAccountNumber("SB22222222"))
                .thenReturn(Optional.of(receiver));


        assertThrows(
                InsufficientBalanceException.class,
                () -> transferService.transfer(request)
        );


        // Sender balance must remain unchanged
        assertEquals(
                new BigDecimal("10000.00"),
                sender.getBalance()
        );


        // Receiver balance must remain unchanged
        assertEquals(
                new BigDecimal("5000.00"),
                receiver.getBalance()
        );


        verify(accountRepository, never())
                .save(any(Account.class));

        verify(transactionRepository, never())
                .save(any(Transaction.class));
    }


    @Test
    void transfer_successWithExactBalance() {

        sender.setBalance(new BigDecimal("5000.00"));

        TransferRequest request = new TransferRequest();

        request.setFromAccountNumber("SB11111111");
        request.setToAccountNumber("SB22222222");
        request.setAmount(new BigDecimal("5000.00"));
        request.setDescription("Full balance transfer");


        when(accountHelperService.getUserAccount("SB11111111"))
                .thenReturn(sender);

        when(accountRepository.findByAccountNumber("SB22222222"))
                .thenReturn(Optional.of(receiver));


        TransferResponse response =
                transferService.transfer(request);


        assertNotNull(response);

        assertEquals(
                0,
                sender.getBalance().compareTo(BigDecimal.ZERO)
        );

        assertEquals(
                new BigDecimal("10000.00"),
                receiver.getBalance()
        );


        verify(accountRepository, times(1))
                .save(sender);

        verify(accountRepository, times(1))
                .save(receiver);

        verify(transactionRepository, times(2))
                .save(any(Transaction.class));
    }


    @Test
    void transfer_descriptionIsStoredInTransactions() {

        TransferRequest request = new TransferRequest();

        request.setFromAccountNumber("SB11111111");
        request.setToAccountNumber("SB22222222");
        request.setAmount(new BigDecimal("1000.00"));
        request.setDescription("Monthly rent");


        when(accountHelperService.getUserAccount("SB11111111"))
                .thenReturn(sender);

        when(accountRepository.findByAccountNumber("SB22222222"))
                .thenReturn(Optional.of(receiver));


        transferService.transfer(request);


        ArgumentCaptor<Transaction> captor =
                ArgumentCaptor.forClass(Transaction.class);

        verify(transactionRepository, times(2))
                .save(captor.capture());


        for (Transaction transaction : captor.getAllValues()) {

            assertEquals(
                    "Monthly rent",
                    transaction.getDescription()
            );

            assertEquals(
                    new BigDecimal("1000.00"),
                    transaction.getAmount()
            );
        }
    }
}

