/*PasswordResetToken.java
 */

package com.smartbank.passwordreset.entity;

import java.time.LocalDateTime;

import com.smartbank.user.entity.User;

import jakarta.persistence.*;
import lombok.*;

/**
 * A one-time code handed out when a user has forgotten their password. Only the
 * BCrypt hash of the code is stored, never the code itself, and a row becomes
 * useless once it is used or expires.
 */
@Entity
@Table(
    name = "password_reset_tokens",
    indexes = @Index(name = "idx_password_reset_user", columnList = "user_id")
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PasswordResetToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "code_hash", nullable = false)
    private String codeHash;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Column(name = "used", nullable = false)
    @Builder.Default
    private boolean used = false;

    @Column(name = "failed_attempts", nullable = false)
    @Builder.Default
    private Integer failedAttempts = 0;

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
