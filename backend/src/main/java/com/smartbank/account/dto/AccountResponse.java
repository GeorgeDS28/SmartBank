/*AccountResponse.java
 */

package com.smartbank.account.dto;

import com.smartbank.account.entity.AccountStatus;
import com.smartbank.account.entity.AccountType;
import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@Builder
public class AccountResponse {

    private String accountNumber;

    private AccountType accountType;

    private BigDecimal balance;

    private AccountStatus status;

}