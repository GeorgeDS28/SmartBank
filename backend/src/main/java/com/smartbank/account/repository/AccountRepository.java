/* AccountRepository.java */


package com.smartbank.account.repository;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import java.math.BigDecimal;

import com.smartbank.account.entity.AccountStatus;
import org.springframework.data.jpa.repository.Query;
import com.smartbank.account.entity.Account;
import com.smartbank.user.entity.User;

public interface AccountRepository extends JpaRepository<Account, Long> {

    Optional<Account> findByAccountNumber(String accountNumber);

    boolean existsByAccountNumber(String accountNumber);

    List<Account> findByUser(User user);
    long countByStatus(AccountStatus status);

     @Query("SELECT COALESCE(SUM(a.balance), 0) FROM Account a")
      BigDecimal getTotalBalance();


}
