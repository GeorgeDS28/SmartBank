package com.smartbank.account.service;

import com.smartbank.account.entity.Account;

public interface AccountHelperService {

    Account getUserAccount(String accountNumber);

}