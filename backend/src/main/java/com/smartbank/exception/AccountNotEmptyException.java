// AccountNotEmptyException.java

package com.smartbank.exception;

public class AccountNotEmptyException extends RuntimeException {

    public AccountNotEmptyException(String message) {
        super(message);
    }
}
