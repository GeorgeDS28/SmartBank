/*PasswordResetTokenRepository.java
 */

package com.smartbank.passwordreset.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.smartbank.passwordreset.entity.PasswordResetToken;

public interface PasswordResetTokenRepository
        extends JpaRepository<PasswordResetToken, Long> {

    // Newest first, with the identifier breaking ties so two codes handed out
    // in the same instant still have one clear winner.
    Optional<PasswordResetToken> findTopByUserIdOrderByCreatedAtDescIdDesc(
            Long userId);

    // A new request retires whatever code is still outstanding, so only the
    // most recent one can ever be redeemed.
    @Modifying
    @Query("""
            update PasswordResetToken t
               set t.used = true,
                   t.updatedAt = CURRENT_TIMESTAMP
             where t.user.id = :userId
               and t.used = false
            """)
    int retireOutstanding(@Param("userId") Long userId);
}
