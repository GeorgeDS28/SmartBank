//TransferResponse.java
package com.smartbank.transaction.dto;



import java.math.BigDecimal;

public class TransferResponse {

    private String message;
    private String fromAccountNumber;
    private String toAccountNumber;
    private BigDecimal amount;

    public TransferResponse() {
    }

    public TransferResponse(String message,
                            String fromAccountNumber,
                            String toAccountNumber,
                            BigDecimal amount) {
        this.message = message;
        this.fromAccountNumber = fromAccountNumber;
        this.toAccountNumber = toAccountNumber;
        this.amount = amount;
    }

    public String getMessage() {
        return message;
    }

    public String getFromAccountNumber() {
        return fromAccountNumber;
    }

    public String getToAccountNumber() {
        return toAccountNumber;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public void setFromAccountNumber(String fromAccountNumber) {
        this.fromAccountNumber = fromAccountNumber;
    }

    public void setToAccountNumber(String toAccountNumber) {
        this.toAccountNumber = toAccountNumber;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }
}