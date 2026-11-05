package com.smartbank.exception;

public class TransactionPinLockedException extends RuntimeException {

    public TransactionPinLockedException(String message) {
        super(message);
    }
}