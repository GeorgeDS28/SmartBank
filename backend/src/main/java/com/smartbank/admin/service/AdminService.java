/*AdminService.java */
package com.smartbank.admin.service;

import java.util.List;

import com.smartbank.admin.dto.AdminAccountResponse;
import com.smartbank.admin.dto.AdminTransactionResponse;
import com.smartbank.admin.dto.AdminUserResponse;
import com.smartbank.admin.dto.AdminUserStatisticsResponse;
import com.smartbank.admin.dto.AdminAccountStatisticsResponse;
public interface AdminService {

    List<AdminUserResponse> getAllUsers();

    List<AdminAccountResponse> getAllAccounts();

    List<AdminTransactionResponse> getAllTransactions();
    AdminUserStatisticsResponse getUserStatistics();

    AdminAccountStatisticsResponse getAccountStatistics();
}