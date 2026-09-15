//GlobalExceptionHandlerTest.java


package com.smartbank.exception;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;

import jakarta.servlet.http.HttpServletRequest;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class GlobalExceptionHandlerTest {

    private GlobalExceptionHandler handler;

    private HttpServletRequest request;

    @BeforeEach
    void setUp() {
        handler = new GlobalExceptionHandler();
        request = mock(HttpServletRequest.class);

        when(request.getRequestURI())
                .thenReturn("/api/test");
    }

    @Test
    void handleEmailAlreadyExistsException_shouldReturnConflict() {

        EmailAlreadyExistsException exception =
                new EmailAlreadyExistsException(
                        "Email already exists"
                );

        ResponseEntity<ErrorResponse> response =
                handler.handleEmailAlreadyExistsException(
                        exception,
                        request
                );

        assertEquals(
                HttpStatus.CONFLICT,
                response.getStatusCode()
        );

        assertNotNull(response.getBody());

        assertEquals(
                409,
                response.getBody().getStatus()
        );

        assertEquals(
                "Email Already Exists",
                response.getBody().getError()
        );

        assertEquals(
                "Email already exists",
                response.getBody().getMessage()
        );

        assertEquals(
                "/api/test",
                response.getBody().getPath()
        );

        assertNotNull(response.getBody().getTimestamp());
    }

    @Test
    void handleValidationException_shouldReturnBadRequestWithFieldErrors()
            throws Exception {

        MethodArgumentNotValidException exception =
                mock(MethodArgumentNotValidException.class);

        BindingResult bindingResult =
                mock(BindingResult.class);

        FieldError emailError =
                new FieldError(
                        "registerRequest",
                        "email",
                        "Invalid email format"
                );

        FieldError passwordError =
                new FieldError(
                        "registerRequest",
                        "password",
                        "Password must contain at least 8 characters"
                );

        when(exception.getBindingResult())
                .thenReturn(bindingResult);

        when(bindingResult.getFieldErrors())
                .thenReturn(
                        List.of(emailError, passwordError)
                );

        ResponseEntity<ErrorResponse> response =
                handler.handleValidationException(
                        exception,
                        request
                );

        assertEquals(
                HttpStatus.BAD_REQUEST,
                response.getStatusCode()
        );

        assertNotNull(response.getBody());

        assertEquals(
                400,
                response.getBody().getStatus()
        );

        assertEquals(
                "Validation Failed",
                response.getBody().getError()
        );

        assertEquals(
                "Request validation failed",
                response.getBody().getMessage()
        );

        assertEquals(
                "/api/test",
                response.getBody().getPath()
        );

        assertNotNull(
                response.getBody().getValidationErrors()
        );

        assertEquals(
                "Invalid email format",
                response.getBody()
                        .getValidationErrors()
                        .get("email")
        );

        assertEquals(
                "Password must contain at least 8 characters",
                response.getBody()
                        .getValidationErrors()
                        .get("password")
        );
    }

    @Test
    void handleInsufficientBalanceException_shouldReturnBadRequest() {

        InsufficientBalanceException exception =
                new InsufficientBalanceException(
                        "Insufficient balance"
                );

        ResponseEntity<ErrorResponse> response =
                handler.handleInsufficientBalanceException(
                        exception,
                        request
                );

        assertEquals(
                HttpStatus.BAD_REQUEST,
                response.getStatusCode()
        );

        assertNotNull(response.getBody());

        assertEquals(
                400,
                response.getBody().getStatus()
        );

        assertEquals(
                "Insufficient Balance",
                response.getBody().getError()
        );

        assertEquals(
                "Insufficient balance",
                response.getBody().getMessage()
        );

        assertEquals(
                "/api/test",
                response.getBody().getPath()
        );
    }

    @Test
    void handleAccountNotFoundException_shouldReturnNotFound() {

        AccountNotFoundException exception =
                new AccountNotFoundException(
                        "Account not found"
                );

        ResponseEntity<ErrorResponse> response =
                handler.handleAccountNotFoundException(
                        exception,
                        request
                );

        assertEquals(
                HttpStatus.NOT_FOUND,
                response.getStatusCode()
        );

        assertNotNull(response.getBody());

        assertEquals(
                404,
                response.getBody().getStatus()
        );

        assertEquals(
                "Account Not Found",
                response.getBody().getError()
        );

        assertEquals(
                "Account not found",
                response.getBody().getMessage()
        );
    }

    @Test
    void handleUnauthorizedAccountAccessException_shouldReturnForbidden() {

        UnauthorizedAccountAccessException exception =
                new UnauthorizedAccountAccessException(
                        "You are not authorized to access this account"
                );

        ResponseEntity<ErrorResponse> response =
                handler.handleUnauthorizedAccountAccessException(
                        exception,
                        request
                );

        assertEquals(
                HttpStatus.FORBIDDEN,
                response.getStatusCode()
        );

        assertNotNull(response.getBody());

        assertEquals(
                403,
                response.getBody().getStatus()
        );

        assertEquals(
                "Unauthorized Account Access",
                response.getBody().getError()
        );

        assertEquals(
                "You are not authorized to access this account",
                response.getBody().getMessage()
        );
    }

    @Test
    void handleInactiveAccountException_shouldReturnBadRequest() {

        InactiveAccountException exception =
                new InactiveAccountException(
                        "Account is inactive"
                );

        ResponseEntity<ErrorResponse> response =
                handler.handleInactiveAccountException(
                        exception,
                        request
                );

        assertEquals(
                HttpStatus.BAD_REQUEST,
                response.getStatusCode()
        );

        assertNotNull(response.getBody());

        assertEquals(
                400,
                response.getBody().getStatus()
        );

        assertEquals(
                "Inactive Account",
                response.getBody().getError()
        );

        assertEquals(
                "Account is inactive",
                response.getBody().getMessage()
        );
    }

    @Test
    void handleGoalNotFoundException_shouldReturnNotFound() {

        GoalNotFoundException exception =
                new GoalNotFoundException(
                        "Goal not found"
                );

        ResponseEntity<ErrorResponse> response =
                handler.handleGoalNotFoundException(
                        exception,
                        request
                );

        assertEquals(
                HttpStatus.NOT_FOUND,
                response.getStatusCode()
        );

        assertNotNull(response.getBody());

        assertEquals(
                404,
                response.getBody().getStatus()
        );

        assertEquals(
                "Goal Not Found",
                response.getBody().getError()
        );

        assertEquals(
                "Goal not found",
                response.getBody().getMessage()
        );
    }

    @Test
    void handleInvalidCredentialsException_shouldReturnUnauthorized() {

        InvalidCredentialsException exception =
                new InvalidCredentialsException(
                        "Invalid email or password"
                );

        ResponseEntity<ErrorResponse> response =
                handler.handleInvalidCredentialsException(
                        exception,
                        request
                );

        assertEquals(
                HttpStatus.UNAUTHORIZED,
                response.getStatusCode()
        );

        assertNotNull(response.getBody());

        assertEquals(
                401,
                response.getBody().getStatus()
        );

        assertEquals(
                "Invalid Credentials",
                response.getBody().getError()
        );

        assertEquals(
                "Invalid email or password",
                response.getBody().getMessage()
        );
    }
}