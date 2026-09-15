//TransferServiceImpl.java



package com.smartbank.transaction.service.impl;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.smartbank.account.entity.Account;
import com.smartbank.account.entity.AccountStatus;
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
import com.smartbank.transaction.service.TransferService;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


@Service
@Transactional
public class TransferServiceImpl implements TransferService{

private static final Logger log =
            LoggerFactory.getLogger(TransferServiceImpl.class);


private final AccountRepository accountRepository;

private final TransactionRepository transactionRepository;

private final AccountHelperService accountHelperService;


  public TransferServiceImpl(AccountRepository accountRepository,
                               TransactionRepository transactionRepository,
                               AccountHelperService accountHelperService) {
        this.accountRepository = accountRepository;
        this.transactionRepository = transactionRepository;
        this.accountHelperService = accountHelperService;
    }



 @Override
    public TransferResponse transfer(TransferRequest request) {

       


        Account sender = accountHelperService.getUserAccount(
        request.getFromAccountNumber());


        Account receiver = accountRepository
        .findByAccountNumber(request.getToAccountNumber())
        .orElseThrow(() ->
                new AccountNotFoundException("Receiver account not found"));

        
        //prevent self transfer
        if (sender.getAccountNumber().equals(receiver.getAccountNumber())) {
        throw new IllegalArgumentException("Cannot transfer to the same account");
         }

         //check both accounts are active 
              if (sender.getStatus() != AccountStatus.ACTIVE) {
          throw new InactiveAccountException("Sender account is inactive");
              }

        if (receiver.getStatus() != AccountStatus.ACTIVE) {
            throw new InactiveAccountException("Receiver account is inactive");
           }
        

        

        // Validate the transfer amount
             if (request.getAmount().compareTo(java.math.BigDecimal.ZERO) <= 0) {
                 throw new IllegalArgumentException("Transfer amount must be greater than zero");
                       }



        if (sender.getBalance().compareTo(request.getAmount()) < 0) {
                log.warn("Insufficient balance for transfer");
    throw new InsufficientBalanceException("Insufficient balance");
        }                 
        
  


        sender.setBalance(
        sender.getBalance().subtract(request.getAmount()));

        receiver.setBalance(
        receiver.getBalance().add(request.getAmount()));

        

        accountRepository.save(sender);
        accountRepository.save(receiver);




        Transaction senderTransaction = Transaction.builder()
        .transactionReference(generateTransactionReference())
        .transactionType(TransactionType.TRANSFER_OUT)
        .amount(request.getAmount())
        .description(request.getDescription())
        .account(sender)
        .build();

Transaction receiverTransaction = Transaction.builder()
        .transactionReference(generateTransactionReference())
        .transactionType(TransactionType.TRANSFER_IN)
        .amount(request.getAmount())
        .description(request.getDescription())
        .account(receiver)
        .build();

transactionRepository.save(senderTransaction);
transactionRepository.save(receiverTransaction);
      
log.info("Money transferred successfully");


      return new TransferResponse(
                "Transfer successful",
                sender.getAccountNumber(),
                receiver.getAccountNumber(),
                request.getAmount()
                );
    }



    private String generateTransactionReference()
     {
    return "TXN" + System.currentTimeMillis();
        }




}