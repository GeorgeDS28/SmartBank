/* TransactionRepository.java */

package com.smartbank.transaction.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.smartbank.account.entity.Account;
import com.smartbank.transaction.entity.Transaction;

public interface TransactionRepository extends JpaRepository<Transaction, Long> {

    List<Transaction> findByAccount(Account account);

    List<Transaction> findByAccountOrderByCreatedAtDesc(Account account);

}