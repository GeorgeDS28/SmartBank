/*TransactionPin.java */

package com.smartbank.transactionpin.entity;

import java.time.LocalDateTime;

import com.smartbank.user.entity.User;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
    name = "transaction_pins",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_transaction_pin_user",
            columnNames = "user_id"
        )
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TransactionPin {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // One transaction PIN per user
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(
        name = "user_id",
        nullable = false,
        unique = true
    )
    private User user;

    // BCrypt hashed PIN
    @Column(name = "pin_hash", nullable = false)
    private String pinHash;

    // Failed PIN attempts
    @Column(name = "failed_attempts", nullable = false)
    @Builder.Default
    private Integer failedAttempts = 0;

    // Temporary PIN lock expiration
    @Column(name = "locked_until")
    private LocalDateTime lockedUntil;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {

        LocalDateTime now = LocalDateTime.now();

        createdAt = now;
        updatedAt = now;

        if (failedAttempts == null) {
            failedAttempts = 0;
        }
    }

    @PreUpdate
    protected void onUpdate() {

        updatedAt = LocalDateTime.now();
    }
}