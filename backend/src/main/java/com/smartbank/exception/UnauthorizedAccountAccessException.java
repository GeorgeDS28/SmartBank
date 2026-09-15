// UnauthorizedAccountAccessException.java

package com.smartbank.exception;

public class UnauthorizedAccountAccessException extends RuntimeException {

    public UnauthorizedAccountAccessException(String message) {
        super(message);
    }
}