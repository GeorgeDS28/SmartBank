//CreateAccountRequest.java

package com.smartbank.account.dto;

import com.smartbank.account.entity.AccountType;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateAccountRequest {

    @NotNull(message = "Account type is required")
    private AccountType accountType;

}