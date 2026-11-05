/* InvalidTransactionPinException.java*/


package com.smartbank.exception;

public class InvalidTransactionPinException extends RuntimeException {

    public InvalidTransactionPinException(String message) {
        super(message);
    }
}