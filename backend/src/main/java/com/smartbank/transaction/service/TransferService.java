package com.smartbank.transaction.service;

import com.smartbank.transaction.dto.TransferRequest;
import com.smartbank.transaction.dto.TransferResponse;

public interface TransferService {

    TransferResponse transfer(TransferRequest request);

}