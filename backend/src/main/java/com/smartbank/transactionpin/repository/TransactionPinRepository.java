/*TransactionPinReepository.java
 * This is the repository class for TransactionPin entity.
 * It provides methods to perform CRUD operations on TransactionPin data.
 */

package com.smartbank.transactionpin.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.smartbank.transactionpin.entity.TransactionPin;

public interface TransactionPinRepository
        extends JpaRepository<TransactionPin, Long> {

    Optional<TransactionPin> findByUserId(Long userId);

    boolean existsByUserId(Long userId);

}