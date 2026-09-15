//JwtServiceTest.java
package com.smartbank.auth.jwt;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertThrows;

import io.jsonwebtoken.ExpiredJwtException;

import java.lang.reflect.Field;
import java.util.Date;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class JwtServiceTest {

    private JwtService jwtService;

    private static final String SECRET =
            "my-super-secret-key-for-smartbank-jwt-testing-123456";

    @BeforeEach
    void setUp() throws Exception {

        jwtService = new JwtService();

        setField(jwtService, "secret", SECRET);
        setField(jwtService, "jwtExpiration", 3600000L);
    }

    private void setField(
            Object target,
            String fieldName,
            Object value) throws Exception {

        Field field =
                target.getClass().getDeclaredField(fieldName);

        field.setAccessible(true);
        field.set(target, value);
    }

    @Test
    void generateToken_shouldGenerateValidToken() {

        String token =
                jwtService.generateToken("george@example.com");

        assertNotNull(token);
        assertFalse(token.isBlank());
    }

    @Test
    void extractEmail_shouldReturnEmailFromToken() {

        String email = "george@example.com";

        String token =
                jwtService.generateToken(email);

        String extractedEmail =
                jwtService.extractEmail(token);

        assertEquals(email, extractedEmail);
    }

    @Test
    void extractExpiration_shouldReturnFutureExpiration() {

        String token =
                jwtService.generateToken("george@example.com");

        Date expiration =
                jwtService.extractExpiration(token);

        assertNotNull(expiration);
        assertTrue(expiration.after(new Date()));
    }

    @Test
    void isTokenExpired_shouldReturnFalseForValidToken() {

        String token =
                jwtService.generateToken("george@example.com");

        boolean expired =
                jwtService.isTokenExpired(token);

        assertFalse(expired);
    }




     @Test
void isTokenExpired_shouldThrowExceptionForExpiredToken()
        throws Exception {

    setField(jwtService, "jwtExpiration", -1000L);

    String token =
            jwtService.generateToken("george@example.com");

    assertThrows(
            ExpiredJwtException.class,
            () -> jwtService.isTokenExpired(token)
    );
}






    @Test
    void isTokenValid_shouldReturnTrueForCorrectEmailAndValidToken() {

        String email = "george@example.com";

        String token =
                jwtService.generateToken(email);

        boolean valid =
                jwtService.isTokenValid(token, email);

        assertTrue(valid);
    }

    @Test
    void isTokenValid_shouldReturnFalseForDifferentEmail() {

        String token =
                jwtService.generateToken("george@example.com");

        boolean valid =
                jwtService.isTokenValid(
                        token,
                        "rohan@example.com"
                );

        assertFalse(valid);
    }

    @Test
void isTokenValid_shouldThrowExceptionForExpiredToken()
        throws Exception {

    setField(jwtService, "jwtExpiration", -1000L);

    String token =
            jwtService.generateToken("george@example.com");

    assertThrows(
            ExpiredJwtException.class,
            () -> jwtService.isTokenValid(
                    token,
                    "george@example.com"
            )
    );
}

   





}