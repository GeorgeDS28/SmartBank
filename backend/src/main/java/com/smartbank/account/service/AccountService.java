/*AccountService.java */

package com.smartbank.account.service;


import java.util.List;

import com.smartbank.account.dto.AccountResponse;
import com.smartbank.account.dto.CreateAccountRequest;
import com.smartbank.transaction.dto.DepositRequest;
import com.smartbank.transaction.dto.DepositResponse;


import com.smartbank.transaction.dto.WithdrawRequest;
import com.smartbank.transaction.dto.WithdrawResponse;




public interface AccountService {

    AccountResponse createAccount(CreateAccountRequest request);

    List<AccountResponse> getMyAccounts();

    AccountResponse getAccountByNumber(String accountNumber);

    DepositResponse deposit(
        String accountNumber,
        DepositRequest request
        
      );
    

    WithdrawResponse withdraw(
        String accountNumber,
        WithdrawRequest request
            );


}