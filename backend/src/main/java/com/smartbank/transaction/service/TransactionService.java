/*
TransactionService.java
*/
package com.smartbank.transaction.service;

import java.math.BigDecimal;
import java.util.List;

import com.smartbank.account.entity.Account;
import com.smartbank.transaction.dto.TransactionResponse;
import com.smartbank.transaction.entity.Transaction;
import com.smartbank.transaction.enums.TransactionType;

public interface TransactionService {

    Transaction recordTransaction(
            Account account,
            TransactionType transactionType,
            BigDecimal amount,
            String description
    );

    List<TransactionResponse> getTransactions(String accountNumber);
}