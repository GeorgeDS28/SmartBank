/*AccountHelperServiceImpl.java */


package com.smartbank.account.service.impl;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.smartbank.account.entity.Account;
import com.smartbank.account.repository.AccountRepository;
import com.smartbank.account.service.AccountHelperService;
import com.smartbank.exception.AccountNotFoundException;
import com.smartbank.exception.UnauthorizedAccountAccessException;
import com.smartbank.user.entity.User;
import com.smartbank.user.repository.UserRepository;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AccountHelperServiceImpl implements AccountHelperService {


    private static final Logger log =
        LoggerFactory.getLogger(AccountHelperServiceImpl.class);

    private final AccountRepository accountRepository;
    private final UserRepository userRepository;

    @Override
    public Account getUserAccount(String accountNumber) {

        String email = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new RuntimeException("Authenticated user not found"));

        Account account = accountRepository.findByAccountNumber(accountNumber)
                .orElseThrow(() ->
                        new AccountNotFoundException("Account not found"));

        if (!account.getUser().getId().equals(user.getId())) {
             log.warn("Unauthorized account access attempt");
    throw new UnauthorizedAccountAccessException("Access denied");
        }

        return account;
    }
}