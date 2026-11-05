/*TransactionPinService.java */


package com.smartbank.transactionpin.service;

import com.smartbank.transactionpin.dto.CreatePinRequest;
import com.smartbank.transactionpin.dto.PinStatusResponse;

import com.smartbank.transactionpin.dto.ChangePinRequest;
import com.smartbank.transactionpin.dto.ResetPinRequest;


public interface TransactionPinService {

    void createPin(CreatePinRequest request);

    PinStatusResponse getPinStatus();
   
    void verifyPin(String enteredPin);
   
    void changePin(ChangePinRequest request);

    void resetPin(ResetPinRequest request);

}