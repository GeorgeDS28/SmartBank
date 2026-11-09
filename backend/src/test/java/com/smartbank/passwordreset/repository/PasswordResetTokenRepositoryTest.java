//PasswordResetTokenRepositoryTest.java
package com.smartbank.passwordreset.repository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDateTime;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;

import com.smartbank.passwordreset.entity.PasswordResetToken;
import com.smartbank.user.entity.User;
import com.smartbank.user.enums.Role;
import com.smartbank.user.repository.UserRepository;

/**
 * The queries that decide which code can be redeemed are JPQL, not Java, so
 * they are exercised against a real database here.
 */
@DataJpaTest
@ActiveProfiles("test")
class PasswordResetTokenRepositoryTest {

    @Autowired
    private PasswordResetTokenRepository passwordResetTokenRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TestEntityManager entityManager;

    private User target;
    private User other;

    @BeforeEach
    void setUp() {

        target = userRepository.save(user("target@example.com"));
        other = userRepository.save(user("other@example.com"));
    }

    private User user(String email) {

        User user = new User();

        user.setFirstName("Reset");
        user.setLastName("Tester");
        user.setEmail(email);
        user.setPassword("stored-hash");
        user.setPhone("9876543210");
        user.setRole(Role.ROLE_USER);

        return user;
    }

    private PasswordResetToken token(User owner, boolean used) {

        return PasswordResetToken.builder()
                .user(owner)
                .codeHash("hash-of-a-code")
                .expiresAt(LocalDateTime.now().plusMinutes(15))
                .used(used)
                .failedAttempts(0)
                .build();
    }

    @Test
    void retireOutstanding_marksOnlyTheUnusedCodesOfThatUser() {

        PasswordResetToken unused = passwordResetTokenRepository
                .save(token(target, false));
        PasswordResetToken alreadyUsed = passwordResetTokenRepository
                .save(token(target, true));
        PasswordResetToken otherUsers = passwordResetTokenRepository
                .save(token(other, false));

        entityManager.flush();

        int retired = passwordResetTokenRepository
                .retireOutstanding(target.getId());

        assertEquals(1, retired);

        entityManager.clear();

        assertTrue(passwordResetTokenRepository
                .findById(unused.getId()).orElseThrow().isUsed());
        assertTrue(passwordResetTokenRepository
                .findById(alreadyUsed.getId()).orElseThrow().isUsed(),
                "a redeemed code is left as it was");
        assertFalse(passwordResetTokenRepository
                .findById(otherUsers.getId()).orElseThrow().isUsed(),
                "another user's code is untouched");
    }

    @Test
    void newestCodeOfAUser_isTheOneReturnedFirst() {

        passwordResetTokenRepository.save(token(target, true));
        PasswordResetToken newest = passwordResetTokenRepository
                .save(token(target, false));

        entityManager.flush();
        entityManager.clear();

        Optional<PasswordResetToken> found = passwordResetTokenRepository
                .findTopByUserIdOrderByCreatedAtDescIdDesc(target.getId());

        assertEquals(newest.getId(), found.orElseThrow().getId());
    }

    @Test
    void aUserWithNoCode_hasNoEntryToRedeem() {

        assertTrue(passwordResetTokenRepository
                .findTopByUserIdOrderByCreatedAtDescIdDesc(other.getId())
                .isEmpty());
    }

    @Test
    void theCodeHashColumnStoresWhatWasGivenAndNothingElse() {

        PasswordResetToken saved = passwordResetTokenRepository
                .save(token(target, false));

        entityManager.flush();
        entityManager.clear();

        PasswordResetToken reloaded = passwordResetTokenRepository
                .findById(saved.getId()).orElseThrow();

        assertEquals("hash-of-a-code", reloaded.getCodeHash());
        assertEquals(0, reloaded.getFailedAttempts());
        assertTrue(reloaded.getExpiresAt().isAfter(LocalDateTime.now()));
    }
}
