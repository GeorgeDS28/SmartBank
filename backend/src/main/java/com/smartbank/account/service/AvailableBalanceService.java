// AvailableBalanceService.java

package com.smartbank.account.service;

import java.math.BigDecimal;

/**
 * Money the signed-in user is actually allowed to spend. Savings goals hold a
 * claim on the balance, so an account balance on its own is not spendable.
 */
public interface AvailableBalanceService {

    BigDecimal getAvailableBalance();

    void assertSpendable(BigDecimal amount);
}
